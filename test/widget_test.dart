import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:takecare_connect/core/api/cursor_page.dart';
import 'package:takecare_connect/core/models/campaign.dart';
import 'package:takecare_connect/core/models/post.dart';
import 'package:takecare_connect/core/utils/formatters.dart';
import 'package:takecare_connect/core/utils/validators.dart';
import 'package:takecare_connect/core/widgets/tcif_logo.dart';

/// Unit tests for the parts that would fail silently.
///
/// The screens are not tested here — they are thin over the providers, and a
/// widget test of each would mostly assert that Flutter lays out a Column.
/// What is tested is the parsing and the arithmetic: the places where a wrong
/// answer looks like a right one.
void main() {
  group('cursor pagination', () {
    test('reads the cursor from meta', () {
      final page = CursorPage.fromJson(
        {
          'data': [
            {'slug': 'a', 'title': 'A'},
          ],
          'meta': {'next_cursor': 'abc123'},
        },
        PostSummary.fromJson,
      );

      expect(page.items.single.slug, 'a');
      expect(page.nextCursor, 'abc123');
    });

    test('falls back to the cursor inside links.next', () {
      final page = CursorPage.fromJson(
        {
          'data': <Map<String, dynamic>>[],
          'links': {'next': 'https://example.test/api/v1/posts?cursor=xyz789'},
        },
        PostSummary.fromJson,
      );

      expect(page.nextCursor, 'xyz789');
    });

    test('a missing cursor is the end of the list', () {
      final page = CursorPage.fromJson(
        {
          'data': <Map<String, dynamic>>[],
          'meta': {'next_cursor': null},
        },
        PostSummary.fromJson,
      );

      expect(page.nextCursor, isNull);
    });
  });

  group('models survive a thin payload', () {
    test('a post with nothing but a slug', () {
      final post = PostSummary.fromJson({'slug': 'x'});

      expect(post.title, '');
      expect(post.category, isNull);
      expect(post.readingMinutes, 1);
      expect(post.publishedAt, isNull);
    });

    test('a campaign clamps progress past its goal', () {
      final campaign = Campaign.fromJson({
        'slug': 'roof',
        'goal_amount': 100000,
        'raised_amount': 150000,
        'progress_percent': 150,
      });

      expect(campaign.progressFraction, 1.0);
    });

    test('a campaign with no closing date has no countdown', () {
      expect(Campaign.fromJson({'slug': 'x'}).daysRemaining, isNull);
    });

    test('a campaign that has closed reports zero days, never negative', () {
      final campaign = Campaign.fromJson({
        'slug': 'x',
        'ends_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      });

      expect(campaign.daysRemaining, 0);
    });
  });

  group('money is formatted the Indian way', () {
    test('groups in lakhs, not thousands', () {
      // 1,23,456 — not 123,456. This is the whole reason for the en_IN locale.
      expect(Fmt.money(123456), contains('1,23,456'));
    });

    test('drops paise when there are none', () {
      expect(Fmt.money(45000), isNot(contains('.00')));
    });

    test('compacts to lakhs and crores', () {
      expect(Fmt.compactMoney(250000), '₹2.5L');
      expect(Fmt.compactMoney(15000000), '₹1.5Cr');
    });
  });

  group('validators stay looser than the server', () {
    test('accepts an Indian mobile in any of its written forms', () {
      expect(Validate.phone('9876543210'), isNull);
      expect(Validate.phone('+91 98765 43210'), isNull);
      expect(Validate.phone('098765-43210'), isNull);
    });

    test('refuses an incomplete number', () {
      expect(Validate.phone('98765'), isNotNull);
    });

    test('checks the shape of a PAN', () {
      expect(Validate.pan('ABCDE1234F'), isNull);
      expect(Validate.pan('ABCD1234F'), isNotNull);
    });

    test('an optional field is only optional when empty', () {
      expect(Validate.email('', optional: true), isNull);
      expect(Validate.email('not-an-address', optional: true), isNotNull);
    });
  });

  test('the logo asset is declared and loadable', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // A missing or misspelled asset does not throw where you would notice: the
    // Image widget renders nothing, the app bar shows a gap, and the only sign
    // is a line in the device log. This fails loudly instead.
    //
    // It cannot catch every version of the problem — a stale incremental build
    // shipped an APK whose manifest listed only assets/icon/, and no test can
    // see inside that. `flutter clean` is the answer to that one.
    final bytes = await rootBundle.load(TcifLogo.asset);

    expect(bytes.lengthInBytes, greaterThan(1000), reason: 'the logo is empty or truncated');
  });

  testWidgets('the logo paints at any size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: TcifLogo(size: 96)),
        ),
      ),
    );

    expect(find.byType(TcifLogo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
