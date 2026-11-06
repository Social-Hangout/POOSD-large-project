import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/back_to_login_link.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/form_status_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_text_field.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../data/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

/// Forgot password. Layout: Figma 04. Behaviour and copy: the web's ForgotForm
/// (POST /auth/forgot-password, the API's message on success). The emailed link opens the
/// web app's /reset-password page, so choosing the new password happens in the browser.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _status;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _status = null;
      _error = null;
      _loading = true;
    });
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .forgotPassword(_email.text);
      if (mounted) setState(() => _status = message);
    } on ApiException catch (e) {
      if (mounted)
        setState(
          () => _error = e.message.isEmpty
              ? 'Unable to send the link.'
              : e.message,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EyebrowHeading(
                eyebrow: 'Back to good things',
                heading: 'Forgot your password?',
                supporting:
                    "It happens. Enter the email you use for Savory and we'll send "
                    'you a link to reset it.',
              ),
              const SizedBox(height: AppSpacing.cardGap),
              SavoryTextField(
                label: 'Email',
                hint: 'you@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.cardGap),
                FormErrorMessage(_error!),
              ],
              if (_status != null) ...[
                const SizedBox(height: AppSpacing.cardGap),
                FormStatusMessage(_status!),
              ],
              const SizedBox(height: AppSpacing.cardGap),
              SavoryButton(
                label: 'Send Reset Link',
                isLoading: _loading,
                loadingLabel: 'Sending…',
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              const BackToLoginLink(),
            ],
          ),
        ),
      ],
    );
  }
}
