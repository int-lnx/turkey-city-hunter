import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/city_model.dart';
import '../data/turkey_cities_data.dart';
import '../data/best_lists_data.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  /// Varsayılan kök süper yönetici
  static const String rootAdminEmail = 'e.murat.cayli@gmail.com';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Koleksiyon ve döküman sabitleri
  static const String configCollection = 'global_config';
  static const String masterDocId = 'master_map_v1';
  static const String adminsDocId = 'admins_v1';

  /// Giriş yapmış kullanıcının admin olup olmadığını denetler
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    final email = user.email!.trim().toLowerCase();
    if (email == rootAdminEmail.toLowerCase()) {
      return true;
    }

    try {
      final doc = await _firestore.collection(configCollection).doc(adminsDocId).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic>? list = doc.data()!['adminEmails'] as List<dynamic>?;
        if (list != null) {
          final normalized = list.map((e) => e.toString().trim().toLowerCase()).toList();
          return normalized.contains(email);
        }
      }
    } catch (e) {
      debugPrint('Admin kontrol hatası: $e');
    }
    return false;
  }

  /// Tüm yetkili adminlerin e-posta listesini getirir
  Future<List<String>> getAdminEmails() async {
    final Set<String> admins = {rootAdminEmail.toLowerCase()};
    try {
      final doc = await _firestore.collection(configCollection).doc(adminsDocId).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic>? list = doc.data()!['adminEmails'] as List<dynamic>?;
        if (list != null) {
          for (final item in list) {
            final em = item.toString().trim().toLowerCase();
            if (em.isNotEmpty) admins.add(em);
          }
        }
      }
    } catch (e) {
      debugPrint('Admin listesi getirme hatası: $e');
    }
    return admins.toList();
  }

  /// Yeni yönetici ekler
  Future<void> addAdminEmail(String newEmail) async {
    final clean = newEmail.trim().toLowerCase();
    if (clean.isEmpty) return;

    final currentAdmins = await getAdminEmails();
    if (!currentAdmins.contains(clean)) {
      currentAdmins.add(clean);
      await _firestore.collection(configCollection).doc(adminsDocId).set({
        'adminEmails': currentAdmins,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.email ?? 'system',
      }, SetOptions(merge: true));
    }
  }

  /// Yönetici yetkisini kaldırır (kök yönetici silinemez)
  Future<void> removeAdminEmail(String emailToRemove) async {
    final clean = emailToRemove.trim().toLowerCase();
    if (clean == rootAdminEmail.toLowerCase()) {
      throw Exception('Ana süper yönetici silinemez!');
    }

    final currentAdmins = await getAdminEmails();
    currentAdmins.remove(clean);
    await _firestore.collection(configCollection).doc(adminsDocId).set({
      'adminEmails': currentAdmins,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.email ?? 'system',
    }, SetOptions(merge: true));
  }

  /// Firestore'daki Master (Varsayılan) Haritayı çeker
  /// Eğer henüz Firestore'da oluşturulmamışsa varsayılan yerel şehirleri döner
  Future<List<CityModel>> getMasterCities() async {
    try {
      final doc = await _firestore.collection(configCollection).doc(masterDocId).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic>? rawCities = doc.data()!['cities'] as List<dynamic>?;
        if (rawCities != null && rawCities.isNotEmpty) {
          return rawCities
              .map((e) => CityModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Master şehirleri çekme hatası: $e');
    }
    return buildDefaultCities();
  }

  /// Firestore'daki Master (Varsayılan) En İyiler Paketlerini çeker
  Future<List<BestListPackage>> getMasterBestPackages() async {
    try {
      final doc = await _firestore.collection(configCollection).doc(masterDocId).get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic>? rawPkgs = doc.data()!['bestPackages'] as List<dynamic>?;
        if (rawPkgs != null && rawPkgs.isNotEmpty) {
          return rawPkgs
              .map((e) => BestListPackage.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Master paketleri çekme hatası: $e');
    }
    return List.from(kBestListPackages);
  }

  /// Yönetici tarafından düzenlenen Master Haritayı ve Paketleri Firestore'a kaydeder (Canlıya alır)
  Future<void> saveMasterData({
    required List<CityModel> masterCities,
    required List<BestListPackage> masterPackages,
  }) async {
    final user = _auth.currentUser;
    final payload = {
      'cities': masterCities.map((c) => c.toJson()).toList(),
      'bestPackages': masterPackages.map((p) => p.toJson()).toList(),
      'lastPublishedAt': FieldValue.serverTimestamp(),
      'lastPublishedBy': user?.email ?? 'admin',
    };

    await _firestore.collection(configCollection).doc(masterDocId).set(
          payload,
          SetOptions(merge: true),
        );
  }
}
