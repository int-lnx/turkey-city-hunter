import 'package:flutter/material.dart';

/// Returns a color for a given completion rate [0.0–1.0] and isVisited flag.
/// - 0% ve görülmedi: Koyu Arka Plan Grisi (0xFF334155 / slate-700)
/// - 0% ama Görüldü/Ziyaret edildi: Hafif açık grimsi/gümüş (0xFF94A3B8 / slate-400)
/// - >0% - <100%: Kırmızıdan yeşile spektrum
/// - 100%: Mavi (0xFF2563EB / royal blue)
Color cityColor(double rate, {bool isVisited = false}) {
  if (rate <= 0.0) {
    if (isVisited) {
      return const Color(0xFF94A3B8); // Hafif grimsi/gümüş - Görüldü ama alt madde seçilmemiş
    }
    return const Color(0xFF334155); // Koyu Gri (Hiç ziyaret edilmemiş)
  }
  if (rate >= 1.0) {
    return const Color(0xFF2563EB); // Mavi (%100 Tamamlanan)
  }

  // Kırmızı (0.0) -> Sarı (0.5) -> Yeşil (1.0) Spektrumu
  if (rate < 0.5) {
    final t = rate / 0.5;
    return Color.lerp(const Color(0xFFEF4444), const Color(0xFFF59E0B), t)!;
  } else {
    final t = (rate - 0.5) / 0.5;
    return Color.lerp(const Color(0xFFF59E0B), const Color(0xFF10B981), t)!;
  }
}

Color cityBorderColor(double rate, {bool isVisited = false}) {
  if (rate <= 0.0) {
    return isVisited ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  }
  if (rate >= 1.0) return const Color(0xFF60A5FA);
  return cityColor(rate, isVisited: isVisited).withValues(alpha: 0.8);
}

