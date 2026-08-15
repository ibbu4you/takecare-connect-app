import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/site.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The form vocabulary: a labelled text field, a labelled dropdown, a
/// checkbox row and a submit button.
///
/// Every one of them takes a [serverError]. That is the whole point of this
/// file: the Laravel FormRequests are the real validation, and a 422 comes
/// back keyed by field name. Screens map those onto the fields so a rejected
/// submission tells the reader *which box* is wrong, instead of one combined
/// message at the top of a nine-field form.

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.serverError,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.optional = false,
    this.enabled = true,
    this.prefix,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;

  /// The message the server sent for this field, shown until the reader edits.
  final String? serverError;

  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool optional;
  final bool enabled;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, optional: optional),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: maxLines > 1 ? TextInputAction.newline : textInputAction,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: AppText.body.copyWith(fontSize: 15),
            onChanged: onChanged,
            // Validate as the reader fixes a rejected field, not while they are
            // still typing the first character of an empty one.
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperMaxLines: 3,
              errorMaxLines: 3,
              prefixIcon: prefix,
              counterText: '',
            ),
            validator: (value) => validator?.call(value) ?? serverError,
          ),
          // A server error outlives the validator when the field itself is
          // fine by the app's rules — an email the server already has, say.
          if (serverError != null && validator?.call(controller.text) == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                serverError!,
                style: AppText.meta.copyWith(color: AppColors.accentDark),
              ),
            ),
        ],
      ),
    );
  }
}

/// A select backed by the server's own option list.
class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Choose one',
    this.optional = false,
    this.serverError,
    this.validator,
  });

  final String label;
  final String? value;
  final List<Option> options;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool optional;
  final String? serverError;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    // A value the list does not contain would throw; this can happen when the
    // options are refreshed while a screen is open.
    final safe = options.any((o) => o.value == value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, optional: optional),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: safe,
            isExpanded: true,
            hint: Text(hint, style: AppText.body.copyWith(fontSize: 15, color: AppColors.mutedForeground)),
            style: AppText.body.copyWith(fontSize: 15, color: AppColors.foreground),
            borderRadius: BorderRadius.circular(AppRadii.field),
            icon: const Icon(Icons.expand_more_rounded),
            decoration: InputDecoration(errorMaxLines: 3, errorText: serverError),
            items: options
                .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                .toList(),
            onChanged: onChanged,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

/// Multi-select, rendered as wrapped filter chips.
///
/// Used for volunteering interests and availability — a list of six choices in
/// a dropdown is worse than six chips a thumb can hit.
class AppChipField extends StatelessWidget {
  const AppChipField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.optional = false,
    this.serverError,
  });

  final String label;
  final List<Option> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool optional;
  final String? serverError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, optional: optional),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isOn = selected.contains(option.value);

              return FilterChip(
                label: Text(option.label),
                selected: isOn,
                showCheckmark: false,
                onSelected: (_) {
                  final next = {...selected};
                  isOn ? next.remove(option.value) : next.add(option.value);
                  onChanged(next);
                },
                labelStyle: AppText.button.copyWith(
                  fontSize: 13,
                  color: isOn ? AppColors.primaryForeground : AppColors.foreground,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                side: BorderSide(color: isOn ? AppColors.primary : AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              );
            }).toList(),
          ),
          if (serverError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                serverError!,
                style: AppText.meta.copyWith(color: AppColors.accentDark),
              ),
            ),
        ],
      ),
    );
  }
}

/// A checkbox with its label to the right, tappable across the whole row.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
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
                  Text(label, style: AppText.body.copyWith(fontSize: 14, height: 1.4)),
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
      ),
    );
  }
}

/// The full-width submit button, with its own busy state.
///
/// Disabled while submitting rather than just spinning: a second tap on a
/// contact form sends a second message to the office.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.accent = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Donate CTAs only.
  final bool accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accent ? AppColors.accent : AppColors.primary,
          disabledBackgroundColor:
              (accent ? AppColors.accent : AppColors.primary).withValues(alpha: 0.5),
          foregroundColor: AppColors.primaryForeground,
          disabledForegroundColor: AppColors.primaryForeground,
        ),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: AppText.button.copyWith(fontSize: 16)),
                ],
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.optional});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(label, style: AppText.metaStrong.copyWith(fontSize: 13))),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('Optional', style: AppText.meta.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}
