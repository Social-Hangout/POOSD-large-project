import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Beige banner at the top of 01 Login: "LESS WASTE. MORE WONDER. / Cook with what you have."
class BrandProposition extends StatelessWidget {
  const BrandProposition({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(AppSpacing.radiusBanner),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LESS WASTE. MORE WONDER.', style: AppTextStyles.eyebrow),
                const SizedBox(height: 8),
                Text('Cook with what you have.', style: AppTextStyles.promise),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Figma "Grain bowl" (96 px). The file is the web app's bowl photo
          // (web/public/assets/24a21.png), which already has its white ring and a
          // transparent background, so it is drawn as is.
          Image.asset(
            'assets/images/grain_bowl.png',
            width: 96,
            height: 96,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => const SizedBox(width: 96, height: 96),
          ),
        ],
      ),
    );
  }
}
