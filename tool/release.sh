#!/usr/bin/env bash
# Builds, verifies and publishes a Komit release on GitHub (README "Publish a version").
# Usage: tool/release.sh <release-notes.md>
# Signing stays on this machine: android/key.properties and the keystore never go to CI.
set -euo pipefail

# Same certificate as README "Verify a downloaded APK"; Android refuses updates signed by another key.
readonly PUBLISHED_CERTIFICATE_SHA256="7b8600aa8099476f8b1dc4290579381d2468af515e326b7b074e3c4b5e6bf9fd"

fail() {
  echo "release: $*" >&2
  exit 1
}

latest_android_build_tool() {
  local sdk_directory="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  local tool_path
  tool_path="$(printf "%s\n" "$sdk_directory"/build-tools/*/"$1" | sort -V | tail -n 1)"
  [[ -x "$tool_path" ]] || fail "$1 not found under $sdk_directory/build-tools; set ANDROID_HOME"
  echo "$tool_path"
}

verify_clean_and_up_to_date_main() {
  [[ "$(git branch --show-current)" == "main" ]] || fail "releases are cut from main"
  [[ -z "$(git status --porcelain)" ]] || fail "the working tree is not clean"
  git fetch --quiet --tags origin main
  [[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || fail "main differs from origin/main"
}

verify_apk_signing_certificate() {
  local apk_path="$1" certificates
  certificates="$("$(latest_android_build_tool apksigner)" verify --print-certs "$apk_path")" ||
    fail "$apk_path is not validly signed"
  [[ "$(grep -c 'certificate SHA-256 digest' <<<"$certificates")" == 1 ]] ||
    fail "$apk_path must have exactly one signer"
  grep -q "certificate SHA-256 digest: $PUBLISHED_CERTIFICATE_SHA256\$" <<<"$certificates" ||
    fail "$apk_path is not signed with the published key"
}

# Prints the versionCode and versionName the APK actually carries, separated by a space.
apk_version_code_and_name() {
  "$(latest_android_build_tool aapt2)" dump badging "$1" |
    sed -n "s/^package: .* versionCode='\([0-9]*\)' versionName='\([^']*\)'.*/\1 \2/p"
}

verify_version_code_went_up() {
  local apk_version_code="$1" previous_tag previous_version_code
  previous_tag="$(gh release view --json tagName --jq .tagName)" || fail "cannot read the latest GitHub release"
  previous_version_code="$(git show "$previous_tag:pubspec.yaml" | sed -n 's/^version: .*+\([0-9]*\)$/\1/p')"
  [[ -n "$previous_version_code" ]] || fail "cannot read the versionCode of $previous_tag"
  ((apk_version_code > previous_version_code)) ||
    fail "versionCode $apk_version_code is not above $previous_version_code ($previous_tag)"
}

main() {
  [[ $# == 1 ]] || fail "usage: tool/release.sh <release-notes.md>"
  local notes_path="$1"
  [[ -s "$notes_path" ]] || fail "release notes $notes_path are missing or empty"

  cd "$(git rev-parse --show-toplevel)"
  verify_clean_and_up_to_date_main

  local version_name version_code tag
  version_name="$(sed -n 's/^version: \([0-9]*\.[0-9]*\.[0-9]*\)+[0-9]*$/\1/p' pubspec.yaml)"
  version_code="$(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml)"
  [[ -n "$version_name" && -n "$version_code" ]] || fail "pubspec.yaml version must look like X.Y.Z+N"
  tag="v$version_name"
  git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null && fail "tag $tag already exists"
  grep -q "^## \[$version_name\]" CHANGELOG.md || fail "CHANGELOG.md has no [$version_name] section"
  [[ "$(grep -m 1 -v '^[[:space:]]*$' "$notes_path")" == "## Komit $version_name" ]] ||
    fail "release notes must start with '## Komit $version_name' (see tool/release-notes-template.md)"
  ! grep -q -e '<!--' -e 'X\.Y\.Z' "$notes_path" || fail "release notes still hold template text"

  flutter build apk --release --target-platform android-arm64 --split-debug-info="build/symbols/$tag"
  local apk_path="build/release/komit-$tag.apk"
  mkdir -p build/release
  cp build/app/outputs/flutter-apk/app-release.apk "$apk_path"

  verify_apk_signing_certificate "$apk_path"
  [[ "$(apk_version_code_and_name "$apk_path")" == "$version_code $version_name" ]] ||
    fail "$apk_path does not carry version $version_name+$version_code"
  verify_version_code_went_up "$version_code"

  echo "Ready to publish $tag ($apk_path) with notes from $notes_path."
  echo "Keep build/symbols/$tag/app.android-arm64.symbols with the keystore backup."
  read -r -p "Create the tag and the GitHub release? [y/N] " answer
  [[ "$answer" == "y" ]] || fail "cancelled; nothing was published"

  git tag -a "$tag" -m "Komit $version_name"
  git push origin "$tag"
  gh release create "$tag" "$apk_path" --verify-tag --title "Komit $version_name" --notes-file "$notes_path"
}

# Sourcing the script (to check one step by hand) defines the functions without releasing.
if [[ "${BASH_SOURCE[0]:-}" == "$0" ]]; then
  main "$@"
fi
