library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/site.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/state_views.dart';

/// What listing in the shop costs a craftsman, for somebody deciding.
///
/// **There is no way to pay from this screen, and there should not be.**
/// Membership is paid in the seller panel, behind a login this app does not
/// have — so this explains the terms and then points at the application form,
/// which is the step that actually comes first anyway.
///
/// The prices come from the server's plans table rather than from the page
/// copy, for the reason the website's own controller gives: a price typed into
/// an editor is a price that will disagree with what the gateway charges, and
/// the first person to notice is the member paying it.
class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(membershipProvider);

    return Scaffold(
      appBar: screenBar(membership.valueOrNull?.title ?? 'Membership'),
      body: membership.when(
        loading: () => const LoadingView(height: 420),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(membershipProvider),
        ),
        data: (data) => _Membership(content: data),
      ),
    );
  }
}

class _Membership extends StatelessWidget {
  const _Membership({required this.content});

  final MembershipContent content;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Text('Listing your work', style: AppText.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          'A membership puts your shop page and everything on it in front of '
          'people looking for exactly what you make. We take no commission: '
          'buyers contact you and settle it with you.',
          style: AppText.lead.copyWith(color: AppColors.mutedForeground),
        ),

        if (content.plans.isNotEmpty) ...[
          const SizedBox(height: 22),
          for (final plan in content.plans) ...[
            _Plan(plan: plan),
            const SizedBox(height: 12),
          ],
        ],

        if (content.graceDays > 0) ...[
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('If it lapses', style: AppText.title.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        'Your shop stays up for ${content.graceDays} days after a '
                        'membership runs out, so a late renewal costs you nothing. '
                        'Nothing you have written is deleted.',
                        style: AppText.excerpt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (content.body != null && content.body!.isNotEmpty) ...[
          const SizedBox(height: 20),
          HtmlBody(content.body!),
        ],

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(Routes.sellWithUs),
          icon: const Icon(Icons.edit_note_rounded, size: 18),
          label: const Text('Apply to sell with us'),
        ),
        const SizedBox(height: 10),
        Text(
          'Applying is free and comes first — somebody here reads it and gets in '
          'touch before anything is paid.',
          style: AppText.meta,
          textAlign: TextAlign.center,
        ),

        if (content.contactEmail != null && content.contactEmail!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse('mailto:${content.contactEmail}')),
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text('Ask us: ${content.contactEmail}'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(plan.name, style: AppText.h3.copyWith(fontSize: 17))),
              if (plan.isFree)
                const Pill.success('Free')
              else
                Text(
                  plan.priceLabel,
                  style: AppText.bodyStrong.copyWith(color: AppColors.primary),
                ),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.description!, style: AppText.excerpt),
          ],
        ],
      ),
    );
  }
}
