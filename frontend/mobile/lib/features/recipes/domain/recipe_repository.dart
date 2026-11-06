import 'paginated.dart';
import 'recipe.dart';

/// Recipe routes the app reads (contract routes 9, 10 and 11).
/// Every method throws ApiException with a message that can be shown as is.
abstract class RecipeRepository {
  /// 9. GET /recipes, newest first.
  Future<Paginated<RecipeListEntry>> listRecipes({
    required int page,
    required int limit,
  });

  /// 10. GET /recipes/search?q=... Results arrive best match first; never re-sort them.
  Future<Paginated<RecipeListEntry>> searchRecipes({
    required String query,
    required int page,
    required int limit,
  });

  /// 11. GET /recipes/:id. 404 for unknown or malformed ids.
  Future<Recipe> getRecipe(String id);
}
