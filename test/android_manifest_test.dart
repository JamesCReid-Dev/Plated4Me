import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const String kExpectedAndroidLabel = 'Plated4Me';

  group('AndroidManifest.xml', () {
    test('android:label should match brand casing "$kExpectedAndroidLabel"', () {
      // The Android app label must use the correct brand casing "Plated4Me",
      // not lowercase "plated4me". This is verified by parsing the manifest XML.
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      );
      expect(
        manifest.existsSync(),
        isTrue,
        reason: 'AndroidManifest.xml should exist at android/app/src/main/',
      );

      final content = manifest.readAsStringSync();

      // Extract the android:label attribute value from the <application> tag.
      // Matches android:label="..." (double-quoted).
      final labelPattern = RegExp(r'android:label="([^"]+)"');
      final match = labelPattern.firstMatch(content);

      expect(match, isNotNull, reason: 'android:label attribute should be present');
      expect(
        match!.group(1),
        equals(kExpectedAndroidLabel),
        reason:
            'App label should use brand casing "$kExpectedAndroidLabel", '
            'not "${match.group(1)}"',
      );
    });
  });
}
