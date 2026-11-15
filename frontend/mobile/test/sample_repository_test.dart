import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/core/network/api_exception.dart';
import 'package:savory_app/features/recipes/data/sample_recipe_repository.dart';
import 'package:savory_app/features/recipes/data/sample_recipes.dart';

void main() {
  final repo = SampleRecipeRepository();

  test('search terms follow the contract search rule', () {
    expect(SampleRecipeRepository.searchTerms('Tomatoes, EGGS'), [
      'tomato',
      'egg',
    ]);
    expect(SampleRecipeRepository.searchTerms('chick, rice'), [
      'chick',
      'rice',
    ]);
    expect(SampleRecipeRepository.searchTerms(',  ,'), isEmpty);
    expect(SampleRecipeRepository.searchTerms('gas'), [
      'gas',
    ]); // 3 letters: unchanged
  });

  test('search ranks recipes matching more terms first', () async {
    final page = await repo.searchRecipes(
      query: 'chick, rice',
      page: 1,
      limit: 20,
    );
    final first = page.items.first;
    expect(first.match!.matchedTerms, 2);
    expect(first.match!.totalTerms, 2);
    for (var i = 1; i < page.items.length; i++) {
      expect(
        page.items[i - 1].match!.matchedTerms >=
            page.items[i].match!.matchedTerms,
        isTrue,
      );
    }
  });

  test('blank search is a 400, like the API', () {
    expect(
      repo.searchRecipes(query: ', ,', page: 1, limit: 20),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });

  test('a page past the end is empty, not an error', () async {
    final page = await repo.listRecipes(page: 99, limit: 20);
    expect(page.items, isEmpty);
    expect(page.totalPages, 1);
  });

  test('unknown id is a 404', () {
    expect(
      repo.getRecipe('nope'),
      throwsA(
        isA<ApiException>().having((e) => e.isNotFound, 'isNotFound', true),
      ),
    );
  });

  test('sample data stays inside the contract limits', () {
    for (final r in sampleRecipes) {
      expect(r.title.length, inInclusiveRange(1, 100), reason: r.title);
      expect(r.ingredients.length, inInclusiveRange(1, 10), reason: r.title);
      expect(r.steps.length, inInclusiveRange(1, 8), reason: r.title);
      for (final i in r.ingredients) {
        expect(i.name, i.name.toLowerCase());
        expect(i.name.length, inInclusiveRange(1, 50));
        expect(i.amount.length, lessThanOrEqualTo(50));
      }
      for (final s in r.steps) {
        expect(s.length, inInclusiveRange(1, 500));
      }
    }
  });
}
