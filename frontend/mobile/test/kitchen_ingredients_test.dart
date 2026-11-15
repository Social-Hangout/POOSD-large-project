import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/kitchen/domain/kitchen_ingredients.dart';

void main() {
  const empty = KitchenIngredients();

  test('adds an ingredient, trimmed, and builds the search query', () {
    final r = empty.add('  Chicken ');
    expect(r.error, isNull);
    expect(r.ingredients.items, ['Chicken']);
    expect(r.ingredients.add('Rice').ingredients.query, 'Chicken,Rice');
  });

  test('commas add several at once and blanks are skipped', () {
    final r = empty.add('chicken, rice,, spinach ,');
    expect(r.ingredients.items, ['chicken', 'rice', 'spinach']);
    expect(r.error, isNull);
  });

  test('extra spaces inside a name collapse to one', () {
    expect(empty.add('green   onion').ingredients.items, ['green onion']);
  });

  test('a duplicate, in any case, is not added twice', () {
    final list = empty.add('Chicken').ingredients;
    final r = list.add('chicken');
    expect(r.ingredients.items, ['Chicken']);
    expect(r.error, 'Chicken is already on your list.');
  });

  test('stops at 10 ingredients, the most the API searches', () {
    final ten = empty.add(List.generate(10, (i) => 'item$i').join(','));
    expect(ten.ingredients.items, hasLength(10));
    final r = ten.ingredients.add('one more');
    expect(r.ingredients.items, hasLength(10));
    expect(r.error, 'You can search with up to 10 ingredients.');
  });

  test('an ingredient over 50 characters is refused', () {
    final r = empty.add('x' * 51);
    expect(r.ingredients.isEmpty, isTrue);
    expect(r.error, 'Use 50 characters or fewer for each ingredient.');
    expect(empty.add('x' * 50).error, isNull);
  });

  test('the query never goes over the API 200-character limit', () {
    var list = empty;
    String? error;
    for (var i = 0; i < 10; i++) {
      final r = list.add('${'x' * 45}$i');
      list = r.ingredients;
      error ??= r.error;
    }
    expect(list.query.length, lessThanOrEqualTo(200));
    expect(
      error,
      'Your list is too long to search. Remove an ingredient first.',
    );
  });

  test('the ones that fit are kept when a later one is refused', () {
    final list = empty.add('Chicken').ingredients;
    final r = list.add('rice, chicken, spinach');
    expect(r.ingredients.items, ['Chicken', 'rice', 'spinach']);
    expect(r.error, 'Chicken is already on your list.');
  });

  test('remove ignores case', () {
    final list = empty.add('Chicken, Rice').ingredients;
    expect(list.remove('chicken').items, ['Rice']);
  });
}
