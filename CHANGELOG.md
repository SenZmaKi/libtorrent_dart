## 1.0.1

- Add Android ARMv7 (`armeabi-v7a`) native binary support.
- Fix native CI Dart SDK setup on composite-action callers.

## 1.0.0

- Mark the cross-platform native-assets API as stable.
- Document installation through `dart pub add libtorrent_dart`.

## 0.4.5

- Include the complete Dart implementation in the published package archive.
- Restore pub.dev analysis, documentation, and native platform detection.
- Document the supported high-level API and hide raw C bindings from dartdoc.
- Update native-asset hooks to `code_assets` 2.0 and `hooks` 2.2.
- Require Dart 3.10 or newer and verify dependency lower bounds.

## 0.4.4

- Package the Dart wrapper and libtorrent object files together in the iOS
  static archive instead of publishing the thin wrapper archive by itself.
- Link the iOS archive into the Flutter example during CI before publishing it.

## 0.4.3

- Fix pub.dev validation by excluding tracked libtorrent submodule sources from
  the repository's broad CMake ignore rules.
- Publish through a warning-aware OIDC job without installing Flutter for this
  pure Dart package.

## 0.4.2

- Replace the generated Flutter counter app with a working magnet download
  example using the public `libtorrent_dart` API.
- Clean up progress callbacks before removing torrents and closing sessions in
  the command-line and Flutter examples.
- Fix the Flutter example package metadata and analyzer dependencies.
- Declare Android network access and document how to run the example.

## 0.4.1

- Add prebuilt native assets for ARM64 and x64 Linux, macOS, Windows, and
  Android targets.
- Add an ARM64 iOS static library.
- Download the native asset matching the package version and target
  architecture from GitHub Releases during the Dart build hook.
- Prepare the package for distribution through pub.dev.
