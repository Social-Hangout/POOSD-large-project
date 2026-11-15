import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// "Savory." wordmark row at the top of every Figma frame (64 tall, 20 side padding).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenX),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              header: true,
              label: 'Savory',
              child: ExcludeSemantics(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Savory', style: AppTextStyles.wordmark),
                      TextSpan(text: '.', style: AppTextStyles.wordmarkDot),
                    ],
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
