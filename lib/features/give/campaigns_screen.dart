import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/state_views.dart';

/// The Give tab: every campaign, and a standing way to give to the general
/// fund without picking one.
class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignsProvider(kAll));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Give'),
        actions: [
          TextButton(
            onPressed: () => context.push('${Routes.more}/transparency'),
            child: const Text('Where it goes'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PagedListView(
        state: state,
        header: const _GeneralFundCard(),
        onLoadMore: () => ref.read(campaignsProvider(kAll).notifier).loadMore(),
        onRefresh: () => ref.read(campaignsProvider(kAll).notifier).refresh(),
        emptyView: const EmptyView(
          title: 'No open appeals right now',
          subtitle: 'You can still give to the general fund above.',
          icon: Icons.favorite_outline_rounded,
        ),
        itemBuilder: (context, campaign, _) => CampaignCard(
          campaign: campaign,
          onTap: () => context.push(Routes.campaign(campaign.slug)),
        ),
      ),
    );
  }
}

/// Giving without choosing a campaign.
///
/// Accent-red bordered rather than filled: it is a call to action, but it sits
/// above a list of campaigns that each have their own donate button, and a
/// solid red block at the top would out-shout all of them.
class _GeneralFundCard extends StatelessWidget {
  const _GeneralFundCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GIVE WHERE IT IS NEEDED MOST', style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text('Support the general fund', style: AppText.h2.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            'Goes wherever the need is greatest that month — a workshop rebuilt, '
            'a loom repaired, school fees covered. Every rupee is receipted, and '
            'donations qualify for 80G tax benefit.',
            style: AppText.excerpt,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(Routes.donate),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accentButton),
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text('Donate'),
            ),
          ),
        ],
      ),
    );
  }
}
