import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/turkey_map_data.dart';
import '../data/turkey_provinces_geo.dart';
import '../providers/city_provider.dart';
import '../utils/color_helper.dart';
import 'city_popup.dart';

// ── Map Bounding Box & Aspect Ratio ──────────────────────────────────────────
const double _minLon = 25.6;
const double _maxLon = 44.8;
const double _minLat = 35.8;
const double _maxLat = 42.1;

const double _kLonSpan = _maxLon - _minLon;
const double _kLatSpan = _maxLat - _minLat;
const double _kMidLatRad = 39.0 * math.pi / 180.0;
final double _kCosLat = math.cos(_kMidLatRad); // ≈ 0.777

double get _mapAspect => (_kLonSpan * _kCosLat) / _kLatSpan;

// ── TurkeyMapWidget ──────────────────────────────────────────────────────────

class TurkeyMapWidget extends StatefulWidget {
  final void Function(String cityId, String cityName)? onCityTap;

  const TurkeyMapWidget({super.key, this.onCityTap});

  @override
  State<TurkeyMapWidget> createState() => _TurkeyMapWidgetState();
}

class _TurkeyMapWidgetState extends State<TurkeyMapWidget> {
  int? _hoveredPlate;

  Map<int, List<Path>>? _cachedPaths;
  Size? _cachedSize;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Map<int, List<Path>> _getPaths(Size size) {
    if (size == _cachedSize && _cachedPaths != null) return _cachedPaths!;
    _cachedPaths = _buildPaths(size);
    _cachedSize = size;
    return _cachedPaths!;
  }

