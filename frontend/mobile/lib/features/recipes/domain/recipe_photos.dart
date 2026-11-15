/// Recipes have no image field, so, like the web app, each recipe gets one of six food
/// photos, picked from its id the same way every time. This is a line-for-line port of
/// `imageFor` in web/src/components/RecipeCard.tsx, with the same photos in the same order
/// (web/public/assets/3ecaf, 412f6, 1df21, da300, 31edd, 3751d), so a recipe shows the
/// same photo in both apps.
const recipePhotos = [
  'assets/images/recipes/recipe_photo_1.png',
  'assets/images/recipes/recipe_photo_2.png',
  'assets/images/recipes/recipe_photo_3.png',
  'assets/images/recipes/recipe_photo_4.png',
  'assets/images/recipes/recipe_photo_5.png',
  'assets/images/recipes/recipe_photo_6.png',
];

String recipePhotoFor(String id) {
  var hash = 0;
  // JS `for (const char of id)` walks code points; `char.charCodeAt(0)` is the first
  // UTF-16 unit of each. `>>> 0` keeps it an unsigned 32-bit number.
  for (final rune in id.runes) {
    final firstUnit = String.fromCharCode(rune).codeUnitAt(0);
    hash = (hash * 31 + firstUnit) & 0xFFFFFFFF;
  }
  return recipePhotos[hash % recipePhotos.length];
}
