import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/campaign.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/share_sheet.dart';
import '../../core/widgets/state_views.dart';

/// One campaign: the story, where the money goes, what has happened since.
class CampaignScreen extends ConsumerWidget {
  const CampaignScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider(slug));

    return Scaffold(
      appBar: AppBar(
        actions: [
          campaign.maybeWhen(
            data: (data) => ShareAction(path: '/campaigns/${data.slug}', title: data.title),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: campaign.when(
        loading: () => const LoadingView(height: 500),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(campaignProvider(slug)),
        ),
        data: (data) => _Campaign(campaign: data),
      ),
      bottomNavigationBar: campaign.maybeWhen(
        data: (data) => _DonateBar(campaign: data),
        orElse: () => null,
      ),
    );
  }
}

class _Campaign extends StatelessWidget {
  const _Campaign({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (campaign.image != null)
          AppImage(url: campaign.image, aspectRatio: 16 / 9, semanticLabel: campaign.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(campaign.title, style: AppText.h1),
              if (campaign.businessName != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: campaign.businessSlug == null
                      ? null
                      : () => context.go(Routes.craftsman(campaign.businessSlug!)),
                  child: Row(
                    children: [
                      const Icon(Icons.handshake_outlined, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'For ${campaign.businessName}',
                          style: AppText.metaStrong.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: CampaignProgress(campaign: campaign),
              ),
              if (campaign.excerpt.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(campaign.excerpt, style: AppText.lead),
              ],
              if (campaign.story != null && campaign.story!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                HtmlBody(campaign.story),
              ],
            ],
          ),
        ),

        if (campaign.fundUsage.isNotEmpty) ...[
          const SectionHeader(eyebrow: 'Accountability', title: 'Where the money goes'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < campaign.fundUsage.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.fundUsage[i].label,
                                  style: AppText.body.copyWith(fontSize: 15),
                                ),
                                if (campaign.fundUsage[i].note != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      campaign.fundUsage[i].note!,
                                      style: AppText.meta,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (campaign.fundUsage[i].amount != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              Fmt.money(
                                campaign.fundUsage[i].amount!,
                                currency: campaign.currency,
                              ),
                              style: AppText.bodyStrong.copyWith(fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        if (campaign.updates.isNotEmpty) ...[
          const SectionHeader(eyebrow: 'Since we started', title: 'Updates'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final update in campaign.updates) ...[
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (update.publishedAt != null)
                          Text(Fmt.date(update.publishedAt), style: AppText.meta),
                        const SizedBox(height: 4),
                        Text(update.title, style: AppText.title.copyWith(fontSize: 15)),
                        if (update.body != null && update.body!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          HtmlBody(update.body, textStyle: AppText.body.copyWith(fontSize: 15)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: ShareBar(path: '/campaigns/${campaign.slug}', title: campaign.title),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _DonateBar extends StatelessWidget {
  const _DonateBar({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: campaign.isOpen
              ? FilledButton.icon(
                  onPressed: () => context.push(
                    '${Routes.donate}?campaign=${campaign.slug}'
                    '&title=${Uri.encodeComponent(campaign.title)}',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text('Donate to this campaign'),
                )
              : OutlinedButton(
                  onPressed: () => context.push(Routes.donate),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('This appeal has closed — give to the general fund'),
                ),
        ),
      ),
    );
  }
}
