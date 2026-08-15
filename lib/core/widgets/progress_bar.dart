import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// A campaign's raised-against-goal bar, with the figures above it.
///
/// Accent red is correct here — it is one of the three places the palette
/// reserves it for. The fraction is clamped in the model, so a campaign that
/// overshoots its goal shows a full bar rather than overflowing the track.
class CampaignProgress extends StatelessWidget {
  const CampaignProgress({
    super.key,
    required this.campaign,
    this.compact = false,
  });

  final Campaign campaign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final raised = compact
        ? Fmt.compactMoney(campaign.raisedAmount)
        : Fmt.money(campaign.raisedAmount, currency: campaign.currency);
    final goal = compact
        ? Fmt.compactMoney(campaign.goalAmount)
        : Fmt.money(campaign.goalAmount, currency: campaign.currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: raised,
                      style: (compact ? AppText.bodyStrong : AppText.figure)
                          .copyWith(color: AppColors.foreground),
                    ),
                    TextSpan(text: '  of $goal', style: AppText.meta),
                  ],
                ),
              ),
            ),
            Text(
              '${(campaign.progressFraction * 100).round()}%',
              style: AppText.metaStrong.copyWith(color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: campaign.progressFraction,
            minHeight: compact ? 6 : 8,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (campaign.donorCount > 0) ...[
              const Icon(Icons.favorite_rounded, size: 12, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text('${Fmt.count(campaign.donorCount)} donors', style: AppText.meta),
            ],
            const Spacer(),
            if (campaign.daysRemaining != null)
              Text(
                campaign.daysRemaining! <= 0
                    ? 'Closed'
                    : '${campaign.daysRemaining} days left',
                style: AppText.meta,
              ),
          ],
        ),
      ],
    );
  }
}
