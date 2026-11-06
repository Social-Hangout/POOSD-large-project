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
  static const saved = '/saved';
  static const account = '/account';

  static String recipe(String id) => '/recipes/$id';
  static String checkEmailFor(String email) =>
      Uri(path: checkEmail, queryParameters: {'email': email}).toString();

  /// Reachable without logging in.
  static const public = {login, register, checkEmail, forgotPassword};
}
