import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/post.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/state_views.dart';

/// The craftsmen directory: search, trade and city filters, infinite list.
class CraftsmenScreen extends ConsumerStatefulWidget {
  const CraftsmenScreen({super.key, this.initialCategory, this.initialCity});

  final String? initialCategory;
  final String? initialCity;

  @override
  ConsumerState<CraftsmenScreen> createState() => _CraftsmenScreenState();
}

class _CraftsmenScreenState extends ConsumerState<CraftsmenScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _category;
  String? _city;
  String? _query;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _city = widget.initialCity;
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
  @override
  void didUpdateWidget(CraftsmenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.initialCity != oldWidget.initialCity) {
      setState(() {
        _category = widget.initialCategory;
        _city = widget.initialCity;
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
  /// query string is a *different* provider, so an undebounced field would
  /// spawn one paged notifier per character typed.
  void _onSearchChanged(String value) {
    // Repaints the clear button straight away; the debounced setState below is
    // 400ms off and the cross would otherwise lag behind the typing.
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final trimmed = value.trim();
      setState(() => _query = trimmed.isEmpty ? null : trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = (category: _category, city: _city, q: _query);
    final state = ref.watch(businessesProvider(query));
    final categories = ref.watch(businessCategoriesProvider);
    final cities = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Craftsmen'),
        actions: [
          IconButton(
            tooltip: 'Filter by city',
            onPressed: () => _pickCity(cities.valueOrNull ?? const []),
            icon: Badge(
              isLabelVisible: _city != null,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.tune_rounded),
            ),
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
                allLabel: 'All trades',
              ),
            ),
            orElse: () => const SizedBox(height: 50),
          ),
        ),
      ),
      body: PagedListView(
        state: state,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The trade's own description, which on the website is a hub page
            // of its own and the main thing an editor writes about that trade.
            // The API sends it on /categories and the app was throwing it away.
            _HubBlurb(
              text: _blurbFor(categories.valueOrNull, _category) ??
                  _blurbFor(cities.valueOrNull, _city),
            ),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or maker',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
            if (_city != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Pill(
                      _cityLabel(cities.valueOrNull ?? const []),
                      icon: Icons.place_outlined,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _city = null),
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
        onLoadMore: () => ref.read(businessesProvider(query).notifier).loadMore(),
        onRefresh: () => ref.read(businessesProvider(query).notifier).refresh(),
        emptyView: EmptyView(
          title: 'No craftsmen found',
          subtitle: _query == null
              ? 'Try another trade or city.'
              : 'Nothing matches "$_query".',
          icon: Icons.search_off_rounded,
          action: (_query != null || _city != null || _category != null)
              ? OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = null;
                      _city = null;
                      _category = null;
                    });
                  },
                  child: const Text('Clear filters'),
                )
              : null,
        ),
        itemBuilder: (context, business, _) => BusinessCard(
          business: business,
          onTap: () => context.push(Routes.craftsman(business.slug)),
        ),
      ),
    );
  }

  /// The description an editor wrote for the selected trade or city.
  static String? _blurbFor(List<TaxonomyOption>? options, String? slug) {
    if (options == null || slug == null) return null;

    for (final option in options) {
      if (option.slug == slug) {
        final text = option.description?.trim() ?? '';

        return text.isEmpty ? null : text;
      }
    }

    return null;
  }

  String _cityLabel(List<TaxonomyOption> cities) {
    for (final city in cities) {
      if (city.slug == _city) {
        return city.state == null ? city.name : '${city.name}, ${city.state}';
      }
    }

    return _city ?? '';
  }

  /// "All cities" needs a value of its own.
  ///
  /// A dismissed sheet also returns null, so popping null for All would mean a
  /// swipe-to-dismiss silently cleared the reader's city filter.
  static const _allCities = ' all';

  Future<void> _pickCity(List<TaxonomyOption> cities) async {
    if (cities.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView.separated(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          itemCount: cities.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                title: Text('All cities', style: AppText.body.copyWith(fontSize: 15)),
                trailing: _city == null
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, _allCities),
              );
            }

            final city = cities[index - 1];

            return ListTile(
              title: Text(city.name, style: AppText.body.copyWith(fontSize: 15)),
              subtitle: city.state == null ? null : Text(city.state!, style: AppText.meta),
              trailing: _city == city.slug
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : Text('${city.count}', style: AppText.meta),
              onTap: () => Navigator.pop(context, city.slug),
            );
          },
        ),
      ),
    );

    // null means the sheet was dismissed without choosing, which changes
    // nothing.
    if (!mounted || picked == null) return;

    setState(() => _city = picked == _allCities ? null : picked);
  }
}

/// The editor's copy for a trade or a city, above the list.
///
/// On the website each of these is a hub page — `/businesses/category/{slug}`
/// — whose whole purpose is that paragraph. Collapsing the hubs into filter
/// pills is right for a phone, but dropping the paragraph with them loses the
/// only thing on those pages an editor actually wrote.
class _HubBlurb extends StatelessWidget {
  const _HubBlurb({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text!, style: AppText.excerpt.copyWith(height: 1.6)),
    );
  }
}
