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
