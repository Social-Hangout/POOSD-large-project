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
import '../controllers/session_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/brand_proposition.dart';
import '../widgets/resend_verification_button.dart';
import '../widgets/text_link.dart';

/// Welcome / log in. Layout: Figma 01 Login. Behaviour: the web's LoginForm
/// (web/src/pages/AuthPage.tsx): no client-side checks, the API's message on failure,
/// and on 403 a "verify your email" message with a resend button.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _unverified = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _unverified = false;
      _loading = true;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(email: _email.text, password: _password.text);
      // The router redirect moves on to the recipe list.
    } on ApiException catch (e) {
      if (!mounted) return;
      // 403 means the password was right but the email isn't verified yet.
      setState(() {
        _unverified = e.isForbidden;
        _error = e.isForbidden
            ? 'Please verify your email before logging in.'
            : (e.message.isEmpty ? 'Unable to log in.' : e.message);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const BrandProposition(),
        SurfaceCard(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EyebrowHeading(
                  eyebrow: 'Your kitchen awaits',
                  heading: 'Welcome back.',
                  supporting: 'Log in to find your next delicious idea.',
                ),
                const SizedBox(height: AppSpacing.cardGap),
                SavoryTextField(
                  label: 'Email',
                  hint: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  // The resend button needs the current email.
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                SavoryTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _password,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.forgotPassword),
                    child: Text('Forgot password?', style: AppTextStyles.link),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.cardGap),
                  FormErrorMessage(_error!),
                ],
                if (_unverified) ...[
                  const SizedBox(height: 12),
                  ResendVerificationButton(email: _email.text),
                ],
                const SizedBox(height: AppSpacing.cardGap),
                SavoryButton(
                  label: 'Log In',
                  isLoading: _loading,
                  loadingLabel: 'Logging in…',
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                LeadInLink(
                  leadIn: "Don't have an account? ",
                  link: 'Sign up',
                  onTap: _loading ? null : () => context.go(AppRoutes.register),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
