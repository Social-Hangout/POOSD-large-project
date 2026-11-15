import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_icon.dart';
import '../../../../shared/widgets/surface_card.dart';

/// Figma 14 "No recipe matches" card, reused for the empty and error states.
/// The words come from the web app's matching states.
class RecipeStateCard extends StatelessWidget {
  const RecipeStateCard({
    super.key,
    required this.heading,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String heading;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7D7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SavoryIcon(SavoryIcons.searchGreen, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              heading,
              style: AppTextStyles.display.copyWith(fontSize: 26),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.body),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SavoryButton(
              label: actionLabel!,
              variant: SavoryButtonVariant.primaryGreen,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
