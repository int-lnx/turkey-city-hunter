import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/best_lists_data.dart';
import '../models/city_item.dart';
import '../models/city_model.dart';
import '../providers/city_provider.dart';
import '../widgets/city_popup.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'visited', 'unvisited'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCityDetails(BuildContext context, CityModel city) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPopup(
        cityId: city.id,
        cityName: city.name,
      ),
    );
  }

  /// Opens the curated package details modal where users can view and check items as visited
  void _openPackageModal(BuildContext context, BestListPackage package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BestListPackageModal(
        package: package,
        onEdit: () {
          final prov = context.read<CityProvider>();
          _showPackageEditDialog(context, prov, existingPackage: package);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131326),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.local_library_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 8),
            Text(
              'Kütüphane',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(
              icon: Icon(Icons.location_city_rounded, size: 18),
              text: 'Şehirler (81 İl)',
            ),
            Tab(
              icon: Icon(Icons.stars_rounded, size: 18),
              text: 'En İyiler Paketleri',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Şehirler Sekmesi
          _buildCitiesTab(provider),
          // 2. En İyiler Sekmesi
          _buildBestListsTab(context, provider),
        ],
      ),
    );
  }

  // ── 1. Şehirler Sekmesi ───────────────────────────────────────────────────

  Widget _buildCitiesTab(CityProvider provider) {
    final filteredCities = provider.cities.where((city) {
      if (_selectedFilter == 'visited' && !city.effectiveIsVisited) return false;
      if (_selectedFilter == 'unvisited' && city.effectiveIsVisited) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchCity = city.name.toLowerCase().contains(q) || city.id.contains(q);
        final matchPlace = city.allItems.any((item) =>
            item.name.toLowerCase().contains(q) ||
            item.subItems.any((sub) => sub.name.toLowerCase().contains(q)));
        return matchCity || matchPlace;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF131326),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visited Cities Badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.visitedCitiesCount}/81 İl Ziyaret Edildi',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search Input
              TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'İl adı veya mekan ara (Örn: Nevşehir, Efes, Nemrut)...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),
              // Filter Chips Row
              Row(
                children: [
                  _buildFilterChip('Tüm İller (${provider.cities.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Gidilenler (${provider.visitedCitiesCount})', 'visited'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Görülmeyenler (${81 - provider.visitedCitiesCount})',
                    'unvisited',
                  ),
                ],
              ),
            ],
          ),
        ),

        // City Cells Grid
        Expanded(
          child: filteredCities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '"$_searchQuery" ile eşleşen şehir veya lokasyon bulunamadı'
                            : 'Kriterlere uygun il bulunamadı',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 2;
                    if (width >= 1100) {
                      crossAxisCount = 5;
                    } else if (width >= 800) {
                      crossAxisCount = 4;
                    } else if (width >= 550) {
                      crossAxisCount = 3;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return _buildCityCard(context, city);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(BuildContext context, CityModel city) {
    final isVisited = city.effectiveIsVisited;
    final totalCount = city.totalItems;
    final checkedCount = city.checkedItems;

    // Count important locations in this city (mustSee and highlyRecommended)
    int importantCount = 0;
    for (final group in city.groups) {
      for (final item in group.items) {
        if (item.subItems.isNotEmpty) {
          for (final sub in item.subItems) {
            if (sub.importance == ItemImportance.mustSee ||
                sub.importance == ItemImportance.highlyRecommended) {
              importantCount++;
            }
          }
        } else if (item.importance == ItemImportance.mustSee ||
            item.importance == ItemImportance.highlyRecommended) {
          importantCount++;
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCityDetails(context, city),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16162D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isVisited
                  ? const Color(0xFF10B981).withValues(alpha: 0.6)
                  : Colors.white12,
              width: isVisited ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isVisited
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Plate & Visited Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      city.id,
                      style: const TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVisited)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Gidildi',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Gidilmedi',
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                ],
              ),

              // City Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Bottom Stats Row: Lokasyon & Önemli
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, color: Color(0xFF38BDF8), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            '$totalCount lokasyon',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      if (importantCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '★ $importantCount Önemli',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: totalCount == 0 ? 0.0 : (checkedCount / totalCount),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isVisited ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. En İyiler Sekmesi ──────────────────────────────────────────────────

  Widget _buildBestListsTab(BuildContext context, CityProvider provider) {
    final packages = provider.bestPackages;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Türkiye’nin En İyileri Paketleri',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Doğal güzellikler, el değmemiş kumsallar ve antik harikalar arasından seçilmiş özel tematik listeler.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Add New Package Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showPackageEditDialog(context, provider),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Yeni Paket Ekle',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Package Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 1;
            if (width >= 800) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxisCount == 1 ? 1.85 : 1.65,
              ),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return _buildPackageCard(context, package, provider);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackageCard(
      BuildContext context, BestListPackage package, CityProvider provider) {
    // Calculate how many items in this package are visited
    int visitedCount = 0;
    for (final pItem in package.items) {
      if (_isItemCheckedInCity(provider, pItem.cityId, pItem.title)) {
        visitedCount++;
      }
    }
    final total = package.items.length;
    final isAllCompleted = visitedCount == total && total > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPackageModal(context, package),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAllCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.6)
                  : Colors.white12,
              width: isAllCompleted ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background cover image
                Image.network(
                  package.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF1E293B)),
                ),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Category tag, Visited progress & Actions (Edit/Delete)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(package.iconEmoji, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  package.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAllCompleted
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAllCompleted
                                        ? const Color(0xFF10B981)
                                        : Colors.white24,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isAllCompleted ? Icons.check_circle : Icons.explore_outlined,
                                      color: isAllCompleted
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF38BDF8),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$visitedCount/$total Keşfedildi',
                                      style: TextStyle(
                                        color: isAllCompleted ? const Color(0xFF10B981) : Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Edit button
                              Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () => _showPackageEditDialog(context, provider, existingPackage: package),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom: Title, Subtitle, and View action
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            package.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Paketi Aç (${package.items.length} Lokasyon)',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 13),
                            ],
                          ),
                        ],
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

  /// Dialog to create or edit a BestListPackage
  void _showPackageEditDialog(BuildContext context, CityProvider provider,
      {BestListPackage? existingPackage}) {
    final isEditing = existingPackage != null;
    final titleController = TextEditingController(text: existingPackage?.title ?? '');
    final subtitleController = TextEditingController(text: existingPackage?.subtitle ?? '');
    final categoryController = TextEditingController(text: existingPackage?.category ?? 'Özel Liste');
    final emojiController = TextEditingController(text: existingPackage?.iconEmoji ?? '✨');
    final coverUrlController = TextEditingController(text: existingPackage?.coverImageUrl ?? '');

    // Working copy of items
    List<BestListItem> items = existingPackage != null
        ? List<BestListItem>.from(existingPackage.items)
        : [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void addOrEditItem({BestListItem? existingItem, int? itemIndex}) {
              String selectedCityId = existingItem?.cityId ?? (provider.cities.isNotEmpty ? provider.cities.first.id : '34');
              final itemTitleCtrl = TextEditingController(text: existingItem?.title ?? '');
              final itemDescCtrl = TextEditingController(text: existingItem?.description ?? '');
              final itemImgCtrl = TextEditingController(text: existingItem?.imageUrl ?? '');
              ItemImportance itemImportance = existingItem?.importance ?? ItemImportance.mustSee;

              showDialog(
                context: dialogCtx,
                builder: (itemCtx) {
                  return StatefulBuilder(
                    builder: (subCtx, setSubState) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1E1E38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          existingItem != null ? 'Lokasyonu Düzenle' : 'Lokasyon Ekle',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedCityId,
                                dropdownColor: const Color(0xFF252548),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Şehir',
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                                items: provider.cities.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.id} - ${c.name}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) selectedCityId = val;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: itemTitleCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Lokasyon / Yer Adı',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  hintText: 'Örn: Kapadokya Vadileri',
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: itemDescCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Açıklama',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  hintText: 'Örn: Sıcak hava balonları ve peri bacaları...',
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: itemImgCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Görsel URL',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  hintText: 'https://...',
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<ItemImportance>(
                                initialValue: itemImportance,
                                dropdownColor: const Color(0xFF252548),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  labelText: 'Önem Derecesi',
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: ItemImportance.mustSee,
                                    child: Text('Görmeden Ölme (En Önemli)'),
                                  ),
                                  DropdownMenuItem(
                                    value: ItemImportance.highlyRecommended,
                                    child: Text('Mutlaka Görülmeli'),
                                  ),
                                  DropdownMenuItem(
                                    value: ItemImportance.recommended,
                                    child: Text('Görülmeli'),
                                  ),
                                  DropdownMenuItem(
                                    value: ItemImportance.ordinary,
                                    child: Text('Sıradan'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) itemImportance = val;
                                },
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(itemCtx),
                            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                            onPressed: () {
                              final title = itemTitleCtrl.text.trim();
                              if (title.isEmpty) return;
                              final cityName = provider.cityById(selectedCityId)?.name ?? selectedCityId;
                              final newItem = BestListItem(
                                cityId: selectedCityId,
                                cityName: cityName,
                                title: title,
                                description: itemDescCtrl.text.trim(),
                                imageUrl: itemImgCtrl.text.trim(),
                                importance: itemImportance,
                              );
                              setDialogState(() {
                                if (existingItem != null && itemIndex != null) {
                                  items[itemIndex] = newItem;
                                } else {
                                  items.add(newItem);
                                }
                              });
                              Navigator.pop(itemCtx);
                            },
                            child: const Text('Tamam', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF16162D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Paketi Düzenle' : 'Yeni Paket Oluştur',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Paketi Sil',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: dialogCtx,
                          builder: (c) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E38),
                            title: const Text('Paketi Sil', style: TextStyle(color: Colors.white)),
                            content: Text(
                              '"${existingPackage.title}" paketini silmek istediğinize emin misiniz?',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deleteBestPackage(existingPackage.id);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        }
                      },
                    ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 65,
                            child: TextField(
                              controller: emojiController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                              decoration: const InputDecoration(
                                labelText: 'İkon',
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: titleController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Paket Başlığı *',
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                                hintText: 'Örn: Türkiye’nin En Güzel Koyları',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subtitleController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Alt Başlık / Kısa Açıklama',
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                          hintText: 'Örn: Ege ve Akdeniz’in el değmemiş cennet köşeleri',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: categoryController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Kategori Adı',
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                                hintText: 'Örn: Doğa & Macera',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: coverUrlController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Kapak Görseli URL',
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                                hintText: 'https://...',
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Package items sub-list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lokasyonlar (${items.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => addOrEditItem(),
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF38BDF8)),
                            label: const Text(
                              'Lokasyon Ekle',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Text(
                            'Henüz lokasyon eklenmedi. "Lokasyon Ekle" butonu ile mekan ekleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final itm = items[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itm.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${itm.cityName} • ${itm.description.isNotEmpty ? itm.description : "Açıklama yok"}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
                                      onPressed: () => addOrEditItem(existingItem: itm, itemIndex: i),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                                      onPressed: () => setDialogState(() => items.removeAt(i)),
                                      visualDensity: VisualDensity.compact,
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final updatedPkg = BestListPackage(
                      id: existingPackage?.id ?? 'custom_pkg_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      subtitle: subtitleController.text.trim(),
                      category: categoryController.text.trim().isNotEmpty
                          ? categoryController.text.trim()
                          : 'Özel Liste',
                      iconEmoji: emojiController.text.trim().isNotEmpty
                          ? emojiController.text.trim()
                          : '✨',
                      coverImageUrl: coverUrlController.text.trim().isNotEmpty
                          ? coverUrlController.text.trim()
                          : 'https://images.unsplash.com/photo-1527838832700-5059252407fa?w=800&q=80',
                      items: items,
                    );

                    if (isEditing) {
                      await provider.updateBestPackage(updatedPkg);
                    } else {
                      await provider.addBestPackage(updatedPkg);
                    }

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: Text(isEditing ? 'Güncelle' : 'Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper to check if an item in a specific city is checked
  static bool _isItemCheckedInCity(
      CityProvider provider, String cityId, String itemTitle) {
    final city = provider.cityById(cityId);
    if (city == null) return false;
    if (city.effectiveIsVisited) return true;

    final query = itemTitle.toLowerCase().trim();
    for (final group in city.groups) {
      for (final item in group.items) {
        final name = item.name.toLowerCase();
        if (name.contains(query) || query.contains(name)) {
          if (item.effectiveIsChecked) return true;
        }
        for (final sub in item.subItems) {
          final sName = sub.name.toLowerCase();
          if (sName.contains(query) || query.contains(sName)) {
            if (sub.isChecked) return true;
          }
        }
      }
    }
    return false;
  }
}

// ── Best List Package Details Modal ──────────────────────────────────────────

class _BestListPackageModal extends StatelessWidget {
  final BestListPackage package;
  final VoidCallback? onEdit;

  const _BestListPackageModal({required this.package, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16162D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top drag bar & close button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(package.iconEmoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${package.items.length} Önemli Lokasyon Paketi',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF38BDF8), size: 20),
                            tooltip: 'Paketi Düzenle',
                            onPressed: () {
                              Navigator.pop(ctx);
                              onEdit!();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Items List
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: package.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = package.items[index];
                    return _buildPackageItemTile(context, provider, item);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageItemTile(
      BuildContext context, CityProvider provider, BestListItem item) {
    final city = provider.cityById(item.cityId);

    // Find the matching item in city data to toggle its checked state
    CityItem? matchedCityItem;
    String? matchedGroupId;

    if (city != null) {
      final query = item.title.toLowerCase().trim();
      for (final g in city.groups) {
        for (final ci in g.items) {
          final ciName = ci.name.toLowerCase();
          if (ciName.contains(query) || query.contains(ciName)) {
            matchedCityItem = ci;
            matchedGroupId = g.id;
            break;
          }
        }
        if (matchedCityItem != null) break;
      }
    }

    final isChecked = (matchedCityItem?.effectiveIsChecked ?? false) ||
        (city?.effectiveIsVisited ?? false);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox (Clicking marks visited!)
          InkWell(
            onTap: () {
              if (city != null) {
                if (matchedCityItem != null && matchedGroupId != null) {
                  provider.toggleItem(city.id, matchedGroupId, matchedCityItem.id);
                } else {
                  // Fallback: Toggle city visit status
                  provider.toggleCityVisited(city.id);
                }
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF10B981) : Colors.white38,
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                width: 50,
                height: 50,
                color: Colors.white10,
                child: const Icon(Icons.image, color: Colors.white24, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title, City Name & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: isChecked ? Colors.white70 : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.cityName,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
