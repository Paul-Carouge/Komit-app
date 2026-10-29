import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/repositories/settings_repository.dart';

const String _latestReleaseApiUrl = 'https://api.github.com/repos/Paul-Carouge/Komit-app/releases/latest';
const MethodChannel _appUpdateChannel = MethodChannel('com.paulcarouge.komit/app_update');
const Duration _networkTimeout = Duration(seconds: 20);

/// The automatic check runs at most this often, so GitHub sees the device's IP address at
/// most once a day however often Komit is opened.
const Duration minimumIntervalBetweenAutomaticUpdateChecks = Duration(hours: 24);

/// Far above a real Komit APK (~25 MB); only guards the cache against a bogus asset.
const int _maximumApkSizeBytes = 200 * 1024 * 1024;

class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkSha256,
    required this.apkSizeBytes,
  });

  final String version;
  final String releaseNotes;
  final Uri apkDownloadUrl;
  final String apkSha256;
  final int apkSizeBytes;
}

/// Why an update failed, so the UI can explain it in the user's language. The install*
/// names after [installFailed] are sent by UpdateInstallStatusReceiver.kt.
enum AppUpdateFailureReason {
  installPermissionRequired,
  network,
  invalidRelease,
  corruptedDownload,
  installFailed,
  installCancelled,
  installConflict,
  installIncompatible,
  installStorage,
  installBlocked,
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.reason, this.technicalDetail);

  final AppUpdateFailureReason reason;

  /// For logs only, never shown to the user.
  final String technicalDetail;

  @override
  String toString() => 'AppUpdateException(${reason.name}): $technicalDetail';
}

/// Self-update from the public GitHub Releases of Komit-app (Android only).
class AppUpdateService {
  bool get isSupported => Platform.isAndroid;

  StreamController<AppUpdateFailureReason>? _installFailures;

  /// Failures Android reports once its installer took over, after [downloadAndInstall] returned.
  Stream<AppUpdateFailureReason> get installFailures {
    final existingFailures = _installFailures;
    if (existingFailures != null) return existingFailures.stream;
    final failures = StreamController<AppUpdateFailureReason>.broadcast();
    _installFailures = failures;
    _appUpdateChannel.setMethodCallHandler((call) async {
      if (call.method != 'installFailed') throw MissingPluginException(call.method);
      failures.add(installFailureReasonNamed(call.arguments));
    });
    return failures.stream;
  }

  Future<bool> canInstallPackages() async => await _appUpdateChannel.invokeMethod<bool>('canInstallPackages') ?? false;

  Future<void> openInstallPermissionSettings() => _appUpdateChannel.invokeMethod<void>('openInstallPermissionSettings');

  Future<void> openReleasesPage() => _appUpdateChannel.invokeMethod<void>('openReleasesPage');

  Future<String> readInstalledVersion() async =>
      await _appUpdateChannel.invokeMethod<String>('currentVersionName') ??
      (throw const AppUpdateException(AppUpdateFailureReason.installFailed, 'Installed version unknown'));

  /// Returns null when the installed version is the latest one.
  Future<AvailableUpdate?> findAvailableUpdate() async {
    final installedVersion = await readInstalledVersion();
    final client = HttpClient()..connectionTimeout = _networkTimeout;
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseApiUrl));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(_networkTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException(AppUpdateFailureReason.network, 'GitHub answered ${response.statusCode}');
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
    if (!await canInstallPackages()) {
      throw const AppUpdateException(AppUpdateFailureReason.installPermissionRequired, 'Install permission missing');
    }
    final apkFile = File('${(await getTemporaryDirectory()).path}/komit-update.apk');
    try {
      await _downloadApk(update, apkFile, onProgress: onProgress);
      await _appUpdateChannel.invokeMethod<void>('installApk', {
        'apkPath': apkFile.path,
        'expectedSha256': update.apkSha256,
      });
    } on PlatformException catch (error) {
      await _deleteLeftoverApk(apkFile);
      final reason = error.code == 'checksum_mismatch'
          ? AppUpdateFailureReason.corruptedDownload
          : AppUpdateFailureReason.installFailed;
      throw AppUpdateException(reason, error.message ?? error.code);
    } on Object {
      // A partial or refused download must not stay in the cache.
      await _deleteLeftoverApk(apkFile);
      rethrow;
    }
  }

  Future<void> _deleteLeftoverApk(File apkFile) async {
    try {
      if (await apkFile.exists()) await apkFile.delete();
    } on FileSystemException catch (error) {
      // The cache is cleared by Android anyway; the failure that brought us here matters more.
      developer.log('Leftover update APK not deleted', name: 'komit.update', error: error.runtimeType);
    }
  }

  Future<void> _downloadApk(
    AvailableUpdate update,
    File apkFile, {
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = _networkTimeout;
    try {
      final response = await (await client.getUrl(update.apkDownloadUrl)).close().timeout(_networkTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw AppUpdateException(AppUpdateFailureReason.network, 'Download answered ${response.statusCode}');
      }
      var receivedByteCount = 0;
      final sink = apkFile.openWrite();
      try {
        // The timeout applies between chunks, so a stalled connection fails instead of hanging forever.
        await for (final chunk in response.timeout(_networkTimeout)) {
          receivedByteCount += chunk.length;
          if (receivedByteCount > update.apkSizeBytes) {
            throw const AppUpdateException(AppUpdateFailureReason.corruptedDownload, 'Larger than announced');
          }
          sink.add(chunk);
          onProgress(receivedByteCount / update.apkSizeBytes);
        }
      } finally {
        await sink.close();
      }
    } on AppUpdateException {
      rethrow;
    } on Object catch (error) {
      throw AppUpdateException(AppUpdateFailureReason.network, '$error');
    } finally {
      client.close();
    }
  }
}

