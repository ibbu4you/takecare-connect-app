library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snack.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/form_fields.dart';

/// The signup box the website carries in its footer.
///
/// Deliberately small: an address, an optional name, and that is all. There is
/// no "interests" step and no frequency picker, because nothing has been sent
/// yet — this is a list being gathered.
///
/// On success the form is replaced by the server's own confirmation rather than
/// a snackbar that scrolls away. And the server answers a repeat address
/// exactly as it answers a new one, so nothing here can tell a stranger whether
/// somebody else is already on the list.
class NewsletterCard extends ConsumerStatefulWidget {
  const NewsletterCard({super.key});

  @override
  ConsumerState<NewsletterCard> createState() => _NewsletterCardState();
}

class _NewsletterCardState extends ConsumerState<NewsletterCard> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();

  bool _busy = false;
  String? _confirmation;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _emailError = null;
    });

    try {
      final message = await ref.read(repositoryProvider).subscribeToNewsletter(
            email: _email.text.trim(),
            name: _name.text.trim(),
          );

      if (!mounted) return;

      setState(() {
        _busy = false;
        _confirmation = message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _emailError = e.errors?['email']?.first;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: _confirmation != null
            ? Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_confirmation!, style: AppText.body.copyWith(fontSize: 15))),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The next story, by email', style: AppText.h3.copyWith(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(
                      'One email when we publish something worth reading. Nothing else, '
                      'and never your details to anybody.',
                      style: AppText.excerpt,
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Your email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) => Validate.email(value),
                      serverError: _emailError,
                    ),
                    AppField(
                      label: 'Your name',
                      controller: _name,
                      optional: true,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SubmitButton(
                      label: 'Keep me posted',
                      busy: _busy,
                      onPressed: _submit,
                      icon: Icons.mail_outline_rounded,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
