// Logic tests for UI helpers. Full-app widget tests are left out because the theme
// loads Google Fonts over the network, which flutter test blocks.
import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/authentication/domain/user.dart';
import 'package:savory_app/features/recipes/domain/recipe.dart';
import 'package:savory_app/features/recipes/presentation/widgets/pagination_bar.dart';
import 'package:savory_app/features/recipes/presentation/widgets/recipe_card.dart';

Recipe _recipe(int ingredientCount) => Recipe(
  id: '1',
  title: 't',
  ingredients: [
    for (var i = 1; i <= ingredientCount; i++) Ingredient(name: 'i$i'),
  ],
  steps: const ['s'],
  author: null,
  createdAt: DateTime.utc(2026),
);

void main() {
  test('pagination shows first, last and neighbours with gaps', () {
    expect(PaginationBar.slots(1, 3), [1, 2, 3]);
    expect(PaginationBar.slots(1, 8), [1, 2, null, 8]);
    expect(PaginationBar.slots(5, 8), [1, null, 4, 5, 6, null, 8]);
  });

  test('ingredient preview matches the web card', () {
    expect(RecipeCard.ingredientPreview(_recipe(2)), 'i1, i2');
    expect(RecipeCard.ingredientPreview(_recipe(3)), 'i1, i2, i3');
    expect(RecipeCard.ingredientPreview(_recipe(5)), 'i1, i2, i3 +2 more');
  });

  test('user survives a save and restore (session storage)', () {
    const user = User(
      id: '1',
      firstName: 'Ana',
      lastName: 'Lopez',
      email: 'a@b.co',
    );
    final back = User.fromJson(user.toJson());
    expect(back.email, user.email);
    expect(back.initials, 'AL');
  });
}
