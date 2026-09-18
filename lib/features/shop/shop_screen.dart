library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/shop.dart';
import '../../core/router/route_names.dart';
import '../../core/state/products_query.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/shop_cards.dart';
import '../../core/widgets/state_views.dart';
import 'brands_screen.dart';
import 'shop_filter_sheet.dart';

/// Which half of the tab is showing.
enum ShopSegment { products, makers }

/// The shop: what our makers sell, and who they are.
///
/// Two segments in one tab, because they answer two halves of the same
/// question. Products is the shelf; Makers is the directory of the people whose
/// shelf it is — and the interviews with them are one tap further in, from the
/// row at the top of that segment.
///
/// The Makers segment is reached at `/shop?segment=makers`, never
/// `/shop/makers`: a path segment there could be shadowed by a product whose
/// slug happened to be "makers", which is a collision the website has to keep a
/// reserved-slug list for.
///
/// There is no Buy button anywhere in this feature, no cart and no checkout.
/// The foundation is not party to the sale — a buyer contacts the maker and the
/// two of them settle it between themselves — so there is nothing here for a
/// purchase to hang off.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initialCategory, this.initialSegment});

  final String? initialCategory;
  final String? initialSegment;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  late ShopSegment _segment;
  late ProductsQuery _query;

  @override
  void initState() {
    super.initState();

    _segment =
        widget.initialSegment == 'makers' ? ShopSegment.makers : ShopSegment.products;
    _query = ProductsQuery(
      categories: widget.initialCategory == null ? const [] : [widget.initialCategory!],
    );
  }

  /*
   | A filter arriving from somewhere else has to be adopted, not just read
   | once.
   |
   | `initState` runs when this screen is first created, and a tab in a
   | StatefulShellRoute is created once and then kept alive — which is what
   | makes each tab remember its place. So the second time somebody arrives
   | here carrying a filter, the widget is rebuilt with the new query but the
   | State is the same object and its field still holds whatever it had.
   |
   | The visible symptom was that tapping a subject on the home page opened
   | the full list of stories: it worked the first time and never again.
   */
  /// A craft tapped on a product page, or `?segment=makers` from a link, has to
  /// land even when this tab has been open all along.
  @override
  void didUpdateWidget(ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        _query = ProductsQuery(
          categories: widget.initialCategory == null ? const [] : [widget.initialCategory!],
        );
      });
    }

    if (widget.initialSegment != oldWidget.initialSegment) {
      setState(() {
        _segment =
            widget.initialSegment == 'makers' ? ShopSegment.makers : ShopSegment.products;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced, because every keystroke is otherwise a request — and each new
  /// query is a *different* provider, so an undebounced field would spawn one
  /// paged notifier per character typed.
  void _onSearchChanged(String value) {
    // Repaints the clear button straight away; the debounced setState below is
    // 400ms off and the cross would otherwise lag behind the typing.
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final trimmed = value.trim();
      setState(() {
        _query = trimmed.isEmpty
            ? _query.copyWith(clearQuery: true)
            : _query.copyWith(q: trimmed);
      });
    });
  }

  Future<void> _openFilters() async {
    final filters = ref.read(shopFiltersProvider).valueOrNull;
    if (filters == null) return;

    final result = await ShopFilterSheet.open(context, filters: filters, query: _query);

    // A dismissed sheet returns null, and treating that as "cleared" would mean
    // a swipe-down silently throwing away the reader's filters.
    if (result == null || !mounted) return;

    setState(() => _query = result);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(shopFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          if (_segment == ShopSegment.products)
            IconButton(
              tooltip: 'Filter',
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _query.hasFilters,
                label: Text('${_query.appliedCount}'),
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.tune_rounded),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ShopSegment>(
                segments: const [
                  ButtonSegment(
                    value: ShopSegment.products,
                    label: Text('Products'),
                    icon: Icon(Icons.inventory_2_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: ShopSegment.makers,
                    label: Text('Makers'),
                    icon: Icon(Icons.handshake_outlined, size: 16),
                  ),
                ],
                selected: {_segment},
                showSelectedIcon: false,
                onSelectionChanged: (value) => setState(() => _segment = value.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: AppColors.primaryForeground,
                  textStyle: AppText.button.copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _segment == ShopSegment.makers
          ? const BrandsView()
          : _Products(
              query: _query,
              searchController: _searchController,
              crafts: filters.valueOrNull,
              onSearchChanged: _onSearchChanged,
              onCraftSelected: (slug) => setState(() {
                _query = ProductsQuery(
                  categories: slug == null ? const [] : [slug],
                  makers: _query.makers,
                  city: _query.city,
                  q: _query.q,
                  priceMin: _query.priceMin,
                  priceMax: _query.priceMax,
                );
              }),
              onClear: () {
                _searchController.clear();
                setState(() => _query = ProductsQuery());
              },
            ),
    );
  }
}

class _Products extends ConsumerWidget {
  const _Products({
    required this.query,
    required this.searchController,
    required this.crafts,
    required this.onSearchChanged,
    required this.onCraftSelected,
    required this.onClear,
  });

  final ProductsQuery query;
  final TextEditingController searchController;
  final ShopFilters? crafts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCraftSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider(query));

    return PagedListView(
      state: state,
      // Two across: these are photographs of objects, and a single column of
      // them scrolls for ever to show six things.
      columns: 2,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search what they make',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
          ),
          if (crafts != null && crafts!.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilterPills(
              options: [
                for (final craft in crafts!.categories) (value: craft.slug, label: craft.name),
              ],
              selected: query.categories.length == 1 ? query.categories.first : null,
              onSelected: onCraftSelected,
              allLabel: 'All crafts',
            ),
          ],
          if (query.appliedCount > (query.categories.length == 1 ? 1 : 0))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Pill('${query.appliedCount} filters', icon: Icons.tune_rounded),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: Text(
                      'Clear',
                      style: AppText.metaStrong.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      onLoadMore: () => ref.read(productsProvider(query).notifier).loadMore(),
      onRefresh: () => ref.read(productsProvider(query).notifier).refresh(),
      emptyView: EmptyView(
        title: 'Nothing here yet',
        subtitle: query.q == null
            ? 'Try another craft, or clear the filters.'
            : 'Nothing matches "${query.q}".',
        icon: Icons.search_off_rounded,
        action: query.hasFilters || query.q != null
            ? OutlinedButton(onPressed: onClear, child: const Text('Clear filters'))
            : null,
      ),
      itemBuilder: (context, product, _) => ProductCard(
        product: product,
        onTap: () => context.push(Routes.product(product.slug)),
      ),
    );
  }
}
