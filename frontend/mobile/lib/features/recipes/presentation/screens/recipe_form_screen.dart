import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_text_field.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/recipe_providers.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_draft.dart';
import '../controllers/my_recipes_controller.dart';
import '../controllers/recipe_list_controller.dart';

/// Create a recipe (/my-recipes/new) or edit one of your own (/my-recipes/:id/edit).
/// Behaviour and words: the web's RecipeFormPage (web/src/pages/RecipeFormPage.tsx):
/// - "NEW RECIPE" / "Share a recipe", or "EDIT RECIPE" / "Edit your recipe";
/// - Title, Ingredients (name + optional amount, "n of 10", "Use a singular name, like
///   tomato."), Steps (numbered, "n of 8"); rows add up to the limit ("+ Add ingredient"
///   becomes "10 ingredients max") and the last row can't be removed;
/// - the same checks and messages as the web before sending, then POST or PUT
///   /api/recipes with every field trimmed; the error clears as soon as the form changes;
/// - "Publish Recipe" / "Save Changes", "Saving…" while sending; on success the saved
///   recipe opens; a 404 says "This recipe no longer exists.", anything else shows the
///   API's message (or "Could not save the recipe.");
/// - editing someone else's recipe: "You can only edit your own recipes."
class RecipeFormScreen extends ConsumerWidget {
  const RecipeFormScreen({super.key, this.recipeId, this.initialRecipe});

  /// null when creating.
  final String? recipeId;

  /// The recipe the previous screen already had, shown at once (else fetched by id).
  final Recipe? initialRecipe;

  bool get _editing => recipeId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    final id = recipeId;

    if (id == null) {
      body = const _RecipeForm(existing: null);
    } else if (initialRecipe != null && initialRecipe!.id == id) {
      body = _ownedOnly(ref, initialRecipe!);
    } else {
      body = ref
          .watch(recipeByIdProvider(id))
          .when(
            data: (recipe) => _ownedOnly(ref, recipe),
            loading: () =>
                Text('Loading your recipe…', style: AppTextStyles.body),
            error: (error, _) => FormErrorMessage(
              error is ApiException
                  ? error.message
                  : 'Could not load this recipe.',
            ),
          );
    }

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenX,
              AppSpacing.screenTop,
              AppSpacing.screenX,
              AppSpacing.screenBottom,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  // The web's "← Back": to the recipe when editing, else My Recipes.
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(
                          id == null ? AppRoutes.myRecipes : AppRoutes.myRecipe(id),
                        ),
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: AppColors.green,
                  ),
                  label: Text('Back', style: AppTextStyles.link),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.tapTarget),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.screenTop),
              Text(
                _editing ? 'EDIT RECIPE' : 'NEW RECIPE',
                style: AppTextStyles.eyebrow,
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  _editing ? 'Edit your recipe' : 'Share a recipe',
                  style: AppTextStyles.display,
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              body,
            ],
          ),
        ),
      ],
    );
  }

  /// As on the web, the form only opens for the recipe's author (the API enforces it too).
  Widget _ownedOnly(WidgetRef ref, Recipe recipe) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;
    if (recipe.author?.id != user?.id) {
      return const FormErrorMessage('You can only edit your own recipes.');
    }
    return _RecipeForm(existing: recipe);
  }
}

/// One ingredient row's text fields.
class _IngredientFields {
  _IngredientFields({String name = '', String amount = '', this.autofocus = false})
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount);

  final TextEditingController name;
  final TextEditingController amount;

  /// True for a row added with "+ Add ingredient", so typing can start at once.
  final bool autofocus;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// One step row's text field.
class _StepField {
  _StepField({String text = '', this.autofocus = false})
    : text = TextEditingController(text: text);

  final TextEditingController text;
  final bool autofocus;

  void dispose() => text.dispose();
}

class _RecipeForm extends ConsumerStatefulWidget {
  const _RecipeForm({required this.existing});

  /// The recipe being edited, or null when creating.
  final Recipe? existing;

