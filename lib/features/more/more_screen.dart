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
/// Ends with the website's footer, more or less verbatim — the registrations,
/// the contact details, the socials — because that block is what tells a
/// stranger this is a real, registered organisation.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _GroupLabel('The foundation'),
          _Item(
            icon: Icons.info_outline_rounded,
            label: 'About us',
            onTap: () => context.push('${Routes.more}/about'),
          ),
          _Item(
            icon: Icons.groups_outlined,
            label: 'Our team',
            onTap: () => context.push('${Routes.more}/pages/team'),
          ),
          _Item(
            icon: Icons.receipt_long_outlined,
            label: 'Where the money goes',
            subtitle: 'Every rupee, campaign by campaign',
            onTap: () => context.push('${Routes.more}/transparency'),
          ),
          _Item(
            icon: Icons.description_outlined,
            label: 'Annual reports',
            onTap: () => context.push('${Routes.more}/pages/annual-reports'),
          ),
          _Item(
            icon: Icons.mail_outline_rounded,
            label: 'Contact us',
            onTap: () => context.push('${Routes.more}/contact'),
          ),

          const _GroupLabel('Media'),
          _Item(
            icon: Icons.photo_library_outlined,
            label: 'Galleries',
            onTap: () => context.push('${Routes.more}/galleries'),
          ),
          _Item(
            icon: Icons.newspaper_outlined,
            label: 'In the press',
            onTap: () => context.push('${Routes.more}/press'),
          ),

          const _GroupLabel('Take part'),
          _Item(
            icon: Icons.volunteer_activism_outlined,
            label: 'Volunteer with us',
            subtitle: 'Field visits, events, and the stories in this app',
            onTap: () => context.push('${Routes.more}/volunteer'),
          ),
          _Item(
            icon: Icons.school_outlined,
            label: 'Apply for an internship',
            subtitle: 'Placed in a department, alongside your studies',
            onTap: () => context.push('${Routes.more}/intern'),
          ),
          _Item(
            icon: Icons.storefront_outlined,
            label: 'Register for an interview',
            subtitle: 'For craftsmen and small businesses',
            onTap: () => context.push('${Routes.more}/register-interview'),
          ),

          const _GroupLabel('This app'),
          _Item(
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: () => context.push('${Routes.home}search'),
          ),
          _Item(
            icon: Icons.ios_share_rounded,
            label: 'Tell someone about us',
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;

              Share.share(
                'Take Care International Foundation — stories, craftsmen and '
                'campaigns from across India.\n${Api.site}',
                sharePositionOrigin:
                    box == null ? null : box.localToGlobal(Offset.zero) & box.size,
              );
            },
          ),
          _Item(
            icon: Icons.open_in_new_rounded,
            label: 'Open the website',
            onTap: () => launchUrl(
              Uri.parse(Api.site),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const _GroupLabel('Legal'),
          _Item(
            icon: Icons.shield_outlined,
            label: 'Privacy policy',
            onTap: () => context.push('${Routes.more}/pages/privacy-policy'),
          ),
          // `terms`, not `terms-of-use`. These slugs are the ones in the pages
          // table, not the ones the page titles suggest — a mismatch is a dead
          // row in this menu and nothing but tool/live_api_check.dart notices.
          _Item(
            icon: Icons.gavel_rounded,
            label: 'Terms of use',
            onTap: () => context.push('${Routes.more}/pages/terms'),
          ),
          _Item(
            icon: Icons.currency_rupee_rounded,
            label: 'Refund policy',
            onTap: () => context.push('${Routes.more}/pages/refund-policy'),
          ),

          const SizedBox(height: 24),
          _Footer(settings: settings),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: AppText.meta.copyWith(fontSize: 11, letterSpacing: 1.2),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.body.copyWith(fontSize: 15, height: 1.3)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(subtitle!, style: AppText.meta),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 50),
      ],
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TcifLogo(size: 34, color: AppColors.footerForeground),
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
            const SizedBox(height: 12),
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
