library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/repository.dart';
import '../../../core/models/home.dart';
import '../../../core/models/navigation.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/web_paths.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/tcif_logo.dart';

/*
 | The foot of the website's landing page: the banner the office sets above
 | the footer, and the footer itself — FooterBanner.tsx and SiteFooter.tsx,
 | as they stack on a phone.
 */

/// The strip above the footer, from Content → Hero banners ("before footer").
///
/// A designed banner, whose words are in the artwork, is shown at its own
/// shape and never cropped — the website stopped cropping it after the bottom
/// of the first one uploaded went missing. Anything else is a navy band with
/// its words and buttons.
class FooterBannerBand extends StatelessWidget {
  const FooterBannerBand({super.key, required this.banner});

  final BannerSlide banner;

  @override
  Widget build(BuildContext context) {
    if (banner.isImageOnly) {
      final picture = AppImage(
        url: banner.bestImage,
        fit: BoxFit.fitWidth,
        semanticLabel: banner.semanticLabel,
      );

      return ColoredBox(
        color: AppColors.primary,
        child: banner.hasCta
            ? InkWell(onTap: () => openWebPath(context, banner.ctaUrl), child: picture)
            : picture,
      );
    }

    return ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banner.eyebrow?.isNotEmpty ?? false) ...[
              Text(banner.eyebrow!.toUpperCase(), style: AppText.eyebrow),
              const SizedBox(height: 10),
            ],
            if (banner.title?.isNotEmpty ?? false)
              Text(banner.title!, style: AppText.h2.copyWith(color: AppColors.primaryForeground)),
            if (banner.subtitle?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                banner.subtitle!,
                style: AppText.body.copyWith(
                  color: AppColors.primaryForeground.withValues(alpha: 0.8),
                ),
              ),
            ],
            if (banner.hasCta) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => openWebPath(context, banner.ctaUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(banner.ctaLabel!, style: AppText.button),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The website's footer: who the foundation is and its registration ticks,
/// then Explore, Get involved and Contact us, then the bottom bar.
///
/// Every part of it comes from the website — the words from Settings, the link
/// columns from the same footer menus the website draws — so it changes when
/// the office changes them. Each part leaves itself out until it has loaded.
class SiteFooterBand extends ConsumerWidget {
  const SiteFooterBand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(settingsProvider).valueOrNull;
    final explore = ref.watch(footerMenuProvider('footer')).valueOrNull ?? const <NavItem>[];
    final involved =
        ref.watch(footerMenuProvider('footer_secondary')).valueOrNull ?? const <NavItem>[];
    final legal = ref.watch(footerMenuProvider('legal')).valueOrNull ?? const <NavItem>[];

    final name = (site?.name.isNotEmpty ?? false) ? site!.name : 'Take Care International Foundation';
    final muted = AppText.body.copyWith(fontSize: 14, color: AppColors.footerMuted, height: 1.6);

    return ColoredBox(
      color: AppColors.footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const TcifLogo(size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: AppText.h3.copyWith(color: AppColors.footerForeground),
                      ),
                    ),
                  ],
                ),
                if (site?.footerDescription.isNotEmpty ?? false) ...[
                  const SizedBox(height: 22),
                  Text(site!.footerDescription, style: muted),
                ],
                if (site?.credentials.isNotEmpty ?? false) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 22,
                    runSpacing: 10,
                    children: [
                      for (final credential in site!.credentials)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            // Flexible, so a long one wraps on a narrow phone
                            // at a large font instead of running off the edge.
                            Flexible(child: Text(credential, style: muted)),
                          ],
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                if (explore.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _Column(heading: 'Explore', items: explore),
                ],
                if (involved.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _Column(heading: 'Get involved', items: involved),
                ],
                if (site != null) ...[
                  const SizedBox(height: 32),
                  const _Heading('Contact us'),
                  const SizedBox(height: 18),
                  if (site.address.isNotEmpty)
                    _ContactRow(
                      icon: Icons.location_on_outlined,
                      text: site.address,
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(site.address)}',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  if (site.phone.isNotEmpty)
                    _ContactRow(
                      icon: Icons.phone_outlined,
                      text: site.phone,
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: site.phone.replaceAll(' ', ''))),
                    ),
                  if (site.email.isNotEmpty)
                    _ContactRow(
                      icon: Icons.mail_outline_rounded,
                      text: site.email,
                      onTap: () => launchUrl(Uri(scheme: 'mailto', path: site.email)),
                    ),
                  if (site.openingDays.isNotEmpty)
                    _ContactRow(icon: Icons.schedule_rounded, text: site.openingDays),
                ],
                const SizedBox(height: 32),
                const _Heading('Support our work'),
                const SizedBox(height: 14),
                Text(
                  'Every rupee funds equipment for a small business — a loom, a kiln, a '
                  'treatment tank.',
                  style: muted,
                ),
                const SizedBox(height: 18),
                // Two doors, as on the website: give, or sell through us.
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => context.push(Routes.donate),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                      ),
                      child: Text('Donate', style: AppText.button.copyWith(fontSize: 14)),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.sellWithUs),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.footerForeground,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                      ),
                      child: Text('Apply as Vendor', style: AppText.button.copyWith(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const _FooterSignup(),
              ],
            ),
          ),
          ColoredBox(
            color: AppColors.footerDeep,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} $name. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      // The seller panel is a website, not an app screen.
                      _BarLink(
                        icon: Icons.storefront_outlined,
                        label: 'Vendor login',
                        onTap: () => openWebPath(context, '/seller'),
                      ),
                      _BarLink(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Back to top',
                        onTap: () => Scrollable.maybeOf(context)?.position.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                    ],
                  ),
                  if (legal.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        for (final item in legal)
                          if (item.url != null)
                            InkWell(
                              onTap: () => openWebPath(context, item.url),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(item.label, style: muted),
                              ),
                            ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.eyebrow.copyWith(color: AppColors.footerForeground, fontSize: 13),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.heading, required this.items});

  final String heading;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(heading),
        const SizedBox(height: 14),
        for (final item in items)
          if (item.url != null)
            InkWell(
              onTap: () => openWebPath(context, item.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  item.label,
                  style: AppText.body.copyWith(fontSize: 14, color: AppColors.footerMuted),
                ),
              ),
            ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.footerMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppText.body.copyWith(fontSize: 14, color: AppColors.footerMuted, height: 1.5),
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _BarLink extends StatelessWidget {
  const _BarLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.footerMuted),
            const SizedBox(width: 6),
            Text(label, style: AppText.body.copyWith(fontSize: 14, color: AppColors.footerMuted)),
          ],
        ),
      ),
    );
  }
}

