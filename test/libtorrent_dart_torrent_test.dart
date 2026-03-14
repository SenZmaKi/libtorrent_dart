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
    expect(status.downloadPayloadRate, greaterThanOrEqualTo(0));
    expect(status.uploadPayloadRate, greaterThanOrEqualTo(0));
    expect(status.totalDownload, greaterThanOrEqualTo(0));
    expect(status.totalUpload, greaterThanOrEqualTo(0));
    expect(status.totalPayloadDownload, greaterThanOrEqualTo(0));
    expect(status.totalPayloadUpload, greaterThanOrEqualTo(0));
    expect(status.totalFailedBytes, greaterThanOrEqualTo(0));
    expect(status.totalRedundantBytes, greaterThanOrEqualTo(0));
    expect(status.nextAnnounce, greaterThanOrEqualTo(-1));
    expect(status.announceInterval, greaterThanOrEqualTo(-1));
    expect(status.currentTracker, isA<String>());
    expect(status.numSeeds, greaterThanOrEqualTo(-1));
    expect(status.numPeers, greaterThanOrEqualTo(-1));
    expect(status.numComplete, greaterThanOrEqualTo(-1));
    expect(status.numIncomplete, greaterThanOrEqualTo(-1));
    expect(status.listSeeds, greaterThanOrEqualTo(-1));
    expect(status.listPeers, greaterThanOrEqualTo(-1));
    expect(status.connectCandidates, greaterThanOrEqualTo(-1));
    expect(status.numPieces, greaterThanOrEqualTo(0));
    expect(status.totalWantedDone, greaterThanOrEqualTo(0));
    expect(status.distributedCopies, greaterThanOrEqualTo(0));
    expect(status.blockSize, greaterThanOrEqualTo(0));
    expect(status.numUploads, greaterThanOrEqualTo(0));
    expect(status.numConnections, greaterThanOrEqualTo(0));
    expect(status.uploadsLimit, greaterThanOrEqualTo(-1));
    expect(status.connectionsLimit, greaterThanOrEqualTo(-1));
    expect(status.upBandwidthQueue, greaterThanOrEqualTo(-1));
    expect(status.downBandwidthQueue, greaterThanOrEqualTo(-1));
    expect(status.allTimeUpload, greaterThanOrEqualTo(0));
    expect(status.allTimeDownload, greaterThanOrEqualTo(0));
    expect(status.activeTime, greaterThanOrEqualTo(0));
    expect(status.seedingTime, greaterThanOrEqualTo(0));
    expect(status.seedRank, greaterThanOrEqualTo(-1));
    expect(status.lastScrape, greaterThanOrEqualTo(-1));
    expect(status.hasIncoming, isA<bool>());
    expect(status.seedMode, isA<bool>());

    await sub.cancel();
    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test('torrent control APIs from spec are callable', () async {
    final session = createConfiguredSession();
    final torrent = addSintel(session);

    torrent.pause();
    torrent.resume();
    torrent.postDownloadQueue();
    expect(torrent.getDownloadQueue(), isA<List<PartialPieceInfo>>());
    torrent.postPeerInfo();
    expect(torrent.getPeerInfo(), isA<List<PeerInfo>>());
    torrent.postTrackers();
    expect(() => torrent.makeMagnetUri(), returnsNormally);
    torrent.flushCache();
    torrent.forceReannounce();
    torrent.forceReannounceWithFlags(flags: 0);
    torrent.forceDhtAnnounce();
    torrent.forceLsdAnnounce();
    torrent.scrapeTracker();
    torrent.addTracker('udp://tracker.opentrackr.org:1337/announce');
    torrent.replaceTrackers(['udp://tracker.opentrackr.org:1337/announce']);
    expect(torrent.getTrackers(), isA<List<String>>());
    torrent.addUrlSeed('https://webtorrent.io/torrents/');
    expect(torrent.getUrlSeeds(), isA<List<String>>());
    torrent.removeUrlSeed('https://webtorrent.io/torrents/');
    torrent.addHttpSeed('https://webtorrent.io/torrents/');
    expect(torrent.getHttpSeeds(), isA<List<String>>());
    torrent.removeHttpSeed('https://webtorrent.io/torrents/');
    expect(torrent.getFileProgress(), isA<List<int>>());
    expect(torrent.getFileStatus(), isA<List<OpenFileState>>());
    try {
      torrent.getFiles();
    } on LibtorrentException {
      // metadata may not be available yet for magnet-added torrents.
    }
    expect(
      () => torrent.connectPeer(address: '127.0.0.1', port: 6881),
      returnsNormally,
    );
    torrent.setFlags(LibtorrentTorrentFlags.paused);
    expect(torrent.flags & LibtorrentTorrentFlags.paused, isNot(0));
    torrent.unsetFlags(LibtorrentTorrentFlags.paused);
    torrent.setFlagsWithMask(
      LibtorrentTorrentFlags.updateSubscribe,
      LibtorrentTorrentFlags.updateSubscribe,
    );
    torrent.clearPieceDeadlines();
    torrent.clearError();
    torrent.clearPeers();
    torrent.queuePositionUp();
    torrent.queuePositionDown();
    torrent.queuePositionTop();
    torrent.queuePositionBottom();
    torrent.setQueuePosition(0);
    expect(torrent.queuePosition, greaterThanOrEqualTo(0));
    torrent.setSequentialDownload(true);
    expect(torrent.getBoolSetting(LibtorrentTag.setSequentialDownload), isTrue);
    torrent.setSuperSeeding(false);
    expect(torrent.getBoolSetting(LibtorrentTag.setSuperSeeding), isFalse);
    torrent.setUploadLimit(1500000);
    expect(torrent.getUploadLimit(), equals(1500000));
    torrent.setDownloadLimit(2500000);
    expect(torrent.getDownloadLimit(), equals(2500000));
    torrent.setMaxUploads(24);
    expect(torrent.getMaxUploads(), equals(24));
    torrent.setMaxConnections(96);
    expect(torrent.getMaxConnections(), equals(96));
    torrent.forceRecheck();
    expect(() => torrent.saveResumeData(), returnsNormally);
    expect(torrent.needSaveResumeData(), isA<bool>());

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
