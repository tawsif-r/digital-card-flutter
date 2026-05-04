import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
        displaySmall: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w400, color: AppColors.onSurface, height: 1.2),
        headlineLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.25),
        headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.onSurface, height: 1.3),
        headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
      );

  static TextTheme get darkTextTheme => GoogleFonts.interTextTheme().copyWith(
        displaySmall: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w400, color: AppColors.onSurfaceDark, height: 1.2),
        headlineLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark, height: 1.25),
        headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark, height: 1.3),
        headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurfaceDark),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurfaceDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceDark),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariantDark),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceDark),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariantDark),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariantDark),
      );
}
