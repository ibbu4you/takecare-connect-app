import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repository.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import 'form_scaffold.dart';

/// Volunteer and intern applications.
///
/// One screen for both, because they differ in four fields and a heading —
/// but they post to **two different routes**, and that matters more than it
/// looks. The server reads which kind of application this is from the route
/// name, never from the payload, so that nobody can file an internship through
/// the volunteer form and skip the institution rules on the way. The app
/// honours the same split: [intern] chooses the endpoint, and there is no
/// `kind` field in the body at all.
class OpportunityScreen extends ConsumerStatefulWidget {
  const OpportunityScreen({super.key, required this.intern});

  final bool intern;

  @override
  ConsumerState<OpportunityScreen> createState() => _OpportunityScreenState();
}

class _OpportunityScreenState extends ConsumerState<OpportunityScreen> with FormController {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _institution = TextEditingController();
  final _course = TextEditingController();
  final _motivation = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();
  final _languages = TextEditingController();
  final _portfolio = TextEditingController();

  Set<String> _areas = {};
  String? _mode;
  String? _hours;
  String? _duration;
  String? _yearOfStudy;
  String? _howHeard;
  bool _academicCredit = false;
  bool _consent = false;
  DateTime? _dateOfBirth;
  DateTime? _availableFrom;

  bool get _isIntern => widget.intern;

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _phone, _city, _state, _country,
      _institution, _course, _motivation, _skills,
      _experience, _languages, _portfolio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _body => {
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        if (_dateOfBirth != null) 'date_of_birth': _iso(_dateOfBirth!),
        'city': _city.text.trim(),
        if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
        if (_country.text.trim().isNotEmpty) 'country': _country.text.trim(),
        'areas': _areas.toList(),
        'mode': _mode,
        if (_availableFrom != null) 'available_from': _iso(_availableFrom!),
        if (_hours != null) 'hours_per_week': _hours,
        if (_duration != null) 'duration': _duration,
        if (_isIntern) ...{
          'institution': _institution.text.trim(),
          'course': _course.text.trim(),
          if (_yearOfStudy != null) 'year_of_study': _yearOfStudy,
          'academic_credit': _academicCredit,
        },
        'motivation': _motivation.text.trim(),
        if (_skills.text.trim().isNotEmpty) 'skills': _skills.text.trim(),
        if (_experience.text.trim().isNotEmpty) 'experience': _experience.text.trim(),
        if (_languages.text.trim().isNotEmpty) 'languages': _languages.text.trim(),
        if (_portfolio.text.trim().isNotEmpty) 'portfolio_url': _portfolio.text.trim(),
        if (_howHeard != null) 'how_heard': _howHeard,
        'consent_to_contact': _consent,
      };

