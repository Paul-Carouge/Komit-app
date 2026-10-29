import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../data/backup/encrypted_backup_envelope.dart';

const MethodChannel _backupEncryptionChannel = MethodChannel('com.paulcarouge.komit/backup_encryption');

/// The passphrase does not open the file, or the file was altered: AES-GCM cannot tell which.
class WrongBackupPassphraseException implements Exception {
  const WrongBackupPassphraseException();

  @override
  String toString() => 'WrongBackupPassphraseException';
}

/// Seals and opens passphrase-protected exports with Android's javax.crypto, on a background
/// thread there (see BackupEncryption.kt and docs/adr/0005).
class BackupEncryptionService {
  BackupEncryptionService({this._channel = _backupEncryptionChannel});

  final MethodChannel _channel;

  /// Returns the encrypted file's content.
  Future<String> encryptBackupJson(String backupJson, {required String passphrase}) async {
    final sealed = await _channel.invokeMapMethod<String, Uint8List>('seal', {
      'plaintext': Uint8List.fromList(utf8.encode(backupJson)),
      'passphrase': passphrase,
      'iterationCount': encryptedBackupKdfIterationCount,
    });
    final salt = sealed?['salt'];
    final nonce = sealed?['nonce'];
    final ciphertext = sealed?['ciphertext'];
    if (salt == null || nonce == null || ciphertext == null) {
      throw PlatformException(code: 'encryption_failed', message: 'Incomplete sealed backup');
    }
    final envelope = EncryptedBackupEnvelope(
      kdfIterationCount: encryptedBackupKdfIterationCount,
      salt: salt,
      nonce: nonce,
      ciphertext: ciphertext,
    );
    return Isolate.run(() => encodeEncryptedBackupEnvelope(envelope));
  }

  /// Returns the backup JSON inside [envelope]; throws [WrongBackupPassphraseException].
  Future<String> decryptBackupEnvelope(EncryptedBackupEnvelope envelope, {required String passphrase}) async {
    final Uint8List? plaintext;
    try {
      plaintext = await _channel.invokeMethod<Uint8List>('open', {
        'salt': envelope.salt,
        'nonce': envelope.nonce,
        'ciphertext': envelope.ciphertext,
        'passphrase': passphrase,
        'iterationCount': envelope.kdfIterationCount,
      });
    } on PlatformException catch (error) {
      if (error.code == 'wrong_passphrase') throw const WrongBackupPassphraseException();
      rethrow;
    }
    if (plaintext == null) throw PlatformException(code: 'encryption_failed', message: 'Empty decrypted backup');
    return utf8.decode(plaintext);
  }
}
