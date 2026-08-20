import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/repository.dart';
import '../../core/models/donation.dart';
import '../../core/router/route_names.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snack.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/state_views.dart';
import '../forms/form_scaffold.dart';

/// The donation form.
///
/// Everything up to the moment money changes hands is native: amount, donor
/// details, PAN above the threshold, anonymity, monthly giving. The payment
/// itself is handed to the gateway's own checkout in the system browser.
///
/// **That hand-off is a deliberate choice, not a shortcut.** Apple's guideline
/// 3.2.1(vi) permits charitable donations collected in a native app only
/// through Apple Pay, SMS, or a website opened outside the app, and apps that
/// have embedded a third-party payments SDK for donations have been rejected
/// for it. Google Play explicitly exempts charitable donations from Play
/// Billing, so Android could take the native route — but one flow that ships on
/// both stores is worth more here than two that diverge, and the browser hand-
/// off is also what keeps card details out of this app's process entirely.
///
/// Confirmation never comes back through the browser. It arrives at the server
/// as a webhook, which is why the order returns an opaque `reference` and the
/// result screen polls it.
class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key, this.campaignSlug, this.campaignTitle});

  final String? campaignSlug;
  final String? campaignTitle;

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pan = TextEditingController();

  String _currency = 'INR';
  bool _anonymous = false;
  bool _recurring = false;
  bool _busy = false;
  int? _preset;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pan.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool _panRequired(DonationOptions options) =>
      _currency == 'INR' && options.panThreshold > 0 && _amountValue >= options.panThreshold;

  Future<void> _submit(DonationOptions options) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _serverErrors = {};
    });

    try {
      final handoff = await ref.read(repositoryProvider).createDonation({
        'amount': _amountValue,
        'currency': _currency,
        'donor_name': _name.text.trim(),
        'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        if (_pan.text.trim().isNotEmpty) 'pan_number': _pan.text.trim().toUpperCase(),
        if (widget.campaignSlug != null) 'campaign_slug': widget.campaignSlug,
        'is_anonymous': _anonymous,
        'is_recurring': _recurring,
      });

      if (!mounted) return;

      final opened = await _openCheckout(handoff);

      if (!mounted) return;

      if (!opened) {
        setState(() => _busy = false);
        AppSnack.show(
          context,
          'Could not open the payment page. Please try again.',
          icon: Icons.error_outline_rounded,
          tone: AppColors.accentDark,
        );

        return;
      }

      // Straight to the result screen. It polls the reference, so a donor who
      // comes back to the app finds out what happened whether the browser
      // returned them or they switched back by hand.
      context.replace(Routes.donateOutcome(handoff.reference));
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _serverErrors = {
          for (final entry in (e.errors ?? {}).entries) entry.key: entry.value.first,
        };
      });

      if (!e.isValidation) AppSnack.error(context, e);
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);
      AppSnack.error(context, e);
    }
  }

  /// Opens the payment.
  ///
  /// One URL for both gateways, and it carries **only the reference**. The
  /// server parked the session payload against that reference when it created
  /// the order, so the page on the other end knows whether to redirect to
  /// Stripe or to start Cashfree's SDK.
  ///
  /// The alternative — putting the payment session id in the URL — would work
  /// and is what a first pass would do. It is avoided because a session id is
  /// a bearer token for that order, and a URL the app hands to the OS ends up
  /// in browser history, in the share sheet, and in every access log on the
  /// way. The reference is opaque and already public to this donor.
  Future<bool> _openCheckout(CheckoutHandoff handoff) async {
    if (handoff.reference.isEmpty) return false;

    final uri = Uri.tryParse(Api.webUrl('/donate/checkout/${handoff.reference}'));
    if (uri == null) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(donationOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Donate'),
      ),
      body: options.when(
        loading: () => const LoadingView(height: 400),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(donationOptionsProvider),
        ),
        data: _form,
      ),
    );
  }

  /// The screen, laid out section for section against the website's donate page.
  ///
  /// Same eyebrow, same headline, same numbered steps, same amount pills, and
  /// the two panels the site keeps in its sidebar — "What happens next" and the
  /// registrations — stacked underneath, which is where a sidebar goes on a
  /// phone. A donor who starts on one and finishes on the other should not have
  /// to work out that they are the same charity.
  Widget _form(DonationOptions options) {
    final panNeeded = _panRequired(options);
    final closed = !options.donationsOpen;
    final campaign = widget.campaignTitle;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign == null ? 'SUPPORT OUR WORK' : 'BACK THIS CAMPAIGN',
                    style: AppText.eyebrow,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign == null ? 'Make a donation' : 'Donate to $campaign',
                    style: AppText.h1.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    campaign == null
                        ? 'General donations fund the reporting: travelling to workshops, '
                            'photographing the work, and the time it takes to do an '
                            'interview properly.'
                        : 'Your donation goes to this campaign and is paid to the supplier '
                            'directly, not as cash.',
                    style: AppText.body.copyWith(
                      fontSize: 15,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Above the form, not instead of it.
            //
            // This screen used to replace everything with "Donations are
            // paused", which is a dead end: a reader cannot see what they were
            // about to be asked, cannot tell whether the app is broken or the
            // charity has switched something off, and has nowhere to go. The
            // website has always shown the form with a banner over it.
            if (closed) const _PausedBanner(),

            FormSection(
              step: 1,
              title: 'How much would you like to give?',
              children: [
                _AmountPills(
                  amounts: options.suggestedAmounts,
                  selected: _preset,
                  currency: _currency,
                  onSelected: (value) => setState(() {
                    _preset = value;
                    _amount.text = '$value';
                  }),
                ),
                const SizedBox(height: 18),
                AppField(
                  label: 'Or enter your own amount',
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  prefix: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Text(
                      _currency == 'INR' ? '₹' : _currency,
                      style: AppText.bodyStrong,
                    ),
                  ),
                  // Clears the pill highlight the moment the figure stops
                  // matching it, so the two can never disagree.
                  onChanged: (value) => setState(() {
                    _preset =
                        options.suggestedAmounts.contains(_amountValue) ? _amountValue : null;
                  }),
                  validator: (value) => Validate.amount(value),
                  serverError: _serverErrors['amount'],
                ),

                if (options.currencies.length > 1) ...[
                  Text('Currency', style: AppText.metaStrong.copyWith(fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final currency in options.currencies)
                        ChoiceChip(
                          label: Text(currency),
                          selected: _currency == currency,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _currency = currency),
                          labelStyle: AppText.button.copyWith(
                            fontSize: 13,
                            color: _currency == currency
                                ? AppColors.primaryForeground
                                : AppColors.foreground,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          side: BorderSide(
                            color:
                                _currency == currency ? AppColors.primary : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),

            FormSection(
              step: 2,
              title: 'Your details',
              subtitle: 'Needed for the receipt, which is emailed to you.',
              children: [
                AppField(
                  label: 'Full name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: Validate.name,
                  serverError: _serverErrors['donor_name'],
                ),
                AppField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  helper: 'Your receipt is sent here.',
                  validator: (value) => Validate.email(value),
                  serverError: _serverErrors['email'],
                ),
                AppField(
                  label: 'Phone',
                  controller: _phone,
                  optional: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                  validator: (value) => Validate.phone(value, optional: true),
                  serverError: _serverErrors['phone'],
                ),

                // Appears the moment the amount crosses the threshold, and the
                // reason is stated rather than assumed — most donors have not
                // memorised Indian tax rules.
                if (panNeeded)
                  AppField(
                    label: 'PAN',
                    controller: _pan,
                    hint: 'ABCDE1234F',
                    helper: 'Required for donations of '
                        '${Fmt.money(options.panThreshold)} or more.',
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      TextInputFormatter.withFunction(
                        (_, next) => next.copyWith(text: next.text.toUpperCase()),
                      ),
                    ],
                    validator: (value) => Validate.pan(value),
                    serverError: _serverErrors['pan_number'],
                  ),

                AppCheckbox(
                  label: 'List my donation anonymously',
                  subtitle: 'Your name stays off the campaign page. '
                      'We still need it for the receipt.',
                  value: _anonymous,
                  onChanged: (value) => setState(() => _anonymous = value),
                ),

                // Only offered where the gateway taking this currency can
                // actually set up a subscription. Cashfree cannot, so INR does
                // not show it — and the server rejects the flag anyway, rather
                // than storing a monthly promise it will charge exactly once.
                if (_currency != 'INR')
                  AppCheckbox(
                    label: 'Give this amount every month',
                    subtitle: 'You can stop at any time.',
                    value: _recurring,
                    onChanged: (value) => setState(() => _recurring = value),
                  ),
                if (_serverErrors['is_recurring'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _serverErrors['is_recurring']!,
                      style: AppText.meta.copyWith(color: AppColors.accentDark),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                children: [
                  SubmitButton(
                    label: closed
                        ? 'Donations are paused'
                        : (_amountValue > 0
                            ? 'Donate ${_currency == "INR" ? Fmt.money(_amountValue) : "$_currency $_amountValue"}'
                            : 'Continue to payment'),
                    accent: true,
                    busy: _busy,
                    enabled: !closed,
                    icon: closed ? Icons.pause_circle_outline_rounded : null,
                    onPressed: () => _submit(options),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Card and bank details are entered on the payment provider’s '
                          'own page and are never seen or stored by us.',
                          style: AppText.meta.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const _WhatHappensNext(),
            const _RegisteredCharity(),
          ],
        ),
      ),
    );
  }
}

/// The suggested amounts, styled as the website styles them.
///
/// A grid rather than a wrapping row of chips: wrapped chips leave a ragged
/// last line and their widths jump about as the figures change, so five choices
/// end up looking like an accident. Equal cells read as a set.
///
/// Selected is an outline and a tint, not a solid fill. These are five
/// equal-weight options, and filling one in solid accent makes it look like the
/// submit button — the reader's eye goes to the wrong red.
class _AmountPills extends StatelessWidget {
  const _AmountPills({
    required this.amounts,
    required this.selected,
    required this.currency,
    required this.onSelected,
  });

  final List<int> amounts;
  final int? selected;
  final String currency;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        // Three to a row, measured against the real constraint. Deriving it
        // from the screen width instead gives cells that sum to exactly the
        // space available, and Wrap treats "exactly" as "does not fit".
        final width = (constraints.maxWidth - gap * 2) / 3 - 0.5;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final amount in amounts)
              SizedBox(
                width: width,
                child: _Pill(
                  label: Fmt.money(amount, currency: currency),
                  selected: selected == amount,
                  onTap: () => onSelected(amount),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0x0DE63946) : AppColors.background,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppText.button.copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.accent : AppColors.foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The website's sidebar panel, stacked under the form.
class _WhatHappensNext extends StatelessWidget {
  const _WhatHappensNext();

  static const _steps = [
    'You pay on the gateway’s secure page.',
    'We confirm the payment with the gateway directly.',
    'Your receipt arrives by email, with 80G details for INR gifts.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What happens next', style: AppText.h3.copyWith(fontSize: 16)),
            const SizedBox(height: 14),
            for (var i = 0; i < _steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 22,
                    width: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.metaStrong.copyWith(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_steps[i], style: AppText.excerpt.copyWith(height: 1.5)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The registrations, beside the amount rather than only in the footer.
///
/// This is the moment somebody decides whether to trust the form, and sending
/// them to the More tab to check is a trip they may not come back from.
class _RegisteredCharity extends StatelessWidget {
  const _RegisteredCharity();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A registered charity', style: AppText.h3.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            const _Credential('Section 8 Company, registered 2019'),
            const SizedBox(height: 8),
            const _Credential('12A and 80G certified'),
            const SizedBox(height: 8),
            _Credential(
              'Every rupee published on our transparency page',
              onTap: () => context.push('${Routes.more}/transparency'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Credential extends StatelessWidget {
  const _Credential(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppText.excerpt.copyWith(
                height: 1.5,
                color: onTap == null ? AppColors.mutedForeground : AppColors.primary,
                fontWeight: onTap == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown above the form when no gateway is live.
///
/// Not an error, and not the app's fault — an admin can switch donations off,
/// and the same banner appears on the website. Amber rather than red for
/// exactly that reason: this is a notice, not a failure, and colouring it like
/// a crash would have people reporting a broken app.
///
/// It offers a way through rather than just stopping: somebody who arrived here
/// meaning to give should leave having been able to.
class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.pause_circle_outline_rounded, size: 18, color: Color(0xFF92400E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Online donations are paused',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              'We are not able to take card or UPI payments at the moment. '
              'Get in touch and we will arrange it another way.',
              style: AppText.meta.copyWith(color: const Color(0xFF92400E), height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: TextButton.icon(
              onPressed: () => context.push('${Routes.more}/contact'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF78350F),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: const Text('Contact us'),
            ),
          ),
        ],
      ),
    );
  }
}

