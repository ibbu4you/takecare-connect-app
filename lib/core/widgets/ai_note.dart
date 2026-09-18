library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Says out loud that a photograph has been tidied up by a machine.
///
/// Craftsmen photograph their work where they make it — on a workshop floor, in
/// whatever light there is, against whatever happens to be behind them. They
/// may ask for the background, the lighting and the framing to be cleaned up.
/// The object itself is never changed and never invented: a real photograph of
/// the real item is required before anything can be done to it.
///
/// Saying so costs a line of text and it is what protects the foundation if
/// anybody ever asks. The alternative is explaining later why it was not said.
///
/// Both wordings are copied verbatim from the website's own
/// EnhancedPhotographNote, because a reader who sees the badge on the site and
/// the badge here should not have to wonder whether they mean the same thing.
class AiNote extends StatelessWidget {
  /// The badge that sits on a photograph in a list, where a sentence would be
  /// shouting.
  const AiNote.badge({super.key}) : _compact = true;

  /// The full sentence, for a product's own page — somewhere somebody has
  /// stopped to read.
  const AiNote.sentence({super.key}) : _compact = false;

  final bool _compact;

  @override
  Widget build(BuildContext context) {
    if (_compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          // Dark and translucent, because it sits over a photograph whose
          // brightness nobody can predict.
          color: const Color(0x8C000000),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'AI enhanced',
                style: AppText.meta.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.auto_awesome, size: 13, color: AppColors.mutedForeground),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Photograph enhanced with AI. The item itself is unchanged.',
            style: AppText.meta,
          ),
        ),
      ],
    );
  }
}
