import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:yaml/yaml.dart';

import 'download.dart';

const _defaultReleaseRepo = 'SenZmaKi/libtorrent_dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final os = input.config.code.targetOS;
    final packageRoot = input.packageRoot;
    final packageVersion = _resolvePackageVersion(packageRoot);

    // Map from target OS to the pre-built binary path inside the package.
    final Uri binaryUri;
    final String releaseAssetName;
    final LinkMode linkMode;
    switch (os) {
      case OS.macOS:
        final architectureDirectory = _architectureDirectory(
          os,
          input.config.code.targetArchitecture,
        );
        binaryUri = packageRoot.resolve(
          'binaries/macos/$packageVersion/$architectureDirectory/'
          'libtorrent-rasterbar.dylib',
        );
        releaseAssetName =
            'macos-$architectureDirectory-libtorrent-rasterbar.dylib';
        linkMode = DynamicLoadingBundled();
      case OS.android:
        final architectureDirectory = _architectureDirectory(
          os,
          input.config.code.targetArchitecture,
        );
        binaryUri = packageRoot.resolve(
          'binaries/android/$packageVersion/$architectureDirectory/'
          'libtorrent-rasterbar.so',
        );
        releaseAssetName =
            'android-$architectureDirectory-libtorrent-rasterbar.so';
        linkMode = DynamicLoadingBundled();
      case OS.linux:
        final architectureDirectory = _architectureDirectory(
          os,
          input.config.code.targetArchitecture,
        );
        binaryUri = packageRoot.resolve(
          'binaries/linux/$packageVersion/$architectureDirectory/'
          'libtorrent-rasterbar.so',
        );
        releaseAssetName =
            'linux-$architectureDirectory-libtorrent-rasterbar.so';
        linkMode = DynamicLoadingBundled();
      case OS.windows:
        final architectureDirectory = _architectureDirectory(
          os,
          input.config.code.targetArchitecture,
        );
        binaryUri = packageRoot.resolve(
          'binaries/windows/$packageVersion/$architectureDirectory/'
          'torrent-rasterbar.dll',
        );
        releaseAssetName =
            'windows-$architectureDirectory-torrent-rasterbar.dll';
        linkMode = DynamicLoadingBundled();
      case OS.iOS:
        binaryUri = packageRoot.resolve(
          'binaries/ios/$packageVersion/libtorrent-rasterbar.a',
        );
        releaseAssetName = 'ios-libtorrent-rasterbar.a';
        linkMode = StaticLinking();
      default:
        throw UnsupportedError('Unsupported target OS: ${os.name}');
    }

    final binaryFile = File.fromUri(binaryUri);
    if (!binaryFile.existsSync()) {
      final releaseTag = _resolveReleaseTag(packageVersion);
      await _downloadReleaseBinary(binaryFile, releaseAssetName, releaseTag);
    }
    if (!binaryFile.existsSync()) {
      throw StateError(
        'Binary unavailable at ${binaryUri.toFilePath()} and release fallback '
        'download failed. Build locally or publish release assets first.',
      );
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        // This name must match the asset ID used in @DefaultAsset:
        //   package:libtorrent_dart/src/libtorrent_dart.dart
        name: 'src/libtorrent_dart.dart',
        linkMode: linkMode,
        file: binaryUri,
      ),
    );

    // Tell the build system to re-run this hook if the binary changes.
    output.dependencies.add(binaryUri);
  });
}

String _architectureDirectory(OS os, Architecture architecture) =>
    switch ((os, architecture)) {
      (OS.android, Architecture.arm) => 'armeabi-v7a',
      (OS.android, Architecture.arm64) => 'arm64-v8a',
      (OS.android, Architecture.x64) => 'x86_64',
      (OS.macOS || OS.linux || OS.windows, Architecture.arm64) => 'arm64',
      (OS.macOS || OS.linux || OS.windows, Architecture.x64) => 'x64',
      _ => throw UnsupportedError(
        'Unsupported ${os.name} architecture: ${architecture.name}',
      ),
    };

String _resolvePackageVersion(Uri packageRoot) {
  final pubspecFile = File.fromUri(packageRoot.resolve('pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw StateError('pubspec.yaml not found at ${pubspecFile.path}');
  }
  final yaml = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final version = yaml['version']?.toString();
  if (version == null || version.isEmpty) {
    throw StateError('Package version missing in pubspec.yaml');
  }
  return version.trim();
}

String _resolveReleaseTag(String packageVersion) {
  final overrideTag = Platform.environment['LTD_RELEASE_TAG'];
  if (overrideTag != null && overrideTag.isNotEmpty) return overrideTag;
  return packageVersion;
}

Future<void> _downloadReleaseBinary(
  File destination,
  String assetName,
  String releaseTag,
) async {
  final repo =
      Platform.environment['LTD_RELEASE_REPOSITORY'] ?? _defaultReleaseRepo;
  stdout.writeln('Native binary missing: ${destination.path}');
  await downloadBinary(
    destination,
    releaseAssetUrls(repo, releaseTag, assetName),
  );
}
