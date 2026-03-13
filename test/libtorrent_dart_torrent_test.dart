import 'package:libtorrent_dart/src/libtorrent_dart.dart';
import 'package:test/test.dart';

import 'support/test_helpers.dart';

void main() {
  test('torrent progress and status APIs are callable', () async {
    final session = createConfiguredSession();
    final torrent = addSintel(session);
    final statuses = <TorrentStatus>[];
    final sub = torrent.listenProgress(onData: statuses.add);

    await waitForStatus(statuses);
    final status = torrent.getStatus();
    expect(status.progress, greaterThanOrEqualTo(0));
    expect(status.progress, lessThanOrEqualTo(1));

    await sub.cancel();
    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test('torrent control APIs from spec are callable', () async {
    final session = createConfiguredSession();
    final torrent = addSintel(session);

    torrent.pause();
    torrent.resume();
    torrent.flushCache();
    torrent.forceReannounce();
    torrent.forceDhtAnnounce();
    torrent.scrapeTracker();
    torrent.clearError();
    torrent.queuePositionUp();
    torrent.queuePositionDown();
    torrent.queuePositionTop();
    torrent.queuePositionBottom();
    torrent.setQueuePosition(0);
    expect(torrent.queuePosition, greaterThanOrEqualTo(0));
    torrent.forceRecheck();

    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test('tag-driven APIs and error propagation still work', () {
    final session = createSession();
    final torrent = session.addTorrentFromTags([
      LibtorrentTagItem.stringValue(LibtorrentTag.torMagnetLink, sintelMagnet),
      LibtorrentTagItem.stringValue(LibtorrentTag.torSavePath, '/tmp'),
    ]);

    torrent.setSettingsFromTags([
      LibtorrentTagItem.intValue(LibtorrentTag.setDownloadRateLimit, 2000000),
      LibtorrentTagItem.intValue(LibtorrentTag.setUploadRateLimit, 1000000),
      LibtorrentTagItem.intValue(LibtorrentTag.setMaxConnections, 120),
    ]);

    expect(torrent.getIntSetting(LibtorrentTag.setMaxConnections), equals(120));
    torrent.cancel(deleteFiles: false);

    expect(
      () => session.addTorrentFromTags(const []),
      throwsA(isA<LibtorrentException>()),
    );
    session.close();
  });
}
