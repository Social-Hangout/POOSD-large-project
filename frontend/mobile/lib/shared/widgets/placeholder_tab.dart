import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_header.dart';
import 'eyebrow_heading.dart';
import 'surface_card.dart';

/// Stand-in for tabs that have Figma frames but are outside the week-2 scope
/// (06 My kitchen, 11 Saved, 12 Account). Keeps the bottom navigation usable.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.eyebrow,
    required this.heading,
    this.message = 'This screen is coming in a later milestone.',
    this.extra,
  });

  final String eyebrow;
  final String heading;
  final String message;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenX,
              AppSpacing.screenTop,
              AppSpacing.screenX,
              AppSpacing.screenBottom,
            ),
            children: [
              EyebrowHeading(eyebrow: eyebrow, heading: heading, gap: 10),
              const SizedBox(height: AppSpacing.section),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(message, style: AppTextStyles.body),
                    if (extra != null) ...[
                      const SizedBox(height: AppSpacing.cardGap),
                      extra!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
