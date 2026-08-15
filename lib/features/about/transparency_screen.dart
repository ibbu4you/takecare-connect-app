import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/site.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';

/// Where the money went.
///
/// The one screen whose purpose is to be checked rather than read. It shows
/// the ledger totals per campaign and — importantly — surfaces any campaign
/// whose cached total disagrees with its ledger, rather than quietly printing
/// the prettier of the two numbers.
class TransparencyScreen extends ConsumerWidget {
  const TransparencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(transparencyProvider);

    return Scaffold(
      appBar: screenBar('Where the money goes'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(transparencyProvider.future),
        child: data.when(
          loading: () => const LoadingView(height: 420),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(transparencyProvider),
          ),
          data: (data) => _Transparency(data: data),
        ),
      ),
    );
  }
}

class _Transparency extends StatelessWidget {
  const _Transparency({required this.data});

  final TransparencyData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 36),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.title, style: AppText.h1),
              if (data.body != null && data.body!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                HtmlBody(data.body),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              _Total(
                label: 'Raised all time',
                value: Fmt.money(data.allTime),
                emphasis: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Total(label: 'This year', value: Fmt.money(data.thisYear)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Total(
                      label: 'General fund',
                      value: Fmt.money(data.generalFund),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Total(label: 'Donations', value: Fmt.count(data.donationCount)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Total(label: 'Donors', value: Fmt.count(data.donorCount)),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (data.campaigns.isNotEmpty) ...[
          const SectionHeader(title: 'Campaign by campaign'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final row in data.campaigns) ...[
                  _LedgerRow(row: row),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: Text(
            'Figures are taken from the donation ledger and update as payments '
            'are confirmed. Take Care International Foundation is registered '
            'under Section 8 with 12A and 80G certification.',
            style: AppText.meta,
          ),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: emphasis ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: emphasis ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.meta.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: emphasis ? AppColors.footerMuted : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.figure.copyWith(
                fontSize: emphasis ? 30 : 22,
                color: emphasis ? AppColors.primaryForeground : AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.row});

  final TransparencyLedgerRow row;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.campaign(row.campaign.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.campaign.title,
                  style: AppText.title.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Fmt.money(row.ledgerTotal, currency: row.campaign.currency),
                style: AppText.bodyStrong.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${Fmt.count(row.donorCount)} donors  ·  '
                'goal ${Fmt.money(row.campaign.goalAmount, currency: row.campaign.currency)}',
                style: AppText.meta,
              ),
              const Spacer(),
              // Shown rather than hidden. A page whose whole point is
              // accountability cannot quietly round away a discrepancy.
              if (!row.reconciles)
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.accentDark),
                    const SizedBox(width: 4),
                    Text(
                      'Under review',
                      style: AppText.meta.copyWith(color: AppColors.accentDark),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
