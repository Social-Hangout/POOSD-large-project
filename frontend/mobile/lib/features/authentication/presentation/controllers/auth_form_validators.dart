import '../../../../core/constants/app_limits.dart';

/// Registration rules and messages, copied from web/src/pages/AuthPage.tsx (RegisterForm)
/// so the two apps accept and reject exactly the same input. Login has no client-side
/// checks, as on the web: the API's own message is shown instead.
class AuthFormValidators {
  const AuthFormValidators._();

  static String? firstName(String value) =>
      value.trim().isEmpty ? 'Enter your first name.' : null;

  static String? lastName(String value) =>
      value.trim().isEmpty ? 'Enter your last name.' : null;

  static String? email(String value) => AppLimits.emailPattern.hasMatch(value)
      ? null
      : 'Enter a valid email, e.g. kai@email.com.';

  static String? password(String value) =>
      AppLimits.passwordPattern.hasMatch(value)
      ? null
      : 'Use at least 8 characters, a number and a symbol.';

  static String? confirmPassword(String value, String password) =>
      value.isNotEmpty && value == password ? null : "Passwords don't match.";
}

/// Web strength meter: one point each for 8+ characters, an uppercase letter, a number
/// and a symbol (0 to 4). Under 3 is "Weak password", otherwise "Strong password".
int passwordStrength(String password) => [
  password.length >= 8,
  RegExp(r'[A-Z]').hasMatch(password),
  RegExp(r'\d').hasMatch(password),
  RegExp(r'[^A-Za-z0-9]').hasMatch(password),
].where((ok) => ok).length;

bool isStrongPassword(int strength) => strength >= 3;
