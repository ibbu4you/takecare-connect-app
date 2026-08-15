import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One place that shows transient messages, so success and failure look the
/// same everywhere and no screen invents its own SnackBar.
class AppSnack {
  AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color tone = AppColors.footer,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: tone,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.field)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.footerForeground),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(fontSize: 14, color: AppColors.footerForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, icon: Icons.check_circle_rounded, tone: AppColors.success);

  /// Shows an error in the reader's language.
  ///
  /// Validation errors are deliberately *not* shown here — those belong under
  /// the field that caused them, which is what `ApiException.errorFor` is for.
  /// A 422 reaching this method means a form forgot to map it, so it gets a
  /// generic prompt rather than a raw field name.
  static void error(BuildContext context, Object error) {
    final message = switch (error) {
      ApiException e when e.isValidation => 'Please check the highlighted fields.',
      ApiException e => e.message,
      _ => 'Something went wrong. Please try again.',
    };

    show(context, message, icon: Icons.error_outline_rounded, tone: AppColors.accentDark);
  }
}
