library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/cursor_page.dart';
import '../../core/models/post.dart';
import '../../core/models/shop.dart';
import '../../core/router/route_names.dart';
import '../../core/state/products_query.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/ai_note.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/site_menu.dart';
import '../../core/widgets/state_views.dart';
import '../home/home_screen.dart';
import '../home/sections/landing_rows.dart';

/// The top of the website's price slider; a high end there means "and above".
const _priceCeiling = 10000.0;

/// The website's orders, under the website's labels — lib/shop.ts.
const _sortOptions = [
  (value: 'latest', label: 'Latest'),
  (value: 'price_asc', label: 'Price: low to high'),
  (value: 'price_desc', label: 'Price: high to low'),
  (value: 'name_asc', label: 'Name: A–Z'),
];

enum _ShopView { grid, list }

/// The shop, as the website's /shop draws it on a phone — Shop/Index.tsx.
///
/// Top to bottom: the heading and its standfirst; a Filters panel whose search
/// box is always showing and whose ticks, price and place open from the
/// "Filters" button; "Showing N products" with the sort and the grid/list
/// switch; the filters in force as chips; then the products.
///
/// The ticks are a draft until Search or Apply Filters is pressed, because on
/// the website they are a form: nothing changes under the reader's thumb while
/// they are still choosing.
///
/// There is no Buy button anywhere in this feature, no cart and no checkout.
/// The foundation is not party to the sale — a buyer contacts the maker and the
/// two of them settle it between themselves.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  late ProductsQuery _query;
  _ShopView _view = _ShopView.grid;
  bool _filtersOpen = false;

  // The panel's draft: what is ticked, not yet what is shown.
  final Set<String> _categories = {};
  final Set<String> _makers = {};
  String? _city;
  RangeValues _price = const RangeValues(0, _priceCeiling);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _adopt(_fromCategory(widget.initialCategory));
  }

  /// A tab is created once and kept alive, so a craft tapped somewhere else
  /// arrives here as a rebuild, not a new screen; it has to be adopted.
  @override
  void didUpdateWidget(ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialCategory != oldWidget.initialCategory) {
      setState(() => _adopt(_fromCategory(widget.initialCategory)));
    }
  }

  static ProductsQuery _fromCategory(String? slug) =>
      ProductsQuery(categories: slug == null ? const [] : [slug]);

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(productsProvider(_query).notifier).loadMore();
    }
  }

  /// Shows [query], and sets the panel to match it.
  void _adopt(ProductsQuery query) {
    _query = query;
    _search.text = query.q ?? '';
    _categories
      ..clear()
      ..addAll(query.categories);
    _makers
      ..clear()
      ..addAll(query.makers);
    _city = query.city;
    _price = RangeValues(
      (query.priceMin ?? 0).clamp(0, _priceCeiling),
      (query.priceMax ?? _priceCeiling).clamp(0, _priceCeiling),
    );
  }

  void _show(ProductsQuery query) {
    FocusScope.of(context).unfocus();
    setState(() => _adopt(query));

    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// Search and Apply Filters both send the whole panel, as the website's one
  /// form does. A slider end at its extreme is no filter at all.
  void _submit() {
    final q = _search.text.trim();

    _filtersOpen = false;
    _show(ProductsQuery(
      categories: _categories.toList(),
      makers: _makers.toList(),
      city: _city,
      q: q.isEmpty ? null : q,
      priceMin: _price.start <= 0 ? null : _price.start,
      priceMax: _price.end >= _priceCeiling ? null : _price.end,
      sort: _query.sort,
    ));
  }

  bool get _hasFilters => _query.hasFilters || _query.q != null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider(_query));
    final options = ref.watch(shopFiltersProvider).valueOrNull ?? const ShopFilters();

    return Scaffold(
      // The website's header and its ☰ menu, as on the home page: on the
      // website the shop sits under the same header as every other page.
      endDrawer: SiteMenu(host: context),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider(_query).notifier).refresh(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            homeAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList.list(children: [
                const _Breadcrumbs(),
                const SizedBox(height: 16),
                Text(
                  'Products by our makers',
                  style: AppText.h1.copyWith(fontSize: 30, height: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Everything the craftsmen we work with currently make. Contact the maker '
                  'directly — we take no part in the sale.',
                  style: AppText.body.copyWith(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 24),
                _FilterPanel(
                  options: options,
                  open: _filtersOpen,
                  hasFilters: _hasFilters,
                  search: _search,
                  categories: _categories,
                  makers: _makers,
                  city: _city,
                  price: _price,
                  onToggleCategory: (slug) => setState(() {
                    if (!_categories.remove(slug)) _categories.add(slug);
                  }),
                  onToggleMaker: (slug) => setState(() {
                    if (!_makers.remove(slug)) _makers.add(slug);
                  }),
                  onCity: (slug) => setState(() => _city = slug),
                  onPrice: (range) => setState(() => _price = range),
                  onSubmit: _submit,
                  onClear: () => _show(ProductsQuery()),
                ),
                const SizedBox(height: 24),
                _ResultsBar(
                  state: state,
                  filtersOpen: _filtersOpen,
                  sort: _query.sort,
                  view: _view,
                  onToggleFilters: () => setState(() => _filtersOpen = !_filtersOpen),
                  onSort: (sort) => _show(_query.copyWith(sort: sort)),
                  onView: (view) => setState(() => _view = view),
                ),
                _ActiveFilters(
                  query: _query,
                  options: options,
                  onRemove: _show,
                ),
                const SizedBox(height: 24),
              ]),
            ),
            ..._results(state),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(PagedState<ShopProduct> state) {
    Widget boxed(Widget child) => SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(child: child),
        );

    if (state.initialLoading) {
      return [boxed(const LoadingView(height: 240))];
    }

    if (state.items.isEmpty && state.error != null) {
      return [
        boxed(ErrorView(
          error: state.error,
          onRetry: () => ref.read(productsProvider(_query).notifier).refresh(),
        )),
      ];
    }

    if (state.items.isEmpty) {
      return [boxed(_NothingMatches(onShowEverything: () => _show(ProductsQuery())))];
    }

    void open(ShopProduct product) => context.push(Routes.product(product.slug));

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: state.items.length,
          separatorBuilder: (context, _) => SizedBox(height: _view == _ShopView.grid ? 20 : 16),
          itemBuilder: (context, index) {
            final product = state.items[index];

            return _view == _ShopView.grid
                ? LandingProductCard(product: product, fill: false, onTap: () => open(product))
                : _ProductRow(product: product, onTap: () => open(product));
          },
        ),
      ),
      boxed(ListFooter(
        loading: state.loadingMore,
        endReached: state.endReached,
        error: state.error,
        onRetry: () => ref.read(productsProvider(_query).notifier).loadMore(),
        endLabel: "That's everything",
      )),
    ];
  }
}

