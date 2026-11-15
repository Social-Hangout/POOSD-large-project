import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/mealdb_credit.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../domain/recipe.dart';
import '../controllers/my_recipes_controller.dart';
import '../widgets/owner_actions.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_card_skeleton.dart';
import '../widgets/recipe_state_card.dart';

/// The logged-in user's own recipes, with Edit and Delete.
/// Behaviour and words: the web's MyRecipesPage (web/src/pages/MyRecipesPage.tsx):
/// - "YOUR KITCHEN" / "My Recipes" with a "+ New Recipe" button;
/// - GET /api/recipes?mine=true, 12 per page, newest first, with page buttons;
/// - each card is the regular recipe card plus Edit and a two-step Delete;
/// - empty: "You haven’t shared any recipes yet." and "Share your first recipe";
/// - error: the API's message (or "Could not load your recipes."), plus "Try again" as
///   on the mobile Explore list;
/// - deleting the last recipe on a page goes back one page.
/// Loading uses the mobile skeleton cards (Figma 13) in place of the web's text.
class MyRecipesScreen extends ConsumerStatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  ConsumerState<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends ConsumerState<MyRecipesScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    ref.read(myRecipesPageNumberProvider.notifier).goTo(page);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _newRecipe() => context.go(AppRoutes.newRecipe);

  void _open(Recipe recipe) =>
      context.go(AppRoutes.myRecipe(recipe.id), extra: recipe);

  void _edit(Recipe recipe) =>
      context.go(AppRoutes.editRecipe(recipe.id), extra: recipe);

  @override
  Widget build(BuildContext context) {
    final pageNumber = ref.watch(myRecipesPageNumberProvider);
    final pageAsync = ref.watch(myRecipesPageProvider);

    final loading = [for (var i = 0; i < 3; i++) const RecipeCardSkeleton()];

    final List<Widget> content = pageAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => loading,
      error: (error, _) => [
        RecipeStateCard(
          heading: error is ApiException
              ? error.message
              : 'Could not load your recipes.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(myRecipesPageProvider),
        ),
      ],
      data: (page) {
        if (page.isEmpty) {
          // As on the web: deleting the last recipe on a page leaves it empty, so step
          // back one page (showing loading meanwhile, not the empty message).
          if (pageNumber > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref
                    .read(myRecipesPageNumberProvider.notifier)
                    .goTo(pageNumber - 1);
              }
            });
            return loading;
          }
          return [
            RecipeStateCard(
              heading: 'You haven’t shared any recipes yet.',
              actionLabel: 'Share your first recipe',
              onAction: _newRecipe,
            ),
          ];
        }
        return [
          for (final entry in page.items)
            RecipeCard(
              // Keyed by id so a card's delete confirmation never moves to another
              // recipe when the list reloads.
              key: ValueKey(entry.recipe.id),
              entry: entry,
              onOpen: () => _open(entry.recipe),
              actions: OwnerActions(
                recipe: entry.recipe,
                onEdit: () => _edit(entry.recipe),
                // The lists reload themselves (refreshRecipeLists).
                onDeleted: () {},
              ),
            ),
          PaginationBar(
            page: page.page,
            totalPages: page.totalPages,
            onPage: _goToPage,
          ),
        ];
      },
    );

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(myRecipesPageProvider.future),
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenX,
                AppSpacing.screenTop,
                AppSpacing.screenX,
                AppSpacing.screenBottom,
              ),
              children: [
                // The web's .section-heading: title on the left, button on the right,
                // wrapping under it on narrow screens.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runSpacing: 14,
                  spacing: 12,
                  children: [
                    const IntrinsicWidth(
                      child: EyebrowHeading(
                        eyebrow: 'Your kitchen',
                        heading: 'My Recipes',
                        gap: 10,
                      ),
                    ),
                    SavoryButton(
                      label: '+ New Recipe',
                      expand: false,
                      height: AppSpacing.tapTarget,
                      onPressed: _newRecipe,
                    ),
                  ],
                ),
                for (final item in content) ...[
                  const SizedBox(height: AppSpacing.section),
                  item,
                ],
                const SizedBox(height: AppSpacing.section),
                const MealDbCredit(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
