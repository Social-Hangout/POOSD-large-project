import 'package:flutter/material.dart';

/// Colors from the Figma file (Mobile Screens / Mobile Design System pages).
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF5F2EC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1C19);
  static const muted = Color(0xFF74756F);
  static const border = Color(0xFFE5E2DA);
  static const yellow = Color(0xFFFBC02D);
  static const green = Color(0xFF22B573);
  static const greenDark = Color(0xFF147E4D);
  static const greenTint = Color(0xFFE8F7EF);
  static const error = Color(0xFFC33F36);
  static const beige = Color(0xFFEDE4D6);
  static const avatar = Color(0xFF272421);
  static const iconButton = Color(0xFFFAF9F6);

  /// Card shadow in Figma: 0 18 55 rgba(73, 52, 27, 0.08).
  static const _shadow = Color(0x1449341B);
  static const cardShadow = [
    BoxShadow(color: _shadow, offset: Offset(0, 18), blurRadius: 55),
  ];
}
