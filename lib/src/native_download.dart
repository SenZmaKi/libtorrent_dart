import 'dart:io';

/// Canonical public asset URL first; retain support for unprefixed release tags.
List<Uri> releaseAssetUrls(String repository, String tag, String assetName) {
  final tags = tag.startsWith('v') ? [tag] : ['v$tag', tag];
  return [
    for (final candidate in tags)
      Uri(
        scheme: 'https',
        host: 'github.com',
        pathSegments: [
          ...repository.split('/'),
          'releases',
          'download',
          candidate,
          assetName,
        ],
      ),
  ];
}

/// Downloads to a temporary file so failed transfers never become native assets.
Future<void> downloadBinary(
  File destination,
  List<Uri> urls, {
  void Function(String)? log,
  int maxRedirects = 8,
}) async {
  final writeLog = log ?? (String message) => stdout.writeln(message);
  final client = HttpClient()
    ..userAgent = 'libtorrent_dart_hook'
    ..connectionTimeout = const Duration(seconds: 30);
  final temporary = File('${destination.path}.tmp');
  try {
    for (final url in urls) {
      writeLog('Downloading native asset from $url');
      final response = await _getWithRedirects(
        client,
        url,
        writeLog,
        maxRedirects,
      );
      if (response.statusCode != HttpStatus.ok) {
        final status = 'HTTP ${response.statusCode} ${response.reasonPhrase}';
        writeLog('$status while downloading $url');
        await response.drain<void>();
        // Only a missing asset/tag warrants trying the alternate tag spelling.
        if (response.statusCode == HttpStatus.notFound) continue;
        throw HttpException('Native asset download failed: $status', uri: url);
      }

      destination.parent.createSync(recursive: true);
      final sink = temporary.openWrite();
      try {
        await sink.addStream(response);
      } finally {
        await sink.close();
      }
      if (temporary.lengthSync() == 0) {
        throw HttpException('Native asset download was empty', uri: url);
      }
      if (destination.existsSync()) destination.deleteSync();
      temporary.renameSync(destination.path);
      writeLog('Native asset saved to ${destination.path}');
      return;
    }
    throw HttpException('Native asset not found at any release URL: $urls');
  } catch (error) {
    writeLog('Error downloading native asset: $error');
    rethrow;
  } finally {
    client.close(force: true);
    if (temporary.existsSync()) {
      try {
        temporary.deleteSync();
      } on FileSystemException catch (error) {
        writeLog('Error removing temporary native asset: $error');
      }
    }
  }
}

Future<HttpClientResponse> _getWithRedirects(
  HttpClient client,
  Uri uri,
  void Function(String) log,
  int maxRedirects,
) async {
  var current = uri;
  for (var redirects = 0; ; redirects++) {
    final request = await client.getUrl(current);
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 30));
    switch (response.statusCode) {
      case HttpStatus.movedPermanently:
      case HttpStatus.found:
      case HttpStatus.seeOther:
      case HttpStatus.temporaryRedirect:
      case HttpStatus.permanentRedirect:
        final status = response.statusCode;
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null || location.isEmpty) {
          throw HttpException(
            'HTTP $status redirect missing Location',
            uri: current,
          );
        }
        if (redirects >= maxRedirects) {
          throw HttpException(
            'Too many redirects (limit $maxRedirects)',
            uri: uri,
          );
        }
        final next = current.resolve(location);
        if ((next.scheme != 'https' && next.scheme != 'http') ||
            (current.scheme == 'https' && next.scheme != 'https')) {
          throw HttpException(
            'Unsupported redirect target: $next',
            uri: current,
          );
        }
        // GitHub's asset redirects contain long, temporary signed query strings.
        log(
          'HTTP $status redirect: '
          '${current.replace(query: '', fragment: '')} -> '
          '${next.replace(query: '', fragment: '')}',
        );
        current = next;
      default:
        return response;
    }
  }
}
