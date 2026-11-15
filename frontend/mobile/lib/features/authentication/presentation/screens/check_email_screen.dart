import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/form_status_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/resend_verification_button.dart';

/// Shown right after POST /auth/register succeeds.
///
/// Content follows the web: after registering, the web shows "We sent a verification link
/// to <email>. Open it to activate your account." and swaps the button for "Resend
/// verification email". The heading copies the web's verify step ("ALMOST THERE").
/// The emailed link opens the web app's /verify page in the browser; afterwards the user
/// comes back here and logs in.
///
/// PROVISIONAL LAYOUT: Figma has no frame for this screen; it reuses the auth card pieces.
class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EyebrowHeading(
                eyebrow: 'Almost there',
                heading: 'Check your email.',
              ),
              const SizedBox(height: AppSpacing.cardGap),
              FormStatusMessage(
                'We sent a verification link to $email. Open it to activate your account.',
              ),
              const SizedBox(height: AppSpacing.cardGap),
              ResendVerificationButton(email: email),
              const SizedBox(height: 12),
              SavoryButton(
                label: 'Back to Log In',
                onPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
