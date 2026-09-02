import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/business.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/author_box.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/state_views.dart';
import '../media/photo_viewer.dart';
import 'enquiry_sheet.dart';

/// One craftsman: their interview, their workshop photographs, what they make,
/// and the two ways to reach them.
class CraftsmanScreen extends ConsumerWidget {
  const CraftsmanScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider(slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          business.maybeWhen(
            data: (data) => ShareAction(path: '/businesses/${data.slug}', title: data.name),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: business.when(
        loading: () => const LoadingView(height: 500),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(businessProvider(slug)),
        ),
        data: (data) => _Profile(business: data),
      ),
      bottomNavigationBar: business.maybeWhen(
        data: (data) => _EnquiryBar(business: data),
        orElse: () => null,
      ),
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.business});

  final BusinessDetail business;

  /// The intro and the interview as one document, so the package lays their
  /// margins out against each other instead of two widgets guessing.
  String get _article => [
        business.intro?.trim() ?? '',
        business.body?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join('\n');

  bool get _ownerWorthShowing {
    final owner = business.ownerName?.trim() ?? '';

    return owner.isNotEmpty && owner.toLowerCase() != business.name.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = business.gallery.isEmpty ? null : business.gallery.first;

    // Other makers in the same trade, from the directory's own provider.
    final related = ref.watch(
      businessesProvider((category: business.category?.slug, city: null, q: null)),
    );
    final more = related.items.where((b) => b.slug != business.slug).take(4).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (cover != null)
          GestureDetector(
            onTap: () => PhotoViewer.open(context, photos: business.gallery, initialIndex: 0),
            child: AppImage(
              url: cover.url,
              aspectRatio: 16 / 9,
              semanticLabel: cover.alt.isEmpty ? business.name : cover.alt,
            ),
          ),
        // Laid out as a story is: the taxonomy above the title, then the
        // title, then who wrote it, then a lead paragraph ruled off from the
        // body. A profile is an interview, and reads like one.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (business.category != null || business.city != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (business.category != null)
                      GestureDetector(
                        onTap: () => context.go(
                          '${Routes.craftsmen}?category=${business.category!.slug}',
                        ),
                        child: Pill(business.category!.name),
                      ),
                    if (business.city != null)
                      GestureDetector(
                        onTap: () => context.go('${Routes.craftsmen}?city=${business.city!.slug}'),
                        child: Pill(
                          business.city!.state == null
                              ? business.city!.name
                              : '${business.city!.name}, ${business.city!.state}',
                          icon: Icons.place_outlined,
                          background: AppColors.surface,
                          foreground: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(business.name, style: AppText.h1),
              // Only when it says something the title has not. Plenty of
              // records set the owner to the business name, and a subtitle
              // that repeats the heading word for word reads as a mistake.
              if (_ownerWorthShowing) ...[
                const SizedBox(height: 4),
                Text(business.ownerName!, style: AppText.body.copyWith(
                  color: AppColors.mutedForeground,
                )),
              ],
              if (business.author != null) ...[
                const SizedBox(height: 12),
                _Byline(business: business),
              ],
              // One article, at the same typography a story's body uses.
              //
              // A story's excerpt is a plain summary sentence, set in a muted
              // lead and ruled off from the body below it. An intro here is
              // not that: it is the opening of the interview, headings and
              // all. Setting it as a lead made its <h2> render grey and
              // undersized, and the rule under it cut the piece in half at an
              // arbitrary point. Joined, they read as one article, which is
              // what they are.
              if (_article.isNotEmpty) ...[
                const SizedBox(height: 16),
                HtmlBody(_article),
              ],
            ],
          ),
        ),

        if (business.products.isNotEmpty) ...[
          SectionHeader(
            eyebrow: 'What they make',
            title: business.products.length == 1
                ? 'Their work'
                : '${business.products.length} things they make',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final product in business.products) ...[
                  ProductCard(product: product),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],

        // The first photograph is already the cover, so the strip starts at the
        // second — otherwise it opens with the picture directly above it.
        if (business.gallery.length > 1) ...[
          const SectionHeader(title: 'The workshop'),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: business.gallery.length - 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final photo = business.gallery[i + 1];

                return GestureDetector(
                  onTap: () => PhotoViewer.open(
                    context,
                    photos: business.gallery,
                    initialIndex: i + 1,
                  ),
                  child: SizedBox(
                    width: 200,
                    child: AppImage(
                      url: photo.url,
                      radius: AppRadii.field,
                      semanticLabel: photo.alt,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        if (business.faqs.isNotEmpty) ...[
          const SectionHeader(title: 'Questions people ask'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final faq in business.faqs)
                  Theme(
                    // The default expansion tile paints its own divider lines,
                    // which double up with the card border below.
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      shape: const Border(bottom: BorderSide(color: AppColors.border)),
                      collapsedShape: const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                      title: Text(faq.question, style: AppText.title.copyWith(fontSize: 15)),
                      children: [HtmlBody(faq.answer)],
                    ),
                  ),
              ],
            ),
          ),
        ],

        // Share, then the author, in the order a story ends. This replaces a
        // one-line "Interviewed by X · date" credit: the date has moved up to
        // the byline where a story keeps it, and the name was already there,
        // so the line had nothing left to say that the top of the page had not
        // said better.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: ShareBar(path: '/businesses/${business.slug}', title: business.name),
        ),
        if (business.author?.slug != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: AuthorBox(slug: business.author!.slug!),
          ),

        if (more.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionDivider(),
          SectionHeader(
            title: 'Others in this trade',
            actionLabel: 'All',
            onAction: () => context.go(Routes.craftsmen),
          ),
          // A column of full cards, as a story closes with. The rail this
          // replaces was a horizontal strip fixed at 264px, and a tile that
          // did not fill that height simply left the difference empty under
          // itself — visible as a band of nothing across the bottom of the
          // page. A column takes the height its contents need.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final other in more) ...[
                  BusinessCard(
                    business: other,
                    // replace, not push, for the reason the stories do it:
                    // otherwise reading four profiles in a row leaves four
                    // screens on the stack to walk back through.
                    onTap: () => context.replace(Routes.craftsman(other.slug)),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
      ],
    );
  }
}

