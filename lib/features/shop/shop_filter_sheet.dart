library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/post.dart';
import '../../core/models/shop.dart';
import '../../core/state/products_query.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The shop's filters, as the website's sidebar arranges them.
///
/// Crafts and makers are multi-select and the city is single, which mirrors the
/// web panel — and the multi-select on crafts is not a detail: a product has
/// one category, so ticking two of them *widens* the shelf. Anybody reading
/// this as an AND would expect it to narrow to nothing.
///
/// Returns the new query on Apply and **null on dismiss**. The caller must
/// treat null as "changed nothing": reading it as "cleared" would mean a
/// swipe-down throwing away filters the reader had just set.
class ShopFilterSheet extends StatefulWidget {
  const ShopFilterSheet({super.key, required this.filters, required this.query});

  final ShopFilters filters;
  final ProductsQuery query;

  static Future<ProductsQuery?> open(
    BuildContext context, {
    required ShopFilters filters,
    required ProductsQuery query,
  }) {
    return showModalBottomSheet<ProductsQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ShopFilterSheet(filters: filters, query: query),
      ),
    );
  }

  @override
  State<ShopFilterSheet> createState() => _ShopFilterSheetState();
}

class _ShopFilterSheetState extends State<ShopFilterSheet> {
  late Set<String> _categories;
  late Set<String> _makers;
  late String? _city;
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();

    _categories = widget.query.categories.toSet();
    _makers = widget.query.makers.toSet();
    _city = widget.query.city;
    _min = TextEditingController(text: _rupees(widget.query.priceMin));
    _max = TextEditingController(text: _rupees(widget.query.priceMax));
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  /// Whole rupees, because the field asks for a price and nobody filters on
  /// paise.
  static String _rupees(double? value) => value == null ? '' : value.toStringAsFixed(0);

  static double? _parse(String text) {
    final trimmed = text.trim();

    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }

  void _apply() {
    Navigator.pop(
      context,
      ProductsQuery(
        categories: _categories.toList(),
        makers: _makers.toList(),
        city: _city,
        // The search term is the screen's own field, not this sheet's, so it
        // travels through untouched.
        q: widget.query.q,
        priceMin: _parse(_min.text),
        priceMax: _parse(_max.text),
      ),
    );
  }

  void _clear() {
    setState(() {
      _categories = {};
      _makers = {};
      _city = null;
      _min.clear();
      _max.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(child: Text('Filter', style: AppText.h2.copyWith(fontSize: 20))),
                TextButton(onPressed: _clear, child: const Text('Clear all')),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              children: [
                if (widget.filters.categories.isNotEmpty) ...[
                  const _Label(
                    'Craft',
                    // Said out loud, because a tick box that widens the results
                    // is the opposite of what a filter usually does.
                    note: 'Tick more than one to see more.',
                  ),
                  _Chips(
                    options: widget.filters.categories,
                    selected: _categories,
                    onToggle: (slug) => setState(() {
                      _categories.contains(slug)
                          ? _categories.remove(slug)
                          : _categories.add(slug);
                    }),
                  ),
                  const SizedBox(height: 18),
                ],
                if (widget.filters.cities.isNotEmpty) ...[
                  const _Label('Where they are'),
                  _Chips(
                    options: widget.filters.cities,
                    selected: _city == null ? const {} : {_city!},
                    // Single-select: tapping the chosen one clears it, which is
                    // the only way back to "anywhere" without a stray "All"
                    // chip in the row.
                    onToggle: (slug) => setState(() => _city = _city == slug ? null : slug),
                  ),
                  const SizedBox(height: 18),
                ],
                if (widget.filters.makers.isNotEmpty) ...[
                  const _Label('Maker'),
                  _Chips(
                    options: widget.filters.makers,
                    selected: _makers,
                    onToggle: (slug) => setState(() {
                      _makers.contains(slug) ? _makers.remove(slug) : _makers.add(slug);
                    }),
                  ),
                  const SizedBox(height: 18),
                ],
                const _Label(
                  'Price',
                  // The website filters both ends against the "from" price,
                  // because that is the figure a buyer compares — and using the
                  // upper price for the ceiling would drop every open-ended
                  // range out of a bounded search.
                  note: 'Against the starting price. Leave either end blank.',
                ),
                Row(
                  children: [
                    Expanded(child: _PriceField(controller: _min, label: 'From ₹')),
                    const SizedBox(width: 12),
                    Expanded(child: _PriceField(controller: _max, label: 'Up to ₹')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _apply, child: const Text('Show these')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppText.title.copyWith(fontSize: 15)),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: AppText.meta),
          ],
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.options, required this.selected, required this.onToggle});

  final List<TaxonomyOption> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(
              option.count == 0 ? option.name : '${option.name} (${option.count})',
            ),
            selected: selected.contains(option.slug),
            onSelected: (_) => onToggle(option.slug),
            showCheckmark: false,
            labelStyle: AppText.meta.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected.contains(option.slug)
                  ? AppColors.primaryForeground
                  : AppColors.foreground,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide(
              color: selected.contains(option.slug) ? AppColors.primary : AppColors.border,
            ),
          ),
      ],
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, hintText: 'Any'),
    );
  }
}
