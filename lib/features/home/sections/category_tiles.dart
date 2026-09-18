library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/home.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/category_colours.dart';
import '../../../core/widgets/app_image.dart';

/// The subjects the foundation writes about, as a grid of tiles.
///
/// Sits directly under the hero because it is the first question a reader has —
/// what is here? — and a list of subjects answers it better than another band
/// of prose.
///
/// Every category is offered, including one with nothing in it yet: an editor
/// who has made a category means to fill it, and a grid that silently drops it
/// looks broken from the admin side. What it does not do is print "0 stories",
/// which is worse than no line at all.
class CategoryTiles extends StatelessWidget {
  const CategoryTiles({super.key, required this.categories});

  final List<PostCategoryTile> categories;

  @override
  Widget build(BuildContext context) {
    final colours = CategoryColours.run([for (final c in categories) c.slug]);

    /*
     | The tile gets taller as the reader's font does.
     |
     | At 1.35 a two-line subject name and its count fit comfortably at the
     | normal font size, and overflowed by a few pixels at the largest one on a
     | 320pt phone — which Flutter paints as hazard stripes and carries on
     | from, so nothing failed and nothing logged. Dividing by the text scale
     | gives the words the room they actually asked for instead of guessing a
     | number that works for one setting.
     */
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final ratio = 1.35 / scale.clamp(1.0, 1.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) => _Tile(
          category: categories[i],
          colour: colours[i],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.category, required this.colour});

  final PostCategoryTile category;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final hasCover = category.image != null && category.image!.isNotEmpty;

    return Material
      (
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      color: colour,
      child: InkWell(
        onTap: () => context.go('${Routes.stories}?category=${category.slug}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCover)
              AppImage(url: category.image, fit: BoxFit.cover, semanticLabel: category.name),
            // A scrim over a photograph; nothing over a flat colour, which is
            // already dark enough for white text by construction.
            if (hasCover)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A0B1020), Color(0xCC0B1020)],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              // Flexible on the name as well as a taller tile: between them,
              // a long subject at a large font ellipsises rather than pushing
              // the count out of the bottom of the card.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      category.name,
                      style: AppText.title.copyWith(color: Colors.white, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (category.countLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category.countLabel!,
                      style: AppText.meta.copyWith(color: const Color(0xCCFFFFFF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
