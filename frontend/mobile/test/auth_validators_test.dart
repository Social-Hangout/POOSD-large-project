import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/authentication/presentation/controllers/auth_form_validators.dart';

// Same rules and messages as web/src/pages/AuthPage.tsx (RegisterForm).
void main() {
  test('names only need to be non-blank', () {
    expect(AuthFormValidators.firstName('  '), 'Enter your first name.');
    expect(AuthFormValidators.lastName(''), 'Enter your last name.');
    expect(AuthFormValidators.firstName('Ana'), isNull);
  });

  test('names are capped at 50 characters after trimming, like the API', () {
    expect(AuthFormValidators.firstName('x' * 50), isNull);
    expect(AuthFormValidators.firstName('  ${'x' * 50}  '), isNull);
    expect(
      AuthFormValidators.lastName('x' * 51),
      'Use 50 characters or fewer.',
    );
  });

  test('email uses the web regex, on the value as typed', () {
    expect(AuthFormValidators.email('kai@email.com'), isNull);
    expect(
      AuthFormValidators.email('kai@email'),
      'Enter a valid email, e.g. kai@email.com.',
    );
    expect(AuthFormValidators.email('kai@email.com '), isNotNull);
  });

  test('password needs 8+ characters, a number and a symbol', () {
    const message = 'Use at least 8 characters, a number and a symbol.';
    expect(AuthFormValidators.password('password'), message);
    expect(AuthFormValidators.password('password1'), message);
    expect(AuthFormValidators.password('pass1!'), message);
    expect(AuthFormValidators.password('password1!'), isNull);
  });

  test('confirm must be filled and match', () {
    expect(
      AuthFormValidators.confirmPassword('', ''),
      "Passwords don't match.",
    );
    expect(
      AuthFormValidators.confirmPassword('a1!aaaaa', 'b1!bbbbb'),
      "Passwords don't match.",
    );
    expect(AuthFormValidators.confirmPassword('a1!aaaaa', 'a1!aaaaa'), isNull);
  });

  test('strength counts length, uppercase, number, symbol', () {
    expect(passwordStrength(''), 0);
    expect(passwordStrength('basil'), 0);
    expect(passwordStrength('basilbasil'), 1);
    expect(passwordStrength('basilbasil1'), 2);
    expect(passwordStrength('basilbasil1!'), 3);
    expect(passwordStrength('Basilbasil1!'), 4);
  });

  test('level is Weak until the required rules pass', () {
    expect(passwordStrengthLevel(''), PasswordStrengthLevel.weak);
    // 3 of 4 checks but no symbol: the form would reject it, so not Medium.
    expect(passwordStrengthLevel('Basilbasil1'), PasswordStrengthLevel.weak);
    expect(passwordStrengthLevel('basilbasil1!'), PasswordStrengthLevel.medium);
    expect(passwordStrengthLevel('Basilbasil1!'), PasswordStrengthLevel.strong);
  });

  test('checklist, strength and submit validation always agree', () {
    for (final p in [
      '',
      'a',
      'password',
      'password1',
      'pass1!',
      'password!',
      'password1!',
      'Password1!',
      '        ',
      '1234567!',
    ]) {
      final requiredMet = passwordRequirements(p)
          .where((r) => r.required)
          .every((r) => r.met);
      expect(AuthFormValidators.password(p) == null, requiredMet, reason: p);
      expect(
        passwordStrengthLevel(p) != PasswordStrengthLevel.weak,
        requiredMet,
        reason: p,
      );
    }
  });

  test('the length rule matches the API (api/utils/validate.js)', () {
    expect(
      passwordRequirements('1234567').first.label,
      'At least 8 characters',
    );
    expect(passwordRequirements('1234567').first.met, isFalse);
    expect(passwordRequirements('12345678').first.met, isTrue);
  });
}
