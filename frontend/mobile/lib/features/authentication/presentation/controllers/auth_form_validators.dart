import '../../../../core/constants/app_limits.dart';

/// Registration rules and messages, copied from web/src/pages/AuthPage.tsx (RegisterForm)
/// so the two apps accept and reject exactly the same input. Login has no client-side
/// checks, as on the web: the API's own message is shown instead.
class AuthFormValidators {
  const AuthFormValidators._();

  /// The API also caps names at 50 characters after trimming (api/utils/validate.js).
  static String? firstName(String value) =>
      value.trim().isEmpty ? 'Enter your first name.' : _nameTooLong(value);

  static String? lastName(String value) =>
      value.trim().isEmpty ? 'Enter your last name.' : _nameTooLong(value);

  static String? _nameTooLong(String value) =>
      value.trim().length > 50 ? 'Use 50 characters or fewer.' : null;

  static String? email(String value) => AppLimits.emailPattern.hasMatch(value)
      ? null
      : 'Enter a valid email, e.g. kai@email.com.';

  /// Every required line of [passwordRequirements], so the checklist and this message
  /// can never disagree.
  static String? password(String value) =>
      passwordRequirements(value).every((r) => r.met || !r.required)
      ? null
      : 'Use at least 8 characters, a number and a symbol.';

  static String? confirmPassword(String value, String password) =>
      value.isNotEmpty && value == password ? null : "Passwords don't match.";
}

/// One line of the password checklist on the registration screen.
class PasswordRequirement {
  const PasswordRequirement({
    required this.label,
    required this.met,
    required this.required,
  });

  final String label;
  final bool met;

  /// Required rules block "Create Account" (the same rules as [AuthFormValidators.password]).
  /// The rest only raise the strength.
  final bool required;
}

/// The checklist, in display order. The four checks are the web's strength meter
/// (web/src/pages/AuthPage.tsx). "At least 8 characters" is the one rule the API enforces
/// (api/utils/validate.js isValidPassword); the number and symbol are the web app's
/// stricter client rule, which the API always accepts.
List<PasswordRequirement> passwordRequirements(String password) => [
  PasswordRequirement(
    label: 'At least 8 characters',
    met: password.length >= 8,
    required: true,
  ),
  PasswordRequirement(
    label: 'A number',
    met: RegExp(r'\d').hasMatch(password),
    required: true,
  ),
  PasswordRequirement(
    label: 'A symbol, like ! or #',
    met: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    required: true,
  ),
  PasswordRequirement(
    label: 'An uppercase letter (recommended)',
    met: RegExp(r'[A-Z]').hasMatch(password),
    required: false,
  ),
];

/// Web strength score: one point each for 8+ characters, an uppercase letter, a number
/// and a symbol (0 to 4). Fills that many segments of the strength bar.
int passwordStrength(String password) =>
    passwordRequirements(password).where((r) => r.met).length;

enum PasswordStrengthLevel {
  weak('Weak password'),
  medium('Medium password'),
  strong('Strong password');

  const PasswordStrengthLevel(this.label);
  final String label;
}

/// Weak until every required rule is met, so "Medium" never labels a password the form
/// would reject. Medium when the required rules pass; Strong when every check passes.
PasswordStrengthLevel passwordStrengthLevel(String password) {
  final requirements = passwordRequirements(password);
  if (requirements.any((r) => r.required && !r.met)) {
    return PasswordStrengthLevel.weak;
  }
  return requirements.every((r) => r.met)
      ? PasswordStrengthLevel.strong
      : PasswordStrengthLevel.medium;
}
