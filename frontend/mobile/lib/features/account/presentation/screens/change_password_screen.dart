import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/form_status_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_text_field.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../../authentication/data/auth_providers.dart';
import '../../../authentication/presentation/controllers/password_reset_form.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../authentication/presentation/widgets/password_strength_meter.dart';
import '../widgets/account_subpage.dart';

/// Change password (Account > Change password). The web's Profile page links
/// "Change password" to its email reset flow, and the API has no other way to change a
/// password, so this screen runs that same flow with the same two routes:
///
/// 1. "Send Reset Link": POST /auth/forgot-password with the logged-in user's email (the
///    web's ForgotForm: "Sending…", then the API's message, or "Unable to send the link.").
/// 2. "Reset Password": the web's ResetForm, in the app. The user pastes the emailed link
///    (or the whole email), and the token is read from it as the web page reads it from
///    its address. Same checks, order and messages ("This reset link is invalid or
///    expired.", "Use at least 8 characters, a number and a symbol.", "Passwords don't
///    match."), "Your passwords match.", "Saving…", then POST /auth/reset-password and
///    the API's message (or "Unable to reset password."). The link still opens the web
///    page in a browser too.
///
/// No Figma frame exists for this page; it uses the Settings page's cards, fields and
/// buttons, and the registration screen's password checklist.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _link = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Step 1: send the link.
  bool _sending = false;
  String? _sendStatus;
  String? _sendError;

  // Step 2: choose the new password.
  bool _resetting = false;
  String? _resetStatus;
  String? _resetError;

  @override
  void dispose() {
    _link.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendLink(String email) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sendStatus = null;
      _sendError = null;
      _sending = true;
    });
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .forgotPassword(email);
      if (mounted) setState(() => _sendStatus = message);
    } catch (e) {
      if (mounted) {
        setState(
          () => _sendError = e is ApiException && e.message.isNotEmpty
              ? e.message
              : 'Unable to send the link.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted || text == null || text.trim().isEmpty) return;
    _link.text = text.trim();
    setState(() => _resetError = null);
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _resetError = null);

    final problem = validatePasswordReset(
      resetLink: _link.text,
      password: _password.text,
      confirm: _confirm.text,
    );
    if (problem != null) {
      setState(() => _resetError = problem);
      return;
    }

    setState(() => _resetting = true);
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: resetTokenFrom(_link.text)!,
            newPassword: _password.text,
          );
      if (mounted) {
        setState(
          () => _resetStatus = message.isEmpty
              ? 'Password reset. You can now log in.'
              : message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _resetError = e is ApiException && e.message.isNotEmpty
              ? e.message
              : 'Unable to reset password.',
        );
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;

    return AccountSubpage(
      title: 'Change password',
      children: [
        if (user == null)
          SurfaceCard(child: Text('Not logged in.', style: AppTextStyles.body))
        else ...[
          SurfaceCard(child: _buildSendStep(user.email)),
          const SizedBox(height: AppSpacing.section),
          SurfaceCard(
            child: _resetStatus == null ? _buildResetStep() : _buildDone(),
          ),
        ],
      ],
    );
  }

  Widget _buildSendStep(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EyebrowHeading(
          eyebrow: 'Step 1 of 2',
          heading: 'Get a reset link',
          headingStyle: AppTextStyles.sectionHeading,
          supporting:
              "We'll email a link to $email. It works once, for one hour.",
        ),
        if (_sendError != null) ...[
          const SizedBox(height: AppSpacing.fieldGap),
          FormErrorMessage(_sendError!),
        ],
        if (_sendStatus != null) ...[
          const SizedBox(height: AppSpacing.fieldGap),
          FormStatusMessage(_sendStatus!),
        ],
        const SizedBox(height: AppSpacing.cardGap),
        SavoryButton(
          label: 'Send Reset Link',
          isLoading: _sending,
          loadingLabel: 'Sending…',
          onPressed: () => _sendLink(email),
        ),
      ],
    );
  }

  Widget _buildResetStep() {
    final matches = _confirm.text.isNotEmpty && _password.text == _confirm.text;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyebrowHeading(
            eyebrow: 'Step 2 of 2',
            heading: 'Choose a new password',
            headingStyle: AppTextStyles.sectionHeading,
            supporting:
                'Copy the link from the email and paste it here. You can also open '
                'the link in your browser instead.',
          ),
          const SizedBox(height: AppSpacing.cardGap),
          SavoryTextField(
            label: 'Reset link',
            hint: 'Paste the link from the email',
            controller: _link,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pasteLink,
              icon: const Icon(
                Icons.content_paste,
                size: 16,
                color: AppColors.green,
              ),
              label: Text('Paste from clipboard', style: AppTextStyles.linkSmall),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.tapTarget),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SavoryTextField(
            label: 'New Password',
            hint: 'New password',
            controller: _password,
            isPassword: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          PasswordStrengthMeter(password: _password.text),
          const SizedBox(height: AppSpacing.fieldGap),
          SavoryTextField(
            label: 'Confirm Password',
            hint: 'Confirm password',
            controller: _confirm,
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _resetPassword(),
          ),
          if (matches) ...[
            const SizedBox(height: 7),
            const FormStatusMessage('Your passwords match.'),
          ],
          if (_resetError != null) ...[
            const SizedBox(height: AppSpacing.fieldGap),
            FormErrorMessage(_resetError!),
          ],
          const SizedBox(height: AppSpacing.cardGap),
          SavoryButton(
            label: 'Reset Password',
            isLoading: _resetting,
            loadingLabel: 'Saving…',
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  /// The web swaps its form for the API's message once the password is reset.
  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Password changed', style: AppTextStyles.sectionHeading),
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        FormStatusMessage(_resetStatus!),
        const SizedBox(height: 8),
        // The API leaves existing sessions alone, so this device stays logged in.
        Text(
          "You're still logged in on this device. Use your new password the next "
          'time you log in.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        SavoryButton(
          label: 'Back to account',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.account),
        ),
      ],
    );
  }
}