  @override
  ConsumerState<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends ConsumerState<_RecipeForm> {
  late final TextEditingController _title;
  late final List<_IngredientFields> _ingredients;
  late final List<_StepField> _steps;

  String? _error;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.existing;
    _title = TextEditingController(text: recipe?.title ?? '');
    _ingredients = recipe == null || recipe.ingredients.isEmpty
        ? [_IngredientFields()]
        : [
            for (final item in recipe.ingredients)
              _IngredientFields(name: item.name, amount: item.amount),
          ];
    _steps = recipe == null || recipe.steps.isEmpty
        ? [_StepField()]
        : [for (final step in recipe.steps) _StepField(text: step)];
  }

  @override
  void dispose() {
    _title.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    for (final row in _steps) {
      row.dispose();
    }
    super.dispose();
  }

  /// The web clears an old error as soon as the title, ingredients or steps change.
  void _changed() {
    if (_error != null) setState(() => _error = null);
  }

  /// Rows leave the tree on the next frame; their controllers are freed after that.
  void _disposeLater(void Function() dispose) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => dispose());

  void _addIngredient() => setState(() {
    _error = null;
    _ingredients.add(_IngredientFields(autofocus: true));
  });

  void _removeIngredient(_IngredientFields row) {
    setState(() {
      _error = null;
      _ingredients.remove(row);
    });
    _disposeLater(row.dispose);
  }

  void _addStep() => setState(() {
    _error = null;
    _steps.add(_StepField(autofocus: true));
  });

  void _removeStep(_StepField row) {
    setState(() {
      _error = null;
      _steps.remove(row);
    });
    _disposeLater(row.dispose);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final draft = RecipeDraft(
      title: _title.text,
      ingredients: [
        for (final row in _ingredients)
          Ingredient(name: row.name.text, amount: row.amount.text),
      ],
      steps: [for (final row in _steps) row.text.text],
    );
    final problem = draft.validate();
    setState(() => _error = problem);
    if (problem != null) return;

    setState(() => _saving = true);
    try {
      final repository = ref.read(recipeRepositoryProvider);
      final existing = widget.existing;
      final saved = existing == null
          ? await repository.createRecipe(draft.trimmed())
          : await repository.updateRecipe(existing.id, draft.trimmed());
      if (!mounted) return;

      refreshRecipeLists(ref);
      // A new recipe is the newest, so My Recipes should open on its first page.
      if (existing == null) {
        ref.read(myRecipesPageNumberProvider.notifier).reset();
      }
      // As on the web, open the saved recipe. From the form this replaces it, so Back on
      // the recipe returns to My Recipes.
      context.go(AppRoutes.myRecipe(saved.id), extra: saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? (e.isNotFound ? 'This recipe no longer exists.' : e.message)
            : 'Could not save the recipe.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsFull = _ingredients.length >= RecipeLimits.maxIngredients;
    final stepsFull = _steps.length >= RecipeLimits.maxSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SavoryTextField(
          label: 'Title',
          hint: 'Garlic Butter Pasta',
          controller: _title,
          maxLength: RecipeLimits.title,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: AppSpacing.section),
        _FormSection(
          title: 'Ingredients',
          count: '${_ingredients.length} of ${RecipeLimits.maxIngredients}',
          hint: 'Use a singular name, like tomato.',
          children: [
            for (var i = 0; i < _ingredients.length; i++)
              _IngredientRow(
                key: ObjectKey(_ingredients[i]),
                number: i + 1,
                fields: _ingredients[i],
                onChanged: _changed,
                onRemove: _ingredients.length == 1
                    ? null
                    : () => _removeIngredient(_ingredients[i]),
              ),
          ],
          addLabel: ingredientsFull ? '10 ingredients max' : '+ Add ingredient',
          onAdd: ingredientsFull ? null : _addIngredient,
        ),
        const SizedBox(height: AppSpacing.section),
        _FormSection(
          title: 'Steps',
          count: '${_steps.length} of ${RecipeLimits.maxSteps}',
          children: [
            for (var i = 0; i < _steps.length; i++)
              _StepRow(
                key: ObjectKey(_steps[i]),
                number: i + 1,
                field: _steps[i],
                onChanged: _changed,
                onRemove: _steps.length == 1
                    ? null
                    : () => _removeStep(_steps[i]),
              ),
          ],
          addLabel: stepsFull ? '8 steps max' : '+ Add step',
          onAdd: stepsFull ? null : _addStep,
        ),
        const SizedBox(height: AppSpacing.section),
        if (_error != null) ...[
          FormErrorMessage(_error!),
          const SizedBox(height: 12),
        ],
        SavoryButton(
          label: _editing ? 'Save Changes' : 'Publish Recipe',
          loadingLabel: 'Saving…',
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// A white card holding one part of the form: the web's `<fieldset>` with its legend
/// ("Ingredients 3 of 10"), optional hint, the rows and an add button.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.count,
    required this.children,
    required this.addLabel,
    required this.onAdd,
    this.hint,
  });

  final String title;
  final String count;
  final String? hint;
  final List<Widget> children;
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppSpacing.radiusRecipeCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: AppTextStyles.sectionHeading),
                const SizedBox(width: 8),
                Text(count, style: AppTextStyles.small),
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: AppTextStyles.small),
          ],
          for (final child in children) ...[
            const SizedBox(height: 10),
            child,
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SavoryButton(
              label: addLabel,
              variant: SavoryButtonVariant.outlineGreen,
              expand: false,
              height: AppSpacing.tapTarget,
              compactText: true,
              fadeWhenDisabled: true,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    super.key,
    required this.number,
    required this.fields,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final _IngredientFields fields;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The web gives the name a little more room than the amount (flex 1.2 : 1).
        Expanded(
          flex: 6,
          child: _RowField(
            controller: fields.name,
            semanticLabel: 'Ingredient $number name',
            hint: 'tomato',
            maxLength: RecipeLimits.ingredientName,
            autofocus: fields.autofocus,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: _RowField(
            controller: fields.amount,
            semanticLabel: 'Ingredient $number amount',
            hint: '2 cups (optional)',
            maxLength: RecipeLimits.ingredientAmount,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        _RemoveButton(
          semanticLabel: 'Remove ingredient $number',
          onTap: onRemove,
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.number,
    required this.field,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final _StepField field;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The web's yellow .step-number circle.
        ExcludeSemantics(
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 8),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTextStyles.recipeAction.copyWith(color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RowField(
            controller: field.text,
            semanticLabel: 'Step $number',
            hint: 'Describe this step',
            maxLength: RecipeLimits.step,
            multiline: true,
            autofocus: field.autofocus,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        _RemoveButton(semanticLabel: 'Remove step $number', onTap: onRemove),
      ],
    );
  }
}

/// The web's row inputs (.ingredient-row input, .step-row textarea): white, 1 px border,
/// 11 px corners, yellow border on focus.
class _RowField extends StatelessWidget {
  const _RowField({
    required this.controller,
    required this.semanticLabel,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
    this.multiline = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final String hint;
  final int maxLength;
  final VoidCallback onChanged;
  final bool multiline;
  final bool autofocus;

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: (_) => onChanged(),
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
        minLines: multiline ? 2 : 1,
        maxLines: multiline ? 6 : 1,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction: multiline
            ? TextInputAction.newline
            : TextInputAction.next,
        textCapitalization: multiline
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          hintText: hint,
          hintStyle: AppTextStyles.inputHint,
          hintMaxLines: 1,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          enabledBorder: _border(AppColors.border, 1),
          focusedBorder: _border(AppColors.yellow, 1.5),
          border: _border(AppColors.border, 1),
        ),
      ),
    );
  }
}

/// The web's "×" .row-remove button: 40 × 46, muted, red tint when pressed, faded when
/// it is the only row left.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.semanticLabel, required this.onTap});

  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.dangerTint,
              highlightColor: AppColors.dangerTint,
              child: SizedBox(
                width: 40,
                height: 46,
                child: Center(
                  child: Text(
                    '×',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 22,
                      height: 1,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
