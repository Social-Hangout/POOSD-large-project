import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import 'mealdb_credit.dart';

/// Figma "Legal footer": Privacy / Terms links and the copyright line,
/// plus the TheMealDB credit (see mealdb_credit.dart).
///
/// The Privacy and Terms entries are plain text, as in Figma; no pages exist yet to link to.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Privacy policy', style: AppTextStyles.footer),
            const SizedBox(width: 20),
            Text('Terms of use', style: AppTextStyles.footer),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 Savory. Made for your everyday kitchen.',
          style: AppTextStyles.footerSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const MealDbCredit(),
      ],
    );
  }
}
