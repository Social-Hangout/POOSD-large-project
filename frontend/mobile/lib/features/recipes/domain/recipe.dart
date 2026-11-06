/// A recipe as api/routes/recipes.js sends it (toPublicRecipe) and web/src/types/index.ts
/// declares it.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<Ingredient> ingredients;
  final List<String> steps;

  /// null when the author's account was deleted (the API sends `"author": null`).
  final Author? author;
  final DateTime createdAt;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    title: json['title'] as String,
    ingredients: (json['ingredients'] as List<dynamic>)
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    steps: (json['steps'] as List<dynamic>).cast<String>().toList(
      growable: false,
    ),
    author: json['author'] == null
        ? null
        : Author.fromJson(json['author'] as Map<String, dynamic>),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class Ingredient {
  const Ingredient({required this.name, this.amount = ''});

  /// Stored lowercase by the API.
  final String name;

  /// Plain text ("2 cups"); "" when not given.
  final String amount;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    name: json['name'] as String,
    amount: (json['amount'] as String?) ?? '',
  );
}

/// The `author` shape: a short version of a user.
class Author {
  const Author({required this.id, required this.firstName});

  final String id;
  final String firstName;

  factory Author.fromJson(Map<String, dynamic> json) =>
      Author(id: json['id'] as String, firstName: json['firstName'] as String);
}

/// From search results only (contract route 10, not built yet): "Matches 2 of 2".
class RecipeMatch {
  const RecipeMatch({required this.matchedTerms, required this.totalTerms});

  final int matchedTerms;
  final int totalTerms;
}

/// One row in the recipe list: a recipe, plus match counts when it came from search.
class RecipeListEntry {
  const RecipeListEntry(this.recipe, {this.match});

  final Recipe recipe;
  final RecipeMatch? match;

  factory RecipeListEntry.fromSearchJson(Map<String, dynamic> json) =>
      RecipeListEntry(
        Recipe.fromJson(json),
        match: RecipeMatch(
          matchedTerms: json['matchedTerms'] as int,
          totalTerms: json['totalTerms'] as int,
        ),
      );
}
