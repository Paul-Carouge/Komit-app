import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const String _latestReleaseApiUrl = 'https://api.github.com/repos/Paul-Carouge/Komit-app/releases/latest';
const MethodChannel _appUpdateChannel = MethodChannel('com.paulcarouge.komit/app_update');
const Duration _networkTimeout = Duration(seconds: 20);

class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkSha256,
  });

  final String version;
  final String releaseNotes;
  final Uri apkDownloadUrl;
  final String apkSha256;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Self-update from the public GitHub Releases of Komit-app (Android only).
class AppUpdateService {
  bool get isSupported => Platform.isAndroid;

  Future<String> readInstalledVersion() async =>
      await _appUpdateChannel.invokeMethod<String>('currentVersionName') ??
      (throw const AppUpdateException('Installed version unknown'));

  /// Returns null when the installed version is the latest one.
  Future<AvailableUpdate?> findAvailableUpdate() async {
    final installedVersion = await readInstalledVersion();
    final client = HttpClient()..connectionTimeout = _networkTimeout;
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseApiUrl));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(_networkTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException('GitHub answered ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join().timeout(_networkTimeout);
      final release = parseLatestRelease(body);
      return isVersionNewer(release.version, than: installedVersion) ? release : null;
    } finally {
      client.close();
    }
  }

  /// Downloads the APK to the cache, then the native side checks its SHA-256 and starts the installer.
  Future<void> downloadAndInstall(AvailableUpdate update, {required void Function(double progress) onProgress}) async {
    final canInstall = await _appUpdateChannel.invokeMethod<bool>('canInstallPackages') ?? false;
    if (!canInstall) {
      await _appUpdateChannel.invokeMethod<void>('openInstallPermissionSettings');
      throw const AppUpdateException('Allow Komit to install apps, then try again.');
    }
    final apkFile = File('${(await getTemporaryDirectory()).path}/komit-update.apk');
    final client = HttpClient()..connectionTimeout = _networkTimeout;
    try {
      final response = await (await client.getUrl(update.apkDownloadUrl)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException('Download failed (${response.statusCode})');
      }
      final totalByteCount = response.contentLength;
      var receivedByteCount = 0;
      final sink = apkFile.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          receivedByteCount += chunk.length;
          if (totalByteCount > 0) onProgress(receivedByteCount / totalByteCount);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
    try {
      await _appUpdateChannel.invokeMethod<void>('installApk', {
        'apkPath': apkFile.path,
        'expectedSha256': update.apkSha256,
      });
    } on PlatformException catch (error) {
      throw AppUpdateException(error.message ?? error.code);
    }
  }
}

/// Reads the GitHub "latest release" payload; the APK asset must carry a sha256 digest.
AvailableUpdate parseLatestRelease(String jsonText) {
  final Object? decoded = jsonDecode(jsonText);
  if (decoded is! Map<String, Object?>) throw const AppUpdateException('Unexpected release format');
  final tagName = decoded['tag_name'];
  final assets = decoded['assets'];
  if (tagName is! String || assets is! List<Object?>) throw const AppUpdateException('Unexpected release format');
  for (final asset in assets) {
    if (asset is! Map<String, Object?>) continue;
    final name = asset['name'];
    final downloadUrl = asset['browser_download_url'];
    final digest = asset['digest'];
    if (name is String &&
        name.endsWith('.apk') &&
        downloadUrl is String &&
        digest is String &&
        digest.startsWith('sha256:')) {
      final downloadUri = Uri.parse(downloadUrl);
      // Never follow a release that points anywhere but GitHub over HTTPS.
      if (downloadUri.scheme != 'https' || downloadUri.host != 'github.com') {
        throw const AppUpdateException('Untrusted download location');
      }
      return AvailableUpdate(
        version: tagName.replaceFirst(RegExp('^v'), ''),
        releaseNotes: (decoded['body'] as String?)?.trim() ?? '',
        apkDownloadUrl: downloadUri,
        apkSha256: digest.substring('sha256:'.length),
      );
    }
  }
  throw const AppUpdateException('No installable APK in the latest release');
}

/// Compares `major.minor.patch` versions; any build suffix (`+3`, `-beta`) is ignored.
bool isVersionNewer(String candidateVersion, {required String than}) {
  List<int> numericParts(String version) => [
    for (final part in version.split(RegExp('[+-]')).first.split('.')) int.tryParse(part) ?? 0,
  ];
  final candidateParts = numericParts(candidateVersion);
  final installedParts = numericParts(than);
  for (var index = 0; index < 3; index++) {
    final candidatePart = index < candidateParts.length ? candidateParts[index] : 0;
    final installedPart = index < installedParts.length ? installedParts[index] : 0;
    if (candidatePart != installedPart) return candidatePart > installedPart;
  }
  return false;
}
