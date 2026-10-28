import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/services/app_update_service.dart';

const String _validSha256 = 'ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12ab12';

String buildReleaseJson({
  String downloadUrl = 'https://github.com/Paul-Carouge/Komit-app/releases/download/v1.1.0/komit-v1.1.0.apk',
  String digest = 'sha256:$_validSha256',
}) => jsonEncode({
  'tag_name': 'v1.1.0',
  'body': '- New statistics screen',
  'assets': [
    {'name': 'notes.txt', 'browser_download_url': 'https://github.com/x', 'digest': 'sha256:00'},
    {'name': 'komit-v1.1.0.apk', 'browser_download_url': downloadUrl, 'digest': digest, 'size': 26000000},
  ],
});

void main() {
  group('isVersionNewer', () {
    test('compares each numeric part, not text', () {
      expect(isVersionNewer('1.10.0', than: '1.9.0'), isTrue);
      expect(isVersionNewer('2.0.0', than: '1.99.99'), isTrue);
      expect(isVersionNewer('1.0.1', than: '1.0.0'), isTrue);
    });

    test('is false for the same or an older version, ignoring build suffixes', () {
      expect(isVersionNewer('1.0.0', than: '1.0.0'), isFalse);
      expect(isVersionNewer('1.0.0+5', than: '1.0.0'), isFalse);
      expect(isVersionNewer('0.9.0', than: '1.0.0'), isFalse);
    });
  });

  group('parseLatestRelease', () {
    test('picks the APK asset with its digest and strips the v prefix', () {
      final update = parseLatestRelease(buildReleaseJson());
      expect(update.version, '1.1.0');
      expect(update.apkSha256, _validSha256);
      expect(update.apkSizeBytes, 26000000);
      expect(update.releaseNotes, '- New statistics screen');
      expect(update.apkDownloadUrl.path, endsWith('.apk'));
    });

    test('refuses an APK hosted outside github.com', () {
      expect(
        () => parseLatestRelease(buildReleaseJson(downloadUrl: 'https://evil.example/komit.apk')),
        throwsA(isA<AppUpdateException>()),
      );
    });

    test('refuses an APK whose digest is not a SHA-256', () {
      expect(() => parseLatestRelease(buildReleaseJson(digest: 'sha256:abc')), throwsA(isA<AppUpdateException>()));
    });

    test('refuses a release without APK', () {
      expect(
        () => parseLatestRelease(jsonEncode({'tag_name': 'v1.1.0', 'assets': <Object?>[]})),
        throwsA(isA<AppUpdateException>()),
      );
    });
  });
}
