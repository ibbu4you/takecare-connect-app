import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repository.dart';
import '../../core/models/business.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snack.dart';
import '../../core/widgets/form_fields.dart';

/// The lead-capture form.
///
/// Two intents, one form, matching the website exactly:
///
/// **`call`** — the reader wants the number. Name and phone only, because this
/// form stands between somebody and a phone number and every extra field is a
/// reason to give up. The number comes back in the response.
///
/// **`enquiry`** — the office forwards a written message to the maker. Email
/// and message become required, because there is nowhere to send a reply
/// without them.
///
/// Which one is offered depends on whether the craftsman has a number stored at
/// all. Most imported ones do not — the old site's "View Number" button was
/// itself a lead form, so the maker's number was never recorded — and offering
/// a reveal that cannot reveal anything would be a lie.
class EnquirySheet extends ConsumerStatefulWidget {
  const EnquirySheet({super.key, required this.business});

  final BusinessDetail business;

  static Future<void> open(BuildContext context, {required BusinessDetail business}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (context) => Padding(
        // Lifts the sheet clear of the keyboard, which otherwise covers the
        // message field and the submit button together.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: EnquirySheet(business: business),
      ),
    );
  }

  @override
  ConsumerState<EnquirySheet> createState() => _EnquirySheetState();
}

class _EnquirySheetState extends ConsumerState<EnquirySheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  late String _intent = widget.business.contact.hasPhone ? 'call' : 'enquiry';
  bool _busy = false;
  Map<String, String> _serverErrors = {};

  /// Set when a phone reveal succeeds — the sheet then shows the number
  /// instead of the form.
  String? _revealed;

  bool get _isEnquiry => _intent == 'enquiry';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _serverErrors = {};
    });

    try {
      final result = await ref.read(repositoryProvider).sendEnquiry(
            slug: widget.business.slug,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            intent: _intent,
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            message: _message.text.trim().isEmpty ? null : _message.text.trim(),
          );

      if (!mounted) return;

      if (result.phone != null && result.phone!.isNotEmpty) {
        setState(() {
          _busy = false;
          _revealed = result.phone;
        });

        return;
      }

      Navigator.pop(context);
      AppSnack.success(context, result.message);
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

  @override
  Widget build(BuildContext context) {
    if (_revealed != null) return _Revealed(phone: _revealed!, business: widget.business);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEnquiry ? 'Send an enquiry' : 'Get their number',
              style: AppText.h2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              _isEnquiry
                  ? 'We will pass this to ${widget.business.ownerName ?? widget.business.name} and they will reply to you directly.'
                  : 'Tell us who is calling, and the number is yours.',
              style: AppText.excerpt,
            ),
            const SizedBox(height: 18),

            // Only offered when there is genuinely a number behind it.
            if (widget.business.contact.hasPhone) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'call',
                    label: Text('Call them'),
                    icon: Icon(Icons.call_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'enquiry',
                    label: Text('Write'),
                    icon: Icon(Icons.mail_outline_rounded, size: 16),
                  ),
                ],
                selected: {_intent},
                showSelectedIcon: false,
                onSelectionChanged: (value) => setState(() => _intent = value.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: AppColors.primaryForeground,
                  textStyle: AppText.button.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 18),
            ],

            AppField(
              label: 'Your name',
              controller: _name,
              validator: Validate.name,
              serverError: _serverErrors['name'],
              textCapitalization: TextCapitalization.words,
            ),
            AppField(
              label: 'Your phone number',
              controller: _phone,
              hint: '10-digit mobile',
              helper: 'So they can call you back.',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
              validator: Validate.phone,
              serverError: _serverErrors['phone'],
            ),
            AppField(
              label: 'Your email',
              controller: _email,
              optional: !_isEnquiry,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: (value) => Validate.email(value, optional: !_isEnquiry),
              serverError: _serverErrors['email'],
            ),
            if (_isEnquiry)
              AppField(
                label: 'What are you after?',
                controller: _message,
                hint: 'A sentence or two, so they can answer properly.',
                maxLines: 4,
                maxLength: 2000,
                validator: (value) => Validate.all([
                  () => Validate.required(value, field: 'A message'),
                  () => (value ?? '').trim().length < 10
                      ? 'A sentence or two, so they can answer properly.'
                      : null,
                ]),
                serverError: _serverErrors['message'],
              ),

            const SizedBox(height: 4),
            SubmitButton(
              label: _isEnquiry ? 'Send enquiry' : 'Show the number',
              busy: _busy,
              onPressed: _submit,
              icon: _isEnquiry ? Icons.send_rounded : Icons.call_outlined,
            ),
            const SizedBox(height: 12),
            Text(
              'Take Care International Foundation does not sell or share your details.',
              style: AppText.meta,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// What replaces the form once a reveal succeeds.
class _Revealed extends StatelessWidget {
  const _Revealed({required this.phone, required this.business});

  final String phone;
  final BusinessDetail business;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.call_rounded, size: 34, color: AppColors.success),
          const SizedBox(height: 12),
          Text(business.ownerName ?? business.name, style: AppText.h3),
          const SizedBox(height: 8),
          SelectableText(phone, style: AppText.figure.copyWith(color: AppColors.primary)),
          const SizedBox(height: 10),
          Text(
            'Please mention you found them through Take Care International Foundation.',
            style: AppText.excerpt,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: phone));

                    if (context.mounted) AppSnack.success(context, 'Number copied');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
