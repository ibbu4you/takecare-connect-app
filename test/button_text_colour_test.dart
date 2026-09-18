import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/theme/app_colors.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/core/widgets/form_fields.dart';
import 'package:takecare_connect/core/widgets/section_header.dart';
import 'package:takecare_connect/features/more/newsletter_card.dart';

/// A button's label takes the button's colour.
///
/// It did not. `AppText.button` carried `AppColors.foreground` — near-black —
/// and a Text merges its own style over the DefaultTextStyle the button puts
/// around it, so any colour the style names wins. Every button whose label was
/// written with that style painted itself near-black over whatever fill was
/// underneath: the donate button drew a black label on red with a white icon
/// beside it, because icons take their colour from the IconTheme and had been
/// getting it right all along.
///
/// The style now names no colour, so the button's foregroundColor reaches the
/// label. These read the colour off the RichText rather than the Text, because
/// the Text is where the style is declared and the RichText is where it has
/// been resolved against everything above it.
void main() {
  Color? colourOf(WidgetTester tester, String label) {
    final rich = tester.widget<RichText>(
      find.descendant(of: find.text(label), matching: find.byType(RichText)).first,
    );

    return rich.text.style?.color;
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: Scaffold(body: Center(child: child))),
    );
  }

  testWidgets('a donate button is white on red', (tester) async {
    await pump(
      tester,
      SubmitButton(label: 'Donate ₹1,000', accent: true, onPressed: () {}),
    );

    expect(colourOf(tester, 'Donate ₹1,000'), AppColors.primaryForeground);
  });

  testWidgets('an ordinary submit button is white on navy', (tester) async {
    await pump(tester, SubmitButton(label: 'Send', onPressed: () {}));

    expect(colourOf(tester, 'Send'), AppColors.primaryForeground);
  });

  /// Disabled is the one case that is *not* white: the fill goes grey, and a
  /// white label on it would be unreadable.
  testWidgets('a disabled button is muted, not white', (tester) async {
    await pump(
      tester,
      SubmitButton(label: 'Donations are paused', enabled: false, onPressed: () {}),
    );

    expect(colourOf(tester, 'Donations are paused'), AppColors.mutedForeground);
  });

  /// The signup box at the foot of More, which is where this was reported.
  /// It is an ordinary SubmitButton, so it was black on navy like the rest —
  /// pinned here as well because it is the one somebody actually looked at.
  testWidgets('the newsletter button is white too', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: NewsletterCard()))),
      ),
    );
    await tester.pump();

    expect(colourOf(tester, 'Keep me posted'), AppColors.primaryForeground);
  });

  testWidgets('a section header action takes the navy', (tester) async {
    await pump(
      tester,
      const SectionHeader(title: 'Stories', actionLabel: 'All', onAction: _noop),
    );

    expect(colourOf(tester, 'All'), AppColors.primary);
  });

  /// The same header over the dark footer, where near-black was at its worst.
  testWidgets('and the light one when it sits on dark', (tester) async {
    await pump(
      tester,
      const ColoredBox(
        color: AppColors.primaryDark,
        child: SectionHeader(
          title: 'Stories',
          actionLabel: 'All',
          onAction: _noop,
          onDark: true,
        ),
      ),
    );

    expect(colourOf(tester, 'All'), AppColors.footerForeground);
  });
}

void _noop() {}
