import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Figma "Pagination": ← 1 2 3 … 8 →, 40x44 buttons, current page filled ink.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  /// Up to 7 slots: first, last, the current page and its neighbours, with gaps as null.
  static List<int?> slots(int page, int total) {
    if (total <= 5) return [for (var i = 1; i <= total; i++) i];
    final pages = <int>{
      1,
      total,
      page - 1,
      page,
      page + 1,
    }.where((p) => p >= 1 && p <= total).toList()..sort();
    final result = <int?>[];
    for (final p in pages) {
      if (result.isNotEmpty && p - (result.last ?? p) > 1) result.add(null);
      result.add(p);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _PageButton(
          label: '←',
          semanticLabel: 'Previous page',
          onTap: page > 1 ? () => onPage(page - 1) : null,
        ),
        for (final slot in slots(page, totalPages))
          slot == null
              ? const _PageButton(label: '…', semanticLabel: 'More pages')
              : _PageButton(
                  label: '$slot',
                  semanticLabel: 'Page $slot',
                  selected: slot == page,
                  onTap: slot == page ? null : () => onPage(slot),
                ),
        _PageButton(
          label: '→',
          semanticLabel: 'Next page',
          onTap: page < totalPages ? () => onPage(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.semanticLabel,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: selected ? AppColors.ink : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPageButton),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: AppSpacing.tapTarget,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: AppTextStyles.pageLabel.copyWith(
                    color: selected ? AppColors.surface : AppColors.ink,
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
