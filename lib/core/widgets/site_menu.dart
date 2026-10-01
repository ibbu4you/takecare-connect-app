library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/navigation.dart';
import '../router/route_names.dart';
import '../router/web_paths.dart';
import '../state/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'tcif_logo.dart';

/// The website's menu, behind the ☰ in the app bar.
///
/// The website's header on a phone is the logo, a red Donate button and a ☰
/// that opens its menu — Our Programs, Shop, Brands, Influencing Narratives,
/// Join our community, News and Media, Reach Us, About Us — with the dropdowns
/// as lists that open in place. This is that menu, drawn from `/navigation`,
/// which is the same tree the website's header reads. So it is the website's
/// menu by construction, and editing it in the admin edits both.
///
/// Opens in place rather than flying out, as the website's phone menu does: a
/// flyout on a 390pt screen has nowhere to fly to.
class SiteMenu extends ConsumerWidget {
  const SiteMenu({super.key, required this.host});

  /// The screen the menu was opened from. Links are followed through it, not
  /// through the menu's own context, which is gone once the menu closes.
  final BuildContext host;

  void _follow(BuildContext context, String? url) {
    Navigator.of(context).pop();

    if (url == null || url.isEmpty) return;

    openWebPath(host, url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(navigationProvider);

    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.sizeOf(context).width * 0.88,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const TcifLogo(size: 40),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close menu',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            Expanded(
              child: menu.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _Unavailable(onRetry: () => ref.invalidate(navigationProvider)),
                data: (items) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Search lived in the app bar, where the website has the
                    // ☰ instead. It moves here rather than being lost.
                    _SearchRow(
                      onTap: () {
                        Navigator.of(context).pop();
                        host.push(Routes.search);
                      },
                    ),
                    const SizedBox(height: 4),
                    for (final item in items)
                      _MenuEntry(item: item, depth: 0, onFollow: (url) => _follow(context, url)),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  host.push(Routes.donate);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentButton,
                  foregroundColor: AppColors.accentForeground,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                ),
                child: Text('Donate', style: AppText.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: AppColors.mutedForeground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search stories, makers and products',
                  style: AppText.meta.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the menu: a link, or a heading whose list opens beneath it.
class _MenuEntry extends StatefulWidget {
  const _MenuEntry({required this.item, required this.depth, required this.onFollow});

  final NavItem item;

  /// 0 for the top level, 1 inside a list, 2 inside a list inside a list.
  final int depth;

  final void Function(String? url) onFollow;

  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final top = widget.depth == 0;

    final labelStyle = top
        ? AppText.bodyStrong.copyWith(fontSize: 16)
        : AppText.body.copyWith(fontSize: 14, color: AppColors.foreground);

    final indent = top ? 4.0 : 16.0;

    if (!item.hasChildren) {
      return _Row(
        indent: indent,
        divided: top,
        onTap: () => widget.onFollow(item.url),
        child: Row(
          children: [
            Expanded(child: Text(item.label, style: labelStyle)),
            // Another website — Pride of Humanity — says so before it opens.
            if (item.external)
              const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.mutedForeground),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          indent: indent,
          divided: top && !_open,
          onTap: () => setState(() => _open = !_open),
          child: Semantics(
            expanded: _open,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: _open ? labelStyle.copyWith(color: AppColors.primary) : labelStyle,
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: _open ? AppColors.primary : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: EdgeInsets.only(left: top ? 4 : 16, bottom: top ? 8 : 4),
            // The guide line down the side of a list, as the website draws it.
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A heading that is also a page — Influencing Narratives is
                // /blog — gets its own row, because tapping it opens the list.
                if (item.url != null)
                  _Row(
                    indent: 16,
                    onTap: () => widget.onFollow(item.url),
                    child: Text(
                      '${item.label} overview',
                      style: AppText.bodyStrong.copyWith(fontSize: 14, color: AppColors.primary),
                    ),
                  ),
                for (final child in item.children)
                  _MenuEntry(item: child, depth: widget.depth + 1, onFollow: widget.onFollow),
              ],
            ),
          ),
        if (top && _open) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.child,
    required this.onTap,
    required this.indent,
    this.divided = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final double indent;

  /// The hairline under a top-level row, as on the website's phone menu.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.fromLTRB(indent, 10, 4, 10),
        alignment: Alignment.centerLeft,
        decoration: divided
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              )
            : null,
        child: child,
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The menu could not be loaded. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppText.excerpt,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('Try again', style: AppText.button)),
          ],
        ),
      ),
    );
  }
}
