import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
        displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w400),
        headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      );
}
