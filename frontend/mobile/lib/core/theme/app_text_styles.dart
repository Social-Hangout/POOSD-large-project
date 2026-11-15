import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles from the Figma frames: DM Sans for UI, Playfair Display for headings.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle _dm(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle get wordmark => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontStyle: FontStyle.italic,
    color: AppColors.ink,
  );
  static TextStyle get wordmarkDot => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.yellow,
  );

  /// "Welcome back.", "Join the kitchen.", "Explore popular recipes"
  static TextStyle get display => GoogleFonts.playfairDisplay(
    fontSize: 30,
    height: 1.18,
    color: AppColors.ink,
  );

  /// "Cook with what you have."
  static TextStyle get promise => GoogleFonts.playfairDisplay(
    fontSize: 27,
    height: 1.18,
    color: AppColors.ink,
  );

  /// "Mediterranean Chicken Bowl" (recipe-of-the-week size), reused for card headings.
  static TextStyle get sectionHeading => GoogleFonts.playfairDisplay(
    fontSize: 24,
    height: 1.18,
    color: AppColors.ink,
  );

  /// "YOUR KITCHEN AWAITS"
  static TextStyle get eyebrow => _dm(10, FontWeight.w700, AppColors.greenDark);

  static TextStyle get fieldLabel =>
      _dm(14, FontWeight.w600, AppColors.ink, height: 1.5);
  static TextStyle get input => _dm(15, FontWeight.w400, AppColors.ink);
  static TextStyle get inputHint => _dm(15, FontWeight.w400, AppColors.muted);
  static TextStyle get fieldError =>
      _dm(12, FontWeight.w400, AppColors.error, height: 1.5);
  static TextStyle get strengthLabel =>
      _dm(12, FontWeight.w600, AppColors.ink, height: 1.5);

  static TextStyle get body =>
      _dm(14, FontWeight.w400, AppColors.muted, height: 1.5);
  static TextStyle get bodyInk =>
      _dm(14, FontWeight.w400, AppColors.ink, height: 1.5);
  static TextStyle get small => _dm(13, FontWeight.w400, AppColors.muted);
  static TextStyle get smallLegal =>
      _dm(12, FontWeight.w400, AppColors.muted, height: 1.6);
  static TextStyle get link => _dm(14, FontWeight.w600, AppColors.green);
  static TextStyle get linkSmall => _dm(13, FontWeight.w600, AppColors.green);
  static TextStyle get button => _dm(15, FontWeight.w700, AppColors.ink);

  static TextStyle get recipeTitle =>
      _dm(16, FontWeight.w400, AppColors.ink, height: 1.5);
  static TextStyle get recipeRating =>
      _dm(13, FontWeight.w400, AppColors.yellow);
  static TextStyle get recipeMeta => _dm(12, FontWeight.w400, AppColors.muted);
  static TextStyle get recipeAction =>
      _dm(13, FontWeight.w700, AppColors.greenDark);

  static TextStyle get footer => _dm(12, FontWeight.w400, AppColors.muted);
  static TextStyle get footerSmall =>
      _dm(11, FontWeight.w400, AppColors.muted, height: 1.5);
  static TextStyle get navLabel => _dm(10, FontWeight.w400, AppColors.ink);
  static TextStyle get navLabelActive =>
      _dm(10, FontWeight.w700, AppColors.ink);
  static TextStyle get pageLabel => _dm(13, FontWeight.w400, AppColors.ink);
  static TextStyle get avatar => _dm(12, FontWeight.w700, AppColors.surface);
}
