import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/city_provider.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../screens/admin_dashboard_screen.dart';
import '../utils/file_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthService? _authService;
  bool _isPasswordObscured = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    try {
      _authService = AuthService();
    } catch (e) {
      debugPrint('AuthService başlatılamadı: $e');
    }
    final provider = context.read<CityProvider>();
    _nameController.text = provider.currentUser;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final currentUser = provider.currentUser;
    final totalItems = provider.cities.fold(0, (s, c) => s + c.totalItems);
    final checkedItems = provider.cities.fold(0, (s, c) => s + c.checkedItems);
    final ratePercent = provider.overallPercent;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profil & Kullanıcı Ayarları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                        backgroundImage: (provider.isLoggedIn &&
                                provider.firebaseUser?.photoURL != null &&
                                provider.firebaseUser!.photoURL!.isNotEmpty)
                            ? NetworkImage(provider.firebaseUser!.photoURL!)
                            : null,
                        child: (provider.isLoggedIn &&
                                provider.firebaseUser?.photoURL != null &&
                                provider.firebaseUser!.photoURL!.isNotEmpty)
                            ? null
                            : Text(
                                currentUser.isNotEmpty ? currentUser[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (provider.isLoggedIn)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (provider.isLoggedIn && provider.firebaseUser?.email != null) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle, color: Color(0xFF60A5FA), size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              provider.firebaseUser!.email!,
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Google ile Bağlı Hesap',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ] else ...[
                    const Text(
                      'Aktif Gezgin Profili (Misafir)',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('Keşif Oranı', ratePercent, const Color(0xFF10B981)),
                      _buildProfileStat('Gezilen Yer', '$checkedItems', const Color(0xFF06B6D4)),
                      _buildProfileStat('Toplam Hedef', '$totalItems', Colors.white70),
                    ],
                  ),
                ],
              ),
            ),

            // Google Auth Card
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: provider.isLoggedIn
                      ? [const Color(0xFF1E3A8A), const Color(0xFF16213E)]
                      : [const Color(0xFF2E1065), const Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: provider.isLoggedIn
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.isLoggedIn ? Icons.cloud_done : Icons.cloud_queue,
                        color: provider.isLoggedIn ? const Color(0xFF60A5FA) : const Color(0xFFA78BFA),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isLoggedIn ? 'Bulut Senkronizasyonu Aktif' : 'Bulut Yedekleme & Giriş',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.isLoggedIn
                        ? 'Harita ve gezi ilerlemeleriniz ${provider.firebaseUser?.email ?? ""} hesabınızla güvende.'
                        : 'Google ile giriş yaparak ilerlemenizi kaydedebilir ve farklı cihazlardan erişebilirsiniz.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoggedIn) ...[
                    FutureBuilder<bool>(
                      future: AdminService().isCurrentUserAdmin(),
                      builder: (ctx, snapshot) {
                        if (snapshot.data == true) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDashboardScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                                label: const Text('Yönetim Paneline Git', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _authService?.signOut();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Başarıyla çıkış yapıldı.')),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                        label: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSigningIn
                            ? null
                            : () async {
                                setState(() => _isSigningIn = true);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  _authService ??= AuthService();
                                  await _authService!.signInWithGoogle();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Google ile giriş başarılı!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Giriş hatası: $e'),
                                      backgroundColor: Colors.redAccent,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSigningIn = false);
                                  }
                                }
                              },
                        icon: _isSigningIn
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                              )
                            : const Icon(Icons.account_circle, color: Colors.black87),
                        label: Text(
                          _isSigningIn ? 'Giriş Yapılıyor...' : 'Google ile Giriş Yap',
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Profile & Account Settings Section
            const Text(
              'Profil Ayarları',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı / Profil İsmi',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF8B5CF6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Şifre / Giriş Kodu (Opsiyonel)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8B5CF6)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newName = _nameController.text.trim();
                        if (newName.isNotEmpty && newName != currentUser) {
                          provider.renameUser(currentUser, newName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil ismi başarıyla güncellendi!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Değişiklik yapılmadı.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Değişiklikleri Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Harita Verisi Paylaş / Yedekle (Export & Import) Section
            const Text(
              'Harita Verisi (Dışa / İçe Aktar)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktif harita verilerinizi JSON formatında dışa aktarabilir veya başka bir hesaptan/cihazdan aldığınız verileri yeni bir harita olarak içeri aktarabilirsiniz.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Export Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleExportMap(context, provider),
                          icon: const Icon(Icons.file_download_outlined, size: 20),
                          label: const Text('Dışa Aktar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Import Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showImportOptionsDialog(context, provider),
                          icon: const Icon(Icons.file_upload_outlined, size: 20),
                          label: const Text('İçe Aktar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // User Profile Switcher List
            const Text(
              'Diğer Kullanıcı Profilleri',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: provider.users.map((user) {
                  final isCurrent = user == currentUser;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF10B981) : Colors.white24,
                      child: Text(
                        user.isNotEmpty ? user[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: isCurrent
                        ? const Text('Aktif Kullanıcı', style: TextStyle(color: Color(0xFF10B981), fontSize: 12))
                        : null,
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                        : TextButton(
                            onPressed: () {
                              provider.switchUser(user);
                              _nameController.text = user;
                            },
                            child: const Text('Geç', style: TextStyle(color: Color(0xFF06B6D4))),
                          ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  // ── Data Export & Import Handlers ──────────────────────────────────────────

  Future<void> _handleExportMap(BuildContext context, CityProvider provider) async {
    final jsonStr = provider.exportMapData();
    final sanitizedName = provider.currentUser.replaceAll(RegExp(r'[^a-zA-Z0-9_\u00C0-\u017F]'), '_');
    final fileName = 'kesif_haritasi_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.json';

    await FileHelper.downloadJsonFile(
      jsonContent: jsonStr,
      fileName: fileName,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Harita verisi indirildi: $fileName'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportOptionsDialog(BuildContext context, CityProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text(
              'Harita Verisi İçe Aktar',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İçe aktarılan veriler her zaman yeni bir harita/profil olarak oluşturulur. Mevcut haritanız asla bozulmaz veya üzerine yazılmaz.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.folder_open_outlined, color: Color(0xFF38BDF8)),
              title: const Text('JSON Dosyasından Yükle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Bilgisayarınızdan .json dosyası seçin', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _handlePickFileAndImport(context, provider);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.paste_outlined, color: Color(0xFFA78BFA)),
              title: const Text('Metin Olarak Yapıştır', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('JSON kodunu doğrudan yapıştırarak aktarın', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
              onTap: () {
                Navigator.of(ctx).pop();
                _showPasteJsonDialog(context, provider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickFileAndImport(BuildContext context, CityProvider provider) async {
    try {
      final jsonContent = await FileHelper.pickJsonFile();
      if (jsonContent == null || jsonContent.trim().isEmpty) return;

      final newMapName = await provider.importMapData(jsonContent);
      _nameController.text = newMapName;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Harita başarıyla "$newMapName" adıyla içe aktarıldı!'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          content: Text('İçe aktarma hatası: $e'),
        ),
      );
    }
  }

  void _showPasteJsonDialog(BuildContext context, CityProvider provider) {
    final textCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'JSON Verisini Yapıştır',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Yeni Harita Adı (Opsiyonel)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintText: 'Örn: Arkadaşımın Haritası',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Buraya JSON içeriğini yapıştırın...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = textCtrl.text.trim();
              if (content.isEmpty) return;

              try {
                Navigator.of(ctx).pop();
                final customName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null;
                final newMapName = await provider.importMapData(content, customMapName: customName);
                _nameController.text = newMapName;

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Harita başarıyla "$newMapName" adıyla eklendi!'),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    content: Text('Hatalı veri formatı: $e'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );
  }
}

