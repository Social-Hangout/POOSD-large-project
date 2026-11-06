import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_limits.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/savory_icon.dart';

/// Figma "Recipe search" bar. Like the web's search box, it is shown but disabled until
/// GET /api/recipes/search exists (AppConfig.recipeSearchAvailable). The filter icon is
/// left out: the filter sheet (frame 09) has no API support.
class RecipeSearchField extends StatelessWidget {
  const RecipeSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.enabled = true,
    this.hint = 'Search recipes...',
  });

  final bool enabled;
  final String hint;

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        border: Border.all(
          color: enabled ? AppColors.yellow : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const SavoryIcon(SavoryIcons.search, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              inputFormatters: [
                LengthLimitingTextInputFormatter(AppLimits.searchMaxChars),
              ],
              style: AppTextStyles.bodyInk,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.body,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: AppSpacing.tapTarget)
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
