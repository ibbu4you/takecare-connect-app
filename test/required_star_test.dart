import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/models/site.dart';
import 'package:takecare_connect/core/theme/app_colors.dart';
import 'package:takecare_connect/core/theme/app_theme.dart';
import 'package:takecare_connect/core/widgets/form_fields.dart';

/// The red star on a field that has to be filled in.
///
/// The website has marked required fields this way from the start and the app
/// never did, so every form here asked for things without saying which of them
/// were compulsory until the server refused the submission.
///
/// Asserted on the shared label rather than on any one form, because that is
/// the only place it is written — a test per form would be testing the same
/// widget five times and would still miss the sixth.
void main() {
  Future<void> pump(WidgetTester tester, Widget field) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: SingleChildScrollView(child: field)),
      ),
    );
  }

  /// The star lives in a span of its own inside the label, so it is found by
  /// walking the rendered text rather than by looking for a separate widget.
  List<InlineSpan> spansOf(WidgetTester tester, String label) {
    final text = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == label || widget.textSpan != null),
        description: 'the field label',
      ).first,
    );

    final span = text.textSpan;

    return span is TextSpan ? (span.children ?? const []) : const [];
  }

  testWidgets('a required field is starred', (tester) async {
    await pump(
      tester,
      AppField(label: 'Your name', controller: TextEditingController()),
    );

    final star = spansOf(tester, 'Your name').whereType<TextSpan>().firstWhere(
          (span) => span.text?.trim() == '*',
          orElse: () => const TextSpan(text: ''),
        );

    expect(star.text?.trim(), '*', reason: 'no star on a required field');

    // Red, and the darker red: the brighter one fails AA at this size.
    expect(star.style?.color, AppColors.accentDark);
  });

  testWidgets('an optional field is not starred', (tester) async {
    await pump(
      tester,
      AppField(label: 'Your name', controller: TextEditingController(), optional: true),
    );

    expect(find.text('Optional'), findsOneWidget);

    final starred = spansOf(tester, 'Your name')
        .whereType<TextSpan>()
        .any((span) => span.text?.trim() == '*');

    expect(starred, isFalse, reason: 'an optional field was starred');
  });

  /// A star is a picture of a rule. Read out as "asterisk" it passes on the
  /// picture and not the rule.
  testWidgets('the star is a word to a screen reader', (tester) async {
    await pump(
      tester,
      AppField(label: 'Your name', controller: TextEditingController()),
    );

    expect(find.bySemanticsLabel('Your name, required'), findsOneWidget);
  });

  testWidgets('dropdowns and chip fields are marked too', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          AppDropdown(
            label: 'Your city',
            value: null,
            options: const [Option(value: 'chennai', label: 'Chennai')],
            onChanged: (_) {},
          ),
          AppChipField(
            label: 'What you make',
            options: const [Option(value: 'cane', label: 'Cane')],
            selected: const {},
            onChanged: (_) {},
          ),
        ],
      ),
    );

    expect(find.bySemanticsLabel('Your city, required'), findsOneWidget);
    expect(find.bySemanticsLabel('What you make, required'), findsOneWidget);
  });
}
