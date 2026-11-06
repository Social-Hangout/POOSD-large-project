import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Don't have an account? Sign up" style row: muted lead-in plus a green tappable link.
/// The whole row keeps a 44 px tap height for accessibility.
class LeadInLink extends StatelessWidget {
  const LeadInLink({
    super.key,
    required this.leadIn,
    required this.link,
    required this.onTap,
  });

  final String leadIn;
  final String link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$leadIn$link',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.tapTarget),
          child: Center(
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: leadIn, style: AppTextStyles.small),
                    TextSpan(text: link, style: AppTextStyles.linkSmall),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
