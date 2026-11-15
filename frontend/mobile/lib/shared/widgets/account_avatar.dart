import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 44 px initials circle in the header of every logged-in frame.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Account',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.tapTarget,
          height: AppSpacing.tapTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.avatar,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.yellow, width: 2),
          ),
          child: Text(initials, style: AppTextStyles.avatar),
        ),
      ),
    );
  }
}
