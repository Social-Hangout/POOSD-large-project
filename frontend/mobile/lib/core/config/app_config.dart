/// Build-time settings, passed with --dart-define. Nothing secret lives here.
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000/api
class AppConfig {
  const AppConfig._();

  /// The API base path (docs/api-contract.md, "Conventions"). The web app calls the same
  /// /api routes through nginx. Local API from a phone: http://<LAN IP>:5000/api
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://contactshub.site/api',
  );

  /// Account routes are live (api/routes/auth.js). true = offline sample account.
  static const useSampleAuth = bool.fromEnvironment(
    'USE_SAMPLE_AUTH',
    defaultValue: false,
  );

  /// Recipe routes are live (api/routes/recipes.js: list, view one, create, edit, delete),
  /// and the web app uses them. true = offline sample recipes (also needs USE_SAMPLE_AUTH=true
  /// to work with no network).
  static const useSampleRecipes = bool.fromEnvironment(
    'USE_SAMPLE_RECIPES',
    defaultValue: false,
  );

  /// GET /api/recipes/search is not built yet; the web app shows its search box disabled
  /// ("coming soon", Week 3). Flip this when the route ships.
  static const recipeSearchAvailable = false;

  static const requestTimeout = Duration(seconds: 15);
}
