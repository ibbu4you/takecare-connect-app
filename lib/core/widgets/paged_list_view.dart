import 'package:flutter/material.dart';

import '../api/cursor_page.dart';
import 'state_views.dart';

/// An infinite list over a [PagedState].
///
/// It owns the three things every paged screen would otherwise re-implement:
/// the scroll listener that asks for the next page, the footer that shows
/// where the list is up to, and pull-to-refresh.
///
/// The trigger is 600 logical pixels from the bottom rather than at it, so the
/// next page is usually already in hand by the time the reader arrives — the
/// spinner is a fallback, not the normal experience. [PagedNotifier.loadMore]
/// guards against the repeat calls a fast flick would otherwise cause, so this
/// can afford to be eager.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.emptyView,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
    this.separator = 12,
    this.endLabel = "That's everything",
  });

  final PagedState<T> state;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  final Widget? emptyView;

  /// Rendered above the first item and scrolling with it — a search field, a
  /// filter row, an intro paragraph.
  final Widget? header;

  final EdgeInsets padding;
  final double separator;
  final String endLabel;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // The first load and a hard failure take over the whole viewport; a failure
    // partway through a list does not, because the reader has rows to keep.
    final Widget body;

    if (state.initialLoading) {
      body = _fill(const LoadingView());
    } else if (state.items.isEmpty && state.error != null) {
      body = _fill(ErrorView(error: state.error, onRetry: widget.onRefresh));
    } else if (state.isEmpty) {
      body = _fill(widget.emptyView ?? const EmptyView(title: 'Nothing here yet'));
    } else {
      body = ListView.separated(
        controller: _controller,
        padding: widget.padding,
        // +1 for the header slot when present, +1 for the footer.
        itemCount: state.items.length + (widget.header == null ? 1 : 2),
        separatorBuilder: (context, index) {
          final isHeaderGap = widget.header != null && index == 0;

          return SizedBox(height: isHeaderGap ? 12 : widget.separator);
        },
        itemBuilder: (context, index) {
          var i = index;

          if (widget.header != null) {
            if (i == 0) return widget.header!;
            i -= 1;
          }

          if (i < state.items.length) {
            return widget.itemBuilder(context, state.items[i], i);
          }

          return ListFooter(
            loading: state.loadingMore,
            endReached: state.endReached,
            error: state.error,
            onRetry: widget.onLoadMore,
            endLabel: widget.endLabel,
          );
        },
      );
    }

    return RefreshIndicator(onRefresh: widget.onRefresh, child: body);
  }

  /// Keeps a single centred state scrollable, so pull-to-refresh still works
  /// on an empty or failed list — otherwise the one gesture that could fix it
  /// is the one gesture that does nothing.
  Widget _fill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.header != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: widget.header!,
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
