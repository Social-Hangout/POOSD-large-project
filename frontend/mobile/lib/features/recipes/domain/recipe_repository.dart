import 'paginated.dart';
import 'recipe.dart';
import 'recipe_draft.dart';

/// Recipe routes the app uses (contract routes 9 to 14), the same set as
/// web/src/api/recipes.ts.
/// Every method throws ApiException with a message that can be shown as is.
abstract class RecipeRepository {
  /// 9. GET /recipes, newest first. [mine] = true sends `mine=true`, which returns only
  /// the logged-in user's recipes (My Recipes).
  Future<Paginated<RecipeListEntry>> listRecipes({
    required int page,
    required int limit,
    bool mine = false,
  });

  /// 10. GET /recipes/search?q=... Results arrive best match first; never re-sort them.
  Future<Paginated<RecipeListEntry>> searchRecipes({
    required String query,
    required int page,
    required int limit,
  });

  /// 11. GET /recipes/:id. 404 for unknown or malformed ids.
  Future<Recipe> getRecipe(String id);

  /// 12. POST /recipes. The author comes from the token. Returns the saved recipe (201).
  Future<Recipe> createRecipe(RecipeDraft draft);

  /// 13. PUT /recipes/:id. Author only: 403 "Not your recipe", 404 "Recipe not found".
  Future<Recipe> updateRecipe(String id, RecipeDraft draft);

  /// 14. DELETE /recipes/:id, with its reviews and comments. Author only (204).
  Future<void> deleteRecipe(String id);
}
