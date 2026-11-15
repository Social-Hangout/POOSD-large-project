import 'auth_form_validators.dart';

/// The token in a reset link: `<APP_URL>/reset-password?token=<64 hex characters>`
/// (api/utils/authEmails.js). Matched anywhere in the pasted text, so pasting the whole
/// plain-text email ("Use this link to choose a new password: https://…") works too.
final _tokenInLink = RegExp(r'[?&]token=([^&#\s]+)');

/// A token pasted on its own (api/utils/tokens.js makes 32 random bytes as hex).
final _bareToken = RegExp(r'^[a-fA-F0-9]{64}$');

/// The reset token in what the user pasted (the emailed link, the whole email, or just
/// the token), or null when there is none. The web page reads the same `token` parameter
/// from its address (`useSearchParams().get("token")`).
String? resetTokenFrom(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final inLink = _tokenInLink.firstMatch(text);
  if (inLink != null) return inLink.group(1);
  return _bareToken.hasMatch(text) ? text.toLowerCase() : null;
}

/// The web's ResetForm checks (web/src/pages/AuthPage.tsx), in the same order and with
/// the same messages, or null when the form can be sent:
/// 1. no token: "This reset link is invalid or expired."
/// 2. the web password rule (8+ characters, a number and a symbol);
/// 3. the confirmation must match: "Passwords don't match."
String? validatePasswordReset({
  required String resetLink,
  required String password,
  required String confirm,
}) {
  if (resetTokenFrom(resetLink) == null) {
    return 'This reset link is invalid or expired.';
  }
  final passwordProblem = AuthFormValidators.password(password);
  if (passwordProblem != null) return passwordProblem;
  if (password != confirm) return "Passwords don't match.";
  return null;
}
