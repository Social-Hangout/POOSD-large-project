import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

/// Figma 13 "Recipe loading placeholder": image circle, title, rating and
/// availability bars, then a time bar and a button block.
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height, {double radius = 99}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Semantics(
      label: 'Loading recipe',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRecipeCard),
          boxShadow: AppColors.cardShadow,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final full = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                bar(math.min(full * 0.77, 240.0), 16),
                const SizedBox(height: 14),
                bar(math.min(full * 0.48, 150.0), 10),
                const SizedBox(height: 14),
                bar(full, 10),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    bar(68, 12),
                    bar(
                      110,
                      AppSpacing.tapTarget,
                      radius: AppSpacing.radiusInput,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
