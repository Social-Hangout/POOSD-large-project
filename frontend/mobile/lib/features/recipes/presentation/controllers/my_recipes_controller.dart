import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_limits.dart';
import '../../../kitchen/presentation/controllers/kitchen_controller.dart';
import '../../data/recipe_providers.dart';
import '../../domain/paginated.dart';
import '../../domain/recipe.dart';
import 'recipe_list_controller.dart';

/// The page My Recipes shows. Behaviour: web/src/pages/MyRecipesPage.tsx (`page` state).
class MyRecipesPageController extends Notifier<int> {
  @override
  int build() => 1;

  void goTo(int page) {
    if (page < 1 || page == state) return;
    state = page;
  }

  /// Back to the first page, e.g. after publishing a new recipe (it lists newest first).
  void reset() => state = 1;
}

final myRecipesPageNumberProvider = NotifierProvider<MyRecipesPageController, int>(
  MyRecipesPageController.new,
);

/// The logged-in user's recipes: GET /api/recipes?page&limit=12&mine=true, as the web
/// (`getRecipes(page, PAGE_SIZE, true)`). Loading, error and empty come from this one
/// AsyncValue.
final myRecipesPageProvider =
    FutureProvider.autoDispose<Paginated<RecipeListEntry>>((ref) {
      final page = ref.watch(myRecipesPageNumberProvider);
      return ref
          .watch(recipeRepositoryProvider)
          .listRecipes(page: page, limit: AppLimits.pageSize, mine: true);
    });

/// After a create, edit or delete, every list that could show the recipe reloads:
/// My Recipes, Explore, My kitchen's matches and any open recipe. The web gets the same
/// effect by fetching again on each page visit.
void refreshRecipeLists(WidgetRef ref) {
  ref.invalidate(myRecipesPageProvider);
  ref.invalidate(recipeListPageProvider);
  ref.invalidate(kitchenResultsProvider);
  ref.invalidate(recipeByIdProvider);
}
