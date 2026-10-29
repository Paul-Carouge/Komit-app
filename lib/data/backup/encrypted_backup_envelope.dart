import 'dart:convert';
import 'dart:typed_data';

import 'backup_snapshot.dart';

const String encryptedBackupFormatName = 'komit-encrypted';
const int currentEncryptedBackupFormatVersion = 1;
const String encryptedBackupKdfName = 'PBKDF2-HMAC-SHA256';
const String encryptedBackupCipherName = 'AES-256-GCM';

/// OWASP's 2023 recommendation for PBKDF2-HMAC-SHA256: about a second on a mid-range phone,
/// which makes guessing a passphrase from a stolen file slow.
const int encryptedBackupKdfIterationCount = 600000;

/// Refuses a file that would keep the phone busy for hours; matches the Kotlin side.
const int maximumEncryptedBackupKdfIterationCount = 10000000;

/// Shorter passphrases are too easy to guess, even with a slow key derivation.
const int minimumBackupPassphraseLength = 8;

/// A v2 backup JSON sealed with a passphrase; see docs/adr/0005.
class EncryptedBackupEnvelope {
  const EncryptedBackupEnvelope({
    required this.kdfIterationCount,
    required this.salt,
    required this.nonce,
    required this.ciphertext,
  });

  final int kdfIterationCount;
  final Uint8List salt;
  final Uint8List nonce;

  /// AES-GCM output: the encrypted backup JSON followed by its authentication tag.
  final Uint8List ciphertext;
}

String encodeEncryptedBackupEnvelope(EncryptedBackupEnvelope envelope) => const JsonEncoder.withIndent(' ').convert({
  'format': encryptedBackupFormatName,
  'version': currentEncryptedBackupFormatVersion,
  'kdf': {'name': encryptedBackupKdfName, 'iterations': envelope.kdfIterationCount},
  'cipher': encryptedBackupCipherName,
  'salt': base64Encode(envelope.salt),
  'nonce': base64Encode(envelope.nonce),
  'ciphertext': base64Encode(envelope.ciphertext),
});

/// Null when [jsonText] is not an encrypted backup, so plain v1 and v2 files take their usual
/// path. Throws [InvalidBackupException] for an encrypted backup this version cannot read.
EncryptedBackupEnvelope? decodeEncryptedBackupEnvelopeIfPresent(String jsonText) {
  final Object? root;
  try {
    root = jsonDecode(jsonText);
  } on FormatException {
    return null;
  }
  if (root is! Map<String, Object?> || root['format'] != encryptedBackupFormatName) return null;
  if (root['version'] != currentEncryptedBackupFormatVersion) {
    throw InvalidBackupException('Unsupported encrypted backup version: ${root['version']}');
  }
  final kdf = root['kdf'];
  if (kdf is! Map<String, Object?> ||
      kdf['name'] != encryptedBackupKdfName ||
      root['cipher'] != encryptedBackupCipherName) {
    throw const InvalidBackupException('Unsupported encryption');
  }
  final iterationCount = kdf['iterations'];
  if (iterationCount is! int || iterationCount < 1 || iterationCount > maximumEncryptedBackupKdfIterationCount) {
    throw const InvalidBackupException('Invalid key derivation settings');
  }
  return EncryptedBackupEnvelope(
    kdfIterationCount: iterationCount,
    salt: _decodeBase64Field(root, 'salt'),
    nonce: _decodeBase64Field(root, 'nonce'),
    ciphertext: _decodeBase64Field(root, 'ciphertext'),
  );
}

Uint8List _decodeBase64Field(Map<String, Object?> root, String key) {
  final value = root[key];
  if (value is! String) throw InvalidBackupException('Missing $key');
  try {
    return base64Decode(value);
  } on FormatException {
    throw InvalidBackupException('Invalid $key');
  }
}
