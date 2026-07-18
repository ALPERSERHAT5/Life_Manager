import 'package:flutter/material.dart';

/// Life Manager renk paleti — prompttaki renk şemasına birebir sadık.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color secondary = Color(0xFF7C3AED); // Mor
  static const Color success = Color(0xFF22C55E); // Yeşil
  static const Color warning = Color(0xFFF59E0B); // Turuncu
  static const Color danger = Color(0xFFEF4444); // Kırmızı
  static const Color accent = Color(0xFF38BDF8); // Camgöbeği

  // Dark tema yüzeyleri
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color subtitleDark = Color(0xFFB0B8C9);

  // Light tema yüzeyleri
  static const Color backgroundLight = Color(0xFFF4F6FB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF0F172A);
  static const Color subtitleLight = Color(0xFF64748B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'Yüksek':
        return danger;
      case 'Orta':
        return warning;
      case 'Düşük':
      default:
        return success;
    }
  }

  static const Map<String, Color> categoryColors = {
    'Kişisel': accent,
    'İş': primary,
    'Okul': secondary,
    'Sağlık': success,
    'Spor': warning,
    'Alışveriş': danger,
    'Diğer': subtitleDark,
  };
}
