import 'dart:math' as math;

import '../../../core/network/api_exception.dart';
import '../domain/paginated.dart';
import '../domain/recipe.dart';
import '../domain/recipe_draft.dart';
import '../domain/recipe_repository.dart';
import 'sample_recipes.dart';

/// In-memory stand-in for API2's routes (USE_SAMPLE_RECIPES=true). It follows the
/// contract's behaviour, including the search rule, so switching to the real routes
/// should not change what the screens see.
///
/// Create, edit and delete change an in-memory copy of the samples for the session, so My
/// Recipes and the form can be tried offline. [currentAuthor] is the logged-in user (the
/// API reads it from the token); with none, writes answer 401 like the API.
class SampleRecipeRepository implements RecipeRepository {
  SampleRecipeRepository({
    List<Recipe>? recipes,
    Author? Function()? currentAuthor,
  }) : _recipes = [...(recipes ?? sampleRecipes)],
       _currentAuthor = currentAuthor ?? (() => null);

  final List<Recipe> _recipes;
  final Author? Function() _currentAuthor;
  var _nextId = 0;
  static const _delay = Duration(milliseconds: 500);

  @override
  Future<Paginated<RecipeListEntry>> listRecipes({
    required int page,
    required int limit,
    bool mine = false,
  }) async {
    await Future<void>.delayed(_delay);
    final me = mine ? _currentAuthor()?.id : null;
    final newestFirst =
        _recipes.where((r) => !mine || r.author?.id == me).toList()
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

  @override
  Future<Recipe> createRecipe(RecipeDraft draft) async {
    await Future<void>.delayed(_delay);
    final author = _requireAuthor();
    final clean = _parse(draft);
    final recipe = Recipe(
      id: _newId(),
      title: clean.title,
      ingredients: clean.ingredients,
      steps: clean.steps,
      author: author,
      createdAt: DateTime.now().toUtc(),
    );
    _recipes.add(recipe);
    return recipe;
  }

  @override
  Future<Recipe> updateRecipe(String id, RecipeDraft draft) async {
    await Future<void>.delayed(_delay);
    final index = _ownIndex(id);
    final clean = _parse(draft);
    final old = _recipes[index];
    final updated = Recipe(
      id: old.id,
      title: clean.title,
      ingredients: clean.ingredients,
      steps: clean.steps,
      author: old.author,
      createdAt: old.createdAt,
    );
    _recipes[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await Future<void>.delayed(_delay);
    _recipes.removeAt(_ownIndex(id));
  }

  Author _requireAuthor() {
    final author = _currentAuthor();
    if (author == null) {
      throw const ApiException('Invalid or missing token', statusCode: 401);
    }
    return author;
  }

  /// The API's 404 then 403 checks for edit and delete.
  int _ownIndex(String id) {
    final author = _requireAuthor();
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw const ApiException('Recipe not found', statusCode: 404);
    }
    if (_recipes[index].author?.id != author.id) {
      throw const ApiException('Not your recipe', statusCode: 403);
    }
    return index;
  }

  /// The API's checks and cleaning (parseRecipe): 400 with its message, names lowercased.
  RecipeDraft _parse(RecipeDraft draft) {
    final trimmed = draft.trimmed();
    final problem = trimmed.validate() ??
        (trimmed.ingredients.any(
              (i) => i.amount.length > RecipeLimits.ingredientAmount,
            )
            ? 'Ingredient amounts can be at most 50 characters'
            : null);
    if (problem != null) throw ApiException(problem, statusCode: 400);
    return RecipeDraft(
      title: trimmed.title,
      ingredients: [
        for (final i in trimmed.ingredients)
          Ingredient(name: i.name.toLowerCase(), amount: i.amount),
      ],
      steps: trimmed.steps,
    );
  }

  /// A 24-character hex id, the shape of a MongoDB ObjectId.
  String _newId() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _nextId++;
    return seconds.toRadixString(16).padLeft(8, '0') +
        _nextId.toRadixString(16).padLeft(16, '0');
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
