import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'savory_icon.dart';

/// Logged-in layout with the Figma "Bottom navigation" (My kitchen, Explore, Saved, Account).
/// Each tab keeps its own navigation stack (GoRouter StatefulShellRoute).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (SavoryIcons.navKitchen, 'My kitchen'),
    (SavoryIcons.navExplore, 'Explore'),
    (SavoryIcons.navSaved, 'Saved'),
    (SavoryIcons.navAccount, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: navigationShell.currentIndex == i,
                    // Tapping the current tab again returns to its first screen.
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SavoryIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.yellow : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPageButton),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SavoryIcon(icon),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: selected
                        ? AppTextStyles.navLabelActive
                        : AppTextStyles.navLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
