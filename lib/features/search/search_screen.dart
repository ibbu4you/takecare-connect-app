import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/cursor_page.dart';
import '../../core/models/business.dart';
import '../../core/models/post.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';

/// One search box across both things worth searching: stories and craftsmen.
///
/// Two tabs rather than one merged list. The server has no combined search
/// endpoint and inventing one client-side would mean interleaving two cursor
/// paginations with no shared ordering — and a reader looking for a weaver is
/// not helped by three articles between each result.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String? _query;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Repaints the clear button as soon as there is something to clear. The
    // debounced setState below is 400ms away, and a cross that appears half a
    // second after you start typing looks like a glitch.
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final trimmed = value.trim();
      // Below three characters the server would return most of the database,
      // which is not a search result — it is a list.
      setState(() => _query = trimmed.length < 3 ? null : trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          title: TextField(
            controller: _controller,
            onChanged: _onChanged,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: AppText.body.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search stories and craftsmen',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            // Material 3 draws a near-black rule under the tabs by default,
            // which is the heaviest line anywhere in this app.
            dividerColor: AppColors.border,
            tabs: [Tab(text: 'Stories'), Tab(text: 'Craftsmen')],
          ),
        ),
        body: _query == null
            ? const _Prompt()
            : TabBarView(
                children: [
                  _Results<PostSummary>(
                    state: ref.watch(
                      postsProvider((category: null, author: null, q: _query)),
                    ),
                    onLoadMore: () => ref
                        .read(postsProvider((category: null, author: null, q: _query)).notifier)
                        .loadMore(),
                    builder: (post) => PostCard(
                      post: post,
                      onTap: () => context.push(Routes.story(post.slug)),
                    ),
                    query: _query!,
                  ),
                  _Results<BusinessSummary>(
                    state: ref.watch(
                      businessesProvider((category: null, city: null, q: _query)),
                    ),
                    onLoadMore: () => ref
                        .read(businessesProvider((category: null, city: null, q: _query))
                            .notifier)
                        .loadMore(),
                    builder: (business) => BusinessCard(
                      business: business,
                      onTap: () => context.push(Routes.craftsman(business.slug)),
                    ),
                    query: _query!,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) {
    return const EmptyView(
      title: 'What are you looking for?',
      subtitle: 'Type at least three letters — a name, a trade, a place.',
      icon: Icons.search_rounded,
    );
  }
}

/// A simple paged list. Not [PagedListView], which owns a `RefreshIndicator`
/// and a header — neither of which belongs inside a tab whose contents are
/// replaced on every keystroke.
class _Results<T> extends StatefulWidget {
  const _Results({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.builder,
    required this.query,
  });

  final PagedState<T> state;
  final VoidCallback onLoadMore;
  final Widget Function(T item) builder;
  final String query;

  @override
  State<_Results<T>> createState() => _ResultsState<T>();
}

class _ResultsState<T> extends State<_Results<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_controller.hasClients) return;

      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 400) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.initialLoading) return const LoadingView();

    if (state.items.isEmpty && state.error != null) {
      return ErrorView(error: state.error);
    }

    if (state.isEmpty) {
      return EmptyView(
        title: 'Nothing found',
        subtitle: 'No matches for "${widget.query}".',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.separated(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index < state.items.length) return widget.builder(state.items[index]);

        return ListFooter(
          loading: state.loadingMore,
          endReached: state.endReached,
          error: state.error,
          onRetry: widget.onLoadMore,
        );
      },
    );
  }
}
