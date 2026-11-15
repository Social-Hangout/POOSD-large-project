import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// "← Back to login", as on the web's forgot/resend pages and Figma 04.
class BackToLoginLink extends StatelessWidget {
  const BackToLoginLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.go(AppRoutes.login),
        icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.green),
        label: Text('Back to login', style: AppTextStyles.link),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.tapTarget),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
