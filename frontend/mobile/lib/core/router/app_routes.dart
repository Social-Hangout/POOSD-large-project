/// Route paths. Screens navigate with these, never with string literals.
class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const checkEmail = '/check-email';
  static const forgotPassword = '/forgot-password';

  static const kitchen = '/kitchen';
  static const recipes = '/recipes';
  static const account = '/account';

  static const accountSettings = '/account/settings';
  static const accountHelp = '/account/help';
  static const accountPrivacy = '/account/privacy';
  static const accountTerms = '/account/terms';

  static String recipe(String id) => '/recipes/$id';

  /// A recipe opened from My kitchen stays in that tab, so Back returns to the list.
  static String kitchenRecipe(String id) => '/kitchen/$id';
  static String checkEmailFor(String email) =>
      Uri(path: checkEmail, queryParameters: {'email': email}).toString();

  /// Reachable without logging in.
  static const public = {login, register, checkEmail, forgotPassword};
}