/// Returns true, and records [now] as the last check, when an automatic check should run now:
/// it is turned on and none ran in the last [minimumIntervalBetweenAutomaticUpdateChecks]. A
/// last check in the future (the clock was set back) does not block checks forever.
Future<bool> claimAutomaticUpdateCheck(SettingsRepository settingsRepository, {required DateTime now}) async {
  if (!settingsRepository.readSettings().isAutomaticUpdateCheckEnabled) return false;
  final lastCheckedAt = settingsRepository.readLastAutomaticUpdateCheckAt();
  final hasCheckedRecently =
      lastCheckedAt != null &&
      !lastCheckedAt.isAfter(now) &&
      now.difference(lastCheckedAt) < minimumIntervalBetweenAutomaticUpdateChecks;
  if (hasCheckedRecently) return false;
  await settingsRepository.saveLastAutomaticUpdateCheckAt(now);
  return true;
}

/// Reads a failure sent by the native installer receiver; anything unknown is a generic failure.
AppUpdateFailureReason installFailureReasonNamed(Object? name) =>
    (name is String ? AppUpdateFailureReason.values.asNameMap()[name] : null) ?? AppUpdateFailureReason.installFailed;

/// Reads the GitHub "latest release" payload; the APK asset must carry a sha256 digest.
AvailableUpdate parseLatestRelease(String jsonText) {
  final Object? decoded = jsonDecode(jsonText);
  if (decoded is! Map<String, Object?>) {
    throw const AppUpdateException(AppUpdateFailureReason.invalidRelease, 'Unexpected release format');
  }
  final tagName = decoded['tag_name'];
  final assets = decoded['assets'];
  if (tagName is! String || assets is! List<Object?>) {
    throw const AppUpdateException(AppUpdateFailureReason.invalidRelease, 'Unexpected release format');
  }
  for (final asset in assets) {
    if (asset is! Map<String, Object?>) continue;
    final name = asset['name'];
    final downloadUrl = asset['browser_download_url'];
    final digest = asset['digest'];
    final sizeBytes = asset['size'];
    if (name is String && name.endsWith('.apk') && downloadUrl is String) {
      final sha256Match = digest is String ? RegExp(r'^sha256:([0-9a-f]{64})$').firstMatch(digest) : null;
      if (sha256Match == null || sizeBytes is! int || sizeBytes <= 0 || sizeBytes > _maximumApkSizeBytes) {
        throw const AppUpdateException(AppUpdateFailureReason.invalidRelease, 'APK digest or size missing');
      }
      final downloadUri = Uri.parse(downloadUrl);
      // Never follow a release that points anywhere but GitHub over HTTPS.
      if (downloadUri.scheme != 'https' || downloadUri.host != 'github.com') {
        throw const AppUpdateException(AppUpdateFailureReason.invalidRelease, 'Untrusted download location');
      }
      return AvailableUpdate(
        version: tagName.replaceFirst(RegExp('^v'), ''),
        releaseNotes: (decoded['body'] as String?)?.trim() ?? '',
        apkDownloadUrl: downloadUri,
        apkSha256: sha256Match.group(1)!,
        apkSizeBytes: sizeBytes,
      );
    }
  }
  throw const AppUpdateException(AppUpdateFailureReason.invalidRelease, 'No APK in the latest release');
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
