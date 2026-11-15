import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/legal_footer.dart';
import '../../../../shared/widgets/placeholder_tab.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../controllers/session_controller.dart';

/// Minimal Account tab until Figma 12 is built: shows who is logged in and a Log Out
/// button, which the demo needs to get back to the welcome screen.
class AccountPlaceholderScreen extends ConsumerWidget {
  const AccountPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;
    return PlaceholderTab(
      eyebrow: 'Your account',
      heading: 'Account',
      message: user == null
          ? 'Not logged in.'
          : 'Logged in as ${user.firstName} ${user.lastName} (${user.email}).',
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SavoryButton(
            label: 'Log Out',
            variant: SavoryButtonVariant.secondary,
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).logout(),
          ),
          const SizedBox(height: 24),
          Text('About', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 12),
          const LegalFooter(),
        ],
      ),
    );
  }
}
