/// Client-side rules, copied from the web app so both clients behave the same.
class AppLimits {
  const AppLimits._();

  /// web/src/pages/AuthPage.tsx, RegisterForm.
  static final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// web/src/pages/AuthPage.tsx: at least 8 characters, a number and a symbol.
  /// (The API itself only requires 8 characters; the web app asks for more.)
  static final passwordPattern = RegExp(r'^(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  /// web/src/pages/RecipesPage.tsx, PAGE_SIZE.
  static const pageSize = 12;

  /// Contract: search is called as the user types, with a 250 ms debounce (once it exists).
  static const searchDebounce = Duration(milliseconds: 250);
  static const searchMaxChars = 200;
}
