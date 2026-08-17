import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/repository.dart';
import '../../core/models/donation.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/tcif_logo.dart';

/// What happened to the payment.
///
/// The app cannot know. A gateway hands control back to the device the instant
/// its checkout closes, but the only thing that marks a donation paid is the
/// webhook, arriving server-to-server and possibly seconds behind. So this
/// screen polls `/donations/{reference}/status` and says plainly which of the
/// three states the donation is in.
///
/// The polling stops. It backs off, and after roughly two minutes it gives up
/// and tells the donor the truth — that the payment is still being confirmed
/// and the receipt will arrive by email. A spinner that never ends is how a
/// donor ends up paying twice.
class DonateResultScreen extends ConsumerStatefulWidget {
  const DonateResultScreen({super.key, required this.reference});

  final String reference;

  @override
  ConsumerState<DonateResultScreen> createState() => _DonateResultScreenState();
}

class _DonateResultScreenState extends ConsumerState<DonateResultScreen> {
  /// Widening gaps: quick while the webhook is most likely to land, then
  /// slower, rather than hammering the endpoint for two minutes.
  static const _schedule = [3, 3, 4, 5, 6, 8, 10, 12, 15, 20, 20, 20];

  Timer? _timer;
  int _attempt = 0;
  bool _gaveUp = false;
  DonationStatus? _status;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await ref.read(repositoryProvider).donationStatus(widget.reference);

      if (!mounted) return;

      setState(() {
        _status = status;
        _error = null;
      });

      // Keep going a little past "paid" while the receipt is still being
      // written. The PDF comes from a queued job that runs after the webhook,
      // so stopping the moment the status flips would show a donor the success
      // screen without the download and never come back for it. The success
      // state is already on screen either way — this only adds the button.
      if (status.hasFailed) return;
      if (!status.isPending && status.hasReceipt) return;
    } catch (e) {
      if (!mounted) return;

      // A failed poll is not a failed donation. Keep the last known state on
      // screen and try again — the donor should not be told their gift failed
      // because the phone lost signal.
      setState(() => _error = e);
    }

    if (_attempt >= _schedule.length) {
      if (mounted) setState(() => _gaveUp = true);

      return;
    }

    final delay = _schedule[_attempt];
    _attempt++;

    _timer = Timer(Duration(seconds: delay), () {
      if (mounted) _poll();
    });
  }

  void _retry() {
    setState(() {
      _attempt = 0;
      _gaveUp = false;
      _error = null;
    });
    _poll();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return PopScope(
      // Back must not return to the donate form, which would invite a second
      // payment. The one way out of this screen is forward.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.give);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => context.go(Routes.give),
              child: const Text('Done'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (status == null && _error != null)
                ErrorView(error: _error, onRetry: _retry)
              else if (status == null)
                const _Pending(message: 'Confirming your payment…')
              else if (status.isPaid)
                _Success(status: status)
              else if (status.hasFailed)
                _Failed(reference: widget.reference)
              else if (_gaveUp)
                _StillPending(reference: widget.reference)
              else
                const _Pending(message: 'Waiting for the payment to be confirmed…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const SizedBox(
            height: 34,
            width: 34,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 22),
          Text(message, style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Please keep this screen open. If you have already completed the '
            'payment in your browser, this will update on its own.',
            style: AppText.excerpt,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.status});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const TcifLogo(size: 62),
        const SizedBox(height: 20),
        Text('Thank you', style: AppText.h1, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          status.isRecurring
              ? 'Your monthly gift of ${Fmt.money(status.amount, currency: status.currency)} is set up.'
              : 'Your gift of ${Fmt.money(status.amount, currency: status.currency)} has gone through.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              if (status.receiptNumber != null) ...[
                _Row(label: 'Receipt', value: status.receiptNumber!),
                const Divider(height: 20),
              ],
              if (status.paidAt != null) ...[
                _Row(label: 'Date', value: Fmt.date(status.paidAt)),
                const Divider(height: 20),
              ],
              _Row(
                label: 'Amount',
                value: Fmt.money(status.amount, currency: status.currency),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          status.hasReceipt
              ? 'Your 80G receipt has also been emailed to you.'
              : 'An 80G receipt is on its way to your email. It may take a few minutes.',
          style: AppText.excerpt,
          textAlign: TextAlign.center,
        ),

        // Only once the PDF genuinely exists.
        //
        // It is written by a queued job after the webhook lands, so a donor
        // who reaches this screen a few seconds after paying has a receipt
        // number and no document. A button that 404s would be worse than no
        // button; the polling picks the link up when it appears.
        if (status.hasReceipt) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            // Opened in the browser, not downloaded into the app: it is a PDF
            // carrying the donor's name and PAN, and it has no business being
            // cached anywhere this app controls.
            onPressed: () => launchUrl(
              Uri.parse(status.receiptUrl!),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Download your 80G receipt'),
          ),
        ],

        const SizedBox(height: 26),
        FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Back to the app'),
        ),
        const SizedBox(height: 10),
        if (status.campaignSlug != null)
          OutlinedButton(
            onPressed: () => context.go(Routes.campaign(status.campaignSlug!)),
            child: const Text('See the campaign'),
          ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.accentDark),
        const SizedBox(height: 18),
        Text('That payment did not go through', style: AppText.h2, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'Nothing has been taken from your account. You are welcome to try '
          'again, and if the money did leave your account please send us this '
          'reference and we will trace it.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        _ReferenceChip(reference: reference),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: () => context.go(Routes.donate),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accentButton),
          child: const Text('Try again'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go('${Routes.more}/contact'),
          child: const Text('Contact us'),
        ),
      ],
    );
  }
}

/// After the polling window closes with no answer.
class _StillPending extends StatelessWidget {
  const _StillPending({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Icon(Icons.schedule_rounded, size: 44, color: AppColors.mutedForeground),
        const SizedBox(height: 18),
        Text('Still being confirmed', style: AppText.h2, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'Your bank has not confirmed the payment to us yet. This usually '
          'resolves within a few minutes, and your receipt will arrive by '
          'email when it does.\n\nPlease do not pay again — if anything has '
          'gone wrong we will find it with this reference.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        _ReferenceChip(reference: reference),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Back to the app'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go('${Routes.more}/contact'),
          child: const Text('Contact us about this'),
        ),
      ],
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('REFERENCE', style: AppText.meta.copyWith(fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 2),
          SelectableText(
            reference,
            style: AppText.metaStrong.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.meta),
        Flexible(
          child: Text(
            value,
            style: AppText.bodyStrong.copyWith(fontSize: 15),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
