import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_text_field.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../data/auth_providers.dart';
import '../controllers/auth_form_validators.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/text_link.dart';

/// Create account. Layout: Figma 02 and 03 (validation). Behaviour: the web's RegisterForm:
/// same rules and messages, errors shown after the first submit and updated as you type,
/// the API's message on failure. On success the mobile app moves to "Check your email",
/// which shows what the web shows in place of the button.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _submitted = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String?> get _errors => {
    'firstName': AuthFormValidators.firstName(_firstName.text),
    'lastName': AuthFormValidators.lastName(_lastName.text),
    'email': AuthFormValidators.email(_email.text),
    'password': AuthFormValidators.password(_password.text),
    'confirm': AuthFormValidators.confirmPassword(
      _confirm.text,
      _password.text,
    ),
  };

  String? _show(String key) => _submitted ? _errors[key] : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_errors.values.any((e) => e != null)) return;

    setState(() => _loading = true);
    final email = _email.text;
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: email,
            password: _password.text,
          );
      if (mounted) context.go(AppRoutes.checkEmailFor(email));
    } on ApiException catch (e) {
      if (mounted)
        setState(
          () => _error = e.message.isEmpty ? 'Unable to register.' : e.message,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changed(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        SurfaceCard(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EyebrowHeading(
                  eyebrow: 'A fresh start',
                  heading: 'Join the kitchen.',
                  gap: 10,
                ),
                const SizedBox(height: AppSpacing.cardGap),
                SavoryTextField(
                  label: 'First name',
                  hint: 'First name',
                  controller: _firstName,
                  errorText: _show('firstName'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  onChanged: _changed,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                SavoryTextField(
                  label: 'Last name',
                  hint: 'Last name',
                  controller: _lastName,
                  errorText: _show('lastName'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  onChanged: _changed,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                SavoryTextField(
                  label: 'Email',
                  hint: 'you@email.com',
                  controller: _email,
                  errorText: _show('email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onChanged: _changed,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                SavoryTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  controller: _password,
                  errorText: _show('password'),
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: _changed,
                ),
                if (_password.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.fieldGap),
                  PasswordStrengthMeter(password: _password.text),
                ],
                const SizedBox(height: AppSpacing.fieldGap),
                SavoryTextField(
                  label: 'Confirm Password',
                  hint: 'Repeat your password',
                  controller: _confirm,
                  errorText: _show('confirm'),
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onChanged: _changed,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.fieldGap),
                  FormErrorMessage(_error!),
                ],
                const SizedBox(height: AppSpacing.fieldGap),
                SavoryButton(
                  label: 'Create Account',
                  isLoading: _loading,
                  loadingLabel: 'Creating…',
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.cardGap),
                Text(
                  'By creating an account, you agree to our Terms of use and Privacy policy.',
                  style: AppTextStyles.smallLegal,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                LeadInLink(
                  leadIn: 'Already have an account? ',
                  link: 'Log in',
                  onTap: _loading ? null : () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
