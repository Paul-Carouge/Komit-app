# 5. On-device privacy: Android backups, export encryption and no SQLCipher

Date: 2026-10-29 · Status: accepted

## Context

Komit promises that a user's habits, notes and first name stay on their phone. By
default Android copies an app's files to the user's Google cloud backup and to a new
phone during a device-to-device transfer. Komit cannot see or verify how the cloud copy
is protected, while the transfer to a new phone is exactly what a user expects when
they change phones.

Users also export backups as JSON files that they store in places Komit does not
control, such as a cloud drive or a messaging app. A plain file there can be read by
anyone who can open it.

Finally, the question of encrypting the database itself (for example with SQLCipher)
comes up for any privacy-focused app.

## Decision

- **No cloud backup, device transfer kept.** On Android 12 and later,
  `res/xml/data_extraction_rules.xml` excludes every storage domain from
  `<cloud-backup>` and has no `<device-transfer>` section, so a transfer still copies
  everything. On Android 9 to 11, `res/xml-v28/backup_rules.xml` includes every domain
  only with `requireFlags="deviceToDeviceTransfer"`. Android 7 to 8.1 cannot tell the
  two apart, so `res/xml/backup_rules.xml` excludes everything there: on those versions
  users move their data with an export.
- **The release build checks the merged manifest.** The `verifyReleaseManifest` Gradle
  task runs before `assembleRelease`, `bundleRelease` and `check`. It fails when the
  merged manifest, plugins included, requests a permission outside
  `releaseManifestAllowedPermissions` or loses `allowBackup`, `fullBackupContent` or
  `dataExtractionRules`.
- **HTTPS only.** `res/xml/network_security_config.xml` forbids cleartext traffic and
  trusts only the system certificate authorities. Komit's only network traffic is the
  GitHub release check and the APK download. Correction (2.3.1): that config does not
  govern `dart:io`, which the updater uses. `dart:io` trusts only the system certificate
  store, not user-installed authorities; `app_update_service.dart` follows redirects itself
  and refuses any that leave HTTPS.
- **Encrypted exports are optional.** The user may protect an export with a passphrase.
  The file is a JSON envelope `{format: "komit-encrypted", version, kdf, salt, nonce,
  ciphertext}` around the usual v2 backup JSON. The key is derived with
  PBKDF2-HMAC-SHA256 and the data is sealed with AES-256-GCM, both from `javax.crypto`
  through a method channel, so Komit adds no cryptography dependency. The work runs on a
  background thread on the Android side. The GCM tag makes a wrong passphrase and a
  tampered file fail the same way, with a typed error, before anything is imported. Plain
  export stays the default because a forgotten passphrase makes a backup useless.
- **Automatic local backups.** Before an import or a restore, before an update is
  installed, and once a day when the data changed, Komit writes a v2 snapshot to
  `files/backups` in app storage and keeps only the most recent ones. They never leave
  the device, follow the backup rules above, and can be restored from Settings.
- **No SQLCipher.** The database is not encrypted at rest by Komit.

## Why not SQLCipher

Android already encrypts app storage at rest with file-based encryption on every device
Komit supports, and other apps cannot read Komit's private files. SQLCipher would
therefore only protect against an attacker who has both an unlocked or rooted phone and
Komit's key; on such a device the key, which has to live in the Android Keystore and be
usable whenever the app or a reminder runs, would be reachable too. In exchange it
would add a native library of several megabytes to every APK, slow down each query,
complicate the database shared across isolates (ADR 0004) and the migrations, and turn a
lost key into a total loss of the user's history. The optional app lock covers the
realistic threat, which is someone else holding the unlocked phone.

## Consequences

- A user who restores a new phone from a Google cloud backup does not get their Komit
  data back; the privacy screen says so and suggests an export or a phone-to-phone
  transfer.
- A new plugin that adds a permission breaks the release build until the allowlist and
  the privacy screen are updated on purpose.
- Encrypted exports can only be opened by Komit on Android, and only with the passphrase.