/// Who reported the interview, laid out as a story's byline is.
///
/// Only the name. A story puts its date and reading time under the author, and
/// a profile has neither — the trade and the town are already chips directly
/// above, and repeating them here read as a stutter.
class _Byline extends StatelessWidget {
  const _Byline({required this.business});

  final BusinessDetail business;

  @override
  Widget build(BuildContext context) {
    final author = business.author!;

    final date = Fmt.date(business.publishedAt);

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surface,
          child: Text(
            author.name.trim().isEmpty ? '?' : author.name.trim()[0].toUpperCase(),
            style: AppText.metaStrong.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: author.slug == null
                    ? null
                    : () => context.push(Routes.author(author.slug!)),
                child: Text(
                  author.name,
                  style: AppText.metaStrong.copyWith(
                    fontSize: 13,
                    color: author.slug == null ? AppColors.foreground : AppColors.primary,
                  ),
                ),
              ),
              // Where a story prints its date and reading time. There is no
              // reading time for a profile, so the date stands alone.
              if (date.isNotEmpty) Text(date, style: AppText.meta),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single thing the craftsman makes.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  String get _price {
    if (!product.hasPrice) return '';

    final min = product.priceMin;
    final max = product.priceMax;

    if (min != null && max != null && min != max) {
      return '${Fmt.money(min, currency: product.currency)} – ${Fmt.money(max, currency: product.currency)}';
    }

    return Fmt.money((min ?? max)!, currency: product.currency);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.image != null)
            AppImage(url: product.image, aspectRatio: 4 / 3, semanticLabel: product.name),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppText.h3.copyWith(fontSize: 17)),
                if (product.hasPrice) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(_price, style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
                      const SizedBox(width: 6),
                      Text('MRP', style: AppText.meta.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
                if (product.description != null && product.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(product.description!, style: AppText.body.copyWith(fontSize: 15)),
                ],
                if (product.hasDetails) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (product.materials != null && product.materials!.isNotEmpty)
                    _Spec(label: 'Materials', value: product.materials!),
                  if (product.howMade != null && product.howMade!.isNotEmpty)
                    _Spec(label: 'How it is made', value: product.howMade!),
                  if (product.whereToBuy != null && product.whereToBuy!.isNotEmpty)
                    _Spec(label: 'Where to buy', value: product.whereToBuy!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.meta.copyWith(fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value, style: AppText.body.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}


/// The bar pinned to the bottom of the interview.
///
/// What it offers depends on what actually exists. Almost no imported craftsman
/// has a phone number stored — the old WordPress "View Number" button opened a
/// form asking the *reader* for theirs — so the common case is a written
/// enquiry the office passes on, and "Call" only appears when there is genuinely
/// a number to call.
class _EnquiryBar extends StatelessWidget {
  const _EnquiryBar({required this.business});

  final BusinessDetail business;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (business.contact.hasPhone)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:${business.contact.phone}')),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              if (business.contact.hasPhone) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => EnquirySheet.open(context, business: business),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Send an enquiry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
