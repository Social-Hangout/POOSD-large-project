import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/account_avatar.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/legal_footer.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';

/// Account tab. Layout: Figma 12 "Account menu": the person's initials and name, then
/// Settings, Change password, Need help?, Privacy policy, Terms of use and Log out, then
/// the legal footer. Change password is the web Profile page's "Change password" link.
/// Figma shows "Savory" as a stand-in where the name goes; this shows the real name, with
/// the email under it. Icons are Material outline icons close to the Figma ones.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenX,
              AppSpacing.screenTop,
              AppSpacing.screenX,
              AppSpacing.screenBottom,
            ),
            children: [
              Semantics(
                header: true,
                child: Text('Account', style: AppTextStyles.display),
              ),
              const SizedBox(height: AppSpacing.section),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            AccountAvatar(initials: user.initials),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.firstName} ${user.lastName}',
                                    style: AppTextStyles.sectionHeading,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(user.email, style: AppTextStyles.small),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.go(AppRoutes.accountSettings),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline,
                      label: 'Change password',
                      onTap: () =>
                          context.go(AppRoutes.accountChangePassword),
                    ),
                    _MenuRow(
                      icon: Icons.help_outline,
                      label: 'Need help?',
                      onTap: () => context.go(AppRoutes.accountHelp),
                    ),
                    _MenuRow(
                      icon: Icons.description_outlined,
                      label: 'Privacy policy',
                      onTap: () => context.go(AppRoutes.accountPrivacy),
                    ),
                    _MenuRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of use',
                      onTap: () => context.go(AppRoutes.accountTerms),
                    ),
                    _MenuRow(
                      icon: Icons.logout,
                      label: 'Log out',
                      showDivider: false,
                      onTap: () =>
                          ref.read(sessionControllerProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              const LegalFooter(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma menu row: outline icon, label, chevron, divider under it.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              border: showDivider
                  ? const Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.muted),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppTextStyles.bodyInk)),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
