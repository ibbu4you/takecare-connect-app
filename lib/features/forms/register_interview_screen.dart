import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repository.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import 'form_scaffold.dart';

/// A craftsman or small business putting themselves forward to be interviewed.
///
/// This is the pipeline that fills the Craftsmen tab. The consent checkbox is
/// not a formality — the interview is published with photographs of the person
/// and their workshop, so somebody who has not agreed to that cannot be
/// interviewed, and the server refuses the submission without it.
class RegisterInterviewScreen extends ConsumerStatefulWidget {
  const RegisterInterviewScreen({super.key});

  @override
  ConsumerState<RegisterInterviewScreen> createState() => _RegisterInterviewScreenState();
}

class _RegisterInterviewScreenState extends ConsumerState<RegisterInterviewScreen>
    with FormController {
  final _applicantName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _role = TextEditingController();
  final _businessName = TextEditingController();
  final _trade = TextEditingController();
  final _foundedYear = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _about = TextEditingController();
  final _story = TextEditingController();
  final _supportNeeded = TextEditingController();

  String? _teamSize;
  String? _turnover;
  bool _consent = false;

  @override
  void dispose() {
    for (final controller in [
      _applicantName, _email, _phone, _role, _businessName, _trade,
      _foundedYear, _city, _state, _website, _instagram, _about,
      _story, _supportNeeded,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _body => {
        'applicant_name': _applicantName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        if (_role.text.trim().isNotEmpty) 'role': _role.text.trim(),
        'business_name': _businessName.text.trim(),
        'trade': _trade.text.trim(),
        if (_foundedYear.text.trim().isNotEmpty)
          'founded_year': int.tryParse(_foundedYear.text.trim()),
        'city': _city.text.trim(),
        if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
        // The business's own address. Not to be confused with the honeypot,
        // which the repository adds as `website_url`.
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
        if (_instagram.text.trim().isNotEmpty) 'instagram': _instagram.text.trim(),
        'about': _about.text.trim(),
        if (_story.text.trim().isNotEmpty) 'story': _story.text.trim(),
        if (_teamSize != null) 'team_size': _teamSize,
        if (_turnover != null) 'annual_turnover': _turnover,
        if (_supportNeeded.text.trim().isNotEmpty)
          'support_needed': _supportNeeded.text.trim(),
        'consent_to_publish': _consent,
      };

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Register for an interview',
      introIcon: Icons.storefront_outlined,
      introTitle: 'Tell us what you make',
      intro: 'We interview craftsmen and small businesses across India, publish '
          'the story with photographs, and put your work in front of people who '
          'want to buy it. There is no charge.',
      confirmation: confirmation,
      confirmationTitle: 'Registration received',
      formKey: formKey,
      busy: busy,
      submitLabel: 'Send registration',
      onSubmit: _onSubmit,
      builder: (context, options) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              step: 1,
              title: 'Who is registering',
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                  validator: Validate.phone,
                  serverError: errorFor('phone'),
                ),
                AppField(
                  label: 'Your role',
                  controller: _role,
                  optional: true,
                  hint: 'Owner, master craftsman, manager…',
                  serverError: errorFor('role'),
                ),
              ],
            ),

            FormSection(
              step: 2,
              title: 'The business',
              children: [
                AppField(
                  label: 'Business name',
                  controller: _businessName,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      Validate.required(value, field: 'The business name'),
                  serverError: errorFor('business_name'),
                ),
                AppField(
                  label: 'Trade or craft',
                  controller: _trade,
                  hint: 'Handloom weaving, pottery, brassware…',
                  validator: (value) => Validate.required(value, field: 'Your trade'),
                  serverError: errorFor('trade'),
                ),
                AppField(
                  label: 'Year founded',
                  controller: _foundedYear,
                  optional: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  serverError: errorFor('founded_year'),
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
                  label: 'Website',
                  controller: _website,
                  optional: true,
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                  textCapitalization: TextCapitalization.none,
                  serverError: errorFor('website'),
                ),
                AppField(
                  label: 'Instagram',
                  controller: _instagram,
                  optional: true,
                  hint: '@yourhandle',
                  textCapitalization: TextCapitalization.none,
                  serverError: errorFor('instagram'),
                ),
                AppDropdown(
                  label: 'How many people work with you?',
                  value: _teamSize,
                  optional: true,
                  options: options['team_sizes'],
                  onChanged: (value) => setState(() => _teamSize = value),
                  serverError: errorFor('team_size'),
                ),
                AppDropdown(
                  label: 'Annual turnover',
                  value: _turnover,
                  optional: true,
                  options: options['turnover_bands'],
                  onChanged: (value) => setState(() => _turnover = value),
                  serverError: errorFor('annual_turnover'),
                ),
              ],
            ),

            FormSection(
              step: 3,
              title: 'Your work',
              children: [
                AppField(
                  label: 'What do you make?',
                  controller: _about,
                  maxLines: 5,
                  maxLength: 3000,
                  hint: 'The products, the materials, how they are made.',
                  validator: (value) => Validate.all([
                    () => Validate.required(value, field: 'This'),
                    () => (value ?? '').trim().length < 40
                        ? 'Please tell us a little more — at least 40 characters.'
                        : null,
                  ]),
                  serverError: errorFor('about'),
                ),
                AppField(
                  label: 'Your story',
                  controller: _story,
                  optional: true,
                  maxLines: 5,
                  maxLength: 5000,
                  hint: 'How you started, who taught you, what has changed.',
                  serverError: errorFor('story'),
                ),
                AppField(
                  label: 'What would help you most?',
                  controller: _supportNeeded,
                  optional: true,
                  maxLines: 3,
                  maxLength: 2000,
                  hint: 'More customers, equipment, training, working capital…',
                  serverError: errorFor('support_needed'),
                ),
              ],
            ),

            ConsentBox(
              label: 'I am happy for our story and photographs to be published',
              subtitle: 'On the website, in this app, and on our social media.',
              value: _consent,
              onChanged: (value) => setState(() => _consent = value),
              error: errorFor('consent_to_publish'),
            ),
          ],
        ),
    );
  }

  void _onSubmit() {
    if (!_consent) {
      complain(
        'consent_to_publish',
        'We can only interview businesses happy for the story and photographs '
            'to be published.',
      );

      return;
    }

    submit(() => ref.read(repositoryProvider).registerForInterview(_body));
  }
}
