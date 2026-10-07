// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../data/turkey_provinces_geo.dart';
import '../providers/city_provider.dart';
import '../utils/color_helper.dart';

class ShareCardDialog extends StatefulWidget {
  final GlobalKey boundaryKey;

  const ShareCardDialog({super.key, required this.boundaryKey});

  static Future<void> show(BuildContext context) async {
    final GlobalKey cardBoundaryKey = GlobalKey();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ShareCardDialog(boundaryKey: cardBoundaryKey),
    );
  }

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  bool _isDownloading = false;

  Future<void> _captureAndSaveImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      // Small frame delay to ensure card is fully rendered
      await Future.delayed(const Duration(milliseconds: 150));

      final boundary = widget.boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render nesnesi bulunamadı.');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Görsel verisi oluşturulamadı.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([pngBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'turkiye_kesif_haritasi.png')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Kart görseli başarıyla indirildi!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('Görsel kaydedilirken hata oluştu: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CityProvider>();
    final rawName = provider.currentUser.trim();
    final userName = rawName.isNotEmpty ? rawName : 'Gezgin';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top action buttons (Close & Title)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.share_rounded,
                          color: Color(0xFF38BDF8), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Haritanı Paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // RepaintBoundary wrapping the generated share card
              RepaintBoundary(
                key: widget.boundaryKey,
                child: _buildShareCardContent(provider, userName),
              ),
              const SizedBox(height: 16),

              // Download / Share Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isDownloading ? null : _captureAndSaveImage,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 22),
                  label: Text(
                    _isDownloading
                        ? 'Görsel Hazırlanıyor...'
                        : 'Görseli İndir / Paylaş',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareCardContent(CityProvider provider, String userName) {
    final checkedItems = provider.cities.fold(0, (s, c) => s + c.checkedItems);
    final visitedCities = provider.visitedCitiesCount;
    final rate = provider.overallRate;
    final ratePercent = provider.overallPercent;
    final overallThemeColor = cityColor(rate);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B0F19),
            Color(0xFF1E1B4B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar with Flag, App Name & Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text('🇹🇷', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName Türkiye Performansı!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Türkiye Keşif Haritası',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: overallThemeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: overallThemeColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: overallThemeColor, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      ratePercent,
                      style: TextStyle(
                        color: overallThemeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Map Preview (Static snapshot rendering)
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF070B14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _ShareMapSnapshotPainter(provider: provider),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Stat Cards Grid (Gezilen İl, Görülen Lokasyon, Ölmeden Önce, Mutlaka Gör)
          Row(
            children: [
              Expanded(
                child: _buildShareStatBox(
                  icon: Icons.explore_rounded,
                  label: 'Ziyaret Edilen İl',
                  value: '$visitedCities / 81',
                  accentColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildShareStatBox(
                  icon: Icons.check_circle_rounded,
                  label: 'Görülen Lokasyon',
                  value: '$checkedItems yer',
                  accentColor: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildShareStatBox(
                  icon: Icons.stars_rounded,
                  label: 'Ölmeden Önce',
                  value:
                      '${provider.mustSeeCheckedCount}/${provider.mustSeeTotalCount} (%${(provider.mustSeeRate * 100).toStringAsFixed(0)})',
                  accentColor: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildShareStatBox(
                  icon: Icons.recommend_rounded,
                  label: 'Mutlaka Görülmeli',
                  value:
                      '${provider.highlyRecommendedCheckedCount}/${provider.highlyRecommendedTotalCount} (%${(provider.highlyRecommendedRate * 100).toStringAsFixed(0)})',
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer Watermark
          Builder(
            builder: (_) {
              final now = DateTime.now();
              const months = [
                'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
              ];
              final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'turkey-city.web.app',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Türkiye Keşif Günlüğü',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShareStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accentColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
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

// ── Snapshot Painter for Map without interaction ─────────────────────────────
class _ShareMapSnapshotPainter extends CustomPainter {
  final CityProvider provider;

  static const double _minLon = 25.6;
  static const double _maxLon = 44.8;
  static const double _minLat = 35.8;
  static const double _maxLat = 42.1;
  static const double _kLonSpan = _maxLon - _minLon;
  static const double _kLatSpan = _maxLat - _minLat;
  static final double _kCosLat = math.cos(39.0 * math.pi / 180.0);
  static double get _mapAspect => (_kLonSpan * _kCosLat) / _kLatSpan;

  _ShareMapSnapshotPainter({required this.provider});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF090D1A), Color(0xFF141E33)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Compute fitted aspect bounds
    double w = size.width;
    double h = size.height;
    if (w / h > _mapAspect) {
      w = h * _mapAspect;
    } else {
      h = w / _mapAspect;
    }

    final dx = (size.width - w) / 2;
    final dy = (size.height - h) / 2;

    canvas.save();
    canvas.translate(dx, dy);

    final fittedSize = Size(w, h);
    final effectiveLonSpan = _kLonSpan * _kCosLat;

    Offset project(double lon, double lat) {
      final nx = (lon - _minLon) * _kCosLat / effectiveLonSpan;
      final ny = (_maxLat - lat) / _kLatSpan;
      return Offset(nx * fittedSize.width, ny * fittedSize.height);
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF0B132B)
      ..strokeWidth = 0.6;

    for (final entry in TurkeyProvinceGeoData.provincePolygons.entries) {
      final plate = entry.key;
      final polygons = entry.value;
      final plateStr = plate.toString().padLeft(2, '0');
      final city = provider.cityById(plateStr);

      final ratio = city?.completionRate ?? 0.0;
      final isVisited = city?.effectiveIsVisited ?? false;
      fillPaint.color = cityColor(ratio, isVisited: isVisited);

      for (final polygon in polygons) {
        if (polygon.isEmpty) continue;
        final path = Path();
        final first = project(polygon[0][0], polygon[0][1]);
        path.moveTo(first.dx, first.dy);
        for (int i = 1; i < polygon.length; i++) {
          final pt = project(polygon[i][0], polygon[i][1]);
          path.lineTo(pt.dx, pt.dy);
        }
        path.close();

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShareMapSnapshotPainter old) => old.provider != provider;
}
