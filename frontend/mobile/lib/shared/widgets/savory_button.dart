import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Figma "Button" component variants.
enum SavoryButtonVariant {
  /// Yellow fill, ink label ("Log In", "Create Account").
  primaryYellow(AppColors.yellow, AppColors.ink),

  /// Green fill, white label ("View recipe →").
  primaryGreen(AppColors.green, AppColors.surface),

  /// Mint fill, dark green label ("View Recipe" on cards).
  tint(AppColors.greenTint, AppColors.greenDark),

  /// White fill with a border ("Reset filters").
  secondary(AppColors.surface, AppColors.ink, border: AppColors.border),

  /// White fill, green border, dark green label: the web's .secondary-button
  /// ("+ Add ingredient", "+ Add step").
  outlineGreen(AppColors.surface, AppColors.greenDark, border: AppColors.green),

  /// Red fill, white label: the web's .danger-button ("Yes, delete").
  danger(AppColors.danger, AppColors.surface);

  const SavoryButtonVariant(this.background, this.foreground, {this.border});
  final Color background;
  final Color foreground;
  final Color? border;
}

class SavoryButton extends StatelessWidget {
  const SavoryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SavoryButtonVariant.primaryYellow,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.height = AppSpacing.buttonHeight,
    this.compactText = false,
    this.fadeWhenDisabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SavoryButtonVariant variant;
  final bool isLoading;

  /// Text shown while loading ("Logging in…"), as the web buttons do. Without it, a spinner.
  final String? loadingLabel;
  final bool expand;
  final double height;

  /// 13 px bold label, used by the 44 px card button.
  final bool compactText;

  /// Draw the button at 55 % opacity while [onPressed] is null.
  final bool fadeWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        (compactText ? AppTextStyles.recipeAction : AppTextStyles.button)
            .copyWith(color: variant.foreground);
    final enabled = onPressed != null && !isLoading;

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: Material(
          color: variant.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            side: variant.border == null
                ? BorderSide.none
                : BorderSide(color: variant.border!),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: isLoading && loadingLabel != null
                    ? ExcludeSemantics(
                        child: Text(loadingLabel!, style: textStyle),
                      )
                    : isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: variant.foreground,
                        ),
                      )
                    : ExcludeSemantics(child: Text(label, style: textStyle)),
              ),
            ),
          ),
        ),
      ),
    );

    // Disabled (not loading) buttons fade like the web's `button:disabled` (opacity .55).
    // Off by default so existing screens look the same.
    return fadeWhenDisabled && onPressed == null && !isLoading
        ? Opacity(opacity: 0.55, child: button)
        : button;
  }
}
