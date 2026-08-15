import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/state_views.dart';

/// Photo galleries from the foundation's events and field visits.
class GalleriesScreen extends ConsumerWidget {
  const GalleriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleriesProvider(kAll));

    return Scaffold(
      appBar: screenBar('Galleries'),
      body: PagedListView(
        state: state,
        onLoadMore: () => ref.read(galleriesProvider(kAll).notifier).loadMore(),
        onRefresh: () => ref.read(galleriesProvider(kAll).notifier).refresh(),
        emptyView: const EmptyView(
          title: 'No galleries yet',
          subtitle: 'Photographs from events and field visits appear here.',
          icon: Icons.photo_library_outlined,
        ),
        itemBuilder: (context, gallery, _) => GalleryCard(
          gallery: gallery,
          onTap: () => context.push('${Routes.more}/galleries/${gallery.slug}'),
        ),
      ),
    );
  }
}
