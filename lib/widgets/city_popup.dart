import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_model.dart';
import '../models/city_group.dart';
import '../models/city_item.dart';
import '../providers/city_provider.dart';
import '../utils/color_helper.dart';
import 'quick_note_dialog.dart';

class CityPopup extends StatefulWidget {
  final String cityId;
  final String cityName;

  const CityPopup({super.key, required this.cityId, required this.cityName});

  @override
  State<CityPopup> createState() => _CityPopupState();
}

class _CityPopupState extends State<CityPopup> {
  bool _showVisitedLockedWarning = false;
  Timer? _warningTimer;

  @override
  void dispose() {
    _warningTimer?.cancel();
    super.dispose();
  }

  void _triggerVisitedLockedWarning() {
    setState(() {
      _showVisitedLockedWarning = true;
    });
    _warningTimer?.cancel();
    _warningTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showVisitedLockedWarning = false;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final city = provider.cityById(widget.cityId);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      snap: true,
      builder: (ctx, controller) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(context, city, provider),
                Expanded(
                  child: city == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(city, controller, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CityModel? city, CityProvider provider) {
    final rate = city?.completionRate ?? 0.0;
    final color = cityColor(rate, isVisited: city?.isVisited ?? false);
    final pct = city?.completionPercent ?? '0%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  pct,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close (X) button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (city != null && city.totalItems > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${city.checkedItems} / ${city.totalItems} madde tamamlandı',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          // Visited City toggle button
          if (city != null)
            (() {
              final bool hasCheckedItems = city.checkedItems > 0;
              final bool isCityVisited = city.effectiveIsVisited;

              void handleToggle() {
                if (hasCheckedItems) {
                  _triggerVisitedLockedWarning();
                } else {
                  provider.toggleCityVisited(widget.cityId);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: handleToggle,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCityVisited
                            ? (hasCheckedItems
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFF64748B).withValues(alpha: 0.25))
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _showVisitedLockedWarning
                              ? const Color(0xFFEF4444)
                              : (isCityVisited
                                  ? (hasCheckedItems ? const Color(0xFF10B981) : const Color(0xFF94A3B8))
                                  : Colors.white12),
                          width: _showVisitedLockedWarning ? 1.6 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCityVisited
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isCityVisited
                                ? (hasCheckedItems ? const Color(0xFF10B981) : const Color(0xFF94A3B8))
                                : Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isCityVisited
                                          ? 'Bu Şehri Ziyaret Ettim'
                                          : 'Şehri Ziyaret Edildi Olarak İşaretle',
                                      style: TextStyle(
                                        color: isCityVisited ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (hasCheckedItems) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.lock_outline, size: 13, color: Colors.white54),
                                    ],
                                  ],
                                ),
                                Text(
                                  hasCheckedItems
                                      ? 'Listede gezilen yerler olduğu için otomatik aktif (Kapatılamaz)'
                                      : (isCityVisited
                                          ? 'Haritada gri renkle gösteriliyor (0% etki)'
                                          : 'Alt madde seçmeseniz bile şehri gezildi sayar'),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isCityVisited,
                            activeThumbColor: hasCheckedItems ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            activeTrackColor: hasCheckedItems ? const Color(0xFF065F46) : const Color(0xFF475569),
                            onChanged: (_) => handleToggle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showVisitedLockedWarning)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFCA5A5), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu şehir içerisindeki listede görüldü olarak işaretlenmiş yerler varken şehir ziyaret edilmedi seçilemez.',
                              style: TextStyle(
                                color: Color(0xFFFEE2E2),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            })(),
          const SizedBox(height: 4),
          const Divider(color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildContent(
      CityModel city, ScrollController controller, CityProvider provider) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        // Groups
        ...city.groups.map((group) => _buildGroupCard(group, provider)),
        const SizedBox(height: 16),
        // Add group button
        _buildAddGroupButton(provider),
      ],
    );
  }

  Widget _buildGroupCard(CityGroup group, CityProvider provider) {
    final checkedCount = group.items.where((i) => i.isChecked).length;
    final totalCount = group.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (totalCount > 0)
                  Text(
                    '$checkedCount/$totalCount',
                    style: TextStyle(
                      color: checkedCount == totalCount && totalCount > 0
                          ? const Color(0xFFF59E0B)
                          : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 4),
                // Delete group button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.white24, size: 18),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _confirmDeleteGroup(provider, group.id),
                ),
              ],
            ),
          ),
          // Items sorted: default order is by importance weight (highest first), keeping relative position if equal
          ...(() {
            final sortedItems = List<CityItem>.from(group.items);
            sortedItems.sort((a, b) {
              final aChecked = a.effectiveIsChecked;
              final bChecked = b.effectiveIsChecked;
              // Checked items still grouped or sorted, let's keep checked items behavior or prioritize importance
              if (aChecked != bChecked) {
                return aChecked ? -1 : 1;
              }
              final weightComp = b.importance.weight.compareTo(a.importance.weight);
              if (weightComp != 0) return weightComp;
              return 0; // Maintain original relative position
            });
            return sortedItems.map((item) => _buildItemTile(item, group.id, provider));
          })(),
          // Add item button
          _buildAddItemButton(group.id, provider),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildItemTile(CityItem item, String groupId, CityProvider provider) {
    final bool isChecked = item.effectiveIsChecked;
    final bool hasSubItems = item.subItems.isNotEmpty;
    final bool hasImage = item.imageUrl.trim().isNotEmpty;
    final bool hasDesc = item.description.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showItemDetailDialog(
            context: context,
            provider: provider,
            groupId: groupId,
            item: item,
          ),
          onLongPress: () => _showItemOptionsModal(
            context: context,
            provider: provider,
            groupId: groupId,
            item: item,
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Specific Checkbox: Only clicking this toggles visited status!
                InkWell(
                  onTap: () => provider.toggleItem(widget.cityId, groupId, item.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF8B5CF6)
                            : (item.checkedCount > 0
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFF8B5CF6)
                              : Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : (item.checkedCount > 0
                              ? const Icon(Icons.remove, color: Colors.white, size: 14)
                              : null),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Optional Thumbnail Image (Only shown if filled)
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl.trim(),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Title, Description, Note and Importance Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: isChecked ? Colors.white70 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: Colors.white38,
                        ),
                      ),
                      // Description: limited characters/lines so as not to break list aesthetics
                      if (hasDesc)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            item.description.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                          ),
                        ),
                      // Short note/hint
                      if (item.note.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Text(
                            item.note.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      if (!hasSubItems)
                        _buildImportanceBadge(
                          item.importance,
                          onSelected: (imp) => provider.updateItemImportance(
                              widget.cityId, groupId, item.id, imp),
                        ),
                    ],
                  ),
                ),
                if (hasSubItems)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${item.checkedCount}/${item.totalCount}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Quick Note button
                IconButton(
                  icon: Icon(
                    item.note.trim().isNotEmpty
                        ? Icons.note_alt_rounded
                        : Icons.note_add_outlined,
                    color: item.note.trim().isNotEmpty
                        ? const Color(0xFF38BDF8)
                        : Colors.white38,
                    size: 16,
                  ),
                  tooltip: item.note.trim().isNotEmpty ? 'Notu Düzenle' : 'Hızlı Not Ekle',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  onPressed: () {
                    QuickNoteDialog.show(
                      context: context,
                      title: item.name,
                      initialNote: item.note,
                      onSave: (newNote) {
                        provider.updateItemNote(
                          widget.cityId,
                          groupId,
                          item.id,
                          newNote,
                        );
                      },
                    );
                  },
                ),
                // Add Sub-item button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF06B6D4), size: 18),
                  tooltip: 'Alt madde ekle',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () =>
                      _showAddSubItemDialog(groupId, item.id, provider),
                ),
              ],
            ),
          ),
        ),
        // Sub-items List sorted
        if (hasSubItems)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: (() {
                final sortedSub = List<CityItem>.from(item.subItems);
                sortedSub.sort((a, b) {
                  if (a.isChecked != b.isChecked) {
                    return a.isChecked ? -1 : 1;
                  }
                  final weightComp = b.importance.weight.compareTo(a.importance.weight);
                  if (weightComp != 0) return weightComp;
                  return 0;
                });
                return sortedSub
                    .map((sub) =>
                        _buildSubItemTile(sub, groupId, item.id, provider))
                    .toList();
              })(),
            ),
          ),
      ],
    );
  }

  Widget _buildSubItemTile(
      CityItem subItem, String groupId, String parentItemId, CityProvider provider) {
    final bool hasImage = subItem.imageUrl.trim().isNotEmpty;
    final bool hasDesc = subItem.description.trim().isNotEmpty;

    return InkWell(
      onTap: () => _showItemDetailDialog(
        context: context,
        provider: provider,
        groupId: groupId,
        item: subItem,
        parentItemId: parentItemId,
      ),
      onLongPress: () => _showSubItemOptionsModal(
        context: context,
        provider: provider,
        groupId: groupId,
        parentItemId: parentItemId,
        subItem: subItem,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.subdirectory_arrow_right,
                color: Colors.white30, size: 16),
            const SizedBox(width: 4),
            // Specific Checkbox: Only clicking this marks visited!
            InkWell(
              onTap: () => provider.toggleSubItem(
                  widget.cityId, groupId, parentItemId, subItem.id),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: subItem.isChecked
                        ? const Color(0xFF06B6D4)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: subItem.isChecked
                          ? const Color(0xFF06B6D4)
                          : Colors.white30,
                      width: 1.2,
                    ),
                  ),
                  child: subItem.isChecked
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Optional sub-item image thumbnail
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  subItem.imageUrl.trim(),
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subItem.name,
                    style: TextStyle(
                      color: subItem.isChecked ? Colors.white60 : Colors.white70,
                      fontSize: 13,
                      decoration: subItem.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.white38,
                    ),
                  ),
                  if (hasDesc)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subItem.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ),
                  if (subItem.note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Text(
                        subItem.note.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  _buildImportanceBadge(
                    subItem.importance,
                    onSelected: (imp) => provider.updateItemImportance(
                      widget.cityId,
                      groupId,
                      parentItemId,
                      imp,
                      subItemId: subItem.id,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                subItem.note.trim().isNotEmpty
                    ? Icons.note_alt_rounded
                    : Icons.note_add_outlined,
                color: subItem.note.trim().isNotEmpty
                    ? const Color(0xFF38BDF8)
                    : Colors.white38,
                size: 15,
              ),
              tooltip: subItem.note.trim().isNotEmpty ? 'Notu Düzenle' : 'Hızlı Not Ekle',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () {
                QuickNoteDialog.show(
                  context: context,
                  title: subItem.name,
                  initialNote: subItem.note,
                  onSave: (newNote) {
                    provider.updateItemNote(
                      widget.cityId,
                      groupId,
                      parentItemId,
                      newNote,
                      subItemId: subItem.id,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(
    ItemImportance importance, {
    required ValueChanged<ItemImportance> onSelected,
  }) {
    final color = Color(importance.colorValue);
    return PopupMenuButton<ItemImportance>(
      onSelected: onSelected,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 24),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${importance.label} (${importance.weight}x)',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => ItemImportance.values.map((imp) {
        final impColor = Color(imp.colorValue);
        return PopupMenuItem<ItemImportance>(
          value: imp,
          height: 36,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: impColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${imp.label} (${imp.weight}x)',
                style: TextStyle(
                  color: impColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddItemButton(String groupId, CityProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: InkWell(
        onTap: () => _showAddItemDialog(groupId, provider),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.add, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 8),
              Text(
                'Madde ekle',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupButton(CityProvider provider) {
    return OutlinedButton.icon(
      onPressed: () => _showAddGroupDialog(provider),
      icon: const Icon(Icons.add_location_alt, size: 18),
      label: const Text('Yeni Bölge / İlçe Ekle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8B5CF6),
        side: const BorderSide(color: Color(0xFF8B5CF6)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showAddGroupDialog(CityProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Yeni Bölge / İlçe',
        hint: 'Örn: Bafra, Alaçam...',
        controller: controller,
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      provider.addGroup(widget.cityId, result.trim());
    }
  }

  Future<void> _showEditItemDialog(
    String groupId,
    String itemId,
    String currentName,
    String currentNote,
    String currentDescription,
    String currentImageUrl,
    ItemImportance currentImportance,
    CityProvider provider, {
    String? subItemId,
  }) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _EditItemDetailsDialog(
        title: subItemId != null ? 'Alt Maddeyi Düzenle' : 'Maddeyi Düzenle',
        initialName: currentName,
        initialNote: currentNote,
        initialDescription: currentDescription,
        initialImageUrl: currentImageUrl,
      ),
    );
    if (result != null && result['name'] != null && result['name']!.trim().isNotEmpty) {
      provider.editItemDetails(
        widget.cityId,
        groupId,
        itemId,
        newName: result['name']!.trim(),
        newNote: result['note'] ?? '',
        newDescription: result['description'] ?? '',
        newImageUrl: result['imageUrl'] ?? '',
        subItemId: subItemId,
      );
    }
  }


  Future<void> _showAddItemDialog(String groupId, CityProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Yeni Madde',
        hint: 'Örn: Kuş Cenneti, Tarihi Çarşı...',
        controller: controller,
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      provider.addItem(widget.cityId, groupId, result.trim());
    }
  }

  Future<void> _confirmDeleteGroup(
      CityProvider provider, String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Bölgeyi Sil', style: TextStyle(color: Colors.white)),
        content: const Text('Bu bölge ve içindeki tüm maddeler silinecek.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Sil', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      provider.deleteGroup(widget.cityId, groupId);
    }
  }

  Future<void> _showAddSubItemDialog(
      String groupId, String itemId, CityProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Yeni Alt Madde',
        hint: 'Örn: Giriş bileti, Hediyelik dükkan...',
        controller: controller,
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      provider.addSubItem(widget.cityId, groupId, itemId, result.trim());
    }
  }

  Future<void> _confirmDeleteSubItem(CityProvider provider, String groupId,
      String itemId, String subItemId, String subItemName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Alt Maddeyi Sil', style: TextStyle(color: Colors.white)),
        content: Text('"$subItemName" silinecek.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Sil', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      provider.deleteSubItem(widget.cityId, groupId, itemId, subItemId);
    }
  }

  Future<void> _showItemOptionsModal({
    required BuildContext context,
    required CityProvider provider,
    required String groupId,
    required CityItem item,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: const Text('Detayları Görüntüle', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Görseli ve tam açıklamayı incele', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showItemDetailDialog(
                    context: context,
                    provider: provider,
                    groupId: groupId,
                    item: item,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
                ),
                title: const Text('Düzenle (Ad, Not, Görsel, Açıklama)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Madde adı, fotoğrafı veya detaylı açıklamasını güncelle', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditItemDialog(
                    groupId,
                    item.id,
                    item.name,
                    item.note,
                    item.description,
                    item.imageUrl,
                    item.importance,
                    provider,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: const Text('Maddeyi Sil', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Bu maddeyi ve alt maddelerini tamamen sil', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteItem(provider, groupId, item.id, item.name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSubItemOptionsModal({
    required BuildContext context,
    required CityProvider provider,
    required String groupId,
    required String parentItemId,
    required CityItem subItem,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  subItem.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: const Text('Detayları Görüntüle', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Görseli ve tam açıklamayı incele', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showItemDetailDialog(
                    context: context,
                    provider: provider,
                    groupId: groupId,
                    item: subItem,
                    parentItemId: parentItemId,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
                ),
                title: const Text('Düzenle (Ad, Not, Görsel, Açıklama)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Alt madde adı, fotoğrafı veya açıklamasını güncelle', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditItemDialog(
                    groupId,
                    parentItemId,
                    subItem.name,
                    subItem.note,
                    subItem.description,
                    subItem.imageUrl,
                    subItem.importance,
                    provider,
                    subItemId: subItem.id,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: const Text('Alt Maddeyi Sil', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Bu alt maddeyi listeden sil', style: TextStyle(color: Colors.white38, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSubItem(
                    provider,
                    groupId,
                    parentItemId,
                    subItem.id,
                    subItem.name,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showItemDetailDialog({
    required BuildContext context,
    required CityProvider provider,
    required String groupId,
    required CityItem item,
    String? parentItemId,
  }) async {
    final bool hasImage = item.imageUrl.trim().isNotEmpty;
    final bool hasDesc = item.description.trim().isNotEmpty;
    final bool hasNote = item.note.trim().isNotEmpty;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 580),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Image if provided
              if (hasImage)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        item.imageUrl.trim(),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          color: const Color(0xFF1E293B),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, color: Colors.white38, size: 36),
                              SizedBox(height: 6),
                              Text('Görsel yüklenemedi', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              // Body Details
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Visited Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.effectiveIsChecked
                                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: item.effectiveIsChecked
                                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.effectiveIsChecked ? Icons.check_circle : Icons.circle_outlined,
                                  color: item.effectiveIsChecked ? const Color(0xFF10B981) : Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.effectiveIsChecked ? 'Gidildi' : 'Gidilmedi',
                                  style: TextStyle(
                                    color: item.effectiveIsChecked ? const Color(0xFF10B981) : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Importance badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(item.importance.colorValue).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Color(item.importance.colorValue).withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Önem: ${item.importance.label} (${item.importance.weight}x)',
                              style: TextStyle(
                                color: Color(item.importance.colorValue),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Note section (if present)
                      if (hasNote) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.note.trim(),
                                  style: const TextStyle(
                                    color: Color(0xFFBAE6FD),
                                    fontSize: 12.5,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Description section
                      if (hasDesc) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Hakkında / Detaylar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ] else if (!hasImage && !hasNote) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Bu madde için henüz detaylı bir görsel veya açıklama eklenmemiş.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Düzenle'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (parentItemId != null) {
                          _showEditItemDialog(
                            groupId,
                            parentItemId,
                            item.name,
                            item.note,
                            item.description,
                            item.imageUrl,
                            item.importance,
                            provider,
                            subItemId: item.id,
                          );
                        } else {
                          _showEditItemDialog(
                            groupId,
                            item.id,
                            item.name,
                            item.note,
                            item.description,
                            item.imageUrl,
                            item.importance,
                            provider,
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Kapat', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteItem(CityProvider provider, String groupId,
      String itemId, String itemName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Maddeyi Sil', style: TextStyle(color: Colors.white)),
        content: Text('"$itemName" ve alt maddeleri silinecek.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Sil', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      provider.deleteItem(widget.cityId, groupId, itemId);
    }
  }
}

/// Simple text input dialog
class _InputDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;

  const _InputDialog({
    required this.title,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => Navigator.pop(context, controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('İptal', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Ekle', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Item edit dialog supporting Name, Detail/Note, Description and Image URL
class _EditItemDetailsDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialNote;
  final String initialDescription;
  final String initialImageUrl;

  const _EditItemDetailsDialog({
    required this.title,
    required this.initialName,
    required this.initialNote,
    this.initialDescription = '',
    this.initialImageUrl = '',
  });

  @override
  State<_EditItemDetailsDialog> createState() => _EditItemDetailsDialogState();
}

class _EditItemDetailsDialogState extends State<_EditItemDetailsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _noteController = TextEditingController(text: widget.initialNote);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _imageUrlController = TextEditingController(text: widget.initialImageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Madde Adı *',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Yer veya mekan adı...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Görsel URL Adresi (Opsiyonel)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://example.com/fotograf.jpg',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white10,
                  prefixIcon: const Icon(Icons.image_outlined, color: Color(0xFF38BDF8), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Detaylı Açıklama (Pop-up’ta okunabilir)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tarihi, önemi, hakkında bilinenler...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Kısa Not / İpucu (İnce Not)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Örn: Gün batımında çok güzel, müze kart geçiyor...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('İptal', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'note': _noteController.text.trim(),
              'description': _descriptionController.text.trim(),
              'imageUrl': _imageUrlController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

