import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../data/recipe_providers.dart';
import '../../domain/recipe.dart';
import '../controllers/my_recipes_controller.dart';

/// Edit and a two-step Delete, a port of `OwnerActions` in web/src/pages/MyRecipesPage.tsx
/// (also used on the recipe screen, as the web's RecipeDetailPage does):
/// - Delete first asks: "Delete “<title>”? Its reviews and comments go too." with
///   "Yes, delete" ("Deleting…" while it runs) and Cancel;
/// - DELETE /api/recipes/:id; on success every recipe list reloads and [onDeleted] runs;
/// - on failure the API's message (or "Could not delete the recipe.") shows above the
///   buttons and the confirmation closes.
class OwnerActions extends ConsumerStatefulWidget {
  const OwnerActions({
    super.key,
    required this.recipe,
    required this.onEdit,
    required this.onDeleted,
  });

  final Recipe recipe;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;

  @override
  ConsumerState<OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends ConsumerState<OwnerActions> {
  bool _confirming = false;
  bool _deleting = false;
  String? _error;

  Future<void> _remove() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(recipeRepositoryProvider).deleteRecipe(widget.recipe.id);
      if (!mounted) return;
      refreshRecipeLists(ref);
      widget.onDeleted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not delete the recipe.';
        _deleting = false;
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirming) {
      return Semantics(
        container: true,
        label: 'Confirm delete',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Delete “${widget.recipe.title}”? Its reviews and comments go too.',
              style: AppTextStyles.bodyInk.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SavoryButton(
                  label: 'Yes, delete',
                  loadingLabel: 'Deleting…',
                  isLoading: _deleting,
                  variant: SavoryButtonVariant.danger,
                  expand: false,
                  height: AppSpacing.tapTarget,
                  compactText: true,
                  onPressed: _remove,
                ),
                RecipeTextAction(
                  label: 'Cancel',
                  onTap: _deleting
                      ? null
                      : () => setState(() => _confirming = false),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          const SizedBox(height: 8),
          FormErrorMessage(_error!),
        ],
        Row(
          children: [
            RecipeTextAction(label: 'Edit', onTap: widget.onEdit),
            const SizedBox(width: 14),
            RecipeTextAction(
              label: 'Delete',
              color: AppColors.danger,
              onTap: () => setState(() {
                _confirming = true;
                _error = null;
              }),
            ),
          ],
        ),
      ],
    );
  }
}

/// The web's small `.text-button` (Edit, Delete, Cancel): dark green, 13 px, semibold,
/// with a full 44 px tap height.
class RecipeTextAction extends StatelessWidget {
  const RecipeTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.greenDark,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(AppSpacing.tapTarget, AppSpacing.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTextStyles.recipeAction.copyWith(
          color: onTap == null ? color.withValues(alpha: 0.55) : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
