import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/site.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';

/// Who the foundation is: vision, mission, values, focus areas and the numbers.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final about = ref.watch(aboutProvider);

    return Scaffold(
      appBar: screenBar('About us'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(aboutProvider.future),
        child: about.when(
          loading: () => const LoadingView(height: 420),
          error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(aboutProvider)),
          data: (data) => _About(about: data),
        ),
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.about});

  final AboutContent about;

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
              const TcifLogo(size: 54),
              const SizedBox(height: 18),
              if (about.introEyebrow.isNotEmpty)
                Text(about.introEyebrow.toUpperCase(), style: AppText.eyebrow),
              if (about.introHeading.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(about.introHeading, style: AppText.h1),
              ],
              if (about.introBody.isNotEmpty) ...[
                const SizedBox(height: 12),
                HtmlBody(about.introBody),
              ],
            ],
          ),
        ),

        if (about.stats.isNotEmpty) _Stats(stats: about.stats),

        if (about.vision.isNotEmpty || about.mission.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                if (about.vision.isNotEmpty)
                  _Statement(
                    icon: Icons.visibility_outlined,
                    label: 'Our vision',
                    body: about.vision,
                  ),
                if (about.vision.isNotEmpty && about.mission.isNotEmpty)
                  const SizedBox(height: 12),
                if (about.mission.isNotEmpty)
                  _Statement(
                    icon: Icons.flag_outlined,
                    label: 'Our mission',
                    body: about.mission,
                  ),
              ],
            ),
          ),

        if (about.values.isNotEmpty) ...[
          SectionHeader(
            eyebrow: 'What we stand for',
            title: 'Our values',
            description: about.valuesLead.isEmpty ? null : about.valuesLead,
          ),
          _Blocks(blocks: about.values),
        ],

        if (about.focusAreas.isNotEmpty) ...[
          SectionHeader(
            title: about.focusHeading.isEmpty ? 'Where we work' : about.focusHeading,
            description: about.focusLead.isEmpty ? null : about.focusLead,
          ),
          _FocusAreas(areas: about.focusAreas),
        ],

        if (about.extraBody != null && about.extraBody!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: HtmlBody(about.extraBody),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Column(
            children: [
              FilledButton.icon(
                onPressed: () => context.push('${Routes.more}/transparency'),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('See where the money goes'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('${Routes.more}/contact'),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: const Text('Get in touch'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final List<AboutStat> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      // Measured, not computed from the screen width.
      //
      // Deriving it as `(screenWidth - padding - gap) / 2` gives a pair that
      // sums to *exactly* the space available, and Wrap treats "exactly" as
      // "doesn't fit" once floating point has had its say — so every card drops
      // onto its own row and the section becomes a column of half-empty boxes.
      // Half a pixel of slack, against the real constraint, is the fix.
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: (constraints.maxWidth - 12) / 2 - 0.5,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stat.value,
                          style: AppText.figure.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat.label,
                        style: AppText.meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Statement extends StatelessWidget {
  const _Statement({required this.icon, required this.label, required this.body});

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: AppText.metaStrong.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          HtmlBody(body, textStyle: AppText.body.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

/// The focus areas.
///
/// Split by whether the entry has any prose, because the API sends two shapes
/// under one key: a focus area is usually just a `label` — "Schooling",
/// "Healthcare" — while a few carry a paragraph. A column of full-width cards
/// holding one word each would be several screens of whitespace, so the bare
/// labels wrap as chips and only the ones with something to say get a card.
class _FocusAreas extends StatelessWidget {
  const _FocusAreas({required this.areas});

  final List<AboutBlock> areas;

  @override
  Widget build(BuildContext context) {
    final labels = areas.where((a) => a.body.trim().isEmpty).toList();
    final described = areas.where((a) => a.body.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final area in labels) Pill(area.title)],
            ),
          ),
        if (labels.isNotEmpty && described.isNotEmpty) const SizedBox(height: 14),
        if (described.isNotEmpty) _Blocks(blocks: described),
      ],
    );
  }
}

class _Blocks extends StatelessWidget {
  const _Blocks({required this.blocks});

  final List<AboutBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final block in blocks) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title, style: AppText.h3.copyWith(fontSize: 16)),
                  if (block.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    HtmlBody(block.body, textStyle: AppText.body.copyWith(fontSize: 15)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
