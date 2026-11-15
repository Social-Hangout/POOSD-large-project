import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/brand_header.dart';
import '../../../../shared/widgets/legal_footer.dart';

/// Shared layout of the auth frames (01-05): brand header, scrolling content with
/// 20/16/20/32 padding and 24 px gaps, and the legal footer at the end.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BrandHeader(
              // "Need help?" is in every auth frame. There is no help page yet, so it is
              // shown as text only (see README, open items).
              trailing: Text('Need help?', style: AppTextStyles.linkSmall),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenX,
                  AppSpacing.screenTop,
                  AppSpacing.screenX,
                  AppSpacing.screenBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final child in children) ...[
                      child,
                      const SizedBox(height: AppSpacing.section),
                    ],
                    const LegalFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
