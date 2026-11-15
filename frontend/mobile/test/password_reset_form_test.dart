// Change password: reading the token from what is pasted, and the web ResetForm's checks
// (web/src/pages/AuthPage.tsx) in the web's order.
import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/authentication/presentation/controllers/password_reset_form.dart';

final _token = 'a1' * 32; // 64 hex characters, the shape api/utils/tokens.js makes
const _good = 'Fresh#basil1';

void main() {
  group('resetTokenFrom', () {
    test('reads the token from the emailed link', () {
      expect(
        resetTokenFrom('https://contactshub.site/reset-password?token=$_token'),
        _token,
      );
    });

    test('reads it from the whole plain-text email, with spaces around', () {
      final email =
          'Use this link to choose a new password:\n\n'
          'https://contactshub.site/reset-password?token=$_token\n\n'
          'This link expires in 1 hour and works once.';
      expect(resetTokenFrom('  $email  '), _token);
    });

    test('stops at other parameters or a fragment', () {
      expect(resetTokenFrom('https://x.site/reset-password?token=$_token&a=1'), _token);
      expect(resetTokenFrom('https://x.site/reset-password?a=1&token=$_token#top'), _token);
    });

    test('accepts the token on its own', () {
      expect(resetTokenFrom(_token), _token);
      expect(resetTokenFrom(_token.toUpperCase()), _token);
    });

    test('anything else has no token', () {
      expect(resetTokenFrom(''), isNull);
      expect(resetTokenFrom('   '), isNull);
      expect(resetTokenFrom('https://contactshub.site/reset-password'), isNull);
      expect(resetTokenFrom('hello'), isNull);
      expect(resetTokenFrom('a1b2'), isNull);
    });
  });

  group('validatePasswordReset (web ResetForm order and messages)', () {
    final link = 'https://contactshub.site/reset-password?token=$_token';

    test('a link, a valid password and a matching confirmation pass', () {
      expect(
        validatePasswordReset(resetLink: link, password: _good, confirm: _good),
        isNull,
      );
    });

    test('a missing link is reported first', () {
      expect(
        validatePasswordReset(resetLink: '', password: 'x', confirm: 'y'),
        'This reset link is invalid or expired.',
      );
    });

    test('then the web password rule: 8+ characters, a number and a symbol', () {
      for (final weak in ['short1!', 'longenough!', 'longenough1', '']) {
        expect(
          validatePasswordReset(resetLink: link, password: weak, confirm: weak),
          'Use at least 8 characters, a number and a symbol.',
          reason: weak,
        );
      }
    });

    test('then the confirmation must match', () {
      expect(
        validatePasswordReset(resetLink: link, password: _good, confirm: 'Fresh#basil2'),
        "Passwords don't match.",
      );
      expect(
        validatePasswordReset(resetLink: link, password: _good, confirm: ''),
        "Passwords don't match.",
      );
    });
  });
}
