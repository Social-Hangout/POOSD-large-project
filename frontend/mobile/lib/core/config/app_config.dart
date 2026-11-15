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

  /// The one login the offline sample account accepts (USE_SAMPLE_AUTH=true only).
  /// Deliberately no defaults: credentials are never written into app code. With either
  /// left empty, every sample login fails. For the dev test account:
  ///   --dart-define=SAMPLE_LOGIN_EMAIL=test --dart-define=SAMPLE_LOGIN_PASSWORD=test
  /// Against the real API these are ignored; the API checks the password (see README).
  static const sampleLoginEmail = String.fromEnvironment('SAMPLE_LOGIN_EMAIL');
  static const sampleLoginPassword = String.fromEnvironment(
    'SAMPLE_LOGIN_PASSWORD',
  );

  /// Recipe routes are live (api/routes/recipes.js: list, ingredient search, view one,
  /// create, edit, delete). true = offline sample recipes (also needs USE_SAMPLE_AUTH=true
  /// to work with no network).
  static const useSampleRecipes = bool.fromEnvironment(
    'USE_SAMPLE_RECIPES',
    defaultValue: false,
  );

  static const requestTimeout = Duration(seconds: 15);
}
