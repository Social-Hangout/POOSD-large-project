import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/recipe_repository.dart';
import 'api_recipe_repository.dart';
import 'sample_recipe_repository.dart';

/// The only place that decides between sample data and API2's routes.
/// Switching to the real routes is a build flag; no screen or widget changes.
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  if (AppConfig.useSampleRecipes) return SampleRecipeRepository();
  return ApiRecipeRepository(ref.watch(dioProvider));
});
