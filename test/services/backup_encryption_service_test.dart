import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/data/backup/backup_json_codec.dart';
import 'package:komit/data/backup/backup_snapshot.dart';
import 'package:komit/data/backup/encrypted_backup_envelope.dart';
import 'package:komit/services/backup_encryption_service.dart';

import '../data/backup_import_test.dart' show buildLegacyBackupJson, buildOldCurrentBackupJson;

const MethodChannel _fakeEncryptionChannel = MethodChannel('test/backup_encryption');

/// Stands in for javax.crypto (tested in BackupEncryptionTest.kt): the "ciphertext" carries the
/// passphrase, so only the same passphrase opens it, like AES-GCM's tag check.
Future<Object?> _fakeJavaxCrypto(MethodCall call) async {
  final arguments = call.arguments as Map<Object?, Object?>;
  final passphraseBytes = utf8.encode(arguments['passphrase']! as String);
  switch (call.method) {
    case 'seal':
      return {
        'salt': Uint8List(16),
        'nonce': Uint8List(12),
        'ciphertext': Uint8List.fromList([...passphraseBytes, 0, ...arguments['plaintext']! as Uint8List]),
      };
    case 'open':
      final ciphertext = arguments['ciphertext']! as Uint8List;
      final separatorIndex = ciphertext.indexOf(0);
      if (separatorIndex < 0 || utf8.decode(ciphertext.sublist(0, separatorIndex)) != utf8.decode(passphraseBytes)) {
        throw PlatformException(code: 'wrong_passphrase');
      }
      return ciphertext.sublist(separatorIndex + 1);
  }
  throw MissingPluginException(call.method);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = BackupEncryptionService(channel: _fakeEncryptionChannel);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _fakeEncryptionChannel,
      _fakeJavaxCrypto,
    );
  });

  test('an encrypted export round-trips to the same backup', () async {
    final plainBackupJson = buildOldCurrentBackupJson();

    final encryptedFile = await service.encryptBackupJson(plainBackupJson, passphrase: 'correct horse');
    final envelope = decodeEncryptedBackupEnvelopeIfPresent(encryptedFile)!;
    final decryptedJson = await service.decryptBackupEnvelope(envelope, passphrase: 'correct horse');

    expect(jsonDecode(encryptedFile), containsPair('format', encryptedBackupFormatName));
    expect(jsonDecode(encryptedFile), containsPair('kdf', {'name': 'PBKDF2-HMAC-SHA256', 'iterations': 600000}));
    expect(encryptedFile, isNot(contains('Felt great')));
    expect(decryptedJson, plainBackupJson);
    expect(decodeBackupSnapshotFromJson(decryptedJson).notes.single.content, 'Felt great');
  });

  test('a wrong passphrase gives a typed error', () async {
    final encryptedFile = await service.encryptBackupJson(buildOldCurrentBackupJson(), passphrase: 'correct horse');
    final envelope = decodeEncryptedBackupEnvelopeIfPresent(encryptedFile)!;

    expect(
      service.decryptBackupEnvelope(envelope, passphrase: 'wrong horse'),
      throwsA(isA<WrongBackupPassphraseException>()),
    );
  });

  test('plain v1 and v2 files are not taken for encrypted ones', () {
    expect(decodeEncryptedBackupEnvelopeIfPresent(buildLegacyBackupJson()), isNull);
    expect(decodeEncryptedBackupEnvelopeIfPresent(buildOldCurrentBackupJson()), isNull);
    expect(decodeEncryptedBackupEnvelopeIfPresent('not json'), isNull);
  });

  test('refuses an encrypted file from a future version or with abusive settings', () {
    String envelopeJson({Object version = 1, Object iterations = 600000}) => jsonEncode({
      'format': encryptedBackupFormatName,
      'version': version,
      'kdf': {'name': encryptedBackupKdfName, 'iterations': iterations},
      'cipher': encryptedBackupCipherName,
      'salt': base64Encode(Uint8List(16)),
      'nonce': base64Encode(Uint8List(12)),
      'ciphertext': base64Encode(Uint8List(32)),
    });

    expect(decodeEncryptedBackupEnvelopeIfPresent(envelopeJson()), isNotNull);
    expect(
      () => decodeEncryptedBackupEnvelopeIfPresent(envelopeJson(version: 2)),
      throwsA(isA<InvalidBackupException>()),
    );
    expect(
      () =>
          decodeEncryptedBackupEnvelopeIfPresent(envelopeJson(iterations: maximumEncryptedBackupKdfIterationCount + 1)),
      throwsA(isA<InvalidBackupException>()),
    );
  });
}
