import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/recipe_photos.dart';

/// The round recipe photo from the Figma recipe card: the recipe's photo (picked as on
/// the web, see recipe_photos.dart) cropped to a circle, with a white ring and the card
/// shadow. The web photos are rectangular, so the ring is drawn here.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.recipeId, this.size = 128});

  final String recipeId;
  final double size;

  /// Ring width read off the Figma renders (about 4 % of the diameter).
  static const _ringFraction = 0.04;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.beige,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surface,
          width: size * _ringFraction,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        recipePhotoFor(recipeId),
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
