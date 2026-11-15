import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../domain/kitchen_ingredients.dart';

/// Figma 06 ingredient card: the ingredients as removable chips, then "Add another
/// ingredient…" with a round green button. The Figma mic button is a "+" here (the app
/// has no speech input), and the "30 min · 2 servings" / "Fine-tune" row is left out:
/// recipes have no time or servings and the API has no filters.
class IngredientInputCard extends StatelessWidget {
  const IngredientInputCard({
    super.key,
    required this.ingredients,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
    required this.onClear,
    this.error,
  });

  final KitchenIngredients ingredients;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final items = ingredients.items;

    return SurfaceCard(
      radius: AppSpacing.radiusRecipeCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? AppColors.error : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in items)
                        _IngredientChip(
                          key: ValueKey(item.toLowerCase()),
                          label: item,
                          onRemove: () => onRemove(item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => onAdd(),
                        style: AppTextStyles.input,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: items.isEmpty
                              ? 'Add an ingredient, like chicken'
                              : 'Add another ingredient…',
                          hintStyle: AppTextStyles.inputHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Add ingredient',
                      child: Material(
                        color: AppColors.greenTint,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onAdd,
                          child: const SizedBox(
                            width: AppSpacing.tapTarget,
                            height: AppSpacing.tapTarget,
                            child: Icon(
                              Icons.add,
                              size: 22,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            FormErrorMessage(error!),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  items.isEmpty
                      ? 'Separate ingredients with commas.'
                      : '${items.length} of ${KitchenIngredients.maxItems} '
                            'ingredients',
                  style: AppTextStyles.small,
                ),
              ),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.tapTarget),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text('Clear all', style: AppTextStyles.linkSmall),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Figma ingredient chip: light pill, bold label, close icon. Pops in when added.
class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 14, right: 2),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.recipeAction.copyWith(color: AppColors.ink),
            ),
            Semantics(
              button: true,
              label: 'Remove $label',
              child: InkResponse(
                onTap: onRemove,
                radius: 18,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.close, size: 16, color: AppColors.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
