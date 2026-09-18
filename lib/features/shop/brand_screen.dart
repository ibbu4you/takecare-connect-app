library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/shop.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/shop_cards.dart';
import '../../core/widgets/state_views.dart';

/// One maker, and their whole shelf.
///
/// **What this screen does not claim**: nobody is verified, nobody is a
/// certified craftsman, and there are no secure payments. The first two would
/// turn a listing into a guarantee of somebody's goods, which is the claim the
/// foundation's own membership certificate is tested for not making. The third
/// would be false — no money passes between a buyer and a maker anywhere in
/// this app. Every badge below is a fact: their craft, their town, how many
/// things they list, how long they have been with us, and whether we published
/// an interview with them.
class BrandScreen extends ConsumerWidget {
  const BrandScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandProvider(slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          brand.maybeWhen(
            data: (data) => ShareAction(path: '/brands/${data.slug}', title: data.name),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: brand.when(
        loading: () => const LoadingView(height: 500),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(brandProvider(slug)),
        ),
        data: (data) => _Brand(brand: data),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final count = brand.productCount ?? brand.products.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (brand.banner != null)
          AppImage(url: brand.banner, aspectRatio: 16 / 9, semanticLabel: brand.name),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.logo != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.small),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: AppImage(url: brand.logo, semanticLabel: brand.name),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(brand.name, style: AppText.h1.copyWith(fontSize: 24)),
                        if (brand.ownerName != null &&
                            brand.ownerName!.isNotEmpty &&
                            brand.ownerName != brand.name) ...[
                          const SizedBox(height: 4),
                          Text(
                            brand.ownerName!,
                            style: AppText.body.copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Facts only. Each one is something the foundation knows.
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (brand.craft != null)
                    GestureDetector(
                      onTap: () => context.go(Routes.shopCategory(brand.craft!.slug)),
                      child: Pill(brand.craft!.name),
                    ),
                  if (brand.city != null)
                    Pill(
                      brand.city!.state == null
                          ? brand.city!.name
                          : '${brand.city!.name}, ${brand.city!.state}',
                      icon: Icons.place_outlined,
                      background: AppColors.surface,
                      foreground: AppColors.mutedForeground,
                    ),
                  if (count > 0)
                    Pill(
                      '$count ${count == 1 ? 'thing' : 'things'} listed',
                      background: AppColors.surface,
                      foreground: AppColors.mutedForeground,
                    ),
                  if (brand.sinceYear != null)
                    Pill(
                      'With us since ${brand.sinceYear}',
                      icon: Icons.schedule_rounded,
                      background: AppColors.surface,
                      foreground: AppColors.mutedForeground,
                    ),
                ],
              ),

              if (brand.blurb != null && brand.blurb!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(brand.blurb!, style: AppText.body.copyWith(fontSize: 15)),
              ],

              const SizedBox(height: 16),
              _Contact(brand: brand),

              if (brand.hasInterview) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(Routes.craftsman(brand.interviewSlug!)),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Read their interview'),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (brand.products.isNotEmpty) ...[
          const SectionHeader(eyebrow: 'On their shelf', title: 'What they make'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: brand.products.length,
              itemBuilder: (context, i) {
                final product = brand.products[i];

                return ProductCard(
                  product: product,
                  onTap: () => context.push(Routes.product(product.slug)),
                );
              },
            ),
          ),
        ] else ...[
          const SizedBox(height: 24),
          const EmptyView(
            title: 'Nothing listed just now',
            subtitle: 'Get in touch with them directly — they may be making to order.',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ],
    );
  }
}

/// WhatsApp, a phone call and an email — each shown only where the maker gave
/// us one.
///
/// Given plainly rather than behind a lead form, and the difference from the
/// interview page is deliberate: that page is journalism and the number on it
/// was collected for an article. This is a shop belonging to somebody paying to
/// be listed, whose whole reason for being here is that people contact them.
class _Contact extends StatelessWidget {
  const _Contact({required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final contact = brand.contact;

    if (!contact.hasAny) {
      return Text(
        'We have no contact details for this maker yet.',
        style: AppText.meta,
      );
    }

    return Row(
      children: [
        if (contact.hasWhatsapp)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(contact.whatsapp!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
            ),
          ),
        if (contact.hasWhatsapp && contact.hasPhone) const SizedBox(width: 10),
        if (contact.hasPhone)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
              icon: const Icon(Icons.call_outlined, size: 18),
              label: const Text('Call'),
            ),
          ),
        if (!contact.hasPhone && !contact.hasWhatsapp && contact.hasEmail)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse('mailto:${contact.email}')),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Email them'),
            ),
          ),
      ],
    );
  }
}