// ============================================================== the top ===

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs();

  @override
  Widget build(BuildContext context) {
    final style = AppText.body.copyWith(fontSize: 14, color: AppColors.mutedForeground);

    return Row(
      children: [
        InkWell(
          onTap: () => context.go(Routes.home),
          child: Text('Home', style: style),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.mutedForeground),
        ),
        Text(
          'Shop',
          style: style.copyWith(color: AppColors.foreground, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ======================================================== filter panel ===

/// ShopFilterPanel.tsx. The search box is always there — on a phone it is the
/// one control that stays reachable — and the rest opens from "Filters".
class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.options,
    required this.open,
    required this.hasFilters,
    required this.search,
    required this.categories,
    required this.makers,
    required this.city,
    required this.price,
    required this.onToggleCategory,
    required this.onToggleMaker,
    required this.onCity,
    required this.onPrice,
    required this.onSubmit,
    required this.onClear,
  });

  final ShopFilters options;
  final bool open;
  final bool hasFilters;
  final TextEditingController search;
  final Set<String> categories;
  final Set<String> makers;
  final String? city;
  final RangeValues price;
  final ValueChanged<String> onToggleCategory;
  final ValueChanged<String> onToggleMaker;
  final ValueChanged<String?> onCity;
  final ValueChanged<RangeValues> onPrice;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final clearColour =
        hasFilters ? AppColors.primary : AppColors.mutedForeground.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Filters', style: AppText.title)),
              InkWell(
                onTap: hasFilters ? onClear : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 15, color: clearColour),
                    const SizedBox(width: 6),
                    Text(
                      'Clear all',
                      style: AppText.button.copyWith(fontSize: 14, color: clearColour),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _GroupHeading('Search'),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmit(),
            style: AppText.body.copyWith(fontSize: 14),
            decoration: _fieldDecoration(
              hint: 'Search products or makers…',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 8),
          _PrimaryButton(label: 'Search', height: 40, onPressed: onSubmit),
          if (open) ...[
            if (options.categories.isNotEmpty) ...[
              const SizedBox(height: 24),
              _TickList(
                legend: 'Categories',
                options: options.categories,
                selected: categories,
                onToggle: onToggleCategory,
              ),
            ],
            if (options.makers.isNotEmpty) ...[
              const SizedBox(height: 28),
              _TickList(
                legend: 'Makers',
                options: options.makers,
                selected: makers,
                onToggle: onToggleMaker,
              ),
            ],
            const SizedBox(height: 28),
            _PriceRange(value: price, onChanged: onPrice),
            if (options.cities.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _GroupHeading('Location'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                // Keyed on the value, so clearing the filters elsewhere resets
                // what this field shows.
                key: ValueKey(city),
                initialValue: city,
                isExpanded: true,
                onChanged: onCity,
                style: AppText.body.copyWith(fontSize: 14, color: AppColors.foreground),
                decoration: _fieldDecoration(icon: Icons.location_on_outlined),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Anywhere in India', overflow: TextOverflow.ellipsis),
                  ),
                  for (final option in options.cities)
                    DropdownMenuItem(
                      value: option.slug,
                      child: Text(option.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            _PrimaryButton(
              label: 'Apply Filters',
              icon: Icons.tune_rounded,
              height: 44,
              onPressed: onSubmit,
            ),
          ],
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint, required IconData icon}) {
  OutlineInputBorder edge(Color colour) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
        borderSide: BorderSide(color: colour),
      );

  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    prefixIcon: Icon(icon, size: 16, color: AppColors.mutedForeground),
    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 40),
    border: edge(AppColors.border),
    enabledBorder: edge(AppColors.border),
    focusedBorder: edge(AppColors.primary),
  );
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.bodyStrong.copyWith(fontSize: 14));
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.height,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final double height;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        minimumSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.button.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// A legend and its tick boxes, each with its count — FilterGroup.
///
/// Capped in height, as on the website, so a maker list in the hundreds does
/// not push the price and the Apply button out of reach.
class _TickList extends StatelessWidget {
  const _TickList({
    required this.legend,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String legend;
  final List<TaxonomyOption> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeading(legend),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              children: [
                for (final option in options)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onToggle(option.slug),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Checkbox(
                              value: selected.contains(option.slug),
                              onChanged: (_) => onToggle(option.slug),
                              activeColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              option.name,
                              style: AppText.body.copyWith(fontSize: 14, height: 1.35),
                            ),
                          ),
                          if (option.count > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${option.count}',
                              style: AppText.meta.copyWith(
                                fontSize: 12,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _money(num value) => '₹${NumberFormat.decimalPattern('en_IN').format(value)}';

/// PriceRangeField.tsx: the range as words, the slider, its two ends.
class _PriceRange extends StatelessWidget {
  const _PriceRange({required this.value, required this.onChanged});

  final RangeValues value;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final high = value.end >= _priceCeiling ? '${_money(_priceCeiling)}+' : _money(value.end);
    final ends = AppText.meta.copyWith(fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupHeading('Price Range'),
        const SizedBox(height: 12),
        Text(
          '${_money(value.start)} – $high',
          style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.card,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
            trackHeight: 6,
          ),
          child: RangeSlider(
            min: 0,
            max: _priceCeiling,
            divisions: (_priceCeiling / 100).round(),
            values: value,
            onChanged: (next) {
              // One step apart at least, as the website's slider keeps them.
              if (next.end - next.start >= 100) onChanged(next);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_money(0), style: ends),
            Text('${_money(_priceCeiling)}+', style: ends),
          ],
        ),
      ],
    );
  }
}

// ========================================================= results bar ===

/// "Showing 5 products", the Filters button, the sort and the grid/list pair.
class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.state,
    required this.filtersOpen,
    required this.sort,
    required this.view,
    required this.onToggleFilters,
    required this.onSort,
    required this.onView,
  });

  final PagedState<ShopProduct> state;
  final bool filtersOpen;
  final String sort;
  final _ShopView view;
  final VoidCallback onToggleFilters;
  final ValueChanged<String> onSort;
  final ValueChanged<_ShopView> onView;

  @override
  Widget build(BuildContext context) {
    final muted = AppText.body.copyWith(fontSize: 14, color: AppColors.mutedForeground);

    // The server's count; an older server sends none, and then what has
    // loaded is the best the app can say once it has reached the end.
    final total = state.total ?? (state.endReached ? state.items.length : null);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Text.rich(
          TextSpan(
            style: muted,
            children: state.initialLoading || total == null
                ? const [TextSpan(text: 'Showing products')]
                : [
                    const TextSpan(text: 'Showing '),
                    TextSpan(
                      text: NumberFormat.decimalPattern('en_IN').format(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    TextSpan(text: total == 1 ? ' product' : ' products'),
                  ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _BoxButton(
              onTap: onToggleFilters,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    filtersOpen ? 'Hide filters' : 'Filters',
                    style: AppText.button.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            // A set width, wide enough for its longest order and narrow enough
            // that the grid/list pair stays on the row beside it on a phone,
            // as on the website. A large text size shortens the label rather
            // than pushing the select off the row.
            Container(
              width: 168,
              height: 40,
              padding: const EdgeInsets.only(left: 12, right: 6),
              decoration: _boxDecoration(active: false),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sort,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  style: AppText.body.copyWith(fontSize: 14, color: AppColors.foreground),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  onChanged: (value) {
                    if (value != null && value != sort) onSort(value);
                  },
                  items: [
                    for (final option in _sortOptions)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Grid view',
                  active: view == _ShopView.grid,
                  onTap: () => onView(_ShopView.grid),
                ),
                const SizedBox(width: 4),
                _ViewButton(
                  icon: Icons.view_list_rounded,
                  label: 'List view',
                  active: view == _ShopView.list,
                  onTap: () => onView(_ShopView.list),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

BoxDecoration _boxDecoration({required bool active}) => BoxDecoration(
      color: active ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.small),
      border: Border.all(color: active ? AppColors.primary : AppColors.border),
    );

class _BoxButton extends StatelessWidget {
  const _BoxButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small),
        child: Ink(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _boxDecoration(active: false),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: Ink(
            width: 40,
            height: 40,
            decoration: _boxDecoration(active: active),
            child: Icon(
              icon,
              size: 16,
              color: active ? AppColors.primaryForeground : AppColors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================== active filters ===

/// ShopActiveFilters.tsx: one chip per filter in force, each removing itself.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.query, required this.options, required this.onRemove});

  final ProductsQuery query;
  final ShopFilters options;
  final ValueChanged<ProductsQuery> onRemove;

  @override
  Widget build(BuildContext context) {
    String nameFor(List<TaxonomyOption> list, String slug) =>
        list.where((option) => option.slug == slug).firstOrNull?.name ?? slug;

    final chips = <(String, ProductsQuery)>[
      for (final slug in query.categories)
        (
          nameFor(options.categories, slug),
          query.copyWith(categories: [...query.categories]..remove(slug)),
        ),
      for (final slug in query.makers)
        (
          nameFor(options.makers, slug),
          query.copyWith(makers: [...query.makers]..remove(slug)),
        ),
      if (query.city != null)
        (nameFor(options.cities, query.city!), query.copyWith(clearCity: true)),
      if (query.q != null) ('Search: “${query.q}”', query.copyWith(clearQuery: true)),
      if (_priceChip(query) case final label?) (label, query.copyWith(clearPrices: true)),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, without) in chips)
            Semantics(
              button: true,
              label: 'Remove this filter: $label',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onRemove(without),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(fontSize: 14, height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.close_rounded, size: 13, color: AppColors.mutedForeground),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// lib/shop.ts `priceChipLabel`.
String? _priceChip(ProductsQuery query) {
  final low = query.priceMin;
  final high = query.priceMax;

  if (low != null && high != null) return '${_money(low)} – ${_money(high)}';
  if (low != null) return 'Over ${_money(low)}';
  if (high != null) return 'Under ${_money(high)}';

  return null;
}

// ============================================================ products ===

/// ProductRow.tsx: the list view's row.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final ShopProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted =
        AppText.body.copyWith(fontSize: 14, color: AppColors.mutedForeground, height: 1.4);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.field),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.small),
                    child: SizedBox(
                      width: 128,
                      height: 96,
                      child: product.thumbnail == null
                          ? ColoredBox(
                              color: AppColors.surface,
                              child: Center(
                                child: Text(
                                  'No photograph yet',
                                  textAlign: TextAlign.center,
                                  style: AppText.meta.copyWith(fontSize: 12),
                                ),
                              ),
                            )
                          : AppImage(
                              url: product.thumbnail,
                              fit: BoxFit.cover,
                              semanticLabel: product.name,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.category != null)
                          Row(
                            children: [
                              const Icon(Icons.sell_outlined, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  product.category!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.meta.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong.copyWith(height: 1.35),
                        ),
                        if (product.maker != null) ...[
                          const SizedBox(height: 2),
                          Text('by ${product.maker!.label}', style: muted),
                        ],
                        if (product.tagline?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.tagline!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ],
                        if (product.aiAssisted) ...[
                          const SizedBox(height: 8),
                          const AiNote.badge(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'View details',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.button.copyWith(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The empty state, in the website's words.
class _NothingMatches extends StatelessWidget {
  const _NothingMatches({required this.onShowEverything});

  final VoidCallback onShowEverything;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 32, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          Text('Nothing matches that', style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Try a different craft, or clear the filters and browse everything.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onShowEverything,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foreground,
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.small)),
            ),
            child: Text('Show everything', style: AppText.button.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
