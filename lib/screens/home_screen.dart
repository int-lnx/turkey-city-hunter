import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_item.dart';
import '../providers/city_provider.dart';
import '../widgets/turkey_map_widget.dart';
import '../widgets/progress_footer.dart';
import '../widgets/share_card_dialog.dart';
import '../widgets/importance_list_modal.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isHeaderVisible = true;
  bool _isFooterVisible = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Full screen dark background
      drawer: _buildMainDrawer(context, provider),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
            )
          : SafeArea(
              top: !isLandscape && _isHeaderVisible,
              bottom: !isLandscape && _isFooterVisible,
              left: isLandscape,
              right: isLandscape,
              child: Stack(
                children: [
                  // Full Screen Map
                  const Positioned.fill(
                    child: TurkeyMapWidget(),
                  ),

                  // PORTRAIT HEADER BAR (Top Overlay)
                  if (!isLandscape && _isHeaderVisible)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D1A).withValues(alpha: 0.92),
                          border: const Border(bottom: BorderSide(color: Colors.white10)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white70),
                                tooltip: 'Yan Çekmece',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                onPressed: () {
                                  Scaffold.of(ctx).openDrawer();
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('🗺️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Türkiye Keşif Haritası',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Gezgin: ${provider.currentUser}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _buildUserSelector(context, provider),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: Color(0xFF38BDF8)),
                              tooltip: 'Haritamı Paylaş',
                              onPressed: () {
                                ShareCardDialog.show(context);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person, color: Color(0xFF8B5CF6)),
                              tooltip: 'Profil',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white70),
                              tooltip: 'Üst Barı Gizle',
                              onPressed: () {
                                setState(() => _isHeaderVisible = false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  // PORTRAIT HEADER TOGGLE BUTTON (When hidden)
                  if (!isLandscape && !_isHeaderVisible)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'show_header_btn',
                        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
                        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onPressed: () {
                          setState(() => _isHeaderVisible = true);
                        },
                      ),
                    ),

                  // PORTRAIT FOOTER BAR (Bottom Overlay)
                  if (!isLandscape && _isFooterVisible)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: InkWell(
                              onTap: () {
                                setState(() => _isFooterVisible = false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0D1A).withValues(alpha: 0.9),
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(12)),
                                  border: const Border(
                                    top: BorderSide(color: Colors.white24),
                                    left: BorderSide(color: Colors.white24),
                                    right: BorderSide(color: Colors.white24),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                                    SizedBox(width: 4),
                                    Text('Gizle', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const ProgressFooter(),
                        ],
                      ),
                    ),

                  // PORTRAIT FOOTER TOGGLE BUTTON (When hidden)
                  if (!isLandscape && !_isFooterVisible)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.extended(
                        heroTag: 'show_footer_btn',
                        backgroundColor: const Color(0xFF10B981),
                        icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                        label: Text(
                          provider.overallPercent,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() => _isFooterVisible = true);
                        },
                      ),
                    ),

                  // LANDSCAPE DRAWER BUTTON (When in landscape)
                  if (isLandscape)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Builder(
                        builder: (ctx) => FloatingActionButton.small(
                          heroTag: 'landscape_menu_btn',
                          backgroundColor: const Color(0xFF8B5CF6),
                          child: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(ctx).openDrawer();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ── Main Drawer (Portrait & Landscape) ───────────────────────────────────────

  Widget _buildMainDrawer(BuildContext context, CityProvider provider) {
    return Drawer(
      backgroundColor: const Color(0xFF0D0D1A),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Top Profile & App Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🗺️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Türkiye Keşif Haritası',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Color(0xFF38BDF8)),
                        tooltip: 'Haritamı Paylaş',
                        onPressed: () {
                          Navigator.of(context).pop(); // Close drawer
                          ShareCardDialog.show(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person, color: Color(0xFF8B5CF6)),
                        tooltip: 'Profil & Giriş',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildUserSelector(context, provider),
                ],
              ),
            ),

            // Drawer Extra Statistics Section
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Özel Hedef İstatistikleri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // 1. Ziyaret Edilen İller
                  _buildDrawerStatRow(
                    title: 'Ziyaret Edilen İller',
                    percent: '${(provider.visitedCitiesCount / 81 * 100).toStringAsFixed(1)}%',
                    countInfo: '${provider.visitedCitiesCount}/81 il',
                    rate: provider.visitedCitiesCount / 81,
                    indicatorColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  // 2. Must See (Ölmeden Önce Görülecek Yerler)
                  _buildDrawerStatRow(
                    title: 'Ölmeden Önce Görülecek Yerler',
                    percent: provider.mustSeePercent,
                    countInfo: '${provider.mustSeeCheckedCount}/${provider.mustSeeTotalCount} yer',
                    rate: provider.mustSeeRate,
                    indicatorColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      ImportanceListModal.show(context, ItemImportance.mustSee);
                    },
                  ),
                  const SizedBox(height: 12),
                  // 3. Highly Recommended (Mutlaka Görülmeli)
                  _buildDrawerStatRow(
                    title: 'Mutlaka Görülmesi Gereken Yerler',
                    percent: provider.highlyRecommendedPercent,
                    countInfo: '${provider.highlyRecommendedCheckedCount}/${provider.highlyRecommendedTotalCount} yer',
                    rate: provider.highlyRecommendedRate,
                    indicatorColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      ImportanceListModal.show(context, ItemImportance.highlyRecommended);
                    },
                  ),
                ],
              ),
            ),

            // Progress Footer inside Drawer
            const Expanded(
              child: SingleChildScrollView(
                child: ProgressFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStatRow({
    required String title,
    required String percent,
    required String countInfo,
    required double rate,
    required Color indicatorColor,
    VoidCallback? onTap,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: Colors.white38),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              percent,
              style: TextStyle(
                color: indicatorColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            countInfo,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildUserSelector(BuildContext context, CityProvider provider) {
    return PopupMenuButton<String>(
      tooltip: 'Kullanıcı Hesabı Değiştir',
      offset: const Offset(0, 45),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5CF6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 16),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                provider.currentUser,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          ],
        ),
      ),
      onSelected: (value) async {
        if (value == '__new_user__') {
          _showAddUserDialog(context, provider);
        } else {
          await provider.switchUser(value);
        }
      },
      itemBuilder: (ctx) {
        final items = <PopupMenuEntry<String>>[];
        for (final user in provider.users) {
          final isSelected = user == provider.currentUser;
          items.add(
            PopupMenuItem<String>(
              value: user,
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.person_outline,
                    color: isSelected ? const Color(0xFF10B981) : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (provider.users.length > 1 && !isSelected)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 16),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.deleteUser(user);
                      },
                    ),
                ],
              ),
            ),
          );
        }
        items.add(const PopupMenuDivider());
        items.add(
          const PopupMenuItem<String>(
            value: '__new_user__',
            child: Row(
              children: [
                Icon(Icons.person_add_alt_1, color: Color(0xFF06B6D4), size: 18),
                SizedBox(width: 10),
                Text(
                  'Yeni Kullanıcı / Profil Ekle',
                  style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
        return items;
      },
    );
  }

  void _showAddUserDialog(BuildContext context, CityProvider provider) {
    final controller = TextEditingController();
    bool isCopyMode = false;
    String selectedSourceUser = provider.users.isNotEmpty ? provider.currentUser : '';
    bool copyCheckedItems = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableUsers = provider.users;
          if (!availableUsers.contains(selectedSourceUser) && availableUsers.isNotEmpty) {
            selectedSourceUser = availableUsers.first;
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.add_location_alt_outlined, color: Color(0xFF38BDF8), size: 24),
                SizedBox(width: 8),
                Text(
                  'Yeni Harita / Profil Ekle',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Harita / Profil Adı',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Örn: Murat, Gezi 2026, Yaz Tatili...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      prefixIcon: const Icon(Icons.badge_outlined, color: Colors.white54, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Başlangıç Verisi',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Seçenek 1: Sıfırdan Varsayılan Harita
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isCopyMode = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: !isCopyMode
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !isCopyMode ? const Color(0xFF10B981) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !isCopyMode ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: !isCopyMode ? const Color(0xFF10B981) : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Varsayılan (Sıfırdan Harita)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'Tüm yerler temiz ve sıfır işaretle başlar',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Seçenek 2: Mevcut Bir Haritadan Kopyala
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isCopyMode = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCopyMode
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCopyMode ? const Color(0xFF8B5CF6) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCopyMode ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isCopyMode ? const Color(0xFF8B5CF6) : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mevcut Bir Haritadan Kopyala',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'Mevcut profilin listelerini veya notlarını aktarır',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kopyalama Ayarları
                  if (isCopyMode) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kopyalanacak Harita:',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E293B),
                                value: availableUsers.contains(selectedSourceUser)
                                    ? selectedSourceUser
                                    : availableUsers.firstOrNull,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                items: availableUsers.map((u) {
                                  return DropdownMenuItem<String>(
                                    value: u,
                                    child: Text(
                                      u == provider.currentUser ? '$u (Aktif Harita)' : u,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      selectedSourceUser = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                copyCheckedItems = !copyCheckedItems;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: copyCheckedItems,
                                  activeColor: const Color(0xFF8B5CF6),
                                  side: const BorderSide(color: Colors.white38),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      copyCheckedItems = val ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'İşaretlenen (gezilen) maddeleri de kopyala',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!copyCheckedItems)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Text(
                                'ℹ️ Özel maddeleriniz ve düzenlemeleriniz korunur, ancak tüm gezildi işaretleri sıfırlanmış olarak başlar.',
                                style: TextStyle(color: Colors.amber.shade200, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    provider.addUser(
                      name,
                      copyFromUser: isCopyMode ? selectedSourceUser : null,
                      copyCheckedState: isCopyMode && copyCheckedItems,
                    );
                    Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
