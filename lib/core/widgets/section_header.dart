import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The heading that opens every section on the home screen and the site.
///
/// Eyebrow → title → optional description, with an optional trailing action.
/// The eyebrow is the one place besides donate CTAs and progress bars where
/// the accent red is spent.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 16, 14),
    this.onDark = false,
  });

  final String title;
  final String? eyebrow;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!.toUpperCase(), style: AppText.eyebrow),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: onDark
                      ? AppText.h2.copyWith(color: AppColors.footerForeground)
                      : AppText.h2,
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: onDark ? AppColors.footerForeground : AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      Text(actionLabel!, style: AppText.button),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: onDark
                  ? AppText.excerpt.copyWith(color: AppColors.footerMuted)
                  : AppText.excerpt,
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline between stacked sections.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, this.indent = 16});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: indent,
      endIndent: indent,
    );
  }
}
