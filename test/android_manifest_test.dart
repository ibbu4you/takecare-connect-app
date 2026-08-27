import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The permission that decides whether the app can do anything at all.
///
/// This is the file that would have caught the rejection. Google Play refused
/// the build on 26 August 2026 under the Broken Functionality policy — "Your
/// app does not open or load" — because the shipped bundle declared no
/// INTERNET permission, so an app whose every screen comes from
/// takecareconnect.com/api/v1 had literally nothing to draw.
///
/// It survived every check because Flutter's template declares the permission
/// in `src/debug` and `src/profile`, and a release build merges neither. So
/// `flutter run` worked, `flutter run --profile` worked, the README's
/// `flutter build apk --debug` worked, and the one variant nobody built was the
/// one that went to the store.
///
/// Reading the file rather than the merged manifest is deliberate: this has to
/// fail in `flutter test`, seconds after somebody deletes the line, not twenty
/// minutes into a Gradle build they may not run before uploading.
void main() {
  late final String manifest;

  setUpAll(() {
    manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  });

  test('the release manifest grants INTERNET', () {
    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason: 'Without this the release build cannot open a socket and every '
          'screen shows the offline error. Play rejects it as broken.',
    );
  });

  test('the permission is on the manifest itself, not inherited', () {
    // src/debug and src/profile also declare it. Only this one ships.
    expect(
      RegExp(r'<uses-permission\s+android:name="android\.permission\.INTERNET"')
          .hasMatch(manifest),
      isTrue,
      reason: 'The declaration must be a real uses-permission element in '
          'src/main, not merely mentioned in a comment.',
    );
  });

  test('outbound links stay resolvable under package visibility', () {
    // launchUrl carries the donation hand-off, the receipt PDF and the
    // tel:/mailto: buttons. On API 30+ these queries keep them resolvable.
    for (final scheme in ['https', 'tel', 'mailto']) {
      expect(
        manifest,
        contains('android:scheme="$scheme"'),
        reason: 'The <queries> block should cover $scheme.',
      );
    }
  });
}
