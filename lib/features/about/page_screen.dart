import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/html_body.dart';
import '../../core/widgets/state_views.dart';

/// The static pages — privacy, terms, refunds and anything else the office
/// publishes. One screen for all of them, keyed on the slug.
class PageScreen extends ConsumerWidget {
  const PageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pageProvider(slug));

    return Scaffold(
      appBar: screenBar(page.valueOrNull?.title ?? ''),
      body: page.when(
        loading: () => const LoadingView(height: 420),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(pageProvider(slug)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Text(data.title, style: AppText.h1),
            if (data.updatedAtLabel != null) ...[
              const SizedBox(height: 6),
              Text('Last updated ${data.updatedAtLabel}', style: AppText.meta),
            ],
            const SizedBox(height: 18),
            HtmlBody(data.body),
          ],
        ),
      ),
    );
  }
}
