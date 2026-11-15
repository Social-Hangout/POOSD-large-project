import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_limits.dart';
import '../../../recipes/data/recipe_providers.dart';
import '../../../recipes/domain/paginated.dart';
import '../../../recipes/domain/recipe.dart';
import '../../domain/kitchen_ingredients.dart';

/// What My kitchen is showing: the ingredients added so far and the results page.
class KitchenState {
  const KitchenState({
    this.ingredients = const KitchenIngredients(),
    this.page = 1,
  });

  final KitchenIngredients ingredients;
  final int page;
}

/// Kept for the whole session, so the list survives switching tabs.
class KitchenController extends Notifier<KitchenState> {
  @override
  KitchenState build() => const KitchenState();

  /// Adds what was typed (commas add several) and returns a message for anything that
  /// couldn't be added, or null. A changed list starts again at page 1.
  String? add(String text) {
    final result = state.ingredients.add(text);
    if (result.ingredients.items.length != state.ingredients.items.length) {
      state = KitchenState(ingredients: result.ingredients);
    }
    return result.error;
  }

  void remove(String item) =>
      state = KitchenState(ingredients: state.ingredients.remove(item));

  void clear() => state = const KitchenState();

  void goToPage(int page) {
    if (page < 1 || page == state.page) return;
    state = KitchenState(ingredients: state.ingredients, page: page);
  }
}

final kitchenControllerProvider =
    NotifierProvider<KitchenController, KitchenState>(KitchenController.new);

/// Recipes for the current ingredients, best match first, straight from
/// GET /api/recipes/search. Null while the list is empty: no request is sent then.
final kitchenResultsProvider =
    FutureProvider.autoDispose<Paginated<RecipeListEntry>?>((ref) async {
      final state = ref.watch(kitchenControllerProvider);
      if (state.ingredients.isEmpty) return null;
      return ref
          .watch(recipeRepositoryProvider)
          .searchRecipes(
            query: state.ingredients.query,
            page: state.page,
            limit: AppLimits.pageSize,
          );
    });
