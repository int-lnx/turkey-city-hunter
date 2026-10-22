import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/city_model.dart';
import '../models/city_group.dart';
import '../models/city_item.dart';
import '../data/turkey_cities_data.dart';
import '../data/best_lists_data.dart';
import '../services/admin_service.dart';

const _kUsersListKey = 'turkey_users_list_v1';
const _kActiveUserKey = 'turkey_active_user_v1';
const _kCustomBestPackagesKey = 'turkey_custom_best_packages_v1';
const _uuid = Uuid();

class CityProvider extends ChangeNotifier {
  List<String> _users = ['Varsayılan'];
  String _currentUser = 'Varsayılan';
  List<CityModel> _cities = [];
  List<BestListPackage> _bestPackages = [];
  bool _isLoading = true;
  User? _firebaseUser;

  List<String> get users => _users;
  String get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;
  List<CityModel> get cities => _cities;
  List<BestListPackage> get bestPackages => _bestPackages;
  bool get isLoading => _isLoading;

  CityProvider() {
    _init();
    try {
      _listenAuth();
    } catch (e) {
      debugPrint('Auth listener hatası: $e');
    }
  }

  void _listenAuth() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        final previousUser = _firebaseUser;
        _firebaseUser = user;

        if (user != null) {
          // Kullanıcı giriş yaptı: Buluttaki profilleri ve harita verilerini cihazla senkronize et
          await _syncFromFirestoreOnLogin();
        } else if (previousUser != null) {
          // Kullanıcı çıkış yaptı: Diğer cihaz/hesap karışmaması için temiz varsayılan duruma sıfırla
          await _resetToGuestDefaults();
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Auth state change hatası: $e');
      });
    } catch (e) {
      debugPrint('Auth listener başlatılamadı: $e');
    }
  }

  // ── User Management ────────────────────────────────────────────────────────

  Future<void> switchUser(String username) async {
    final clean = username.trim();
    if (clean.isEmpty || clean == _currentUser) return;
    if (!_users.contains(clean)) {
      _users.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kUsersListKey, _users);
    }
    _currentUser = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveUserKey, _currentUser);
    await _loadUserCities();
    await _saveToFirebaseOnly();
    notifyListeners();
  }

  /// Yeni profil/harita oluşturur.
  /// [copyFromUser] verilirse belirtilen kullanıcının haritası kaynak alınır.
  /// [copyCheckedState] false ise maddeler ve grup yapıları kopyalanır ancak işaretler (gezildi durumları) sıfırlanır.
  Future<void> addUser(
    String username, {
    String? copyFromUser,
    bool copyCheckedState = false,
  }) async {
    final clean = username.trim();
    if (clean.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<CityModel> newCities;

    if (copyFromUser != null && copyFromUser.isNotEmpty) {
      // Kaynak harita verisini al
      final sourceList = await _fetchCitiesForUser(copyFromUser);
      newCities = _cloneCities(sourceList, copyCheckedState: copyCheckedState);
    } else {
      // Buluttaki güncel Master (Varsayılan) harita
      try {
        newCities = await AdminService().getMasterCities();
      } catch (_) {
        newCities = buildDefaultCities();
      }
    }

    // Yeni kullanıcının haritasını kaydet
    final rawList = newCities.map((c) => c.toJson()).toList();
    await prefs.setString('turkey_cities_user_$clean', jsonEncode(rawList));

    if (!_users.contains(clean)) {
      _users.add(clean);
      await prefs.setStringList(_kUsersListKey, _users);
    }

    // Yeni kullanıcıya geç
    _currentUser = clean;
    _cities = newCities;
    await prefs.setString(_kActiveUserKey, _currentUser);

    // Firebase senkronizasyonu
    await _saveToFirebaseOnly();

    notifyListeners();
  }

  List<CityModel> _cloneCities(List<CityModel> source, {required bool copyCheckedState}) {
    return source.map((city) {
      return CityModel(
        id: city.id,
        name: city.name,
        isVisited: copyCheckedState ? city.isVisited : false,
        groups: city.groups.map((group) {
          return CityGroup(
            id: group.id,
            name: group.name,
            items: group.items.map((item) {
              return CityItem(
                id: item.id,
                name: item.name,
                note: item.note,
                description: item.description,
                imageUrl: item.imageUrl,
                importance: item.importance,
                isChecked: copyCheckedState ? item.isChecked : false,
                subItems: item.subItems.map((sub) {
                  return CityItem(
                    id: sub.id,
                    name: sub.name,
                    note: sub.note,
                    description: sub.description,
                    imageUrl: sub.imageUrl,
                    importance: sub.importance,
                    isChecked: copyCheckedState ? sub.isChecked : false,
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }

  Future<List<CityModel>> _fetchCitiesForUser(String username) async {
    if (username == _currentUser && _cities.isNotEmpty) {
      return _cities;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('turkey_cities_user_$username');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    // Firebase'de profil varsa oradan dene
    if (_firebaseUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .collection('profiles')
            .doc(username)
            .get();
        if (doc.exists && doc.data()?['cities'] != null) {
          final List<dynamic> list = doc.data()!['cities'];
          return list
              .map((e) => CityModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }
    return buildDefaultCities();
  }

  Future<void> deleteUser(String username) async {
    if (_users.length <= 1) return; // En az 1 profil kalsın
    _users.remove(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kUsersListKey, _users);

    // Kullanıcı yerel verisini sil
    await prefs.remove('turkey_cities_user_$username');

    // Firebase'deki profil belgesini sil
    if (_firebaseUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .collection('profiles')
            .doc(username)
            .delete();
      } catch (_) {}
    }

    if (_currentUser == username) {
      _currentUser = _users.first;
      await prefs.setString(_kActiveUserKey, _currentUser);
      await _loadUserCities();
    }
    notifyListeners();
  }

  Future<void> renameUser(String oldName, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty || clean == oldName) return;

    final prefs = await SharedPreferences.getInstance();
    final index = _users.indexOf(oldName);
    if (index != -1) {
      _users[index] = clean;
    } else {
      _users.add(clean);
    }
    await prefs.setStringList(_kUsersListKey, _users);

    // Veriyi yeni anahtara taşı
    final oldKey = 'turkey_cities_user_$oldName';
    final newKey = 'turkey_cities_user_$clean';
    final existingData = prefs.getString(oldKey);
    if (existingData != null) {
      await prefs.setString(newKey, existingData);
      await prefs.remove(oldKey);
    } else {
      final rawList = _cities.map((c) => c.toJson()).toList();
      await prefs.setString(newKey, jsonEncode(rawList));
    }

    if (_currentUser == oldName) {
      _currentUser = clean;
      await prefs.setString(_kActiveUserKey, _currentUser);
    }

    await _saveToFirebaseOnly();
    notifyListeners();
  }

  // ── Data Export & Import ────────────────────────────────────────────────────

  /// Aktif haritayı JSON metni olarak dışa aktarır.
  String exportMapData({String? targetUser}) {
    final userToExport = targetUser ?? _currentUser;
    final cityList = _cities.isNotEmpty ? _cities : buildDefaultCities();
    final payload = {
      'app': 'turkiye_kesif_haritasi',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'mapName': userToExport,
      'cities': cityList.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Dışarıdan gelen JSON verisini her zaman yeni bir harita/profil olarak içe aktarır.
  /// Var olan herhangi bir haritanın üzerine yazmaz.
  /// İçe aktarılan yeni profil adını döndürür.
  Future<String> importMapData(String jsonString, {String? customMapName}) async {
    final dynamic decoded = jsonDecode(jsonString);
    List<dynamic>? rawCities;
    String suggestedName = customMapName?.trim() ?? '';

    if (decoded is Map<String, dynamic>) {
      if (suggestedName.isEmpty) {
        suggestedName = (decoded['mapName'] as String?)?.trim() ?? '';
      }
      if (decoded['cities'] is List) {
        rawCities = decoded['cities'] as List<dynamic>;
      }
    } else if (decoded is List) {
      rawCities = decoded;
    }

    if (rawCities == null || rawCities.isEmpty) {
      throw const FormatException('Geçersiz veya boş harita verisi.');
    }

    // Şehirleri çözümle
    final importedCities = rawCities
        .map((e) => CityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (suggestedName.isEmpty) {
      suggestedName = 'İçe Aktarılan Harita';
    }

    // Var olan isimlerle çakışmayı önlemek için benzersiz bir isim üret
    String finalName = suggestedName;
    int counter = 1;
    while (_users.contains(finalName)) {
      finalName = '$suggestedName ($counter)';
      counter++;
    }

    final prefs = await SharedPreferences.getInstance();
    final rawList = importedCities.map((c) => c.toJson()).toList();
    await prefs.setString('turkey_cities_user_$finalName', jsonEncode(rawList));

    if (!_users.contains(finalName)) {
      _users.add(finalName);
      await prefs.setStringList(_kUsersListKey, _users);
    }

    // Yeni içe aktarılan haritaya geç
    _currentUser = finalName;
    _cities = importedCities;
    await prefs.setString(_kActiveUserKey, _currentUser);

    // Firebase bağlıysa oraya da kaydet
    await _saveToFirebaseOnly();

    notifyListeners();
    return finalName;
  }

  // ── Computed Stats ─────────────────────────────────────────────────────────

  /// Overall Turkey weighted completion rate [0.0–1.0]
  double get overallRate {
    final totalW = _cities.fold(0.0, (s, c) => s + c.totalWeight);
    if (totalW == 0.0) return 0.0;
    final checkedW = _cities.fold(0.0, (s, c) => s + c.checkedWeight);
    return checkedW / totalW;
  }

  String get overallPercent =>
      '${(overallRate * 100).toStringAsFixed(1)}%';

  /// Ziyaret edilen il sayısı (effectiveIsVisited: gezildi işaretlenen veya içinde gezilen yer olan iller)
  int get visitedCitiesCount =>
      _cities.where((c) => c.effectiveIsVisited).length;

  int get totalCitiesCount => _cities.length;

  /// Toplam ve tamamlanan Görmeden Ölme (mustSee) istatistikleri
  int get mustSeeTotalCount {
    int count = 0;
    for (final c in _cities) {
      for (final g in c.groups) {
        for (final item in g.items) {
          if (item.subItems.isNotEmpty) {
            count += item.subItems.where((s) => s.importance == ItemImportance.mustSee).length;
          } else if (item.importance == ItemImportance.mustSee) {
            count++;
          }
        }
      }
    }
    return count;
  }

  int get mustSeeCheckedCount {
    int count = 0;
    for (final c in _cities) {
      for (final g in c.groups) {
        for (final item in g.items) {
          if (item.subItems.isNotEmpty) {
            count += item.subItems.where((s) => s.importance == ItemImportance.mustSee && s.isChecked).length;
          } else if (item.importance == ItemImportance.mustSee && item.isChecked) {
            count++;
          }
        }
      }
    }
    return count;
  }

  double get mustSeeRate =>
      mustSeeTotalCount == 0 ? 0.0 : mustSeeCheckedCount / mustSeeTotalCount;

  String get mustSeePercent =>
      '${(mustSeeRate * 100).toStringAsFixed(1)}%';

  /// Toplam ve tamamlanan Mutlaka Görülmeli (highlyRecommended) istatistikleri
  int get highlyRecommendedTotalCount {
    int count = 0;
    for (final c in _cities) {
      for (final g in c.groups) {
        for (final item in g.items) {
          if (item.subItems.isNotEmpty) {
            count += item.subItems.where((s) => s.importance == ItemImportance.highlyRecommended).length;
          } else if (item.importance == ItemImportance.highlyRecommended) {
            count++;
          }
        }
      }
    }
    return count;
  }

  int get highlyRecommendedCheckedCount {
    int count = 0;
    for (final c in _cities) {
      for (final g in c.groups) {
        for (final item in g.items) {
          if (item.subItems.isNotEmpty) {
            count += item.subItems.where((s) => s.importance == ItemImportance.highlyRecommended && s.isChecked).length;
          } else if (item.importance == ItemImportance.highlyRecommended && item.isChecked) {
            count++;
          }
        }
      }
    }
    return count;
  }

  double get highlyRecommendedRate =>
      highlyRecommendedTotalCount == 0 ? 0.0 : highlyRecommendedCheckedCount / highlyRecommendedTotalCount;

  String get highlyRecommendedPercent =>
      '${(highlyRecommendedRate * 100).toStringAsFixed(1)}%';

  CityModel? cityById(String id) {
    try {
      return _cities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void updateItemImportance(
      String cityId, String groupId, String itemId, ItemImportance newImportance,
      {String? subItemId}) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex = _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = _cities[cityIndex].groups[groupIndex];
    final itemIndex = group.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = group.items[itemIndex];

    if (subItemId != null) {
      final subIndex = item.subItems.indexWhere((s) => s.id == subItemId);
      if (subIndex != -1) {
        item.subItems[subIndex] =
            item.subItems[subIndex].copyWith(importance: newImportance);
      }
    } else {
      group.items[itemIndex] = item.copyWith(importance: newImportance);
    }

    notifyListeners();
    _save();
  }

  bool toggleCityVisited(String cityId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return false;

    final city = _cities[cityIndex];
    if (city.checkedItems > 0 && city.effectiveIsVisited) {
      // Şehir içinde işaretlenmiş yerler varken ziyaret edilmedi yapılamaz
      return false;
    }
    _cities[cityIndex] = city.copyWith(isVisited: !city.isVisited);
    notifyListeners();
    _save();
    return true;
  }

  void editItemDetails(
    String cityId,
    String groupId,
    String itemId, {
    required String newName,
    required String newNote,
    String newDescription = '',
    String newImageUrl = '',
    String? subItemId,
  }) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex = _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = _cities[cityIndex].groups[groupIndex];
    final itemIndex = group.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = group.items[itemIndex];

    if (subItemId != null) {
      final subIndex = item.subItems.indexWhere((s) => s.id == subItemId);
      if (subIndex != -1) {
        item.subItems[subIndex] = item.subItems[subIndex].copyWith(
          name: newName,
          note: newNote,
          description: newDescription,
          imageUrl: newImageUrl,
        );
      }
    } else {
      group.items[itemIndex] = item.copyWith(
        name: newName,
        note: newNote,
        description: newDescription,
        imageUrl: newImageUrl,
      );
    }

    notifyListeners();
    _save();
  }


  void updateItemNote(String cityId, String groupId, String itemId, String note,
      {String? subItemId}) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex = _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = _cities[cityIndex].groups[groupIndex];
    final itemIndex = group.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = group.items[itemIndex];

    if (subItemId != null) {
      final subIndex = item.subItems.indexWhere((s) => s.id == subItemId);
      if (subIndex != -1) {
        item.subItems[subIndex] = item.subItems[subIndex].copyWith(note: note);
      }
    } else {
      group.items[itemIndex] = item.copyWith(note: note);
    }

    notifyListeners();
    _save();
  }

  void editItemName(String cityId, String groupId, String itemId, String newName,
      {String? subItemId}) {
    editItemDetails(cityId, groupId, itemId, newName: newName, newNote: '', subItemId: subItemId);
  }

  void toggleItem(String cityId, String groupId, String itemId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final city = _cities[cityIndex];
    final groupIndex = city.groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = city.groups[groupIndex];
    final itemIndex = group.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = group.items[itemIndex];
    if (item.subItems.isNotEmpty) {
      final targetState = !item.effectiveIsChecked;
      for (int i = 0; i < item.subItems.length; i++) {
        item.subItems[i] = item.subItems[i].copyWith(isChecked: targetState);
      }
    } else {
      group.items[itemIndex] = item.copyWith(isChecked: !item.isChecked);
    }
    // Eğer herhangi bir madde seçildiyse şehri de ziyaret edilmiş say
    if (_cities[cityIndex].checkedItems > 0 && !_cities[cityIndex].isVisited) {
      _cities[cityIndex] = _cities[cityIndex].copyWith(isVisited: true);
    }
    notifyListeners();
    _save();
  }

  void toggleSubItem(String cityId, String groupId, String itemId, String subItemId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex = _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final group = _cities[cityIndex].groups[groupIndex];
    final itemIndex = group.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = group.items[itemIndex];
    final subIndex = item.subItems.indexWhere((s) => s.id == subItemId);
    if (subIndex == -1) return;

    final subItem = item.subItems[subIndex];
    item.subItems[subIndex] = subItem.copyWith(isChecked: !subItem.isChecked);

    // Eğer herhangi bir madde seçildiyse şehri de ziyaret edilmiş say
    if (_cities[cityIndex].checkedItems > 0 && !_cities[cityIndex].isVisited) {
      _cities[cityIndex] = _cities[cityIndex].copyWith(isVisited: true);
    }

    notifyListeners();
    _save();
  }

  void addGroup(String cityId, String groupName) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    _cities[cityIndex].groups.add(CityGroup(
      id: 'g-${_uuid.v4()}',
      name: groupName,
    ));
    notifyListeners();
    _save();
  }

  void deleteGroup(String cityId, String groupId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    _cities[cityIndex].groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
    _save();
  }

  void addItem(String cityId, String groupId, String itemName,
      {ItemImportance importance = ItemImportance.ordinary}) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex =
        _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    _cities[cityIndex].groups[groupIndex].items.add(CityItem(
      id: 'i-${_uuid.v4()}',
      name: itemName,
      importance: importance,
    ));
    notifyListeners();
    _save();
  }

  void addSubItem(String cityId, String groupId, String itemId, String subItemName,
      {ItemImportance importance = ItemImportance.ordinary}) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex =
        _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final itemIndex =
        _cities[cityIndex].groups[groupIndex].items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    _cities[cityIndex].groups[groupIndex].items[itemIndex].subItems.add(CityItem(
      id: 's-${_uuid.v4()}',
      name: subItemName,
      importance: importance,
    ));
    notifyListeners();
    _save();
  }

  void deleteItem(String cityId, String groupId, String itemId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex =
        _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    _cities[cityIndex].groups[groupIndex].items
        .removeWhere((i) => i.id == itemId);
    notifyListeners();
    _save();
  }

  void deleteSubItem(String cityId, String groupId, String itemId, String subItemId) {
    final cityIndex = _cities.indexWhere((c) => c.id == cityId);
    if (cityIndex == -1) return;

    final groupIndex =
        _cities[cityIndex].groups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return;

    final itemIndex =
        _cities[cityIndex].groups[groupIndex].items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    _cities[cityIndex].groups[groupIndex].items[itemIndex].subItems
        .removeWhere((s) => s.id == subItemId);
    notifyListeners();
    _save();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _users = prefs.getStringList(_kUsersListKey) ?? ['Varsayılan'];
    _currentUser = prefs.getString(_kActiveUserKey) ?? _users.first;
    await _loadUserCities();
    await _loadBestPackages();
    _isLoading = false;
    notifyListeners();
  }

  /// Kullanıcı giriş yaptığında Firestore'daki tüm profilleri ve aktif haritayı çeker
  Future<void> _syncFromFirestoreOnLogin() async {
    if (_firebaseUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .get();

      final prefs = await SharedPreferences.getInstance();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final cloudProfiles = (data['profiles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        final cloudLastActive = data['lastActiveProfile'] as String?;

        if (cloudProfiles != null && cloudProfiles.isNotEmpty) {
          _users = cloudProfiles;
          await prefs.setStringList(_kUsersListKey, _users);
        }

        if (cloudLastActive != null && cloudLastActive.isNotEmpty) {
          _currentUser = cloudLastActive;
          await prefs.setString(_kActiveUserKey, _currentUser);
        } else if (!_users.contains(_currentUser) && _users.isNotEmpty) {
          _currentUser = _users.first;
          await prefs.setString(_kActiveUserKey, _currentUser);
        }
      }

      // Aktif haritayı Firestore'dan öncelikli olarak yükle (forceCloud: true)
      await _loadUserCities(forceCloud: true);
    } catch (e) {
      debugPrint('Firestore giriş senkronizasyonu hatası: $e');
      await _loadUserCities(forceCloud: false);
    }
  }

  /// Hesaptan çıkış yapıldığında cihazdaki ekranı ve verileri misafir varsayılanına sıfırlar
  Future<void> _resetToGuestDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    _users = ['Varsayılan'];
    _currentUser = 'Varsayılan';
    await prefs.setStringList(_kUsersListKey, _users);
    await prefs.setString(_kActiveUserKey, _currentUser);
    await prefs.remove('turkey_cities_user_Varsayılan');

    _cities = buildDefaultCities();
    final rawList = _cities.map((c) => c.toJson()).toList();
    await prefs.setString('turkey_cities_user_Varsayılan', jsonEncode(rawList));
  }

  Future<void> _loadUserCities({bool forceCloud = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'turkey_cities_user_$_currentUser';

    // 1. Eğer kullanıcı giriş yapmışsa veya forceCloud istenmişse Firestore'dan güncel veriyi öncelikli al
    if (_firebaseUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .collection('profiles')
            .doc(_currentUser)
            .get();

        if (doc.exists && doc.data()?['cities'] != null) {
          final List<dynamic> list = doc.data()!['cities'];
          _cities = list
              .map((e) => CityModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          // Yerel önbelleğe de güncelle
          await prefs.setString(userKey, jsonEncode(list));
          return;
        } else if (!forceCloud) {
          // Bulutta henüz bu profil yok ama yerelde varsa Firestore'a yedekle
          final localRaw = prefs.getString(userKey);
          if (localRaw != null) {
            final List<dynamic> decoded = jsonDecode(localRaw) as List<dynamic>;
            _cities = decoded
                .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
                .toList();
            await _saveToFirebaseOnly();
            return;
          }
        }
      } catch (e) {
        debugPrint('Firestore profil yükleme hatası: $e');
      }
    }

    // 2. SharedPreferences'tan bu profil için yerel veriyi kontrol et
    final raw = prefs.getString(userKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cities = decoded
            .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return;
      } catch (_) {}
    }

    // 3. Hiçbiri yoksa buluttaki Master (Varsayılan) Türkiye şehir listesini çek
    try {
      _cities = await AdminService().getMasterCities();
    } catch (_) {
      _cities = buildDefaultCities();
    }
    final rawList = _cities.map((c) => c.toJson()).toList();
    await prefs.setString(userKey, jsonEncode(rawList));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'turkey_cities_user_$_currentUser';
    final rawList = _cities.map((c) => c.toJson()).toList();
    final encoded = jsonEncode(rawList);
    await prefs.setString(userKey, encoded);

    await _saveToFirebaseOnly();
  }

  Future<void> _saveToFirebaseOnly() async {
    if (_firebaseUser == null) return;
    try {
      final rawList = _cities.map((c) => c.toJson()).toList();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('profiles')
          .doc(_currentUser)
          .set({
        'profileName': _currentUser,
        'email': _firebaseUser!.email,
        'displayName': _firebaseUser!.displayName,
        'lastUpdated': FieldValue.serverTimestamp(),
        'cities': rawList,
      }, SetOptions(merge: true));

      // Kullanıcının profil listesini de ana belgede güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set({
        'email': _firebaseUser!.email,
        'displayName': _firebaseUser!.displayName,
        'lastActiveProfile': _currentUser,
        'profiles': _users,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore kaydetme hatası: $e');
    }
  }

  // ── Best List Packages Management ──────────────────────────────────────────

  Future<void> _loadBestPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCustomBestPackagesKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _bestPackages = decoded
            .map((e) => BestListPackage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return;
      }
    } catch (e) {
      debugPrint('Özel paket yükleme hatası: $e');
    }
    // Buluttaki Master varsayılan paketleri yükle
    try {
      _bestPackages = await AdminService().getMasterBestPackages();
    } catch (_) {
      _bestPackages = List.from(kBestListPackages);
    }
  }

  Future<void> _saveBestPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = _bestPackages.map((p) => p.toJson()).toList();
      await prefs.setString(_kCustomBestPackagesKey, jsonEncode(rawList));
    } catch (e) {
      debugPrint('Özel paket kaydetme hatası: $e');
    }
  }

  Future<void> addBestPackage(BestListPackage package) async {
    _bestPackages.add(package);
    notifyListeners();
    await _saveBestPackages();
  }

  Future<void> updateBestPackage(BestListPackage updatedPackage) async {
    final index = _bestPackages.indexWhere((p) => p.id == updatedPackage.id);
    if (index != -1) {
      _bestPackages[index] = updatedPackage;
      notifyListeners();
      await _saveBestPackages();
    }
  }

  Future<void> deleteBestPackage(String packageId) async {
    _bestPackages.removeWhere((p) => p.id == packageId);
    notifyListeners();
    await _saveBestPackages();
  }
}
