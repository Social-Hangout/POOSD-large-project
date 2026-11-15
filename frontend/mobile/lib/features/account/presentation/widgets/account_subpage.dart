import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';

/// Frame for the pages opened from the Account menu: the header, "Back to account" (the
/// same link style as "Back to recipes" on the recipe screen) and a Playfair title.
class AccountSubpage extends StatelessWidget {
  const AccountSubpage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenX,
              AppSpacing.screenTop,
              AppSpacing.screenX,
              AppSpacing.screenBottom,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.account),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: AppColors.green,
                  ),
                  label: Text('Back to account', style: AppTextStyles.link),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.tapTarget),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.display),
              ),
              const SizedBox(height: AppSpacing.section),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}
