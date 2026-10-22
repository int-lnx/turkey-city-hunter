import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_model.dart';
import '../models/city_group.dart';
import '../models/city_item.dart';
import '../data/best_lists_data.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  bool _isCheckingAuth = true;
  bool _isAdmin = false;
  bool _isLoadingData = false;
  bool _isSaving = false;

  // Master Harita ve Paket Verileri
  List<CityModel> _masterCities = [];
  List<BestListPackage> _masterPackages = [];
  List<String> _adminEmails = [];

  // Arama & Filtre
  String _citySearchQuery = '';
  String? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    setState(() => _isCheckingAuth = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isCheckingAuth = false;
        });
        if (isAdmin) {
          _loadMasterData();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoadingData = true);
    try {
      final cities = await _adminService.getMasterCities();
      final packages = await _adminService.getMasterBestPackages();
      final admins = await _adminService.getAdminEmails();

      if (mounted) {
        setState(() {
          _masterCities = cities;
          _masterPackages = packages;
          _adminEmails = admins;
          _isLoadingData = false;
          if (_selectedCityId == null && _masterCities.isNotEmpty) {
            _selectedCityId = _masterCities.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Admin veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _saveMasterDataToCloud() async {
    setState(() => _isSaving = true);
    try {
      await _adminService.saveMasterData(
        masterCities: _masterCities,
        masterPackages: _masterPackages,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text(
              '🎉 Varsayılan harita ve paketler başarıyla Firestore\'a kaydedildi ve tüm kullanıcılara yayınlandı!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Kaydetme hatası: $e'),
          ),
        );
      }
    }
  }

  CityModel? _getCityById(String id) {
    try {
      return _masterCities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 16),
              Text(
                'Yönetici yetkisi doğrulanıyor...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return _buildUnauthorizedScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131326),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yönetim Paneli (Master Harita)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Varsayılan Genel Harita & Paket Düzenleyici',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Ana Haritaya Dön butonu
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            icon: const Icon(Icons.public, color: Color(0xFF38BDF8), size: 18),
            label: const Text('Kullanıcı Haritası', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5)),
          ),
          const SizedBox(width: 8),
          // Canlıya Kaydet / Yayınla Butonu
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveMasterDataToCloud,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(_isSaving ? 'Yayınlanıyor...' : 'Canlıya Yayınla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Varsayılan Şehirler & Mekanlar'),
            Tab(icon: Icon(Icons.stars_rounded, size: 18), text: 'En İyiler Paketleri'),
            Tab(icon: Icon(Icons.manage_accounts_rounded, size: 18), text: 'Yöneticiler'),
          ],
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMasterCitiesTab(),
                _buildMasterPackagesTab(),
                _buildAdminsTab(),
              ],
            ),
    );
  }

  // ── 0. Yetkisiz Erişim & Giriş Ekranı ──────────────────────────────────────────

  Widget _buildUnauthorizedScreen() {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
      ),
      body: Center(
        child: Container(
          width: 440,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF16162D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFFEF4444), size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                'Yönetici Paneli Girişi',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user == null
                    ? 'Bu alana sadece yetkili yöneticiler erişebilir. Lütfen yetkili Google hesabınızla giriş yapınız.'
                    : 'Giriş yapılan hesap: ${user.email}\nBu hesabın yönetici yetkisi bulunmamaktadır.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _authService.signInWithGoogle();
                    await _checkAdminAccess();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Giriş başarısız: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login, color: Colors.white),
                label: Text(user == null ? 'Google ile Yönetici Girişi' : 'Farklı Hesapla Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                child: const Text('Ana Haritaya Geri Dön', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Varsayılan Şehirler & Mekanlar Sekmesi ───────────────────────────────

  Widget _buildMasterCitiesTab() {
    final filteredCities = _masterCities.where((c) {
      if (_citySearchQuery.trim().isEmpty) return true;
      final q = _citySearchQuery.toLowerCase().trim();
      return c.name.toLowerCase().contains(q) || c.id.contains(q);
    }).toList();

    final selectedCity = _selectedCityId != null ? _getCityById(_selectedCityId!) : null;

    return Row(
      children: [
        // Sol Panel: Şehir Seçici
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF131326),
            border: Border(right: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Şehir ara (Örn: Muğla, 48)...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _citySearchQuery = val),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredCities.length,
                  itemBuilder: (ctx, idx) {
                    final c = filteredCities[idx];
                    final isSelected = c.id == _selectedCityId;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      title: Text(
                        '${c.id} - ${c.name}',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFA78BFA) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${c.totalItems} lokasyon • ${c.groups.length} grup',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                      onTap: () {
                        setState(() => _selectedCityId = c.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Sağ Panel: Seçili Şehir Mekan Editörü & Harita Önizleme
        Expanded(
          child: selectedCity == null
              ? const Center(child: Text('Lütfen düzenlemek için bir şehir seçin.', style: TextStyle(color: Colors.white54)))
              : _buildCityEditor(selectedCity),
        ),
      ],
    );
  }

  Widget _buildCityEditor(CityModel city) {
    return Column(
      children: [
        // Şehir Başlığı ve Grup Ekle Butonu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF16162D),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      city.id,
                      style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${city.name} - Varsayılan Lokasyonlar',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '(${city.totalItems} lokasyon)',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddGroupDialog(city),
                icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                label: const Text('Yeni Grup Ekle', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Gruplar ve Maddeler Listesi
        Expanded(
          child: city.groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open_rounded, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text('Bu şehirde henüz grup eklenmemiş.', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _showAddGroupDialog(city),
                        child: const Text('İlk Grubu Ekle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: city.groups.length,
                  itemBuilder: (ctx, gIdx) {
                    final group = city.groups[gIdx];
                    return _buildGroupCard(city, group);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(CityModel city, CityGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: Colors.white54,
        iconColor: const Color(0xFFA78BFA),
        title: Row(
          children: [
            const Icon(Icons.folder_rounded, color: Color(0xFF8B5CF6), size: 18),
            const SizedBox(width: 8),
            Text(
              group.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Text('(${group.items.length} mekan)', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_location_alt_outlined, color: Color(0xFF38BDF8), size: 18),
              tooltip: 'Bu Gruba Mekan Ekle',
              onPressed: () => _showAddOrEditItemDialog(city, group),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
              tooltip: 'Grubu Sil',
              onPressed: () {
                setState(() {
                  city.groups.removeWhere((g) => g.id == group.id);
                });
              },
            ),
          ],
        ),
        children: [
          if (group.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Grupta henüz mekan yok.', style: TextStyle(color: Colors.white38, fontSize: 12)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.items.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (ctx, iIdx) {
                final item = group.items[iIdx];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(item.importance.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Color(item.importance.colorValue).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.importance.label,
                          style: TextStyle(color: Color(item.importance.colorValue), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: item.description.isNotEmpty
                      ? Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11.5))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
                        tooltip: 'Düzenle',
                        onPressed: () => _showAddOrEditItemDialog(city, group, existingItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                        tooltip: 'Sil',
                        onPressed: () {
                          setState(() {
                            group.items.removeWhere((i) => i.id == item.id);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddGroupDialog(CityModel city) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text('${city.name} - Yeni Grup Ekle', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Grup Adı',
            hintText: 'Örn: Antik Kentler, Plajlar, Doğal Güzellikler',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  city.groups.add(CityGroup(
                    id: 'group_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    items: [],
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditItemDialog(CityModel city, CityGroup group, {CityItem? existingItem}) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final descCtrl = TextEditingController(text: existingItem?.description ?? '');
    final imgCtrl = TextEditingController(text: existingItem?.imageUrl ?? '');
    ItemImportance importance = existingItem?.importance ?? ItemImportance.mustSee;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E38),
          title: Text(
            existingItem != null ? 'Mekanı Düzenle' : 'Yeni Mekan Ekle',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mekan / Yer Adı *',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Görsel URL',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ItemImportance>(
                  initialValue: importance,
                  dropdownColor: const Color(0xFF252548),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Önem Derecesi', labelStyle: TextStyle(color: Colors.white70)),
                  items: const [
                    DropdownMenuItem(value: ItemImportance.mustSee, child: Text('Görmeden Ölme (Kırmızı)')),
                    DropdownMenuItem(value: ItemImportance.highlyRecommended, child: Text('Mutlaka Görülmeli (Turuncu)')),
                    DropdownMenuItem(value: ItemImportance.recommended, child: Text('Görülmeli (Yeşil)')),
                    DropdownMenuItem(value: ItemImportance.ordinary, child: Text('Sıradan (Gri)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => importance = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                setState(() {
                  if (existingItem != null) {
                    existingItem.name = name;
                    existingItem.description = descCtrl.text.trim();
                    existingItem.imageUrl = imgCtrl.text.trim();
                    existingItem.importance = importance;
                  } else {
                    group.items.add(CityItem(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      description: descCtrl.text.trim(),
                      imageUrl: imgCtrl.text.trim(),
                      importance: importance,
                    ));
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(existingItem != null ? 'Kaydet' : 'Ekle', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. En İyiler Paketleri Sekmesi ──────────────────────────────────────────

  Widget _buildMasterPackagesTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Paket Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showPackageEditorDialog(),
      ),
      body: _masterPackages.isEmpty
          ? const Center(child: Text('Henüz paket eklenmedi.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _masterPackages.length,
              itemBuilder: (ctx, idx) {
                final pkg = _masterPackages[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Text(pkg.iconEmoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(pkg.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(pkg.category, style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(pkg.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                            const SizedBox(height: 4),
                            Text('${pkg.items.length} mekan içeriyor', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                        tooltip: 'Paketi Düzenle',
                        onPressed: () => _showPackageEditorDialog(existingPackage: pkg),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                        tooltip: 'Paketi Sil',
                        onPressed: () {
                          setState(() {
                            _masterPackages.removeWhere((p) => p.id == pkg.id);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showPackageEditorDialog({BestListPackage? existingPackage}) {
    final titleCtrl = TextEditingController(text: existingPackage?.title ?? '');
    final subtitleCtrl = TextEditingController(text: existingPackage?.subtitle ?? '');
    final categoryCtrl = TextEditingController(text: existingPackage?.category ?? 'Doğa & Gezi');
    final emojiCtrl = TextEditingController(text: existingPackage?.iconEmoji ?? '🌊');
    final coverUrlCtrl = TextEditingController(text: existingPackage?.coverImageUrl ?? '');

    List<BestListItem> items = existingPackage != null ? List.from(existingPackage.items) : [];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16162D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              existingPackage != null ? 'Paketi Düzenle' : 'Yeni En İyiler Paketi',
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: emojiCtrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20),
                            decoration: const InputDecoration(labelText: 'Emoji'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: titleCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Paket Başlığı *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subtitleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Alt Başlık / Açıklama'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: categoryCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Kategori'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: coverUrlCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Kapak Görseli URL'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mekanlar (${items.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () {
                            _showAddItemToPackageDialog(ctx, (newItem) {
                              setDialogState(() => items.add(newItem));
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Mekan Ekle'),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (c, i) {
                          final item = items[i];
                          return ListTile(
                            dense: true,
                            title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text('${item.cityName} • ${item.description}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                              onPressed: () => setDialogState(() => items.removeAt(i)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  final pkg = BestListPackage(
                    id: existingPackage?.id ?? 'master_pkg_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    subtitle: subtitleCtrl.text.trim(),
                    category: categoryCtrl.text.trim().isNotEmpty ? categoryCtrl.text.trim() : 'Özel Liste',
                    iconEmoji: emojiCtrl.text.trim().isNotEmpty ? emojiCtrl.text.trim() : '✨',
                    coverImageUrl: coverUrlCtrl.text.trim().isNotEmpty
                        ? coverUrlCtrl.text.trim()
                        : 'https://images.unsplash.com/photo-1527838832700-5059252407fa?w=800&q=80',
                    items: items,
                  );

                  setState(() {
                    if (existingPackage != null) {
                      final idx = _masterPackages.indexWhere((p) => p.id == existingPackage.id);
                      if (idx != -1) _masterPackages[idx] = pkg;
                    } else {
                      _masterPackages.add(pkg);
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemToPackageDialog(BuildContext context, void Function(BestListItem item) onAdd) {
    String selectedCityId = _masterCities.isNotEmpty ? _masterCities.first.id : '34';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (subCtx, setSubState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E38),
          title: const Text('Pakete Mekan Ekle', style: TextStyle(color: Colors.white, fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCityId,
                dropdownColor: const Color(0xFF252548),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Şehir'),
                items: _masterCities.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.id} - ${c.name}'))).toList(),
                onChanged: (val) {
                  if (val != null) setSubState(() => selectedCityId = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Mekan Adı (Örn: Kelebekler Vadisi)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Kısa Açıklama'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imgCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Görsel URL'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              onPressed: () {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;
                final cityName = _getCityById(selectedCityId)?.name ?? selectedCityId;
                onAdd(BestListItem(
                  cityId: selectedCityId,
                  cityName: cityName,
                  title: t,
                  description: descCtrl.text.trim(),
                  imageUrl: imgCtrl.text.trim(),
                  importance: ItemImportance.mustSee,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Yöneticiler Sekmesi ──────────────────────────────────────────────────

  Widget _buildAdminsTab() {
    final newEmailController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yönetici Yetkilendirme',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buradaki e-posta adreslerine sahip kullanıcılar Google ile giriş yaptıklarında Yönetim Paneline erişebilir ve varsayılan haritayı düzenleyebilir.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: newEmailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Yeni Yönetici E-posta Adresi',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'ornek@gmail.com',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final email = newEmailController.text.trim();
                  if (email.isNotEmpty) {
                    await _adminService.addAdminEmail(email);
                    newEmailController.clear();
                    final updated = await _adminService.getAdminEmails();
                    setState(() => _adminEmails = updated);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$email yönetici olarak eklendi.')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Yetki Ver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Mevcut Yöneticiler',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _adminEmails.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (ctx, i) {
                final email = _adminEmails[i];
                final isRoot = email.toLowerCase() == AdminService.rootAdminEmail.toLowerCase();
                return ListTile(
                  leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
                  title: Text(email, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: isRoot ? const Text('Ana Süper Yönetici (Silinemez)', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)) : null,
                  trailing: isRoot
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                          onPressed: () async {
                            await _adminService.removeAdminEmail(email);
                            final updated = await _adminService.getAdminEmails();
                            setState(() => _adminEmails = updated);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
