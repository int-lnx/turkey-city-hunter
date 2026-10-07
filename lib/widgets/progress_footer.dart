import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_item.dart';
import '../providers/city_provider.dart';
import '../utils/color_helper.dart';
import 'importance_list_modal.dart';
import 'share_card_dialog.dart';

class ProgressFooter extends StatelessWidget {
  const ProgressFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final rate = provider.overallRate;
    final color = cityColor(rate);
    final totalItems = provider.cities.fold(0, (s, c) => s + c.totalItems);
    final checkedItems = provider.cities.fold(0, (s, c) => s + c.checkedItems);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          border: const Border(top: BorderSide(color: Colors.white10)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: InkWell(
          onTap: () => _showExploredPlacesModal(context, provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('🇹🇷', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Keşif Listesi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.list_alt_rounded,
                            color: Color(0xFF06B6D4),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      child: Text(
                        provider.overallPercent,
                        style: const TextStyle(height: 1.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0, end: rate),
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _statChip(
                      icon: Icons.check_circle_outline,
                      label: '$checkedItems madde',
                      color: color,
                    ),
                    _statChip(
                      icon: Icons.explore,
                      label: '${provider.visitedCitiesCount}/81 il ziyaret edildi',
                      color: const Color(0xFF10B981),
                    ),
                    _statChip(
                      icon: Icons.list_alt,
                      label: '$totalItems toplam madde',
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Özel Dipnot İstatistikleri (Görmeden Ölme & Mutlaka Görülmeli)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ImportanceListModal.show(context, ItemImportance.mustSee);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444), // Red
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Ölmeden Önce Görülecek: %${(provider.mustSeeRate * 100).toStringAsFixed(0)} (${provider.mustSeeCheckedCount}/${provider.mustSeeTotalCount})',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 14, color: Colors.white30),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ImportanceListModal.show(context, ItemImportance.highlyRecommended);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B), // Amber
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Mutlaka Görülmeli: %${(provider.highlyRecommendedRate * 100).toStringAsFixed(0)} (${provider.highlyRecommendedCheckedCount}/${provider.highlyRecommendedTotalCount})',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right, size: 14, color: Colors.white30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showExploredPlacesModal(BuildContext context, CityProvider provider) {
    final activeCities = provider.cities
        .where((c) => c.effectiveIsVisited)
        .toList()
      ..sort((a, b) {
        final cmp = b.completionRate.compareTo(a.completionRate);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.95,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.playlist_add_check_circle,
                        color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Gezilen İller & Tamamlananlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${activeCities.length} İl',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF38BDF8), size: 20),
                      tooltip: 'Kartı Paylaş',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        ShareCardDialog.show(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: activeCities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_off,
                                  color: Colors.white24, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Henüz hiçbir ilde gezi kaydı yapılmadı.',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Haritadan bir il seçerek gezdiğin yerleri işaretleyebilirsin!',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: activeCities.length,
                          itemBuilder: (context, index) {
                            final city = activeCities[index];
                            final rate = city.completionRate;
                            final cColor = cityColor(rate, isVisited: city.isVisited);

                            // Get checked places names
                            final checkedPlaces = <String>[];
                            for (final g in city.groups) {
                              for (final item in g.items) {
                                if (item.subItems.isNotEmpty) {
                                  for (final sub in item.subItems) {
                                    if (sub.isChecked) {
                                      checkedPlaces.add('${item.name} › ${sub.name}');
                                    }
                                  }
                                } else if (item.isChecked) {
                                  checkedPlaces.add(item.name);
                                }
                              }
                            }

                            final hasSubItemsChecked = checkedPlaces.isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: cColor.withValues(alpha: 0.2),
                                  child: Text(
                                    city.id,
                                    style: TextStyle(
                                      color: cColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  city.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  hasSubItemsChecked
                                      ? '${city.checkedItems}/${city.totalItems} Yer (%${(rate * 100).toStringAsFixed(0)})'
                                      : 'Ziyaret Edildi (Alt madde seçilmedi)',
                                  style: TextStyle(
                                    color: hasSubItemsChecked ? cColor : const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                                children: hasSubItemsChecked
                                    ? checkedPlaces.map((place) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Color(0xFF10B981), size: 12),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  place,
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Bu şehir ziyaret edildi olarak işaretlendi fakat henüz gezilen alt yer seçilmedi.',
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
