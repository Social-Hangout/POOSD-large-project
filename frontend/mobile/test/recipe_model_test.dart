import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/recipes/domain/paginated.dart';
import 'package:savory_app/features/recipes/domain/recipe.dart';

// JSON in the shape api/routes/recipes.js sends (toPublicRecipe). GET /recipes wraps
// recipes in `recipes`, as the API does (the web's types say `results`; see README).
const _recipeJson = {
  'id': '6721f3aa9b8c7d6e5f403122',
  'title': 'Garlic Butter Pasta',
  'ingredients': [
    {'name': 'pasta', 'amount': '200 g'},
    {'name': 'butter', 'amount': ''},
  ],
  'steps': ['Boil the pasta.', 'Toss with butter.'],
  'author': {'id': '6721f0c2a1b2c3d4e5f60718', 'firstName': 'Ana'},
  'createdAt': '2026-10-26T15:04:14.195Z',
};

void main() {
  test('parses the recipe shape the API sends', () {
    final recipe = Recipe.fromJson(_recipeJson);
    expect(recipe.title, 'Garlic Butter Pasta');
    expect(recipe.ingredients.first.amount, '200 g');
    expect(recipe.ingredients.last.amount, '');
    expect(recipe.steps, hasLength(2));
    expect(recipe.author!.firstName, 'Ana');
    expect(recipe.createdAt.isUtc, isTrue);
  });

  test(
    'author is null when the account was deleted (api/routes/recipes.js)',
    () {
      final recipe = Recipe.fromJson({..._recipeJson, 'author': null});
      expect(recipe.author, isNull);
    },
  );

  test('parses the list envelope from GET /recipes', () {
    final page = Paginated.fromJson(
      {
        'recipes': [_recipeJson],
        'page': 1,
        'totalPages': 2,
      },
      itemsKey: 'recipes',
      fromJson: (json) => RecipeListEntry(Recipe.fromJson(json)),
    );
    expect(page.items, hasLength(1));
    expect(page.hasNext, isTrue);
    expect(page.items.first.match, isNull);
  });

  test('parses search results with matchedTerms and totalTerms', () {
    final page = Paginated.fromJson(
      {
        'results': [
          {..._recipeJson, 'matchedTerms': 1, 'totalTerms': 2},
        ],
        'page': 1,
        'totalPages': 1,
      },
      itemsKey: 'results',
      fromJson: RecipeListEntry.fromSearchJson,
    );
    expect(page.items.first.match!.matchedTerms, 1);
    expect(page.items.first.match!.totalTerms, 2);
  });

  test('empty list envelope', () {
    final page = Paginated.fromJson(
      {'recipes': <dynamic>[], 'page': 1, 'totalPages': 0},
      itemsKey: 'recipes',
      fromJson: (json) => RecipeListEntry(Recipe.fromJson(json)),
    );
    expect(page.isEmpty, isTrue);
    expect(page.hasNext, isFalse);
  });
}
