import 'dart:io';
import 'dart:convert';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:yaml/yaml.dart';

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
      final releaseTag = _resolveReleaseTag(packageRoot);
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
        linkMode: DynamicLoadingBundled(),
        file: binaryUri,
      ),
    );

    // Tell the build system to re-run this hook if the binary changes.
    output.dependencies.add(binaryUri);
  });
}

String _resolveReleaseTag(Uri packageRoot) {
  final overrideTag = Platform.environment['LTD_RELEASE_TAG'];
  if (overrideTag != null && overrideTag.isNotEmpty) return overrideTag;

  final pubspecFile = File.fromUri(packageRoot.resolve('pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw StateError('pubspec.yaml not found at ${pubspecFile.path}');
  }
  final yaml = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final version = yaml['version']?.toString();
  if (version == null || version.isEmpty) {
    throw StateError('Package version missing in pubspec.yaml');
  }
  return version;
}

Future<void> _downloadReleaseBinary(
  File destination,
  String assetName,
  String releaseTag,
) async {
  final repo =
      Platform.environment['LTD_RELEASE_REPOSITORY'] ?? _defaultReleaseRepo;
  final candidateTags = <String>[releaseTag, 'v$releaseTag'];

  final client = HttpClient();
  client.userAgent = 'libtorrent_dart_hook';
  try {
    stdout.writeln('---------------------------------------------------------');
    stdout.writeln('Native binary missing: ${destination.path}');
    stdout.writeln(
      'Attempting to download $assetName from $repo (tag: $releaseTag)...',
    );
    stdout.writeln('---------------------------------------------------------');

    Map<String, Object?>? selectedAsset;
    for (final tag in candidateTags) {
      final releaseApi = Uri.https(
        'api.github.com',
        '/repos/$repo/releases/tags/$tag',
      );
      final releaseRes = await _getWithRedirects(client, releaseApi);
      if (releaseRes.statusCode != 200) continue;

      final releaseBody = await utf8.decodeStream(releaseRes);
      final releaseJson = jsonDecode(releaseBody) as Map<String, Object?>;
      final assets = (releaseJson['assets'] as List<Object?>?) ?? const [];
      for (final asset in assets) {
        final map = asset as Map<String, Object?>;
        if (map['name'] == assetName) {
          selectedAsset = map;
          break;
        }
      }
      if (selectedAsset != null) {
        break;
      }
    }
    if (selectedAsset == null) return;

    final downloadUrl = selectedAsset['browser_download_url'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) return;

    destination.parent.createSync(recursive: true);
    stdout.write('Downloading $assetName... ');
    final assetRes = await _getWithRedirects(client, Uri.parse(downloadUrl));
    if (assetRes.statusCode != 200) {
      stdout.writeln('Failed (HTTP ${assetRes.statusCode}).');
      return;
    }

    final tempFile = File('${destination.path}.tmp');
    if (tempFile.existsSync()) tempFile.deleteSync();
    try {
      await tempFile.openWrite().addStream(assetRes);
      if (destination.existsSync()) destination.deleteSync();
      tempFile.renameSync(destination.path);
      stdout.writeln('Done.');
    } catch (_) {
      if (tempFile.existsSync()) tempFile.deleteSync();
      rethrow;
    }
  } finally {
    client.close(force: true);
  }
}

Future<HttpClientResponse> _getWithRedirects(
  HttpClient client,
  Uri uri, {
  int maxRedirects = 8,
}) async {
  Uri current = uri;
  for (var i = 0; i <= maxRedirects; i++) {
    final req = await client.getUrl(current);
    req.followRedirects = false;
    final res = await req.close();
    switch (res.statusCode) {
      case HttpStatus.movedPermanently:
      case HttpStatus.found:
      case HttpStatus.seeOther:
      case HttpStatus.temporaryRedirect:
      case HttpStatus.permanentRedirect:
        final location = res.headers.value(HttpHeaders.locationHeader);
        if (location == null || location.isEmpty) return res;
        current = current.resolve(location);
      default:
        return res;
    }
  }
  throw StateError('Too many redirects while downloading $uri');
}
