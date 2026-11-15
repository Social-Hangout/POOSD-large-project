import 'recipe.dart';

/// The contract's recipe limits (docs/api-contract.md, "Limits and validation"), the same
/// numbers as web/src/pages/RecipeFormPage.tsx and api/routes/recipes.js.
class RecipeLimits {
  const RecipeLimits._();

  static const maxIngredients = 10;
  static const maxSteps = 8;
  static const title = 100;
  static const ingredientName = 50;
  static const ingredientAmount = 50;
  static const step = 500;
}

/// What create and edit send (contract 12. POST /api/recipes, 13. PUT /api/recipes/:id).
/// The web calls this RecipeInput.
class RecipeDraft {
  const RecipeDraft({
    required this.title,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final List<Ingredient> ingredients;
  final List<String> steps;

  /// The body the web sends: every field trimmed (web RecipeFormPage `submit`).
  RecipeDraft trimmed() => RecipeDraft(
    title: title.trim(),
    ingredients: [
      for (final item in ingredients)
        Ingredient(name: item.name.trim(), amount: item.amount.trim()),
    ],
    steps: [for (final step in steps) step.trim()],
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'ingredients': [
      for (final item in ingredients)
        {'name': item.name, 'amount': item.amount},
    ],
    'steps': steps,
  };

  /// Line-for-line port of `validate` in web/src/pages/RecipeFormPage.tsx: the first
  /// problem, in the server's own words, or null when the form can be sent.
  String? validate() {
    final t = title.trim();
    if (t.isEmpty || t.length > RecipeLimits.title) {
      return 'Title must be 1 to 100 characters';
    }
    if (ingredients.isEmpty || ingredients.length > RecipeLimits.maxIngredients) {
      return 'A recipe needs 1 to 10 ingredients';
    }
    if (ingredients.any((item) {
      final name = item.name.trim();
      return name.isEmpty || name.length > RecipeLimits.ingredientName;
    })) {
      return 'Ingredient names must be 1 to 50 characters';
    }
    if (steps.isEmpty || steps.length > RecipeLimits.maxSteps) {
      return 'A recipe needs 1 to 8 steps';
    }
    if (steps.any((step) {
      final s = step.trim();
      return s.isEmpty || s.length > RecipeLimits.step;
    })) {
      return 'Each step must be 1 to 500 characters';
    }
    return null;
  }
}
