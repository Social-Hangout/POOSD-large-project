import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_limits.dart';
import '../../data/recipe_providers.dart';
import '../../domain/paginated.dart';
import '../../domain/recipe.dart';

/// What the recipe list is showing: a page of all recipes, or a page of search results.
class RecipeListQuery {
  const RecipeListQuery({this.search = '', this.page = 1});

  final String search;
  final int page;

  /// True when the search text has at least one term after splitting on commas,
  /// so ", ," never reaches the server (which would answer 400).
  bool get isSearching => search.split(',').any((t) => t.trim().isNotEmpty);

  RecipeListQuery copyWith({String? search, int? page}) =>
      RecipeListQuery(search: search ?? this.search, page: page ?? this.page);
}

class RecipeListQueryController extends Notifier<RecipeListQuery> {
  @override
  RecipeListQuery build() => const RecipeListQuery();

  /// New search text always starts again at page 1.
  void setSearch(String text) {
    final trimmed = text.length > AppLimits.searchMaxChars
        ? text.substring(0, AppLimits.searchMaxChars)
        : text;
    if (trimmed == state.search) return;
    state = RecipeListQuery(search: trimmed);
  }

  void clearSearch() => state = const RecipeListQuery();

  void goToPage(int page) {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page);
  }
}

final recipeListQueryProvider =
    NotifierProvider<RecipeListQueryController, RecipeListQuery>(
      RecipeListQueryController.new,
    );

/// The current page of the recipe list. Loading, error and empty states all come
/// from this one AsyncValue.
final recipeListPageProvider =
    FutureProvider.autoDispose<Paginated<RecipeListEntry>>((ref) {
      final query = ref.watch(recipeListQueryProvider);
      final repository = ref.watch(recipeRepositoryProvider);

      if (query.isSearching) {
        return repository.searchRecipes(
          query: query.search,
          page: query.page,
          limit: AppLimits.pageSize,
        );
      }
      return repository.listRecipes(
        page: query.page,
        limit: AppLimits.pageSize,
      );
    });

/// One recipe by id, for when the detail screen is opened without a recipe passed in
/// (a deep link, or the app restoring its route).
final recipeByIdProvider = FutureProvider.autoDispose.family<Recipe, String>((
  ref,
  id,
) {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});