  static Map<int, List<Path>> _buildPaths(Size size) {
    final result = <int, List<Path>>{};
    for (final entry in TurkeyProvinceGeoData.provincePolygons.entries) {
      final plate = entry.key;
      final polygons = entry.value;
      final pathList = <Path>[];

      for (final polygon in polygons) {
        if (polygon.isEmpty) continue;
        final path = Path();
        final first = _project(polygon[0][0], polygon[0][1], size);
        path.moveTo(first.dx, first.dy);

        for (int i = 1; i < polygon.length; i++) {
          final pt = _project(polygon[i][0], polygon[i][1], size);
          path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        pathList.add(path);
      }
      result[plate] = pathList;
    }
    return result;
  }

  static Offset _project(double lon, double lat, Size size) {
    final effectiveLonSpan = _kLonSpan * _kCosLat;
    final nx = (lon - _minLon) * _kCosLat / effectiveLonSpan;
    final ny = (_maxLat - lat) / _kLatSpan;
    return Offset(nx * size.width, ny * size.height);
  }

  int? _hitTestPlate(Offset point, Size size) {
    final pathsMap = _getPaths(size);
    for (final entry in pathsMap.entries) {
      for (final path in entry.value) {
        if (path.contains(point)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double w = constraints.maxWidth;
        double h = constraints.maxHeight;

        if (w / h > _mapAspect) {
          w = h * _mapAspect;
        } else {
          h = w / _mapAspect;
        }

        final size = Size(w, h);

        return Stack(
          children: [
            // Full-screen Background Grid
            const Positioned.fill(
              child: CustomPaint(
                painter: _TurkeyMapBg(),
              ),
            ),
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 6.0,
              clipBehavior: Clip.none,
              child: Center(
                child: SizedBox(
                  width: w,
                  height: h,
                  child: MouseRegion(
                    onHover: (event) {
                      final plate = _hitTestPlate(event.localPosition, size);
                      if (plate != _hoveredPlate) {
                        setState(() => _hoveredPlate = plate);
                      }
                    },
                    onExit: (_) {
                      if (_hoveredPlate != null) {
                        setState(() => _hoveredPlate = null);
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final plate = _hitTestPlate(details.localPosition, size);
                        if (plate != null) {
                          final plateStr = plate.toString().padLeft(2, '0');
                          final cityName = TurkeyGridData.cityNames[plateStr] ?? plateStr;
                          if (widget.onCityTap != null) {
                            widget.onCityTap!(plateStr, cityName);
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CityPopup(
                                cityId: plateStr,
                                cityName: cityName,
                              ),
                            );
                          }
                        }
                      },
                      onTap: () {},
                      child: CustomPaint(
                        size: size,
                        foregroundPainter: _TurkeyMapPainter(
                          pathsMap: _getPaths(size),
                          hoveredPlate: _hoveredPlate,
                          provider: Provider.of<CityProvider>(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Reset Zoom Floating Button
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: IconButton(
                  icon: const Icon(Icons.zoom_out_map, color: Colors.white70, size: 20),
                  tooltip: 'Yakınlaştırmayı Sıfırla',
                  onPressed: () {
                    _transformationController.value = Matrix4.identity();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Background Painter ───────────────────────────────────────────────────────

class _TurkeyMapBg extends CustomPainter {
  const _TurkeyMapBg();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const step = 45.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_TurkeyMapBg old) => false;
}

// ── Foreground Painter ───────────────────────────────────────────────────────

class _TurkeyMapPainter extends CustomPainter {
  final Map<int, List<Path>> pathsMap;
  final int? hoveredPlate;
  final CityProvider provider;

  _TurkeyMapPainter({
    required this.pathsMap,
    required this.hoveredPlate,
    required this.provider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (final entry in pathsMap.entries) {
      final plate = entry.key;
      final pathList = entry.value;
      final isHovered = plate == hoveredPlate;
      final plateStr = plate.toString().padLeft(2, '0');
      final city = provider.cityById(plateStr);

      final ratio = city?.completionRate ?? 0.0;
      final isVisited = city?.effectiveIsVisited ?? false;
      final baseColor = cityColor(ratio, isVisited: isVisited);

      fillPaint.color = isHovered
          ? Color.lerp(baseColor, Colors.white, 0.25)!
          : baseColor;

      for (final path in pathList) {
        canvas.drawPath(path, fillPaint);

        if (isHovered) {
          final glowPaint = Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
            ..strokeWidth = 5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawPath(path, glowPaint);
        }

        borderPaint
          ..color = isHovered ? Colors.white : const Color(0xFF0F172A)
          ..strokeWidth = isHovered ? 2.2 : 0.8;
        canvas.drawPath(path, borderPaint);
      }
    }

    _drawLabels(canvas, size);
  }

  void _drawLabels(Canvas canvas, Size size) {
    final fontSize = _labelFontSize(size);

    for (final entry in pathsMap.entries) {
      final plate = entry.key;
      final pathList = entry.value;
      if (pathList.isEmpty) continue;

      final plateStr = plate.toString().padLeft(2, '0');
      final name = TurkeyGridData.cityNames[plateStr] ?? plateStr;
      final isHovered = plate == hoveredPlate;

      // Find center of bounds
      Rect bounds = pathList.first.getBounds();
      for (int i = 1; i < pathList.length; i++) {
        bounds = bounds.expandToInclude(pathList[i].getBounds());
      }
      final center = bounds.center;

      final style = TextStyle(
        color: Colors.white,
        fontSize: isHovered ? fontSize + 1.5 : fontSize,
        fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0.5, 0.5)),
        ],
      );

      _drawCenteredText(canvas, name, center, style, maxWidth: bounds.width * 1.2);
    }
  }

  static double _labelFontSize(Size size) {
    if (size.width < 500) return 6.0;
    if (size.width < 800) return 7.5;
    if (size.width < 1100) return 9.0;
    return 10.5;
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    double maxWidth = 60,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: math.max(maxWidth, 20));

    tp.paint(
      canvas,
      center - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TurkeyMapPainter old) {
    return old.hoveredPlate != hoveredPlate || old.provider != provider;
  }
}
