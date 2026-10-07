import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_item.dart';
import '../providers/city_provider.dart';
import 'quick_note_dialog.dart';

class ImportanceItemEntry {
  final String cityId;
  final String cityName;
  final String groupId;
  final String groupTitle;
  final String parentItemId;
  final String? subItemId;
  final String itemName;
  final String displayName;
  final String note;
  final bool isChecked;
  final ItemImportance importance;

  ImportanceItemEntry({
    required this.cityId,
    required this.cityName,
    required this.groupId,
    required this.groupTitle,
    required this.parentItemId,
    this.subItemId,
    required this.itemName,
    required this.displayName,
    required this.note,
    required this.isChecked,
    required this.importance,
  });
}

class ImportanceListModal extends StatefulWidget {
  final ItemImportance targetImportance;

  const ImportanceListModal({
    super.key,
    required this.targetImportance,
  });

  static void show(BuildContext context, ItemImportance importance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ImportanceListModal(targetImportance: importance),
    );
  }

  @override
  State<ImportanceListModal> createState() => _ImportanceListModalState();
}

class _ImportanceListModalState extends State<ImportanceListModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final isMustSee = widget.targetImportance == ItemImportance.mustSee;

    final themeColor = isMustSee ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final headerTitle = isMustSee
        ? 'Ölmeden Önce Görülecek Yerler'
        : 'Mutlaka Görülmesi Gereken Yerler';

    // Collect all matching items from all 81 cities
    final List<ImportanceItemEntry> allEntries = [];

    for (final city in provider.cities) {
      for (final group in city.groups) {
        for (final item in group.items) {
          if (item.subItems.isNotEmpty) {
            for (final sub in item.subItems) {
              if (sub.importance == widget.targetImportance) {
                allEntries.add(
                  ImportanceItemEntry(
                    cityId: city.id,
                    cityName: city.name,
                    groupId: group.id,
                    groupTitle: group.name,
                    parentItemId: item.id,
                    subItemId: sub.id,
                    itemName: sub.name,
                    displayName: '${item.name} › ${sub.name}',
                    note: sub.note,
                    isChecked: sub.isChecked,
                    importance: sub.importance,
                  ),
                );
              }
            }
          } else if (item.importance == widget.targetImportance) {
            allEntries.add(
              ImportanceItemEntry(
                cityId: city.id,
                cityName: city.name,
                groupId: group.id,
                groupTitle: group.name,
                parentItemId: item.id,
                subItemId: null,
                itemName: item.name,
                displayName: item.name,
                note: item.note,
                isChecked: item.isChecked,
                importance: item.importance,
              ),
            );
          }
        }
      }
    }

    // Sort by importance weight desc, then cityName, then itemName
    allEntries.sort((a, b) {
      final cmpWeight = b.importance.weight.compareTo(a.importance.weight);
      if (cmpWeight != 0) return cmpWeight;
      final cmpCity = a.cityName.compareTo(b.cityName);
      if (cmpCity != 0) return cmpCity;
      return a.displayName.compareTo(b.displayName);
    });

    final filteredEntries = allEntries.where((entry) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return entry.cityName.toLowerCase().contains(q) ||
          entry.displayName.toLowerCase().contains(q) ||
          entry.note.toLowerCase().contains(q);
    }).toList();

    final checkedCount = allEntries.where((e) => e.isChecked).length;
    final totalCount = allEntries.length;
    final rate = totalCount == 0 ? 0.0 : checkedCount / totalCount;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isMustSee ? Icons.stars_rounded : Icons.recommend_rounded,
                    color: themeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tüm Türkiye Listesi • Önem Sırasına Göre',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$checkedCount / $totalCount (%${(rate * 100).toStringAsFixed(0)})',
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Şehir veya lokasyon adı ara...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: const Icon(Icons.clear, color: Colors.white38, size: 16),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            color: Colors.white24,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aradığınız kritere uygun yer bulunamadı.'
                                : 'Bu önem seviyesinde henüz kayıtlı yer yok.',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final hasNote = entry.note.trim().isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17172E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: entry.isChecked
                                  ? themeColor.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Toggle Checkbox
                              InkWell(
                                onTap: () {
                                  if (entry.subItemId != null) {
                                    provider.toggleSubItem(
                                      entry.cityId,
                                      entry.groupId,
                                      entry.parentItemId,
                                      entry.subItemId!,
                                    );
                                  } else {
                                    provider.toggleItem(
                                      entry.cityId,
                                      entry.groupId,
                                      entry.parentItemId,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: entry.isChecked
                                        ? const Color(0xFF10B981)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: entry.isChecked
                                          ? const Color(0xFF10B981)
                                          : Colors.white30,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: entry.isChecked
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),

                              // Sol Kısım: Şehir Adı / Lokasyon + Detay Notu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Şehir Adı / Lokasyon
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${entry.cityName}  /  ',
                                            style: TextStyle(
                                              color: themeColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(
                                            text: entry.displayName,
                                            style: TextStyle(
                                              color: entry.isChecked ? Colors.white60 : Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              decoration: entry.isChecked
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                              decorationColor: Colors.white38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Grup bilgisi
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        entry.groupTitle,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),

                                    // Lokasyon Notu (Varsa minimalist göster)
                                    if (hasNote)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.sticky_note_2_rounded,
                                                color: Color(0xFF38BDF8),
                                                size: 11,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  entry.note.trim(),
                                                  style: const TextStyle(
                                                    color: Color(0xFFBAE6FD),
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Not İkonu (Minimalist not alma)
                              IconButton(
                                icon: Icon(
                                  hasNote ? Icons.note_alt_rounded : Icons.note_add_outlined,
                                  color: hasNote ? const Color(0xFF38BDF8) : Colors.white38,
                                  size: 19,
                                ),
                                tooltip: hasNote ? 'Notu Düzenle' : 'Not Ekle',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () {
                                  QuickNoteDialog.show(
                                    context: context,
                                    title: '${entry.cityName} • ${entry.displayName}',
                                    initialNote: entry.note,
                                    onSave: (newNote) {
                                      provider.updateItemNote(
                                        entry.cityId,
                                        entry.groupId,
                                        entry.parentItemId,
                                        newNote,
                                        subItemId: entry.subItemId,
                                      );
                                    },
                                  );
                                },
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
  }
}
