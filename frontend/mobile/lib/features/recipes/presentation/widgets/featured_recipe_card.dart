import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../domain/recipe.dart';
import 'recipe_image.dart';

/// Featured recipe. Layout: Figma's "Recipe of the week" card (frame 08). Behaviour and
/// content: the web's featured block (web/src/pages/RecipesPage.tsx): the first recipe of
/// page 1, "FEATURED RECIPE", "<n> ingredients · <n> steps · by <name>", "View recipe →".
/// The eyebrow says "Featured recipe", not "Recipe of the week", because it is simply the
/// newest recipe, as on the web.
class FeaturedRecipeCard extends StatelessWidget {
  const FeaturedRecipeCard({
    super.key,
    required this.recipe,
    required this.onOpen,
  });

  final Recipe recipe;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final meta =
        '${recipe.ingredients.length} ingredients · ${recipe.steps.length} steps · '
        'by ${recipe.author?.firstName ?? 'a Savory cook'}';

    return SurfaceCard(
      radius: AppSpacing.radiusRecipeCard,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeImage(recipeId: recipe.id, size: 104),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FEATURED RECIPE', style: AppTextStyles.eyebrow),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text(
                    recipe.title,
                    style: AppTextStyles.sectionHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(meta, style: AppTextStyles.recipeMeta),
                const SizedBox(height: 12),
                SavoryButton(
                  label: 'View recipe →',
                  variant: SavoryButtonVariant.primaryGreen,
                  expand: false,
                  height: AppSpacing.tapTarget,
                  compactText: true,
                  onPressed: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