/// "Get the latest stories", the website footer's signup, in its dark style.
///
/// The same `/newsletter` call as the signup on More, so a reader is added
/// once whichever one they use.
class _FooterSignup extends ConsumerStatefulWidget {
  const _FooterSignup();

  @override
  ConsumerState<_FooterSignup> createState() => _FooterSignupState();
}

class _FooterSignupState extends ConsumerState<_FooterSignup> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _busy = false;
  String? _confirmation;
  String? _serverError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _serverError = null;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      final message =
          await ref.read(repositoryProvider).subscribeToNewsletter(email: _email.text.trim());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _confirmation = message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = e.errors?['email']?.first;
      });
      _formKey.currentState!.validate();
      if (!e.isValidation) AppSnack.error(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnack.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppText.body.copyWith(fontSize: 14, color: AppColors.footerMuted);

    if (_confirmation != null) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.footerForeground),
          const SizedBox(width: 10),
          Expanded(child: Text(_confirmation!, style: muted)),
        ],
      );
    }

    OutlineInputBorder edge(Color colour) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: colour),
        );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Get the latest stories',
            style: AppText.bodyStrong.copyWith(fontSize: 14, color: AppColors.footerForeground),
          ),
          const SizedBox(height: 4),
          Text('We email when a new story goes out. Nothing else.', style: muted),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: AppText.body.copyWith(fontSize: 14, color: AppColors.footerForeground),
            validator: (value) => _serverError ?? Validate.email(value),
            decoration: InputDecoration(
              hintText: 'Your email address',
              hintStyle: muted,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: edge(Colors.white.withValues(alpha: 0.15)),
              focusedBorder: edge(AppColors.footerForeground),
              errorBorder: edge(AppColors.accent),
              focusedErrorBorder: edge(AppColors.accent),
              errorStyle: AppText.meta.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.footerForeground,
              foregroundColor: AppColors.footer,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.footer),
                  )
                : Text('Subscribe', style: AppText.button.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
