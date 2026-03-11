import 'dart:io';
import 'dart:convert';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _defaultReleaseRepo = 'SenZmaKi/libtorrent_dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final os = input.config.code.targetOS;
    final packageRoot = input.packageRoot;

    // Map from target OS to the pre-built binary path inside the package.
    final Uri binaryUri;
    final String releaseAssetName;
    switch (os) {
      case OS.macOS:
        binaryUri = packageRoot.resolve(
          'binaries/macos/libtorrent-rasterbar.dylib',
        );
        releaseAssetName = 'macos-libtorrent-rasterbar.dylib';
      case OS.android:
        binaryUri = packageRoot.resolve(
          'binaries/android/libtorrent-rasterbar.so',
        );
        releaseAssetName = 'android-libtorrent-rasterbar.so';
      case OS.linux:
        binaryUri = packageRoot.resolve(
          'binaries/linux/libtorrent-rasterbar.so',
        );
        releaseAssetName = 'linux-libtorrent-rasterbar.so';
      case OS.windows:
        binaryUri = packageRoot.resolve(
          'binaries/windows/torrent-rasterbar.dll',
        );
        releaseAssetName = 'windows-torrent-rasterbar.dll';
      default:
        throw UnsupportedError('Unsupported target OS: ${os.name}');
    }

    final binaryFile = File.fromUri(binaryUri);
    if (!binaryFile.existsSync()) {
      await _downloadReleaseBinary(binaryFile, releaseAssetName);
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
        linkMode: DynamicLoadingBundled(),
        file: binaryUri,
      ),
    );

    // Tell the build system to re-run this hook if the binary changes.
    output.dependencies.add(binaryUri);
  });
}

Future<void> _downloadReleaseBinary(File destination, String assetName) async {
  final repo = Platform.environment['LTD_RELEASE_REPOSITORY'] ?? _defaultReleaseRepo;
  final tag = Platform.environment['LTD_RELEASE_TAG'];
  final releaseApi = tag == null || tag.isEmpty
      ? Uri.https('api.github.com', '/repos/$repo/releases/latest')
      : Uri.https('api.github.com', '/repos/$repo/releases/tags/$tag');

  final client = HttpClient();
  client.userAgent = 'libtorrent_dart_hook';
  try {
    final releaseRes = await (await client.getUrl(releaseApi)).close();
    if (releaseRes.statusCode != 200) return;

    final releaseBody = await utf8.decodeStream(releaseRes);
    final releaseJson = jsonDecode(releaseBody) as Map<String, Object?>;
    final assets = (releaseJson['assets'] as List<Object?>?) ?? const [];
    Map<String, Object?>? selectedAsset;
    for (final asset in assets) {
      final map = asset as Map<String, Object?>;
      if (map['name'] == assetName) {
        selectedAsset = map;
        break;
      }
    }
    if (selectedAsset == null) return;

    final downloadUrl = selectedAsset['browser_download_url'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) return;

    destination.parent.createSync(recursive: true);
    final assetRes = await (await client.getUrl(Uri.parse(downloadUrl))).close();
    if (assetRes.statusCode != 200) return;

    await destination.openWrite().addStream(assetRes);
  } finally {
    client.close(force: true);
  }
}
