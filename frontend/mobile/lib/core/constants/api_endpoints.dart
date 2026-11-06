/// Every route path the app calls (docs/api-contract.md, api/routes/). Same routes as web/src/api/.
/// Paths are relative to AppConfig.apiBaseUrl, which already ends in /api.
class ApiEndpoints {
  const ApiEndpoints._();

  // Accounts (API1)
  static const register = '/auth/register';
  static const resendVerification = '/auth/resend-verification';
  static const forgotPassword = '/auth/forgot-password';
  static const login = '/auth/login';

  // Recipes (API2)
  static const recipes = '/recipes';
  static const recipeSearch = '/recipes/search';
  static String recipe(String id) => '/recipes/$id';
}
