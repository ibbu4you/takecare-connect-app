import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/site.dart';
import '../../core/router/app_router.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_snack.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';

/// What the four submission screens have in common.
///
/// All of them: wait for `/form-options` before they can render a single
/// select, map a 422 field-by-field onto their inputs, disable the submit
/// while it is in flight, and replace themselves with a confirmation that
/// quotes the server's own wording. Doing that four times over would be four
/// chances to do it differently.
///
/// [FormController] holds the submission mechanics; [FormPage] holds the frame.
mixin FormController<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();

  bool busy = false;
  Map<String, String> serverErrors = {};
  String? confirmation;

  /// Reads the field's server-side complaint, if it has one.
  String? errorFor(String field) => serverErrors[field];

  /// Runs [send], mapping every outcome onto the screen.
  ///
  /// Returns nothing: the caller's job is done once it has handed over the
  /// request. The confirmation, the field errors and the busy flag are all set
  /// here so no screen can forget one of them.
  Future<void> submit(Future<String> Function() send) async {
    FocusScope.of(context).unfocus();

    if (!formKey.currentState!.validate()) {
      // A long form scrolled past its first invalid field would otherwise show
      // no visible reason for refusing to submit.
      AppSnack.show(
        context,
        'Please check the highlighted fields.',
        icon: Icons.error_outline_rounded,
        tone: AppColors.accentDark,
      );

      return;
    }

    setState(() {
      busy = true;
      serverErrors = {};
    });

    try {
      final message = await send();

      if (!mounted) return;

      setState(() {
        busy = false;
        confirmation = message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        busy = false;
        serverErrors = {
          for (final entry in (e.errors ?? {}).entries) entry.key: entry.value.first,
        };
      });

      if (e.isValidation) {
        AppSnack.show(
          context,
          'Please check the highlighted fields.',
          icon: Icons.error_outline_rounded,
          tone: AppColors.accentDark,
        );
      } else {
        AppSnack.error(context, e);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => busy = false);
      AppSnack.error(context, e);
    }
  }
}

/// The frame: app bar, options gate, and the confirmation that replaces the
/// form once it has been sent.
class FormPage extends ConsumerWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.builder,
    this.confirmation,
    this.confirmationTitle = 'Thank you',
    this.intro,
    this.introTitle,
  });

  final String title;

  /// Given the loaded option lists, because a select cannot be drawn without
  /// them and a hard-coded copy is what causes the 422s the endpoint exists to
  /// prevent.
  final Widget Function(BuildContext context, FormOptions options) builder;

  /// Non-null once the submission succeeded — the server's own words.
  final String? confirmation;
  final String confirmationTitle;

  final String? introTitle;
  final String? intro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(formOptionsProvider);

    return Scaffold(
      appBar: screenBar(title),
      body: confirmation != null
          ? _Confirmation(title: confirmationTitle, message: confirmation!)
          : options.when(
              loading: () => const LoadingView(height: 420),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(formOptionsProvider),
              ),
              data: (data) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (introTitle != null) ...[
                      Text(introTitle!, style: AppText.h1.copyWith(fontSize: 24)),
                      const SizedBox(height: 8),
                    ],
                    if (intro != null) ...[
                      Text(intro!, style: AppText.body.copyWith(fontSize: 15)),
                      const SizedBox(height: 22),
                    ],
                    builder(context, data),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
      child: Column(
        children: [
          const TcifLogo(size: 56),
          const SizedBox(height: 22),
          Text(title, style: AppText.h1, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(message, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// A labelled group of fields, so long forms read as sections rather than a
/// wall of inputs.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h3.copyWith(fontSize: 16)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppText.meta),
        ],
        const SizedBox(height: 14),
        ...children,
        const SizedBox(height: 10),
      ],
    );
  }
}
