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
/// select, map a 422 field-by-field onto their inputs, keep the submit
/// reachable, and replace themselves with a confirmation that quotes the
/// server's own wording. Doing that four times over would be four chances to
/// do it differently.
///
/// The layout is deliberately not one long scroll of inputs. These forms run to
/// twenty-odd fields, and an undifferentiated column of them is the reason long
/// forms get abandoned halfway. Instead: a tinted page, numbered sections as
/// white cards, and the submit **pinned to the bottom** so it is never a
/// thousand pixels away from wherever the reader has got to.
///
/// [FormController] holds the submission mechanics; [FormPage] holds the frame.
mixin FormController<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();

  bool busy = false;
  Map<String, String> serverErrors = {};
  String? confirmation;

  /// Reads the field's server-side complaint, if it has one.
  String? errorFor(String field) => serverErrors[field];

  /// Records a complaint the app itself is making, in the same place the
  /// server's would appear — so a screen never has two ways of saying "this
  /// field is wrong".
  void complain(String field, String message) {
    setState(() => serverErrors = {...serverErrors, field: message});
  }

  /// Runs [send], mapping every outcome onto the screen.
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

/// The frame: header, options gate, sections, pinned submit, confirmation.
class FormPage extends ConsumerWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.builder,
    this.formKey,
    this.confirmation,
    this.confirmationTitle = 'Thank you',
    this.intro,
    this.introTitle,
    this.introIcon,
    this.submitLabel,
    this.onSubmit,
    this.busy = false,
  });

  final String title;

  /// Given the loaded option lists, because a select cannot be drawn without
  /// them and a hard-coded copy is what causes the 422s the endpoint exists to
  /// prevent.
  final Widget Function(BuildContext context, FormOptions options) builder;

  final GlobalKey<FormState>? formKey;

  /// Non-null once the submission succeeded — the server's own words.
  final String? confirmation;
  final String confirmationTitle;

  final String? introTitle;
  final String? intro;
  final IconData? introIcon;

  /// When both are given, the submit sits in a bar pinned to the bottom.
  final String? submitLabel;
  final VoidCallback? onSubmit;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(formOptionsProvider);
    final done = confirmation != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: screenBar(title),
      body: done
          ? _Confirmation(title: confirmationTitle, message: confirmation!)
          : options.when(
              loading: () => const LoadingView(height: 420),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(formOptionsProvider),
              ),
              data: (data) => _Body(
                introIcon: introIcon,
                introTitle: introTitle,
                intro: intro,
                formKey: formKey,
                child: builder(context, data),
              ),
            ),
      bottomNavigationBar: done || submitLabel == null || onSubmit == null
          ? null
          : _SubmitBar(label: submitLabel!, busy: busy, onPressed: onSubmit!),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.child,
    required this.formKey,
    this.introIcon,
    this.introTitle,
    this.intro,
  });

  final Widget child;
  final GlobalKey<FormState>? formKey;
  final IconData? introIcon;
  final String? introTitle;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (introTitle != null || intro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (introIcon != null) ...[
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(introIcon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                ],
                if (introTitle != null)
                  Text(introTitle!, style: AppText.h1.copyWith(fontSize: 24)),
                if (intro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    intro!,
                    style: AppText.body.copyWith(fontSize: 15, color: AppColors.mutedForeground),
                  ),
                ],
              ],
            ),
          ),
        child,
        const SizedBox(height: 24),
      ],
    );

    if (formKey != null) content = Form(key: formKey, child: content);

    return SingleChildScrollView(
      // The keyboard is handled by the Scaffold; this only has to clear the
      // pinned bar.
      padding: const EdgeInsets.only(bottom: 8),
      child: content,
    );
  }
}

/// One numbered step: a heading on the tinted page, and its fields in a card.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.step,
    required this.title,
    required this.children,
    this.subtitle,
  });

  /// Shown in a small disc beside the heading.
  ///
  /// Numbering is not decoration. These forms are long enough that a reader
  /// needs to know where they are and how much is left, and "3" beside a
  /// heading answers both without a progress bar that would have to lie about
  /// what counts as done.
  final int step;

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: AppText.metaStrong.copyWith(
                    color: AppColors.primaryForeground,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3.copyWith(fontSize: 16)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: AppText.meta),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 2),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

/// The consent box.
///
/// Set apart from the other fields on purpose. On both application forms and
/// the interview registration this is not a formality — the server refuses the
/// submission without it, and on the interview form it is a person agreeing
/// that photographs of them will be published. A tick box lost among twenty
/// others would be consent in name only.
class ConsentBox extends StatelessWidget {
  const ConsentBox({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final wrong = error != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Material(
        color: wrong ? const Color(0x0DC22B38) : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: wrong
                    ? AppColors.accentDark
                    : (value ? AppColors.primary : AppColors.border),
                width: value || wrong ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: value,
                          onChanged: (v) => onChanged(v ?? false),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: AppText.body.copyWith(fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 2),
                            Text(subtitle, style: AppText.meta),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (wrong)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 34),
                      child: Text(
                        error!,
                        style: AppText.meta.copyWith(color: AppColors.accentDark),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The submit, pinned above the tab bar.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

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
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                // Full colour while busy: fading it to a tint would take the
                // white spinner with it.
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.primaryForeground,
              ),
              icon: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(busy ? 'Sending…' : label),
            ),
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
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
            child: const TcifLogo(size: 56),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(title, style: AppText.h2),
            ],
          ),
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
