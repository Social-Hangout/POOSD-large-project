import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/mealdb_credit.dart';
import '../../../recipes/domain/recipe.dart';
import '../../../recipes/presentation/widgets/pagination_bar.dart';
import '../../../recipes/presentation/widgets/recipe_card.dart';
import '../../../recipes/presentation/widgets/recipe_card_skeleton.dart';
import '../../../recipes/presentation/widgets/recipe_state_card.dart';
import '../controllers/kitchen_controller.dart';
import '../widgets/ingredient_input_card.dart';

/// My kitchen. Layout: Figma 06. Ingredients pop up as chips as they're added (Enter, the
/// "+" button, or typing a comma), and "Recipes you can make" lists the recipes that use
/// the most of them, from GET /api/recipes/search, in the order the API returns them.
/// Left out because the API can't back them: the recipe count, time and servings,
/// "Fine-tune" filters, the heart (no saved recipes) and the mic (no speech input).
class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _input.addListener(_addOnComma);
  }

  @override
  void dispose() {
    _input.removeListener(_addOnComma);
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Typing a comma adds everything before it, so ingredients pop up as you go.
  void _addOnComma() {
    final text = _input.text;
    final lastComma = text.lastIndexOf(',');
    if (lastComma < 0) return;
    final before = text.substring(0, lastComma);
    final added = _addText(before);
    // Nothing added (a duplicate, say): keep the text, without the comma, to fix it.
    _setField(added ? text.substring(lastComma + 1).trimLeft() : before);
  }

  void _addFromField() {
    if (_addText(_input.text)) _input.clear();
    _focus.requestFocus();
  }

  /// Returns whether anything was added; shows why if something couldn't be.
  bool _addText(String text) {
    final count = ref.read(kitchenControllerProvider).ingredients.items.length;
    final error = text.trim().isEmpty
        ? null
        : ref.read(kitchenControllerProvider.notifier).add(text);
    setState(() => _error = error);
    return ref.read(kitchenControllerProvider).ingredients.items.length !=
        count;
  }

  void _setField(String text) => _input.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  void _remove(String item) {
    ref.read(kitchenControllerProvider.notifier).remove(item);
    setState(() => _error = null);
  }

  void _clear() {
    ref.read(kitchenControllerProvider.notifier).clear();
    setState(() => _error = null);
  }

  void _open(Recipe recipe) =>
      context.go(AppRoutes.kitchenRecipe(recipe.id), extra: recipe);

  List<Widget> _results(KitchenState state) {
    if (state.ingredients.isEmpty) {
      return const [
        RecipeStateCard(
          heading: 'Add what you have to get started.',
          message: 'Recipes that use the most of your ingredients show up here first.',
        ),
      ];
    }

    return ref
        .watch(kitchenResultsProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => [
            for (var i = 0; i < 3; i++) const RecipeCardSkeleton(),
          ],
          error: (error, _) => [
            RecipeStateCard(
              heading: error is ApiException
                  ? error.message
                  : 'Could not load recipes.',
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(kitchenResultsProvider),
            ),
          ],
          data: (page) {
            if (page == null) return const <Widget>[];
            if (page.isEmpty) {
              return const [
                RecipeStateCard(
                  heading: 'No matches just yet.',
                  message: 'Try another ingredient, or remove one.',
                ),
              ];
            }
            return [
              for (final entry in page.items)
                RecipeCard(entry: entry, onOpen: () => _open(entry.recipe)),
              PaginationBar(
                page: page.page,
                totalPages: page.totalPages,
                onPage: ref.read(kitchenControllerProvider.notifier).goToPage,
              ),
            ];
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenControllerProvider);
    final results = _results(state);

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (state.ingredients.isNotEmpty) {
                await ref.refresh(kitchenResultsProvider.future);
              }
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenX,
                AppSpacing.screenTop,
                AppSpacing.screenX,
                AppSpacing.screenBottom,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    "What's in your kitchen?",
                    style: AppTextStyles.display,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tell us what you have and we'll find recipes you can make "
                  'right now.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.section),
                IngredientInputCard(
                  ingredients: state.ingredients,
                  controller: _input,
                  focusNode: _focus,
                  error: _error,
                  onAdd: _addFromField,
                  onRemove: _remove,
                  onClear: _clear,
                ),
                const SizedBox(height: AppSpacing.section),
                EyebrowHeading(
                  eyebrow: 'Made for you',
                  heading: 'Recipes you can make',
                  headingStyle: AppTextStyles.sectionHeading,
                  gap: 10,
                ),
                for (final item in results) ...[
                  const SizedBox(height: AppSpacing.section),
                  item,
                ],
                const SizedBox(height: AppSpacing.section),
                const MealDbCredit(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
