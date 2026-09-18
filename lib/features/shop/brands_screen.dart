library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/shop_cards.dart';
import '../../core/widgets/state_views.dart';

/// The makers, on their own screen.
///
/// Reachable from the More menu and from a deep link; the same grid is the Shop
/// tab's Makers segment, which is [BrandsView] below.
class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: BrandsView()),
    );
  }
}

/// Every maker selling through the foundation, busiest first.
///
/// A grid rather than a paged list, because the server hands the whole set over
/// at once — it orders by how much each maker has on the shelf, which a cursor
/// cannot encode, and the set is bounded by paying members with something
/// listed. See Repository.brands.
class BrandsView extends ConsumerStatefulWidget {
  const BrandsView({super.key});

  @override
  ConsumerState<BrandsView> createState() => _BrandsViewState();
}

class _BrandsViewState extends ConsumerState<BrandsView> {
  String? _craft;

  @override
  Widget build(BuildContext context) {
    final query = (craft: _craft, city: null, q: null);
    final brands = ref.watch(brandsProvider(query));
    final filters = ref.watch(shopFiltersProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(brandsProvider(query).future),
      child: brands.when(
        loading: () => const LoadingView(height: 420),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(brandsProvider(query)),
        ),
        data: (list) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The journalism, one tap away. The interviews were their
                    // own tab before the shop arrived, and they are the reason
                    // most of these makers are here at all.
                    const _InterviewsRow(),
                    if (filters.valueOrNull != null &&
                        filters.value!.categories.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      FilterPills(
                        options: [
                          for (final craft in filters.value!.categories)
                            (value: craft.slug, label: craft.name),
                        ],
                        selected: _craft,
                        onSelected: (value) => setState(() => _craft = value),
                        allLabel: 'All crafts',
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  title: 'No makers here yet',
                  subtitle: 'Try another craft.',
                  icon: Icons.storefront_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => BrandCard(
                      brand: list[i],
                      onTap: () => context.push(Routes.brand(list[i].slug)),
                    ),
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InterviewsRow extends StatelessWidget {
  const _InterviewsRow();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.craftsmen),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Read the interviews', style: AppText.title.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'How these makers learned their trade, in their own words.',
                  style: AppText.meta,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}
