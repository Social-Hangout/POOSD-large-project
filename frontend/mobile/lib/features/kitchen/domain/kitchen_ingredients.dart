/// The ingredients someone has added on My kitchen. They are searched with
/// GET /api/recipes/search?q=<ingredients joined by commas> (contract route 10), so the
/// list stays inside that route's limits and never builds a request it would reject.
class KitchenIngredients {
  const KitchenIngredients([this.items = const []]);

  final List<String> items;

  /// The API searches only the first 10 terms.
  static const maxItems = 10;

  /// The longest ingredient name a recipe can have (api/routes/recipes.js LIMITS).
  static const maxLength = 50;

  /// The API rejects a longer `q` with 400.
  static const maxQueryLength = 200;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// The `q` value for the search request.
  String get query => items.join(',');

  bool contains(String item) =>
      items.any((i) => i.toLowerCase() == item.trim().toLowerCase());

  /// Adds what was typed. Commas add several ingredients at once. Ingredients that fit
  /// are added even when a later one doesn't; [error] explains the first one that didn't.
  ({KitchenIngredients ingredients, String? error}) add(String text) {
    final next = [...items];
    String? error;

    for (final raw in text.split(',')) {
      final item = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (item.isEmpty) continue;

      String? problem;
      if (item.length > maxLength) {
        problem = 'Use $maxLength characters or fewer for each ingredient.';
      } else if (next.any((i) => i.toLowerCase() == item.toLowerCase())) {
        problem = '${_capitalized(item)} is already on your list.';
      } else if (next.length >= maxItems) {
        problem = 'You can search with up to $maxItems ingredients.';
      } else if ([...next, item].join(',').length > maxQueryLength) {
        problem =
            'Your list is too long to search. Remove an ingredient first.';
      }

      if (problem == null) {
        next.add(item);
      } else {
        error ??= problem;
      }
    }

    return (ingredients: KitchenIngredients(next), error: error);
  }

  KitchenIngredients remove(String item) => KitchenIngredients(
    items.where((i) => i.toLowerCase() != item.toLowerCase()).toList(),
  );

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
