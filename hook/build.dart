import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final os = input.config.code.targetOS;
    final packageRoot = input.packageRoot;

    // Map from target OS to the pre-built binary path inside the package.
    final Uri binaryUri;
    switch (os) {
      case OS.macOS:
        binaryUri = packageRoot.resolve(
          'binaries/macos/libtorrent-rasterbar.dylib',
        );
      case OS.android || OS.linux:
        binaryUri = packageRoot.resolve(
          'binaries/android/libtorrent-rasterbar.so',
        );
      case OS.windows:
        binaryUri = packageRoot.resolve(
          'binaries/windows/torrent-rasterbar.dll',
        );
      default:
        throw UnsupportedError('Unsupported target OS: ${os.name}');
    }

    final binaryFile = File.fromUri(binaryUri);
    if (!binaryFile.existsSync()) {
      throw StateError(
        'Pre-built binary not found at ${binaryUri.toFilePath()}. '
        'Run the CMake build for ${os.name} first — see docs/BUILD.md.',
      );
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        // This name must match the asset ID used in @DefaultAsset:
        //   package:libtorrent_dart/src/libtorrent_dart.dart
        name: 'src/libtorrent_dart.dart',
        linkMode: DynamicLoadingBundled(),
        file: binaryUri,
      ),
    );

    // Tell the build system to re-run this hook if the binary changes.
    output.dependencies.add(binaryUri);
  });
}
