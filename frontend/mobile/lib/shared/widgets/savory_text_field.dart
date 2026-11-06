import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'savory_icon.dart';

/// Figma "Text field": label, 50 px input, optional error line.
/// Password fields get the eye toggle; other fields show the alert icon on error.
class SavoryTextField extends StatefulWidget {
  const SavoryTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.errorText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  State<SavoryTextField> createState() => _SavoryTextFieldState();
}

class _SavoryTextFieldState extends State<SavoryTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    Widget? trailing;
    if (widget.isPassword) {
      trailing = _IconButton(
        icon: _obscured ? SavoryIcons.eyeOff : SavoryIcons.eye,
        label: _obscured ? 'Show password' : 'Hide password',
        onTap: () => setState(() => _obscured = !_obscured),
      );
    } else if (hasError) {
      trailing = const SizedBox(
        width: AppSpacing.tapTarget,
        height: AppSpacing.tapTarget,
        child: Center(child: SavoryIcon(SavoryIcons.alertCircle)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 7),
        Container(
          height: AppSpacing.inputHeight,
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.isPassword && _obscured,
                  enableSuggestions: !widget.isPassword,
                  autocorrect: !widget.isPassword,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  textCapitalization: widget.textCapitalization,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTextStyles.input,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.inputHint,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 7),
          Text(widget.errorText!, style: AppTextStyles.fieldError),
        ],
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final SavoryIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.tapTarget / 2,
        child: SizedBox(
          width: AppSpacing.tapTarget,
          height: AppSpacing.tapTarget,
          child: Center(child: SavoryIcon(icon)),
        ),
      ),
    );
  }
}
