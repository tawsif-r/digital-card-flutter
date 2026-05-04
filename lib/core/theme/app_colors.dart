import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Palette
  static const Color mint = Color(0xFFC0E1D2);      // #C0E1D2
  static const Color sage = Color(0xFFE5EEE4);      // #E5EEE4
  static const Color cream = Color(0xFFF6F4E8);     // #F6F4E8
  static const Color rose = Color(0xFFDC9B9B);      // #DC9B9B

  // Primary — rose for CTAs
  static const Color primary = Color(0xFFDC9B9B);
  static const Color primaryDark = Color(0xFFE8B0B0);
  static const Color onPrimary = Color(0xFF3D1515);
  static const Color onPrimaryDark = Color(0xFF2A0D0D);

  // Light backgrounds
  static const Color background = Color(0xFFF6F4E8);     // cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE5EEE4);  // sage
  static const Color surfaceContainer = Color(0xFFC0E1D2); // mint

  // Dark backgrounds (tinted derivations)
  static const Color backgroundDark = Color(0xFF1E1C16);
  static const Color surfaceDark = Color(0xFF27251F);
  static const Color surfaceVariantDark = Color(0xFF1F2920);  // dark sage
  static const Color surfaceContainerDark = Color(0xFF1A2B24); // dark mint

  // Text
  static const Color onSurface = Color(0xFF1E1C16);
  static const Color onSurfaceVariant = Color(0xFF5A6359);
  static const Color onSurfaceDark = Color(0xFFF0EFE5);
  static const Color onSurfaceVariantDark = Color(0xFF8DA899);

  // Borders
  static const Color outline = Color(0xFFBDCBBA);      // sage-tinted border
  static const Color outlineDark = Color(0xFF2E3D35);  // dark mint border

  // Status
  static const Color error = Color(0xFFAC3535);
  static const Color errorDark = Color(0xFFE87070);
  static const Color success = Color(0xFF2D6E4A);
}
