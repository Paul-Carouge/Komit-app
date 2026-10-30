# 2. In-app updates from public GitHub Releases

Date: 2026-10-28 · Status: accepted

## Context

Komit is distributed as an APK outside the Play Store. The user wants the app to
update itself and to show what changed. A private repository would require shipping a
GitHub token inside the APK, where anyone could extract it.

## Decision

- The repository `Paul-Carouge/Komit-app` is public; each version is a GitHub Release
  with one arm64 APK asset. The release body is the changelog shown in the app.
- At launch (once per process) and on demand, the app reads
  `/repos/Paul-Carouge/Komit-app/releases/latest`, compares the tag to the installed
  `versionName`, and offers the update. Since 2.4.0 the automatic check runs at most once an
  hour (it was once a day), and the release body is rendered as headings, bullets and bold
  text only; it is shown again once after the update installs.
- The APK is downloaded to the app cache, its SHA-256 is checked natively against the
  asset digest published by GitHub, then installed with a `PackageInstaller` session.
- Android itself refuses an update signed with a different key, which is the real
  protection against a tampered APK; the digest check catches corrupted downloads.

## Consequences

- Requires `REQUEST_INSTALL_PACKAGES`; the user must allow "install unknown apps"
  for Komit once.
- The release keystore must never be lost (see README, "Release signing").
- Only arm64 devices are supported by the published APK.
