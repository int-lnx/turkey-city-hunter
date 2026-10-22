import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/highlight_locations_data.dart';
import '../models/city_item.dart';
import '../providers/city_provider.dart';
import 'city_popup.dart';

class HighlightLocationsMarquee extends StatefulWidget {
  const HighlightLocationsMarquee({super.key});

  @override
  State<HighlightLocationsMarquee> createState() => _HighlightLocationsMarqueeState();
}

class _HighlightLocationsMarqueeState extends State<HighlightLocationsMarquee> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Start somewhere in the middle
        _scrollController.jumpTo(1000.0);
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted || !_scrollController.hasClients || _isUserInteracting) return;

      final currentOffset = _scrollController.offset;
      final maxOffset = _scrollController.position.maxScrollExtent;

      if (currentOffset >= maxOffset - 200) {
        _scrollController.jumpTo(500.0);
      } else {
        _scrollController.jumpTo(currentOffset + 0.9);
      }
    });
  }

  void _pauseAutoScroll() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
  }

  void _resumeAutoScrollDelayed() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  void _openCity(HighlightLocation loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPopup(
        cityId: loc.cityId,
        cityName: loc.cityName,
      ),
    );
  }

  /// Determines if a specific highlight location has already been visited by the user
  bool _isLocationVisited(CityProvider provider, HighlightLocation loc) {
    final city = provider.cityById(loc.cityId);
    if (city == null) return false;

    // 1. If the whole city has been marked as visited, consider this location visited
    if (city.effectiveIsVisited) return true;

    // 2. If the specific location item is checked inside this city
    final matchKey = (loc.itemNameMatch ?? loc.title).toLowerCase().trim();
    for (final group in city.groups) {
      for (final item in group.items) {
        final itemName = item.name.toLowerCase();
        if (itemName.contains(matchKey) || matchKey.contains(itemName)) {
          if (item.effectiveIsChecked) return true;
        }
        for (final sub in item.subItems) {
          final subName = sub.name.toLowerCase();
          if (subName.contains(matchKey) || matchKey.contains(subName)) {
            if (sub.isChecked) return true;
          }
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();

    // Filter out already visited locations! Only unvisited destinations should be suggested.
    final unvisitedLocations = kHighlightLocations.where((loc) {
      return !_isLocationVisited(provider, loc);
    }).toList();

    // If all locations have been visited, show a congratulatory badge
    if (unvisitedLocations.isEmpty) {
      return Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A).withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: Colors.white12, width: 0.8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 20),
            SizedBox(width: 8),
            Text(
              'Tebrikler! Öne çıkan tüm ana lokasyonları keşfettiniz! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 122,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 0.8),
          bottom: BorderSide(color: Colors.white10, width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFA78BFA), size: 12),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Görülmesi Gereken Önemli Lokasyonlar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${unvisitedLocations.length} Öneri',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                const Text(
                  'İncelemek için tıkla',
                  style: TextStyle(color: Colors.white38, fontSize: 9.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          // Horizontal scrolling list of unvisited destinations
          Expanded(
            child: Listener(
              onPointerDown: (_) => _pauseAutoScroll(),
              onPointerUp: (_) => _resumeAutoScrollDelayed(),
              onPointerCancel: (_) => _resumeAutoScrollDelayed(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification && notification.dragDetails != null) {
                    _pauseAutoScroll();
                  } else if (notification is ScrollEndNotification) {
                    _resumeAutoScrollDelayed();
                  }
                  return false;
                },
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    itemBuilder: (context, index) {
                      final item = unvisitedLocations[index % unvisitedLocations.length];
                      return _buildSquareCell(item);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareCell(HighlightLocation item) {
    final impColor = Color(item.importance.colorValue);

    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCity(item),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white12,
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Location Image
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.landscape, color: Colors.white30, size: 28),
                      ),
                    ),
                  ),
                  // Gradient Overlay for readable text
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Top badge: Importance badge
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: impColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.importance == ItemImportance.mustSee ? '★ Ölmeden' : '★ Mutlaka',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Bottom text: Place name and City
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 9),
                            const SizedBox(width: 1),
                            Expanded(
                              child: Text(
                                item.cityName,
                                style: const TextStyle(
                                  color: Color(0xFFBAE6FD),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 3),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
      ),
    );
  }
}
