import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgPrimary = Color(0xFF0A0E17);
  static const Color bgSecondary = Color(0xFF0F172A);
  static const Color bgTertiary = Color(0xFF020617);
  static const Color bgPanel = Color(0xDA111827);
  static const Color bgCard = Color(0x1A1E293B);

  // Accent - Neon Cyan
  static const Color accentCyan = Color(0xFF00F0FF);
  static const Color accentCyanDim = Color(0x4400F0FF);
  static const Color accentCyanGlow = Color(0x0D00F0FF);

  // Accent - Others
  static const Color accentBlue = Color(0xFF0066FF);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPink = Color(0xFFFF006E);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGreen = Color(0xFF00FF87);

  // Text
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF475569);

  // Borders & Effects
  static const Color borderGlow = Color(0x3300F0FF);
  static const Color scanline = Color(0x0800F0FF);
  static const Color gridLine = Color(0x1000F0FF);

  // Status colors
  static const Color success = Color(0xFF00FF87);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF006E);

  // Weather condition gradients
  static const List<Color> sunnyGradient = [
    Color(0xFF0A0E17),
    Color(0xFF1A1A3E),
    Color(0xFF2A1A4E),
  ];

  static const List<Color> cloudyGradient = [
    Color(0xFF0A0E17),
    Color(0xFF1E293B),
    Color(0xFF334155),
  ];

  static const List<Color> rainyGradient = [
    Color(0xFF0A0E17),
    Color(0xFF0F172A),
    Color(0xFF1E3A5F),
  ];

  static const List<Color> snowyGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
    Color(0xFF3B4A6B),
  ];

  static const List<Color> stormGradient = [
    Color(0xFF0A0E17),
    Color(0xFF1A0A2E),
    Color(0xFF2D1B4E),
  ];
}
