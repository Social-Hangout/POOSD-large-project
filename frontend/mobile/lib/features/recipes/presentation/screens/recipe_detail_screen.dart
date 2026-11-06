import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/mealdb_credit.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../domain/recipe.dart';
import '../controllers/recipe_list_controller.dart';
import '../widgets/recipe_image.dart';
import '../widgets/recipe_state_card.dart';

/// One recipe. Content and behaviour: the web's RecipeDetailPage
/// (web/src/pages/RecipeDetailPage.tsx): "SAVORY RECIPE", title, "By <first name>",
/// Ingredients (name and amount) and Method (numbered steps); while loading "Preparing your
/// recipe…"; on failure the API's message (e.g. "Recipe not found") and a way back.
/// The id travels in the route (/recipes/:id) as on the web. The list also passes the
/// recipe it already has, so it shows at once; with no recipe passed (deep link) it is
/// fetched with GET /api/recipes/:id.
///
/// PROVISIONAL LAYOUT: Figma has no recipe screen; it is built from existing pieces.
/// The photo is the same one the card shows (the web detail page has none).
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.initialRecipe,
  });

  final String recipeId;
  final Recipe? initialRecipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passed = initialRecipe;
    final Widget body;

    if (passed != null && passed.id == recipeId) {
      body = _RecipeContent(recipe: passed);
    } else {
      body = ref
          .watch(recipeByIdProvider(recipeId))
          .when(
            data: (recipe) => _RecipeContent(recipe: recipe),
            loading: () => const _Padded(
              child: RecipeStateCard(heading: 'Preparing your recipe…'),
            ),
            error: (error, _) => _Padded(
              child: RecipeStateCard(
                heading: error is ApiException
                    ? error.message
                    : ApiException.genericMessage,
                actionLabel: 'Back to recipes',
                onAction: () => context.go(AppRoutes.recipes),
              ),
            ),
          );
    }

    return Column(
      children: [
        const AppHeader(),
        Expanded(child: body),
      ],
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenX),
    children: [child],
  );
}

class _RecipeContent extends StatelessWidget {
  const _RecipeContent({required this.recipe});

  final Recipe recipe;

  String get _byline => 'By ${recipe.author?.firstName ?? 'a Savory cook'}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenX,
        AppSpacing.screenTop,
        AppSpacing.screenX,
        AppSpacing.screenBottom,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.recipes),
            icon: const Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColors.green,
            ),
            label: Text('Back to recipes', style: AppTextStyles.link),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.tapTarget),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.screenTop),
        Center(child: RecipeImage(recipeId: recipe.id, size: 160)),
        const SizedBox(height: AppSpacing.section),
        Text('SAVORY RECIPE', style: AppTextStyles.eyebrow),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(recipe.title, style: AppTextStyles.display),
        ),
        const SizedBox(height: 8),
        Text(_byline, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.section),
        _Section(
          title: 'Ingredients',
          child: Column(
            children: [
              for (var i = 0; i < recipe.ingredients.length; i++)
                _IngredientRow(
                  ingredient: recipe.ingredients[i],
                  showDivider: i < recipe.ingredients.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        _Section(
          title: 'Method',
          child: Column(
            children: [
              for (var i = 0; i < recipe.steps.length; i++)
                _StepRow(number: i + 1, text: recipe.steps[i]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const MealDbCredit(),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppSpacing.radiusRecipeCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.sectionHeading),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.showDivider});

  final Ingredient ingredient;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    // Shown as stored (lowercase), as on the web.
    final name = ingredient.name;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(name, style: AppTextStyles.bodyInk)),
          if (ingredient.amount.isNotEmpty) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                ingredient.amount,
                style: AppTextStyles.body,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $number. $text',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: AppTextStyles.recipeAction.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: AppTextStyles.bodyInk)),
            ],
          ),
        ),
      ),
    );
  }
}
