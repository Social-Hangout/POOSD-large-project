import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_limits.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/mealdb_credit.dart';
import '../../domain/recipe.dart';
import '../controllers/recipe_list_controller.dart';
import '../widgets/featured_recipe_card.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_card_skeleton.dart';
import '../widgets/recipe_search_field.dart';
import '../widgets/recipe_state_card.dart';

/// Recipe list. Layout: Figma 08 Explore recipes, 13 (loading) and 14 (empty).
/// Behaviour: the web's RecipesPage (web/src/pages/RecipesPage.tsx):
/// - GET /api/recipes, 12 per page, newest first;
/// - on page 1 the first recipe is also shown as the featured recipe;
/// - error: the API's message (or "Could not load recipes.") with "Try again";
/// - empty: "No recipes yet";
/// - search is visible but disabled until GET /api/recipes/search exists.
class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(recipeListQueryProvider).search,
  );
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(AppLimits.searchDebounce, () {
      ref.read(recipeListQueryProvider.notifier).setSearch(text);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    ref.read(recipeListQueryProvider.notifier).clearSearch();
  }

  void _goToPage(int page) {
    ref.read(recipeListQueryProvider.notifier).goToPage(page);
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _open(Recipe recipe) =>
      context.go(AppRoutes.recipe(recipe.id), extra: recipe);

  void _retry() => ref.invalidate(recipeListPageProvider);

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(recipeListQueryProvider);
    final pageAsync = ref.watch(recipeListPageProvider);

    final List<Widget> results = pageAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => [for (var i = 0; i < 3; i++) const RecipeCardSkeleton()],
      error: (error, _) => [
        RecipeStateCard(
          heading: error is ApiException
              ? error.message
              : 'Could not load recipes.',
          actionLabel: 'Try again',
          onAction: _retry,
        ),
      ],
      data: (page) {
        if (page.isEmpty) {
          return [
            query.isSearching
                ? RecipeStateCard(
                    heading: 'No matches just yet.',
                    message: 'Try different ingredients, separated by commas.',
                    actionLabel: 'Clear search',
                    onAction: _clearSearch,
                  )
                : const RecipeStateCard(heading: 'No recipes yet'),
          ];
        }
        final featured = page.page == 1 && !query.isSearching
            ? page.items.first.recipe
            : null;
        return [
          if (featured != null)
            FeaturedRecipeCard(recipe: featured, onOpen: () => _open(featured)),
          for (final entry in page.items)
            RecipeCard(entry: entry, onOpen: () => _open(entry.recipe)),
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
            onRefresh: () => ref.refresh(recipeListPageProvider.future),
            child: ListView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenX,
                AppSpacing.screenTop,
                AppSpacing.screenX,
                AppSpacing.screenBottom,
              ),
              children: [
                RecipeSearchField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  enabled: AppConfig.recipeSearchAvailable,
                  hint: AppConfig.recipeSearchAvailable
                      ? 'Search by ingredient'
                      : 'Search by ingredient (coming soon)',
                ),
                const SizedBox(height: AppSpacing.section),
                const EyebrowHeading(
                  eyebrow: 'From our community',
                  heading: 'Explore recipes',
                  gap: 10,
                ),
                for (final item in results) ...[
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
