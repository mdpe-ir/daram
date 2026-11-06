import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/localization/fa_strings.dart';
import 'theme/daram_colors.dart';

/// The four-section bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: colors.navBar,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : colors.shadow,
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: LucideIcons.sparkles,
                  label: FaStrings.navChat,
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => _go(0),
                ),
                _NavItem(
                  icon: LucideIcons.chartPie,
                  label: FaStrings.navDashboard,
                  selected: navigationShell.currentIndex == 1,
                  onTap: () => _go(1),
                ),
                _NavItem(
                  icon: LucideIcons.receiptText,
                  label: 'اطلاعات',
                  selected: navigationShell.currentIndex == 2,
                  onTap: () => _go(2),
                ),
                _NavItem(
                  icon: LucideIcons.settings,
                  label: FaStrings.navSettings,
                  selected: navigationShell.currentIndex == 3,
                  onTap: () => _go(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
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

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? colors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? colors.accent : colors.textMuted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? colors.accent : colors.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10.5,
                    ),
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
