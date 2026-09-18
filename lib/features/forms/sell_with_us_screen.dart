library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repository.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import 'form_scaffold.dart';

/// A craftsman asking to sell through the foundation.
///
/// The two consent boxes are not a formality and the server refuses the
/// application without either: one agrees to their work and their details
/// being published, the other to the terms of being listed. Their wording is
/// the website's own, because what somebody is agreeing to must not be
/// paraphrased differently on two surfaces.
///
/// Note the `website` field. It is a real question here — a maker's own site —
/// which is why this form's honeypot is `website_url` instead, added by the
/// repository. Sending the wrong one fails silently.
class SellWithUsScreen extends ConsumerStatefulWidget {
  const SellWithUsScreen({super.key});

  @override
  ConsumerState<SellWithUsScreen> createState() => _SellWithUsScreenState();
}

class _SellWithUsScreenState extends ConsumerState<SellWithUsScreen> with FormController {
  final _applicantName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _shopName = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _about = TextEditingController();
  final _whatTheyMake = TextEditingController();

  String? _trade;
  bool _consentToPublish = false;
  bool _consentToTerms = false;

  @override
  void dispose() {
    for (final controller in [
      _applicantName, _email, _phone, _shopName, _city, _state,
      _website, _instagram, _about, _whatTheyMake,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _body => {
        'applicant_name': _applicantName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'shop_name': _shopName.text.trim(),
        if (_trade != null) 'trade': _trade,
        'city': _city.text.trim(),
        if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
        // Their own site. Not the honeypot — see the note on this class.
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_instagram.text.trim().isNotEmpty) 'instagram': _instagram.text.trim(),
        'about': _about.text.trim(),
        'what_they_make': _whatTheyMake.text.trim(),
        'consent_to_publish': _consentToPublish,
        'consent_to_terms': _consentToTerms,
      };

  Future<void> _onSubmit() async {
    if (!_consentToPublish) {
      complain('consent_to_publish', 'We cannot list your work without this.');

      return;
    }

    if (!_consentToTerms) {
      complain('consent_to_terms', 'Please agree to the terms of being listed.');

      return;
    }

    await submit(() => ref.read(repositoryProvider).applyToSell(_body));
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Sell with us',
      introIcon: Icons.storefront_outlined,
      introTitle: 'List your work in our shop',
      intro: 'We take no commission on anything you sell — buyers contact you '
          'directly and settle it with you. Somebody here reads every '
          'application.',
      confirmation: confirmation,
      confirmationTitle: 'Application received',
      formKey: formKey,
      busy: busy,
      submitLabel: 'Send application',
      onSubmit: _onSubmit,
      builder: (context, options) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSection(
            step: 1,
            title: 'You',
            children: [
              AppField(
                label: 'Your name',
                controller: _applicantName,
                textCapitalization: TextCapitalization.words,
                validator: Validate.name,
                serverError: errorFor('applicant_name'),
              ),
              AppField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                validator: (value) => Validate.email(value),
                serverError: errorFor('email'),
              ),
              AppField(
                label: 'Phone',
                controller: _phone,
                helper: 'This is the number buyers will call.',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                validator: Validate.phone,
                serverError: errorFor('phone'),
              ),
            ],
          ),

          FormSection(
            step: 2,
            title: 'Your shop',
            children: [
              AppField(
                label: 'Shop name',
                controller: _shopName,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validate.required(value, field: 'Your shop name'),
                serverError: errorFor('shop_name'),
              ),
              // Served rather than hard-coded: the website offers these ten and
              // the server validates against them.
              AppDropdown(
                label: 'What you make',
                value: _trade,
                options: options['vendor_trades'],
                onChanged: (value) => setState(() => _trade = value),
                validator: (value) => value == null ? 'Please choose your trade.' : null,
                serverError: errorFor('trade'),
              ),
              AppField(
                label: 'City',
                controller: _city,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validate.required(value, field: 'Your city'),
                serverError: errorFor('city'),
              ),
              AppField(
                label: 'State',
                controller: _state,
                optional: true,
                textCapitalization: TextCapitalization.words,
                serverError: errorFor('state'),
              ),
              AppField(
                label: 'Your website',
                controller: _website,
                optional: true,
                keyboardType: TextInputType.url,
                textCapitalization: TextCapitalization.none,
                serverError: errorFor('website'),
              ),
              AppField(
                label: 'Instagram',
                controller: _instagram,
                optional: true,
                textCapitalization: TextCapitalization.none,
                serverError: errorFor('instagram'),
              ),
            ],
          ),

          FormSection(
            step: 3,
            title: 'Your work',
            children: [
              AppField(
                label: 'About you and your work',
                controller: _about,
                hint: 'How long you have been at it, where you learned, who you work with.',
                maxLines: 5,
                maxLength: 2000,
                validator: (value) => Validate.all([
                  () => Validate.required(value, field: 'This'),
                  () => (value ?? '').trim().length < 40
                      ? 'A few sentences, so we know who we are listing.'
                      : null,
                ]),
                serverError: errorFor('about'),
              ),
              AppField(
                label: 'What you would list',
                controller: _whatTheyMake,
                hint: 'Serving bowls, water jugs, dinner plates…',
                maxLines: 3,
                maxLength: 1000,
                validator: (value) => Validate.required(value, field: 'This'),
                serverError: errorFor('what_they_make'),
              ),
            ],
          ),

          FormSection(
            step: 4,
            title: 'Your agreement',
            children: [
              AppCheckbox(
                label: 'You may publish my work and my details',
                subtitle: 'Your shop page carries your name, your town and the way to '
                    'reach you. That is the point of being listed.',
                value: _consentToPublish,
                onChanged: (value) => setState(() => _consentToPublish = value),
              ),
              if (errorFor('consent_to_publish') != null)
                _ConsentError(errorFor('consent_to_publish')!),
              AppCheckbox(
                label: 'I agree to the terms of being listed',
                subtitle: 'You deal with your own buyers and your own postage. The '
                    'foundation takes no commission and takes no part in the sale.',
                value: _consentToTerms,
                onChanged: (value) => setState(() => _consentToTerms = value),
              ),
              if (errorFor('consent_to_terms') != null)
                _ConsentError(errorFor('consent_to_terms')!),
            ],
          ),
        ],
      ),
    );
  }
}

/// A checkbox has no error slot of its own, so its complaint is drawn under it
/// in the same red the fields use.
class _ConsentError extends StatelessWidget {
  const _ConsentError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        message,
        style: Theme.of(context).inputDecorationTheme.errorStyle ??
            TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
      ),
    );
  }
}
