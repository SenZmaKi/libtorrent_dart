import 'dart:io';

import 'package:test/test.dart';

import 'package:libtorrent_dart/src/native_download.dart';

void registerDownloadContract() {
  test('release URLs prefer v tags without duplicating the prefix', () {
    expect(
      releaseAssetUrls('owner/repo', '1.2.3', 'native.dylib').map((u) => '$u'),
      [
        'https://github.com/owner/repo/releases/download/v1.2.3/native.dylib',
        'https://github.com/owner/repo/releases/download/1.2.3/native.dylib',
      ],
    );
    expect(
      releaseAssetUrls('owner/repo', 'v1.2.3', 'native.dylib'),
      hasLength(1),
    );
  });

  group('native asset HTTP downloads', () {
    late HttpServer server;
    late Directory directory;
    late File destination;
    late List<String> logs;
    late List<String> requests;
    late void Function(HttpRequest) respond;
    Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      directory = await Directory.systemTemp.createTemp('ltd-download-');
      destination = File('${directory.path}/native.bin');
      logs = [];
      requests = [];
      server.listen((request) {
        requests.add(request.uri.path);
        respond(request);
      });
    });
    tearDown(() async {
      await server.close(force: true);
      await directory.delete(recursive: true);
    });

    for (final status in [301, 302, 303, 307, 308]) {
      test('follows HTTP $status relative redirects and saves bytes', () async {
        respond = (request) {
          if (request.uri.path == '/start') {
            request.response.statusCode = status;
            request.response.headers.set(
              HttpHeaders.locationHeader,
              '/asset?signature=temporary-secret',
            );
          } else {
            request.response.add([1, 2, 3, 4]);
          }
          request.response.close();
        };
        await downloadBinary(destination, [url('/start')], log: logs.add);
        expect(await destination.readAsBytes(), [1, 2, 3, 4]);
        expect(requests, ['/start', '/asset']);
        expect(logs.join('\n'), contains('HTTP $status redirect:'));
        expect(logs.join('\n'), isNot(contains('temporary-secret')));
        expect(File('${destination.path}.tmp').existsSync(), isFalse);
      });
    }

    test('logs 404 and tries the alternate tag URL', () async {
      respond = (request) {
        if (request.uri.path == '/missing') {
          request.response.statusCode = 404;
        } else {
          request.response.add([7, 8]);
        }
        request.response.close();
      };
      await downloadBinary(destination, [
        url('/missing'),
        url('/asset'),
      ], log: logs.add);
      expect(await destination.readAsBytes(), [7, 8]);
      expect(logs.join('\n'), contains('HTTP 404'));
    });

    for (final status in [300, 304, 403, 429, 500]) {
      test(
        'reports HTTP $status without silently trying another tag',
        () async {
          destination.writeAsBytesSync([9]);
          respond = (request) {
            request.response.statusCode = status;
            request.response.close();
          };
          await expectLater(
            downloadBinary(destination, [
              url('/failure'),
              url('/alternate'),
            ], log: logs.add),
            throwsA(isA<HttpException>()),
          );
          expect(requests, ['/failure']);
          expect(logs.join('\n'), contains('HTTP $status'));
          expect(logs.join('\n'), contains('Error downloading native asset:'));
          expect(destination.readAsBytesSync(), [9]);
        },
      );
    }

    test('reports a redirect missing Location', () async {
      respond = (request) {
        request.response.statusCode = 302;
        request.response.close();
      };
      await expectLater(
        downloadBinary(destination, [url('/broken')], log: logs.add),
        throwsA(isA<HttpException>()),
      );
      expect(logs.join('\n'), contains('redirect missing Location'));
      expect(destination.existsSync(), isFalse);
    });

    test('bounds redirect loops and logs the error', () async {
      respond = (request) {
        request.response.statusCode = 302;
        request.response.headers.set(HttpHeaders.locationHeader, '/loop');
        request.response.close();
      };
      await expectLater(
        downloadBinary(
          destination,
          [url('/loop')],
          log: logs.add,
          maxRedirects: 2,
        ),
        throwsA(isA<HttpException>()),
      );
      expect(requests, hasLength(3));
      expect(logs.join('\n'), contains('Too many redirects'));
    });

    test('reports all missing assets', () async {
      respond = (request) {
        request.response.statusCode = 404;
        request.response.close();
      };
      await expectLater(
        downloadBinary(destination, [
          url('/first'),
          url('/second'),
        ], log: logs.add),
        throwsA(isA<HttpException>()),
      );
      expect(requests, ['/first', '/second']);
      expect(logs.join('\n'), contains('not found at any release URL'));
    });

    test(
      'rejects empty successful downloads and removes temporary files',
      () async {
        respond = (request) => request.response.close();
        await expectLater(
          downloadBinary(destination, [url('/empty')], log: logs.add),
          throwsA(isA<HttpException>()),
        );
        expect(logs.join('\n'), contains('download was empty'));
        expect(destination.existsSync(), isFalse);
        expect(File('${destination.path}.tmp').existsSync(), isFalse);
      },
    );
  });
}
