import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/paginated.dart';
import '../domain/recipe.dart';
import '../domain/recipe_draft.dart';
import '../domain/recipe_repository.dart';

/// Talks to API2's recipe routes (api/routes/recipes.js). Request and response shapes
/// come straight from docs/api-contract.md, the same calls as web/src/api/recipes.ts.
class ApiRecipeRepository implements RecipeRepository {
  ApiRecipeRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Paginated<RecipeListEntry>> listRecipes({
    required int page,
    required int limit,
    bool mine = false,
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.recipes,
      queryParameters: {
        'page': page,
        'limit': limit,
        // The API accepts only the strings "true" and "false" (400 otherwise).
        if (mine) 'mine': 'true',
      },
    );
    return Paginated.fromJson(
      res.data!,
      itemsKey: 'recipes',
      fromJson: (json) => RecipeListEntry(Recipe.fromJson(json)),
    );
  });

  @override
  Future<Paginated<RecipeListEntry>> searchRecipes({
    required String query,
    required int page,
    required int limit,
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.recipeSearch,
      queryParameters: {'q': query, 'page': page, 'limit': limit},
    );
    return Paginated.fromJson(
      res.data!,
      itemsKey: 'results',
      fromJson: RecipeListEntry.fromSearchJson,
    );
  });

  @override
  Future<Recipe> getRecipe(String id) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.recipe(id));
    return Recipe.fromJson(res.data!);
  });

  @override
  Future<Recipe> createRecipe(RecipeDraft draft) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.recipes,
      data: draft.toJson(),
    );
    return Recipe.fromJson(res.data!);
  });

  @override
  Future<Recipe> updateRecipe(String id, RecipeDraft draft) => _call(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      ApiEndpoints.recipe(id),
      data: draft.toJson(),
    );
    return Recipe.fromJson(res.data!);
  });

  /// 204 with no body.
  @override
  Future<void> deleteRecipe(String id) => _call(() async {
    await _dio.delete<void>(ApiEndpoints.recipe(id));
  });
}
