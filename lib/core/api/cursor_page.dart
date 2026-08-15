import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One page of a cursor-paginated list.
///
/// The API uses Laravel's `cursorPaginate`, which is **not** page numbers.
/// There is no `total`, no `last_page`, no `current_page` — so the app can
/// never show "page 3 of 12" and should not try. The absence of a cursor is
/// the end signal, and that is the whole contract.
class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  static CursorPage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = (json['data'] as List?) ?? const [];

    return CursorPage<T>(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false),
      nextCursor: _cursorFrom(json),
    );
  }

  /// `meta.next_cursor`, with a fallback to the cursor inside `links.next`.
  ///
  /// Laravel sends both today. The fallback is three lines and means a change
  /// to either one does not silently end pagination at page one.
  static String? _cursorFrom(Map<String, dynamic> json) {
    final meta = json['meta'];
    if (meta is Map && meta['next_cursor'] != null) {
      return meta['next_cursor'].toString();
    }

    final links = json['links'];
    if (links is Map && links['next'] is String) {
      return Uri.tryParse(links['next'] as String)?.queryParameters['cursor'];
    }

    return null;
  }
}

/// What a paged screen renders from.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.nextCursor,
    this.initialLoading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<T> items;
  final String? nextCursor;
  final bool initialLoading;
  final bool loadingMore;
  final Object? error;

  bool get endReached => !initialLoading && nextCursor == null;

  bool get isEmpty => !initialLoading && error == null && items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    String? nextCursor,
    bool? initialLoading,
    bool? loadingMore,
    Object? error,
    bool clearCursor = false,
    bool clearError = false,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Accumulates pages as the reader scrolls.
///
/// This is the one place the app departs from the house pattern. A
/// `FutureProvider` returns a value and `ref.invalidate` throws it away — fine
/// for a detail screen, useless for a list somebody has scrolled through, since
/// refreshing would discard every page but the first. So lists use a notifier
/// that appends, and their pull-to-refresh calls [refresh] rather than
/// `ref.invalidate`.
abstract class PagedNotifier<T, Q> extends AutoDisposeFamilyNotifier<PagedState<T>, Q> {
  /// Fetch one page. `cursor` is null for the first.
  Future<CursorPage<T>> fetch(Q query, String? cursor);

  /// Identity, so a refresh racing a load cannot duplicate a row.
  String keyOf(T item);

  @override
  PagedState<T> build(Q arg) {
    // Fired without awaiting: build() must return a state synchronously, and
    // the first frame is the loading one.
    Future.microtask(_loadFirst);

    // Typed explicitly. `const PagedState()` would infer PagedState<dynamic>,
    // which satisfies the analyzer and throws the moment it is assigned.
    return PagedState<T>();
  }

  Future<void> _loadFirst() async {
    try {
      final page = await fetch(arg, null);

      state = PagedState<T>(
        items: page.items,
        nextCursor: page.nextCursor,
        initialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(initialLoading: false, error: e);
    }
  }

  /// Fetch the next page and append it.
  Future<void> loadMore() async {
    // Without this guard a fast flick fires four identical requests and the
    // same rows arrive four times.
    if (state.loadingMore || state.initialLoading || state.endReached) return;

    state = state.copyWith(loadingMore: true, clearError: true);

    try {
      final page = await fetch(arg, state.nextCursor);
      final seen = state.items.map(keyOf).toSet();

      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((item) => seen.add(keyOf(item))),
        ],
        nextCursor: page.nextCursor,
        loadingMore: false,
        clearCursor: page.nextCursor == null,
      );
    } catch (e) {
      // The reader keeps everything already loaded; only the footer changes.
      state = state.copyWith(loadingMore: false, error: e);
    }
  }

  /// Start again from page one.
  Future<void> refresh() async {
    state = PagedState<T>();
    await _loadFirst();
  }
}
