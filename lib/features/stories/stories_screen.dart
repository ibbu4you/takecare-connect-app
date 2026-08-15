import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/state_views.dart';

/// The blog index, filtered by category.
///
/// The filter is app-side state rather than a route parameter: changing it
/// swaps which paged provider the list watches, and each category keeps its
/// own accumulated pages, so flicking between two of them does not refetch
/// either.
class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final query = (category: _category, author: null, q: null);
    final state = ref.watch(postsProvider(query));
    final categories = ref.watch(postCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        actions: [
          IconButton(
            onPressed: () => context.push('${Routes.home}search'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search stories',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: categories.maybeWhen(
            data: (list) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilterPills(
                options: [for (final c in list) (value: c.slug, label: c.name)],
                selected: _category,
                onSelected: (value) => setState(() => _category = value),
                allLabel: 'All stories',
              ),
            ),
            orElse: () => const SizedBox(height: 50),
          ),
        ),
      ),
      body: PagedListView(
        state: state,
        onLoadMore: () => ref.read(postsProvider(query).notifier).loadMore(),
        onRefresh: () => ref.read(postsProvider(query).notifier).refresh(),
        emptyView: const EmptyView(
          title: 'No stories here yet',
          subtitle: 'Try another category.',
          icon: Icons.article_outlined,
        ),
        itemBuilder: (context, post, _) => PostCard(
          post: post,
          onTap: () => context.push(Routes.story(post.slug)),
        ),
      ),
    );
  }
}
