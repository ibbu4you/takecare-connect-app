import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/repository.dart';
import '../../core/models/site.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/map_card.dart';
import 'form_scaffold.dart';

/// Write to the office.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> with FormController {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String? _subject;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Contact us',
      confirmation: confirmation,
      confirmationTitle: 'Message sent',
      formKey: formKey,
      busy: busy,
      submitLabel: 'Send message',
      onSubmit: () => submit(
        () => ref.read(repositoryProvider).sendContact({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
          'subject': _subject,
          'message': _message.text.trim(),
        }),
      ),
      builder: (context, options) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ContactDetails(),
            ),
            FormSection(
              step: 1,
              title: 'Send us a message',
              subtitle: 'We reply to everything, usually within a few days.',
              children: [
            AppField(
              label: 'Your name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: Validate.name,
              serverError: errorFor('name'),
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
              optional: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
              validator: (value) => Validate.phone(value, optional: true),
              serverError: errorFor('phone'),
            ),
            AppDropdown(
              label: 'What is this about?',
              value: _subject,
              options: options['contact_subjects'],
              onChanged: (value) => setState(() => _subject = value),
              serverError: errorFor('subject'),
              validator: (value) => value == null ? 'Please choose a subject.' : null,
            ),
            AppField(
              label: 'Your message',
              controller: _message,
              maxLines: 6,
              maxLength: 5000,
              hint: 'Tell us what you need — at least a couple of sentences.',
              validator: (value) => Validate.all([
                () => Validate.required(value, field: 'A message'),
                () => (value ?? '').trim().length < 20
                    ? 'Please tell us a little more — at least 20 characters.'
                    : null,
              ]),
              serverError: errorFor('message'),
            ),
              ],
            ),
          ],
        ),
    );
  }
}

/// The office's own details, above the form.
///
/// Somebody who would rather phone than type should not have to fill in a form
/// to find the number.
class _ContactDetails extends ConsumerWidget {
  const _ContactDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;

    if (settings == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The map the website carries. Same embed URL, out of the same setting.
        if ((settings.mapEmbedUrl?.isNotEmpty ?? false) && settings.address.isNotEmpty)
          MapCard(embedUrl: settings.mapEmbedUrl!, address: settings.address),
        _Details(settings: settings),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (settings.phone.isNotEmpty)
            _Line(
              icon: Icons.call_outlined,
              label: settings.phone,
              onTap: () => launchUrl(Uri.parse('tel:${settings.phone}')),
            ),
          if (settings.email.isNotEmpty)
            _Line(
              icon: Icons.mail_outline_rounded,
              label: settings.email,
              onTap: () => launchUrl(Uri.parse('mailto:${settings.email}')),
            ),
          if (settings.address.isNotEmpty)
            _Line(
              icon: Icons.place_outlined,
              label: settings.address,
              onTap: () => launchUrl(
                Uri.parse(
                  'https://maps.google.com/?q=${Uri.encodeComponent(settings.address)}',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          if (settings.openingDays.isNotEmpty)
            _Line(icon: Icons.schedule_outlined, label: settings.openingDays),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 14,
                  color: onTap == null ? AppColors.mutedForeground : AppColors.foreground,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
