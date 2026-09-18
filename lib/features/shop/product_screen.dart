library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/business.dart';
import '../../core/models/shop.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/ai_note.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/enquiry_sheet.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/shop_cards.dart';
import '../../core/widgets/state_views.dart';
import '../media/photo_viewer.dart';

/// One thing a maker makes.
///
/// **There is no Buy button on this screen, and there is no cart.** The
/// foundation takes no part in the sale and no money passes through this app: a
/// reader who wants the piece contacts whoever made it, and the two of them
/// settle it between themselves. Nothing here is "verified" or "certified"
/// either — that would turn a listing into a guarantee of somebody's goods,
/// which is not the foundation's to give. Every claim on the page is a fact:
/// what it is made of, how it is made, who made it, and how long they have been
/// with us.
class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          product.maybeWhen(
            data: (data) => ShareAction(path: '/shop/${data.slug}', title: data.name),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: product.when(
        loading: () => const LoadingView(height: 500),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productProvider(slug)),
        ),
        data: (data) => _Product(product: data),
      ),
      bottomNavigationBar: product.maybeWhen(
        data: (data) => _ContactBar(product: data),
        orElse: () => null,
      ),
    );
  }
}

class _Product extends StatelessWidget {
  const _Product({required this.product});

  final ShopProductDetail product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (product.images.isNotEmpty) _Gallery(images: product.images, name: product.name),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.category != null) ...[
                GestureDetector(
                  onTap: () => context.go(Routes.shopCategory(product.category!.slug)),
                  child: Pill.accent(product.category!.name),
                ),
                const SizedBox(height: 12),
              ],
              Text(product.name, style: AppText.h1.copyWith(fontSize: 25)),
              if (product.tagline != null && product.tagline!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  product.tagline!,
                  style: AppText.lead.copyWith(color: AppColors.mutedForeground),
                ),
              ],
              const SizedBox(height: 14),
              // Exactly as the server worded it — "₹450 / piece", a range, or
              // "Ask the maker" for something made to order.
              Text(
                product.priceLabel,
                style: AppText.figure.copyWith(fontSize: 22, color: AppColors.primary),
              ),
              if (product.images.any((image) => image.aiAssisted)) ...[
                const SizedBox(height: 14),
                const AiNote.sentence(),
              ],
              if (product.highlights.isNotEmpty) ...[
                const SizedBox(height: 18),
                for (final line in product.highlights) _Highlight(line),
              ],
              if (product.description != null && product.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                HtmlBody(product.description!),
              ],
            ],
          ),
        ),

        if (product.maker != null) ...[
          const SectionHeader(eyebrow: 'Who made it', title: 'The maker'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Maker(maker: product.maker!),
          ),
        ],

        if (product.hasDetails) ...[
          const SectionHeader(title: 'About this piece'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.materials != null && product.materials!.isNotEmpty)
                    _Spec(label: 'Materials', value: product.materials!),
                  if (product.howMade != null && product.howMade!.isNotEmpty)
                    _Spec(label: 'How it is made', value: product.howMade!),
                  if (product.whereToBuy != null && product.whereToBuy!.isNotEmpty)
                    _Spec(label: 'Where to buy', value: product.whereToBuy!),
                ],
              ),
            ),
          ),
        ],

        if (product.alsoBy.isNotEmpty) ...[
          SectionHeader(
            title: 'More from ${product.maker?.name ?? 'this maker'}',
            actionLabel: product.maker == null ? null : 'All',
            onAction: product.maker == null
                ? null
                : () => context.push(Routes.brand(product.maker!.slug)),
          ),
          SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: product.alsoBy.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final other = product.alsoBy[i];

                return ProductCard(
                  product: other,
                  width: 190,
                  onTap: () => context.push(Routes.product(other.slug)),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// The photographs, swipeable, with dots.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, required this.name});

  final List<Photo> images;
  final String name;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final image = widget.images[i];

                  return GestureDetector(
                    onTap: () => PhotoViewer.open(
                      context,
                      photos: widget.images,
                      initialIndex: i,
                    ),
                    child: AppImage(
                      url: image.url,
                      fit: BoxFit.cover,
                      semanticLabel: image.alt.isEmpty ? widget.name : image.alt,
                    ),
                  );
                },
              ),
              // On the picture itself, so it is clear which one was tidied up.
              if (widget.images[_index].aiAssisted)
                const Positioned(right: 12, top: 12, child: AiNote.badge()),
            ],
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _index ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The maker's card: their mark, their trade, and the facts we can stand behind.
class _Maker extends StatelessWidget {
  const _Maker({required this.maker});

  final ProductMaker maker;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.brand(maker.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (maker.logo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: AppImage(url: maker.logo, semanticLabel: maker.name),
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(maker.name, style: AppText.title, maxLines: 2),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (maker.ownerName != null && maker.ownerName != maker.name)
                          maker.ownerName!,
                        if (maker.city != null) maker.city!,
                      ].join('  ·  '),
                      style: AppText.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground),
            ],
          ),
          if (maker.blurb != null && maker.blurb!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(maker.blurb!, style: AppText.excerpt, maxLines: 3),
          ],
          // Facts, not badges of approval. "With us since 2021" is something
          // the foundation knows; "verified maker" is not.
          if (maker.sinceYear != null) ...[
            const SizedBox(height: 12),
            Pill('With us since ${maker.sinceYear}', icon: Icons.schedule_rounded, dense: true),
          ],
          if (maker.hasInterview) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.craftsman(maker.interviewSlug!)),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Read their interview'),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Ask about this" and "Call the maker", each only where it leads somewhere.
///
/// Both gated on the server's own answer. The website found out the hard way
/// that one flag for both puts a reveal in front of a maker with an email and
/// no phone: it took the buyer's details and had nothing to hand back.
class _ContactBar extends StatelessWidget {
  const _ContactBar({required this.product});

  final ShopProductDetail product;

  @override
  Widget build(BuildContext context) {
    final contact = product.maker?.contact;

    if (!product.canEnquire && !product.canCall) return const SizedBox.shrink();

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
              // WhatsApp only where they gave us a number for it. The link is
              // built server-side, already a wa.me URL — the app never has to
              // guess a country code.
              if (contact != null && contact.hasWhatsapp)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: OutlinedButton(
                    onPressed: () => launchUrl(
                      Uri.parse(contact.whatsapp!),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Icon(Icons.chat_outlined, size: 18),
                  ),
                ),
              if (product.canCall)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => EnquirySheet.forProduct(context, product),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Their number'),
                  ),
                ),
              if (product.canCall && product.canEnquire) const SizedBox(width: 10),
              if (product.canEnquire)
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => EnquirySheet.forProduct(context, product),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: const Text('Ask about this'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_rounded, size: 16, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 15))),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.eyebrow.copyWith(color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          HtmlBody(value),
        ],
      ),
    );
  }
}
