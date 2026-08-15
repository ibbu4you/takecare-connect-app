import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/business.dart' show Photo;
import '../../core/models/media.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import 'photo_viewer.dart';

/// Press coverage, grouped the way the server groups it: newspaper cuttings,
/// television, and online write-ups.
class PressScreen extends ConsumerWidget {
  const PressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final press = ref.watch(pressProvider);

    return Scaffold(
      appBar: screenBar('In the press'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(pressProvider.future),
        child: press.when(
          loading: () => const LoadingView(height: 420),
          error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(pressProvider)),
          data: (sections) {
            final live = sections.where((s) => s.items.isNotEmpty).toList();

            if (live.isEmpty) {
              return const EmptyView(
                title: 'No coverage listed yet',
                icon: Icons.newspaper_outlined,
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                for (final section in live) ...[
                  SectionHeader(
                    title: section.label.isEmpty ? section.kind.label : section.label,
                    description: section.description.isEmpty ? null : section.description,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final item in section.items) ...[
                          _PressCard(item: item),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PressCard extends StatelessWidget {
  const _PressCard({required this.item});

  final PressItem item;

  /// A cutting opens full-screen so it can be read; a video or a write-up
  /// opens where it lives, which is off in the browser or YouTube.
  Future<void> _open(BuildContext context) async {
    if (item.kind == PressKind.photo) {
      final url = item.fullImage ?? item.image;
      if (url == null) return;

      return PhotoViewer.open(
        context,
        photos: [Photo(url: url, alt: item.title)],
        title: item.title,
      );
    }

    final target = item.video?.watchUrl ?? item.video?.src ?? item.linkUrl;
    if (target == null || target.isEmpty) return;

    final uri = Uri.tryParse(target);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = item.image ?? item.video?.poster;
    final meta = [
      if (item.outlet != null && item.outlet!.isNotEmpty) item.outlet!,
      if (item.publishedOnLabel != null && item.publishedOnLabel!.isNotEmpty)
        item.publishedOnLabel!,
    ];

    return AppCard(
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail != null)
            Stack(
              alignment: Alignment.center,
              children: [
                AppImage(url: thumbnail, aspectRatio: 16 / 9, semanticLabel: item.title),
                if (item.kind == PressKind.video)
                  Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xCC0B1020),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppText.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta.join('  ·  '), style: AppText.meta),
                ],
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: AppText.excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      switch (item.kind) {
                        PressKind.photo => Icons.zoom_in_rounded,
                        PressKind.video => Icons.play_circle_outline_rounded,
                        PressKind.website => Icons.open_in_new_rounded,
                      },
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      switch (item.kind) {
                        PressKind.photo => 'View the cutting',
                        PressKind.video => 'Watch',
                        PressKind.website => 'Read the article',
                      },
                      style: AppText.metaStrong.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
