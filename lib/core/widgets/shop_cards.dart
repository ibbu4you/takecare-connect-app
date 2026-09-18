library;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ai_note.dart';
import 'app_image.dart';
import 'cards.dart';
import 'pill.dart';

/// A product on a shelf.
///
/// There is no Buy button here, no cart and no quantity, and that is the
/// architecture rather than an omission: the foundation is not party to the
/// sale. A buyer reads about a piece and then contacts whoever made it.
///
/// The price is printed exactly as the server worded it — "₹450 / piece",
/// "₹400 – ₹900", or "Ask the maker" for something made to order. The app never
/// composes that string; see the note at the top of models/shop.dart.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.width});

  final ShopProduct product;
  final VoidCallback? onTap;

  /// Set on a home or brand rail; null makes it fill its grid cell.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppImage(
                url: product.thumbnail,
                aspectRatio: 4 / 3,
                semanticLabel: product.name,
              ),
              // Said on the picture itself, where somebody can see what was
              // tidied up.
              if (product.aiAssisted)
                const Positioned(right: 8, top: 8, child: AiNote.badge()),
            ],
          ),
          /*
           | Expanded, so both callers are safe.
           |
           | Every use of this card gives it a bounded height — a grid cell or
           | a fixed-height rail — and Expanded hands the text whatever is left
           | after the photograph. Without it, a name running one line longer
           | than whoever picked the height expected overflows, and so does the
           | whole shelf the moment a reader turns their font size up.
           */
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.category != null) ...[
                    Text(
                      product.category!.name.toUpperCase(),
                      style: AppText.eyebrow.copyWith(color: AppColors.accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Flexible(
                    child: Text(
                      product.name,
                      style: AppText.title.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.maker != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'by ${product.maker!.label}',
                      style: AppText.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    product.priceLabel,
                    style: AppText.bodyStrong.copyWith(fontSize: 14, color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

/// A maker in the directory.
///
/// Every line is a fact: their craft, their town, and how many things they
/// list. Nobody is verified and nobody is certified — that would turn a listing
/// into a guarantee of somebody's goods, which is not the foundation's to give.
class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.brand, this.onTap, this.width});

  final Brand brand;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final count = brand.productCount ?? 0;

    final card = AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url: brand.mark, aspectRatio: 4 / 3, semanticLabel: brand.name),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      brand.name,
                      style: AppText.title.copyWith(fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (brand.craft != null) brand.craft!.name,
                      if (brand.city != null) brand.city!.name,
                    ].join('  ·  '),
                    style: AppText.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (count > 0)
                    Pill('$count ${count == 1 ? 'item' : 'items'}', dense: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}
