import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:libtorrent_dart/libtorrent_dart.dart';
import 'package:test/test.dart';

void registerStreamingContract() {
  test(
    'layout, full alert batch and owned piece buffers survive subsequent pops',
    () async {
      final dir = await Directory.systemTemp.createTemp('ltd-streaming-test-');
      final expected = Uint8List.fromList(
        List.generate(550123, (i) => (i * 31) % 251),
      );
      final file = File('${dir.path}/sample.bin');
      await file.writeAsBytes(expected);
      final session = createSessionFromTags([
        LibtorrentTagItem.settingsString(
          LibtorrentSettingsTag.listenInterfaces,
          '127.0.0.1:0',
        ),
        LibtorrentTagItem.intValue(LibtorrentTag.sesAlertMask, 1 | 8 | 64),
        LibtorrentTagItem.settingsBool(LibtorrentSettingsTag.enableDht, false),
        LibtorrentTagItem.settingsBool(LibtorrentSettingsTag.enableLsd, false),
        LibtorrentTagItem.settingsBool(LibtorrentSettingsTag.enableUpnp, false),
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.enableNatpmp,
          false,
        ),
      ]);
      try {
        final data = createTorrentData(
          sourcePath: file.path,
          pieceSize: 131072,
        );
        final torrent = session.addTorrentData(
          torrentData: data,
          savePath: dir.path,
        );
        torrent.unsetFlags(
          LibtorrentTorrentFlags.autoManaged | LibtorrentTorrentFlags.paused,
        );
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (!torrent.havePiece(0) && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(torrent.pieceLength, 131072);
        expect(torrent.numPieces, 5);
        expect(torrent.pieceSize(4), expected.length - 4 * 131072);
        expect(() => torrent.pieceSize(5), throwsA(isA<LibtorrentException>()));
        for (var i = 0; i < torrent.numPieces; i++) {
          torrent.readPiece(i);
        }
        // Let all completions enter one batch: returning only its front loses reads.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final results = <int, Uint8List>{};
        while (results.length < 5 && DateTime.now().isBefore(deadline)) {
          final alert = session.popAlertInfo(includePieceData: true);
          if (alert == null) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          } else if (alert.pieceIndex != null) {
            expect(alert.torrentId, torrent.id);
            expect(alert.pieceError, 0);
            results[alert.pieceIndex!] = alert.pieceData!;
          }
        }
        expect(results.keys.toSet(), {0, 1, 2, 3, 4});
        // These copies remain valid after another native pop invalidates its batch.
        session.popAlertInfo(includePieceData: true);
        for (final entry in results.entries) {
          final start = entry.key * 131072;
          expect(
            entry.value,
            expected.sublist(start, start + torrent.pieceSize(entry.key)),
          );
        }
      } finally {
        session.close();
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
