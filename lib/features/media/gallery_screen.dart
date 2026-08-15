import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/state_views.dart';
import 'photo_viewer.dart';

/// One gallery: a grid of photographs that open full-screen.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(gallery.valueOrNull?.title ?? 'Gallery', style: AppText.h3.copyWith(fontSize: 17)),
        actions: [
          gallery.maybeWhen(
            data: (data) => ShareAction(path: '/galleries/${data.slug}', title: data.title),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: gallery.when(
        loading: () => const LoadingView(height: 420),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(galleryProvider(slug)),
        ),
        data: (data) => _Gallery(gallery: data),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.gallery});

  final GalleryDetail gallery;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (gallery.location != null && gallery.location!.isNotEmpty) gallery.location!,
      if (gallery.dateLabel != null && gallery.dateLabel!.isNotEmpty) gallery.dateLabel!,
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gallery.title, style: AppText.h1.copyWith(fontSize: 24)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meta.join('  ·  '), style: AppText.meta),
                ],
                if (gallery.description != null && gallery.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  HtmlBody(gallery.description),
                ],
              ],
            ),
          ),
        ),
        if (gallery.photos.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyView(
              title: 'No photographs here yet',
              icon: Icons.photo_outlined,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: gallery.photos.length,
                (context, index) {
                  final photo = gallery.photos[index];

                  return GestureDetector(
                    onTap: () => PhotoViewer.open(
                      context,
                      photos: gallery.photos,
                      initialIndex: index,
                      title: gallery.title,
                    ),
                    // Hero would be nicer, but a grid of a hundred photographs
                    // with a hundred tags is a hundred layout passes on open.
                    child: AppImage(
                      url: photo.url,
                      radius: AppRadii.field,
                      semanticLabel: photo.alt,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
