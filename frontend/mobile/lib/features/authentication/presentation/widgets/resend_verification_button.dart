import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/form_status_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../data/auth_providers.dart';

/// The web's ResendButton (web/src/pages/AuthPage.tsx): POST /auth/resend-verification for
/// [email], with the same states and messages. Shown after registering and after a 403 login.
class ResendVerificationButton extends ConsumerStatefulWidget {
  const ResendVerificationButton({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResendVerificationButton> createState() =>
      _ResendVerificationButtonState();
}

enum _ResendState { idle, sending, sent }

class _ResendVerificationButtonState
    extends ConsumerState<ResendVerificationButton> {
  _ResendState _state = _ResendState.idle;
  String? _error;

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _state = _ResendState.sending;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
      if (mounted) setState(() => _state = _ResendState.sent);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message.isEmpty ? 'Unable to resend the link.' : e.message;
          _state = _ResendState.idle;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          FormErrorMessage(_error!),
          const SizedBox(height: 12),
        ],
        if (_state == _ResendState.sent) ...[
          const FormStatusMessage('A new verification link is on its way.'),
          const SizedBox(height: 12),
        ],
        SavoryButton(
          label: 'Resend verification email',
          variant: SavoryButtonVariant.secondary,
          isLoading: _state == _ResendState.sending,
          loadingLabel: 'Sending…',
          onPressed: widget.email.isEmpty ? null : _resend,
        ),
      ],
    );
  }
}
