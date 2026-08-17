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
import '../../core/widgets/tcif_logo.dart';

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
      appBar: AppBar(title: const Text('Donate')),
      body: options.when(
        loading: () => const LoadingView(height: 400),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(donationOptionsProvider),
        ),
        data: (data) => data.donationsOpen ? _form(data) : const _Closed(),
      ),
    );
  }

  Widget _form(DonationOptions options) {
    final panNeeded = _panRequired(options);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.campaignTitle != null)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You are giving to', style: AppText.meta),
                          Text(
                            widget.campaignTitle!,
                            style: AppText.title.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Text('How much would you like to give?', style: AppText.h3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in options.suggestedAmounts)
                  ChoiceChip(
                    label: Text(Fmt.money(amount)),
                    selected: _preset == amount,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _preset = amount;
                      _amount.text = '$amount';
                    }),
                    labelStyle: AppText.button.copyWith(
                      fontSize: 14,
                      color: _preset == amount
                          ? AppColors.accentForeground
                          : AppColors.foreground,
                    ),
                    selectedColor: AppColors.accentButton,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: _preset == amount ? AppColors.accent : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppField(
              label: 'Amount',
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
              // Clears the pill highlight the moment the figure stops matching
              // it, so the two can never disagree.
              onChanged: (value) => setState(() {
                _preset = options.suggestedAmounts.contains(_amountValue) ? _amountValue : null;
              }),
              validator: (value) => Validate.amount(value),
              serverError: _serverErrors['amount'],
            ),

            if (options.currencies.length > 1) ...[
              Text('Currency', style: AppText.metaStrong.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
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
                        color: _currency == currency ? AppColors.primary : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            const Divider(height: 32),
            Text('Your details', style: AppText.h3),
            const SizedBox(height: 4),
            Text(
              'Needed for the receipt, which is emailed to you.',
              style: AppText.excerpt,
            ),
            const SizedBox(height: 14),

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
              helper: 'Your 80G receipt goes here.',
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
                helper: 'Indian tax rules require a PAN for gifts of '
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

            const SizedBox(height: 4),
            AppCheckbox(
              label: 'Give anonymously',
              subtitle: 'Your name will not appear on the campaign page.',
              value: _anonymous,
              onChanged: (value) => setState(() => _anonymous = value),
            ),

            // Only offered where the gateway taking this currency can actually
            // set up a subscription. Cashfree cannot, so INR does not show it —
            // and the server rejects the flag anyway, rather than storing a
            // monthly promise it will charge exactly once.
            if (_currency != 'INR')
              AppCheckbox(
                label: 'Make this a monthly gift',
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

            const SizedBox(height: 22),
            SubmitButton(
              label: _amountValue > 0
                  ? 'Give ${_currency == "INR" ? Fmt.money(_amountValue) : "$_currency $_amountValue"}'
                  : 'Continue to payment',
              accent: true,
              busy: _busy,
              icon: Icons.lock_outline_rounded,
              onPressed: () => _submit(options),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment opens in your browser on our secure page. Your card '
                    'details are never handled by this app.',
                    style: AppText.meta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _Credentials(),
          ],
        ),
      ),
    );
  }
}

/// Shown when no gateway is live.
///
/// This is not an error — an admin can turn donations off, and a screen that
/// showed a broken form would be worse than one that says so.
class _Closed extends StatelessWidget {
  const _Closed();

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: 'Donations are paused',
      subtitle: 'We are not taking online donations at the moment. '
          'Please get in touch and we will arrange it another way.',
      icon: Icons.pause_circle_outline_rounded,
      action: OutlinedButton(
        onPressed: () => context.push('${Routes.more}/contact'),
        child: const Text('Contact us'),
      ),
    );
  }
}

/// The registrations a donor checks before giving.
class _Credentials extends ConsumerWidget {
  const _Credentials();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(settingsProvider).valueOrNull?.credentials ?? const [];

    if (credentials.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          const TcifLogo(size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              credentials.join('  ·  '),
              style: AppText.meta.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