  /// The server validates these as `date`, so they go as plain ISO dates —
  /// not an ISO 8601 timestamp, which would carry a timezone the office does
  /// not need and a birthday could be shifted by.
  static String _iso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({
    required DateTime first,
    required DateTime last,
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) setState(() => onPicked(picked));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return FormPage(
      title: _isIntern ? 'Apply for an internship' : 'Volunteer with us',
      introTitle: _isIntern ? 'Intern with the foundation' : 'Give us your time',
      intro: _isIntern
          ? 'Internships are placed inside a department and run alongside your '
              'studies. Tell us where you study and what you are hoping to learn.'
          : 'Volunteers run our field visits, help at events, and keep the '
              'stories on this app coming. Tell us how you would like to help.',
      confirmation: confirmation,
      confirmationTitle: 'Application received',
      builder: (context, options) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: 'About you',
              children: [
                AppField(
                  label: 'Full name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: Validate.name,
                  serverError: errorFor('full_name'),
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
                _DateField(
                  label: 'Date of birth',
                  optional: true,
                  value: _dateOfBirth,
                  helper: 'You need to be at least 16 to apply.',
                  serverError: errorFor('date_of_birth'),
                  onTap: () => _pickDate(
                    first: DateTime(1920),
                    // The server refuses anybody under 16; offering later dates
                    // in the picker would only be a 422 waiting to happen.
                    last: DateTime(now.year - 16, now.month, now.day),
                    initial: DateTime(now.year - 20),
                    onPicked: (value) => _dateOfBirth = value,
                  ),
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
                  label: 'Country',
                  controller: _country,
                  optional: true,
                  textCapitalization: TextCapitalization.words,
                  serverError: errorFor('country'),
                ),
              ],
            ),

            FormSection(
              title: 'How you would like to help',
              subtitle: 'Pick up to five, so we know where to place you.',
              children: [
                AppChipField(
                  label: 'Areas',
                  options: options[_isIntern ? 'intern_areas' : 'volunteer_areas'],
                  selected: _areas,
                  onChanged: (value) => setState(() => _areas = value),
                  serverError: errorFor('areas'),
                ),
                AppDropdown(
                  label: 'How would you like to work?',
                  value: _mode,
                  options: options['modes'],
                  onChanged: (value) => setState(() => _mode = value),
                  serverError: errorFor('mode'),
                  validator: (value) => value == null ? 'Please choose one.' : null,
                ),
                AppDropdown(
                  label: 'Hours a week',
                  value: _hours,
                  optional: true,
                  options: options['hours_per_week'],
                  onChanged: (value) => setState(() => _hours = value),
                  serverError: errorFor('hours_per_week'),
                ),
                AppDropdown(
                  label: 'For how long',
                  value: _duration,
                  optional: true,
                  options: options['durations'],
                  onChanged: (value) => setState(() => _duration = value),
                  serverError: errorFor('duration'),
                ),
                _DateField(
                  label: 'Available from',
                  optional: true,
                  value: _availableFrom,
                  serverError: errorFor('available_from'),
                  onTap: () => _pickDate(
                    first: now,
                    last: DateTime(now.year + 2, now.month, now.day - 1),
                    initial: now,
                    onPicked: (value) => _availableFrom = value,
                  ),
                ),
              ],
            ),

            if (_isIntern)
              FormSection(
                title: 'Your studies',
                subtitle: 'An internship is placed in a department and usually '
                    'reported back to your college.',
                children: [
                  AppField(
                    label: 'Institution',
                    controller: _institution,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validate.required(value, field: 'Where you study'),
                    serverError: errorFor('institution'),
                  ),
                  AppField(
                    label: 'Course',
                    controller: _course,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validate.required(value, field: 'What you are studying'),
                    serverError: errorFor('course'),
                  ),
                  AppDropdown(
                    label: 'Year of study',
                    value: _yearOfStudy,
                    optional: true,
                    options: options['years_of_study'],
                    onChanged: (value) => setState(() => _yearOfStudy = value),
                    serverError: errorFor('year_of_study'),
                  ),
                  AppCheckbox(
                    label: 'This internship is for academic credit',
                    subtitle: 'We will provide the paperwork your college needs.',
                    value: _academicCredit,
                    onChanged: (value) => setState(() => _academicCredit = value),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            FormSection(
              title: 'In your own words',
              children: [
                AppField(
                  label: 'Why do you want to do this?',
                  controller: _motivation,
                  maxLines: 5,
                  maxLength: 3000,
                  hint: 'A short paragraph is plenty.',
                  validator: (value) => Validate.all([
                    () => Validate.required(value, field: 'This'),
                    () => (value ?? '').trim().length < 40
                        ? 'Please tell us a little more — at least 40 characters.'
                        : null,
                  ]),
                  serverError: errorFor('motivation'),
                ),
                AppField(
                  label: 'Skills you would bring',
                  controller: _skills,
                  optional: true,
                  maxLines: 3,
                  maxLength: 2000,
                  serverError: errorFor('skills'),
                ),
                AppField(
                  label: 'Relevant experience',
                  controller: _experience,
                  optional: true,
                  maxLines: 3,
                  maxLength: 3000,
                  serverError: errorFor('experience'),
                ),
                AppField(
                  label: 'Languages you speak',
                  controller: _languages,
                  optional: true,
                  hint: 'Hindi, English, Gujarati…',
                  serverError: errorFor('languages'),
                ),
                AppField(
                  label: 'Portfolio or LinkedIn',
                  controller: _portfolio,
                  optional: true,
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                  textCapitalization: TextCapitalization.none,
                  serverError: errorFor('portfolio_url'),
                ),
                AppDropdown(
                  label: 'How did you hear about us?',
                  value: _howHeard,
                  optional: true,
                  options: options['how_heard'],
                  onChanged: (value) => setState(() => _howHeard = value),
                  serverError: errorFor('how_heard'),
                ),
              ],
            ),

            AppCheckbox(
              label: 'You may contact me about a placement',
              subtitle: 'By phone or email. We do not share your details with anyone else.',
              value: _consent,
              onChanged: (value) => setState(() => _consent = value),
            ),
            if (errorFor('consent_to_contact') != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 36),
                child: Text(
                  errorFor('consent_to_contact')!,
                  style: AppText.meta.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),

            const SizedBox(height: 20),
            SubmitButton(
              label: _isIntern ? 'Apply for an internship' : 'Apply to volunteer',
              busy: busy,
              icon: Icons.send_rounded,
              // Guarded here rather than by a disabled button: a button that
              // does nothing when tapped tells the reader nothing about why.
              onPressed: () {
                if (!_consent) {
                  setState(() => serverErrors = {
                        ...serverErrors,
                        'consent_to_contact':
                            'We need your permission to contact you about a placement.',
                      });

                  return;
                }

                if (_areas.isEmpty) {
                  setState(() => serverErrors = {
                        ...serverErrors,
                        'areas': 'Please pick at least one area you would like to help with.',
                      });

                  return;
                }

                submit(
                  () => _isIntern
                      ? ref.read(repositoryProvider).applyIntern(_body)
                      : ref.read(repositoryProvider).applyVolunteer(_body),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A read-only field that opens a date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.optional = false,
    this.serverError,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? helper;
  final bool optional;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppText.metaStrong.copyWith(fontSize: 13)),
              if (optional) ...[
                const SizedBox(width: 6),
                Text('Optional', style: AppText.meta.copyWith(fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                helperText: helper,
                errorText: serverError,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                value == null
                    ? 'Choose a date'
                    : '${value!.day} ${_months[value!.month - 1]} ${value!.year}',
                style: AppText.body.copyWith(
                  fontSize: 15,
                  color: value == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}
