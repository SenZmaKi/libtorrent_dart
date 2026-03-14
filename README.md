# libtorrent_dart

Dart FFI wrapper over [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

This package exposes two direct entry points:

- High-level wrapper API: `package:libtorrent_dart/src/libtorrent_dart.dart`
- Low-level FFI API: `package:libtorrent_dart/src/libtorrent_dart_ffi.dart`

## Installation

Add this to your `pubspec.yaml`

```yaml
dependencies:
  libtorrent_dart:
    git:
      url: https://github.com/SenZmaKi/libtorrent_dart
      ref: main # or specify a commit/tag
```

Then run:

```bash
flutter pub get
```

## Usage

Check out the [example](example/example.dart) for a quick start.

## Build

Build instructions for all supported platforms (macOS, Linux, Windows, Android, iOS) are in:

- [BUILD.md](docs/BUILD.md)

## API port coverage

Libtorrent API port coverage is tracked in:

- [API_PORT.md](docs/API_PORT.md)
