import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.yellow,
        primary: AppColors.yellow,
        onPrimary: AppColors.ink,
        secondary: AppColors.green,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
      ),
    );
  }
}
