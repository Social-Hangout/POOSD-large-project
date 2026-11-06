import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/recipes/domain/recipe_photos.dart';

// Expected photo numbers were produced by running the web's own imageFor
// (web/src/components/RecipeCard.tsx) in Node, so both apps pick the same photo.
void main() {
  const expected = {
    '6721f3aa9b8c7d6e5f403101': 2,
    '6721f3aa9b8c7d6e5f403102': 3,
    '6721f3aa9b8c7d6e5f403103': 4,
    '6721f3aa9b8c7d6e5f403122': 5,
    '000000000000000000000000': 1,
    'ffffffffffffffffffffffff': 1,
    'a': 2,
    '': 1,
    '😀x': 2,
  };

  expected.forEach((id, photo) {
    test('"$id" gets photo $photo, like the web', () {
      expect(
        recipePhotoFor(id),
        'assets/images/recipes/recipe_photo_$photo.png',
      );
    });
  });
}
