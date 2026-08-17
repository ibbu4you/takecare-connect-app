import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/models/site.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/tcif_logo.dart';

/// Everything that is not a tab of its own.
///
/// Laid out as grouped cards rather than one long divided list. A flat list of
/// fifteen identical rows is a menu you read; the same fifteen in labelled
/// cards is a menu you scan — and this screen is only ever visited on the way
/// somewhere else.
///
/// The two things people actually come here to do — take part, and check the
/// money — are lifted out of the list entirely and given tiles at the top,
/// because burying "Volunteer" as the ninth identical row is how it never gets
/// tapped.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('More'),
        actions: [
          IconButton(
            onPressed: () => context.push('${Routes.home}search'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(settings: settings),

          const _Group(
            label: 'Take part',
            children: [
              _Row(
                icon: Icons.volunteer_activism_outlined,
                label: 'Volunteer with us',
                subtitle: 'Field visits, events, and the stories in this app',
                path: '/volunteer',
              ),
              _Row(
                icon: Icons.school_outlined,
                label: 'Apply for an internship',
                subtitle: 'Placed in a department, alongside your studies',
                path: '/intern',
              ),
              _Row(
                icon: Icons.storefront_outlined,
                label: 'Register for an interview',
                subtitle: 'For craftsmen and small businesses',
                path: '/register-interview',
              ),
            ],
          ),

          const _Group(
            label: 'The foundation',
            children: [
              _Row(icon: Icons.info_outline_rounded, label: 'About us', path: '/about'),
              _Row(icon: Icons.groups_outlined, label: 'Our team', path: '/pages/team'),
              _Row(
                icon: Icons.description_outlined,
                label: 'Annual reports',
                path: '/pages/annual-reports',
              ),
              _Row(icon: Icons.mail_outline_rounded, label: 'Contact us', path: '/contact'),
            ],
          ),

          const _Group(
            label: 'Media',
            children: [
              _Row(icon: Icons.photo_library_outlined, label: 'Galleries', path: '/galleries'),
              _Row(icon: Icons.newspaper_outlined, label: 'In the press', path: '/press'),
            ],
          ),

          _Group(
            label: 'This app',
            children: [
              _Row(
                icon: Icons.ios_share_rounded,
                label: 'Tell someone about us',
                onTap: (context) {
                  final box = context.findRenderObject() as RenderBox?;

                  Share.share(
                    'Take Care International Foundation — stories, craftsmen and '
                    'campaigns from across India.\n${Api.site}',
                    sharePositionOrigin:
                        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                  );
                },
              ),
              _Row(
                icon: Icons.open_in_new_rounded,
                label: 'Open the website',
                external: true,
                onTap: (_) => launchUrl(
                  Uri.parse(Api.site),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),

          // The slugs are the ones in the pages table, not the ones the titles
          // suggest — "Terms of use" lives at `terms`.
          const _Group(
            label: 'Legal',
            children: [
              _Row(
                icon: Icons.shield_outlined,
                label: 'Privacy policy',
                path: '/pages/privacy-policy',
              ),
              _Row(icon: Icons.gavel_rounded, label: 'Terms of use', path: '/pages/terms'),
              _Row(
                icon: Icons.currency_rupee_rounded,
                label: 'Refund policy',
                path: '/pages/refund-policy',
              ),
            ],
          ),

          const SizedBox(height: 8),
          _Footer(settings: settings),
        ],
      ),
    );
  }
}

/// The logo, the tagline, and the two things worth doing from this screen.
class _Header extends StatelessWidget {
  const _Header({required this.settings});

  final SiteSettings? settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TcifLogo(size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings?.name ?? 'Take Care International Foundation',
                      style: AppText.title.copyWith(fontSize: 15, height: 1.25),
                    ),
                    if (settings != null && settings!.tagline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(settings!.tagline, style: AppText.meta),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two tiles, not two more rows. Giving and accountability are the
          // reasons somebody opens this tab; as rows nine and ten of a list
          // they read as admin.
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.favorite_rounded,
                  label: 'Donate',
                  caption: '80G receipt by email',
                  accent: true,
                  onTap: () => context.go(Routes.donate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Where it goes',
                  caption: 'Campaign by campaign',
                  onTap: () => context.push('${Routes.more}/transparency'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final foreground = accent ? AppColors.accentForeground : AppColors.foreground;

    return Material(
      color: accent ? AppColors.accentButton : AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: accent ? AppColors.accentButton : AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: accent ? foreground : AppColors.primary),
                const SizedBox(height: 10),
                Text(label, style: AppText.title.copyWith(fontSize: 15, color: foreground)),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: AppText.meta.copyWith(
                    color: accent ? const Color(0xCCFFFFFF) : AppColors.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled card of rows.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<_Row> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: AppText.meta.copyWith(fontSize: 11, letterSpacing: 1.1),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  // Inset to clear the icon column, so the rule reads as a
                  // separator between rows rather than a line across the card.
                  if (i > 0) const Divider(height: 1, indent: 54),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.path,
    this.onTap,
    this.external = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// A route under `/more`, which is where this tab's branch lives.
  final String? path;

  /// For rows that do something other than navigate.
  final void Function(BuildContext context)? onTap;

  final bool external;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) return onTap!(context);
        if (path != null) context.push('${Routes.more}$path');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // A tinted square rather than a bare glyph: it gives the column a
            // consistent optical width whatever the icon's own proportions,
            // which is what stops a list like this looking ragged.
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body.copyWith(fontSize: 15, height: 1.3)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle!,
                        style: AppText.meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
              size: external ? 15 : 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark band that closes the site, brought across.
class _Footer extends StatelessWidget {
  const _Footer({required this.settings});

  final SiteSettings? settings;

  static const _socialIcons = {
    'facebook': Icons.facebook_rounded,
    'instagram': Icons.camera_alt_outlined,
    'youtube': Icons.play_circle_outline_rounded,
    'linkedin': Icons.work_outline_rounded,
    'twitter': Icons.alternate_email_rounded,
    'x': Icons.alternate_email_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final site = settings;

    return Container(
      width: double.infinity,
      color: AppColors.footer,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // On a white disc: the badge is navy, and against the footer's
              // dark band it would otherwise all but disappear.
              const TcifLogo(size: 40, onDark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  site?.name ?? 'Take Care International Foundation',
                  style: AppText.title.copyWith(color: AppColors.footerForeground),
                ),
              ),
            ],
          ),
          if (site != null && site.footerDescription.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              site.footerDescription,
              style: AppText.excerpt.copyWith(color: AppColors.footerMuted, height: 1.6),
            ),
          ],

          if (site != null && site.credentials.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final credential in site.credentials)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.footerDeep,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Text(
                      credential,
                      style: AppText.meta.copyWith(color: AppColors.footerMuted, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],

          if (site != null && site.social.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                for (final entry in site.social.entries)
                  if (entry.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        onPressed: () => launchUrl(
                          Uri.parse(entry.value),
                          mode: LaunchMode.externalApplication,
                        ),
                        tooltip: entry.key,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.footerDeep,
                          foregroundColor: AppColors.footerForeground,
                          minimumSize: const Size(38, 38),
                        ),
                        icon: Icon(
                          _socialIcons[entry.key.toLowerCase()] ?? Icons.link_rounded,
                          size: 18,
                        ),
                      ),
                    ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          Text(
            '© ${DateTime.now().year} ${site?.name ?? 'Take Care International Foundation'}',
            style: AppText.meta.copyWith(color: AppColors.footerMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
