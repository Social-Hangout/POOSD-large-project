// The recipe form's checks, ported from web/src/pages/RecipeFormPage.tsx (`validate`).
import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/recipes/domain/recipe.dart';
import 'package:savory_app/features/recipes/domain/recipe_draft.dart';

RecipeDraft _draft({
  String title = 'Garlic Butter Pasta',
  List<Ingredient>? ingredients,
  List<String>? steps,
}) => RecipeDraft(
  title: title,
  ingredients: ingredients ?? const [Ingredient(name: 'pasta', amount: '200 g')],
  steps: steps ?? const ['Boil the pasta.'],
);

void main() {
  test('a complete form passes', () {
    expect(_draft().validate(), isNull);
  });

  test('title must be 1 to 100 characters after trimming', () {
    expect(_draft(title: '   ').validate(), 'Title must be 1 to 100 characters');
    expect(_draft(title: 'a' * 101).validate(), 'Title must be 1 to 100 characters');
    expect(_draft(title: 'a' * 100).validate(), isNull);
  });

  test('1 to 10 ingredients, each named with 1 to 50 characters', () {
    expect(_draft(ingredients: const []).validate(), 'A recipe needs 1 to 10 ingredients');
    expect(
      _draft(ingredients: List.filled(11, const Ingredient(name: 'egg'))).validate(),
      'A recipe needs 1 to 10 ingredients',
    );
    expect(
      _draft(ingredients: const [Ingredient(name: ' ', amount: '1')]).validate(),
      'Ingredient names must be 1 to 50 characters',
    );
    expect(
      _draft(ingredients: [Ingredient(name: 'x' * 51)]).validate(),
      'Ingredient names must be 1 to 50 characters',
    );
    // The amount is optional.
    expect(_draft(ingredients: const [Ingredient(name: 'salt')]).validate(), isNull);
  });

  test('1 to 8 steps, each 1 to 500 characters', () {
    expect(_draft(steps: const []).validate(), 'A recipe needs 1 to 8 steps');
    expect(_draft(steps: List.filled(9, 'Stir.')).validate(), 'A recipe needs 1 to 8 steps');
    expect(_draft(steps: const ['  ']).validate(), 'Each step must be 1 to 500 characters');
    expect(
      _draft(steps: ['s' * 501]).validate(),
      'Each step must be 1 to 500 characters',
    );
  });

  test('the first problem wins, in the web order', () {
    expect(
      const RecipeDraft(title: '', ingredients: [], steps: []).validate(),
      'Title must be 1 to 100 characters',
    );
  });

  test('trimmed() and toJson() send what the web sends', () {
    final json = _draft(
      title: '  Toast ',
      ingredients: const [Ingredient(name: ' bread ', amount: ' 2 slices ')],
      steps: const [' Toast it. '],
    ).trimmed().toJson();
    expect(json, {
      'title': 'Toast',
      'ingredients': [
        {'name': 'bread', 'amount': '2 slices'},
      ],
      'steps': ['Toast it.'],
    });
  });
}
