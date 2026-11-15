import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Eyebrow + Playfair heading + optional supporting copy ("Introduction" in Figma).
class EyebrowHeading extends StatelessWidget {
  const EyebrowHeading({
    super.key,
    required this.eyebrow,
    required this.heading,
    this.supporting,
    this.headingStyle,
    this.gap = 8,
  });

  final String eyebrow;
  final String heading;
  final String? supporting;
  final TextStyle? headingStyle;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTextStyles.eyebrow),
        SizedBox(height: gap),
        Semantics(
          header: true,
          child: Text(heading, style: headingStyle ?? AppTextStyles.display),
        ),
        if (supporting != null) ...[
          const SizedBox(height: 8),
          Text(supporting!, style: AppTextStyles.body),
        ],
      ],
    );
  }
}
