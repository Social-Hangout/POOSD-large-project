import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../domain/recipe.dart';
import 'recipe_image.dart';

/// Recipe card. Layout: Figma "Recipe card" (frame 08), photo overlapping the top edge.
/// Content: the web's RecipeCard (web/src/components/RecipeCard.tsx): title, the first
/// three ingredients plus "+N more", "By <first name>" and "View Recipe".
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.entry, required this.onOpen});

  final RecipeListEntry entry;
  final VoidCallback onOpen;

  static const _imageSize = 128.0;
  static const _overlap = 32.0;

  /// "pasta, butter, garlic +2 more", as on the web.
  static String ingredientPreview(Recipe recipe) {
    final shown = recipe.ingredients.take(3).map((i) => i.name).join(', ');
    final extra = recipe.ingredients.length - 3;
    return extra > 0 ? '$shown +$extra more' : shown;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = entry.recipe;
    final byline = 'By ${recipe.author?.firstName ?? 'Savory cook'}';
    final preview = ingredientPreview(recipe);

    return Semantics(
      button: true,
      label: '${recipe.title}. $preview. $byline',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.only(top: _overlap),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 102, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.radiusRecipeCard,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(recipe.title, style: AppTextStyles.recipeTitle),
                      const SizedBox(height: 6),
                      Text(preview, style: AppTextStyles.small),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              byline,
                              style: AppTextStyles.recipeMeta,
                            ),
                          ),
                          SavoryButton(
                            label: 'View Recipe',
                            variant: SavoryButtonVariant.tint,
                            expand: false,
                            height: AppSpacing.tapTarget,
                            compactText: true,
                            onPressed: onOpen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -_overlap,
                child: RecipeImage(recipeId: recipe.id, size: _imageSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
