import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/city_provider.dart';
import '../services/auth_service.dart';

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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    child: Text(
                      currentUser.isNotEmpty ? currentUser[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  const Text(
                    'Aktif Gezgin Profili',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
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
                  if (provider.isLoggedIn)
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
                    )
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
}
