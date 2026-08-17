import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The five-tab frame the whole app sits in.
///
/// Built on `StatefulShellRoute`, which keeps a separate navigator — and so a
/// separate scroll position and history — per tab. Leaving the Stories tab
/// three articles deep and coming back to find it on the index would be an app
/// that forgets what you were reading.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Destination>[
    _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Destination(Icons.article_outlined, Icons.article_rounded, 'Stories'),
    _Destination(Icons.handshake_outlined, Icons.handshake_rounded, 'Craftsmen'),
    _Destination(Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Give'),
    _Destination(Icons.menu_rounded, Icons.menu_rounded, 'More'),
  ];

  void _onTap(int index) {
    // Tapping the tab you are already on pops it back to its root — the
    // standard gesture for "take me back to the top of this section".
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      // Give is the donate tab, so its active state is the one
                      // place in the navigation the accent red is spent.
                      accent: i == 3,
                      selected: i == index,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final _Destination destination;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = accent ? AppColors.accent : AppColors.primary;
    final colour = selected ? active : AppColors.mutedForeground;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // min + Flexible, because the bar's height is fixed and the label's
          // is not. At the largest font size the app allows, on the narrowest
          // phone, this column was four pixels taller than the bar.
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? destination.activeIcon : destination.icon, size: 22, color: colour),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.meta.copyWith(
                  color: colour,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
