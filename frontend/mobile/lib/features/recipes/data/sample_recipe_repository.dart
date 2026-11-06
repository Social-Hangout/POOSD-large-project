import 'dart:math' as math;

import '../../../core/network/api_exception.dart';
import '../domain/paginated.dart';
import '../domain/recipe.dart';
import '../domain/recipe_repository.dart';
import 'sample_recipes.dart';

/// In-memory stand-in for API2's routes (USE_SAMPLE_RECIPES=true). It follows the
/// contract's behaviour, including the search rule, so switching to the real routes
/// should not change what the screens see.
class SampleRecipeRepository implements RecipeRepository {
  SampleRecipeRepository({List<Recipe>? recipes})
    : _recipes = recipes ?? sampleRecipes;

  final List<Recipe> _recipes;
  static const _delay = Duration(milliseconds: 500);

  @override
  Future<Paginated<RecipeListEntry>> listRecipes({
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(_delay);
    final newestFirst = [..._recipes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paginate(
      newestFirst.map(RecipeListEntry.new).toList(),
      page,
      limit,
    );
  }

  @override
  Future<Paginated<RecipeListEntry>> searchRecipes({
    required String query,
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(_delay);
    final terms = searchTerms(query);
    if (terms.isEmpty) {
      throw const ApiException('Search text is required', statusCode: 400);
    }

    final results = <RecipeListEntry>[];
    for (final recipe in _recipes) {
      final haystack = [
        recipe.title.toLowerCase(),
        ...recipe.ingredients.map((i) => i.name),
      ];
      final matched = terms
          .where((t) => haystack.any((h) => h.contains(t)))
          .length;
      if (matched > 0) {
        results.add(
          RecipeListEntry(
            recipe,
            match: RecipeMatch(matchedTerms: matched, totalTerms: terms.length),
          ),
        );
      }
    }
    results.sort((a, b) {
      final byMatch = b.match!.matchedTerms.compareTo(a.match!.matchedTerms);
      return byMatch != 0 ? byMatch : a.recipe.title.compareTo(b.recipe.title);
    });
    return _paginate(results, page, limit);
  }

  @override
  Future<Recipe> getRecipe(String id) async {
    await Future<void>.delayed(_delay);
    for (final recipe in _recipes) {
      if (recipe.id == id) return recipe;
    }
    throw const ApiException('Recipe not found', statusCode: 404);
  }

  /// Contract "Search rule" steps 1 and 2: split on commas, trim, lowercase, drop empty
  /// pieces, keep the first 10, and strip one trailing "es" or "s" from terms over 3 letters.
  static List<String> searchTerms(String query) {
    return query
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .take(10)
        .map((t) {
          if (t.length <= 3) return t;
          if (t.endsWith('es')) return t.substring(0, t.length - 2);
          if (t.endsWith('s')) return t.substring(0, t.length - 1);
          return t;
        })
        .toList();
  }

  Paginated<RecipeListEntry> _paginate(
    List<RecipeListEntry> all,
    int page,
    int limit,
  ) {
    final totalPages = (all.length / limit).ceil();
    final start = (page - 1) * limit;
    final items = start >= all.length
        ? const <RecipeListEntry>[]
        : all.sublist(start, math.min(start + limit, all.length));
    return Paginated(items: items, page: page, totalPages: totalPages);
  }
}
