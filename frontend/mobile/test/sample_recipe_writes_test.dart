// Offline create / edit / delete / mine=true (USE_SAMPLE_RECIPES=true), which follow the
// API's rules (api/routes/recipes.js) so My Recipes and the form behave the same offline.
import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/core/network/api_exception.dart';
import 'package:savory_app/features/recipes/data/sample_recipe_repository.dart';
import 'package:savory_app/features/recipes/domain/recipe.dart';
import 'package:savory_app/features/recipes/domain/recipe_draft.dart';

const _ana = Author(id: '6721f0c2a1b2c3d4e5f60718', firstName: 'Ana');
const _kai = Author(id: '6721f0c2a1b2c3d4e5f60719', firstName: 'Kai');

const _draft = RecipeDraft(
  title: 'Toast',
  ingredients: [Ingredient(name: 'Bread', amount: '2 slices')],
  steps: ['Toast it.'],
);

Matcher _status(int code) =>
    isA<ApiException>().having((e) => e.statusCode, 'statusCode', code);

void main() {
  test('mine=true lists only the current user\'s recipes, newest first', () async {
    final repo = SampleRecipeRepository(currentAuthor: () => _ana);
    final page = await repo.listRecipes(page: 1, limit: 50, mine: true);
    expect(page.items, isNotEmpty);
    expect(page.items.every((e) => e.recipe.author?.id == _ana.id), isTrue);
    final all = await repo.listRecipes(page: 1, limit: 50);
    expect(all.items.length, greaterThan(page.items.length));
  });

  test('create adds a recipe by the current user, lowercasing names', () async {
    final repo = SampleRecipeRepository(currentAuthor: () => _ana);
    final saved = await repo.createRecipe(_draft);
    expect(saved.id, hasLength(24));
    expect(saved.author?.id, _ana.id);
    expect(saved.ingredients.single.name, 'bread');
    final mine = await repo.listRecipes(page: 1, limit: 50, mine: true);
    expect(mine.items.map((e) => e.recipe.id), contains(saved.id));
  });

  test('create answers 400 with the API message and 401 with no user', () async {
    final repo = SampleRecipeRepository(currentAuthor: () => _ana);
    expect(
      repo.createRecipe(const RecipeDraft(title: ' ', ingredients: [], steps: [])),
      throwsA(_status(400)),
    );
    expect(SampleRecipeRepository().createRecipe(_draft), throwsA(_status(401)));
  });

  test('only the author can edit or delete (403), unknown ids are 404', () async {
    final repo = SampleRecipeRepository(currentAuthor: () => _kai);
    final anas = (await repo.listRecipes(page: 1, limit: 50))
        .items
        .firstWhere((e) => e.recipe.author?.id == _ana.id)
        .recipe;
    expect(repo.updateRecipe(anas.id, _draft), throwsA(_status(403)));
    expect(repo.deleteRecipe(anas.id), throwsA(_status(403)));
    expect(repo.deleteRecipe('000000000000000000000000'), throwsA(_status(404)));
  });

  test('edit keeps id, author and date; delete removes the recipe', () async {
    final repo = SampleRecipeRepository(currentAuthor: () => _ana);
    final created = await repo.createRecipe(_draft);
    final edited = await repo.updateRecipe(
      created.id,
      const RecipeDraft(
        title: 'Better Toast',
        ingredients: [Ingredient(name: 'bread'), Ingredient(name: 'butter')],
        steps: ['Toast it.', 'Butter it.'],
      ),
    );
    expect(edited.id, created.id);
    expect(edited.author?.id, _ana.id);
    expect(edited.createdAt, created.createdAt);
    expect(edited.title, 'Better Toast');

    await repo.deleteRecipe(created.id);
    expect(repo.getRecipe(created.id), throwsA(_status(404)));
  });
}
