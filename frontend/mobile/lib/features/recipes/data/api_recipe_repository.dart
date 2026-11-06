import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/paginated.dart';
import '../domain/recipe.dart';
import '../domain/recipe_repository.dart';

/// Talks to API2's recipe routes once they are live. Request and response shapes come
/// straight from docs/api-contract.md; check them against the deployed routes before
/// switching USE_SAMPLE_RECIPES off.
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
  }) => _call(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.recipes,
      queryParameters: {'page': page, 'limit': limit},
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
}
