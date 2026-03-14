import 'dart:io';
import 'dart:typed_data';

import 'package:libtorrent_dart/src/libtorrent_dart.dart';
import 'package:test/test.dart';

import 'support/test_helpers.dart';

void main() {
  test('session lifecycle and settings APIs are callable', () {
    final session = createConfiguredSession();
    final status = session.getStatus();
    expect(session.listenPort, greaterThanOrEqualTo(0));
    expect(session.sslListenPort, greaterThanOrEqualTo(0));
    expect(status.uploadRate, greaterThanOrEqualTo(0));
    expect(getLibtorrentVersion(), isNotEmpty);
    expect(status.payloadUploadRate, greaterThanOrEqualTo(0));
    expect(status.payloadDownloadRate, greaterThanOrEqualTo(0));
    expect(status.ipOverheadUploadRate, greaterThanOrEqualTo(0));
    expect(status.ipOverheadDownloadRate, greaterThanOrEqualTo(0));
    expect(status.dhtUploadRate, greaterThanOrEqualTo(0));
    expect(status.dhtDownloadRate, greaterThanOrEqualTo(0));
    expect(status.trackerUploadRate, greaterThanOrEqualTo(0));
    expect(status.trackerDownloadRate, greaterThanOrEqualTo(0));
    expect(status.totalPayloadDownload, greaterThanOrEqualTo(0));
    expect(status.totalPayloadUpload, greaterThanOrEqualTo(0));
    expect(status.totalIpOverheadDownload, greaterThanOrEqualTo(0));
    expect(status.totalIpOverheadUpload, greaterThanOrEqualTo(0));
    expect(status.totalDhtDownload, greaterThanOrEqualTo(0));
    expect(status.totalDhtUpload, greaterThanOrEqualTo(0));
    expect(status.totalTrackerDownload, greaterThanOrEqualTo(0));
    expect(status.totalTrackerUpload, greaterThanOrEqualTo(0));
    expect(status.totalRedundantBytes, greaterThanOrEqualTo(0));
    expect(status.totalFailedBytes, greaterThanOrEqualTo(0));
    expect(status.numUnchoked, greaterThanOrEqualTo(0));
    expect(status.allowedUploadSlots, greaterThanOrEqualTo(0));
    expect(status.upBandwidthQueue, greaterThanOrEqualTo(0));
    expect(status.downBandwidthQueue, greaterThanOrEqualTo(0));
    expect(status.upBandwidthBytesQueue, greaterThanOrEqualTo(0));
    expect(status.downBandwidthBytesQueue, greaterThanOrEqualTo(0));
    expect(status.optimisticUnchokeCounter, greaterThanOrEqualTo(0));
    expect(status.unchokeCounter, greaterThanOrEqualTo(0));
    expect(status.dhtNodes, greaterThanOrEqualTo(0));
    expect(status.dhtNodeCache, greaterThanOrEqualTo(0));
    expect(status.dhtTorrents, greaterThanOrEqualTo(0));
    expect(status.dhtGlobalNodes, greaterThanOrEqualTo(0));

    expect(session.getIntSetting(0x200 + 5), equals(200));
    session.setStringSetting(LibtorrentSettingsTag.proxyHostname, '127.0.0.1');
    session.setUploadRateLimit(1400000);
    expect(session.getUploadRateLimit(), equals(1400000));
    session.setDownloadRateLimit(2400000);
    expect(session.getDownloadRateLimit(), equals(2400000));
    session.setConnectionsLimit(180);
    expect(session.getConnectionsLimit(), equals(180));
    session.setUnchokeSlotsLimit(16);
    expect(session.getUnchokeSlotsLimit(), equals(16));
    session.setDhtUploadRateLimit(5000);
    expect(session.getDhtUploadRateLimit(), equals(5000));
    session.setDhtAnnounceInterval(180);
    expect(session.getDhtAnnounceInterval(), equals(180));
    session.setDhtMaxPeers(256);
    expect(session.getDhtMaxPeers(), equals(256));
    session.setDhtMaxDhtItems(512);
    expect(session.getDhtMaxDhtItems(), equals(512));
    session.setDhtEnabled(true);
    expect(session.isDhtEnabled(), isTrue);
    session.setLsdEnabled(false);
    expect(session.isLsdEnabled(), isFalse);
    session.setLsdEnabled(true);
    expect(session.isLsdEnabled(), isTrue);
    session.setUpnpEnabled(true);
    expect(session.isUpnpEnabled(), isA<bool>());
    session.setNatPmpEnabled(true);
    expect(session.isNatPmpEnabled(), isA<bool>());
    final parsedMagnet = parseMagnetUri(sintelMagnet);
    expect(parsedMagnet.infohashHex, equals(sintelInfohashHex));
    expect(parsedMagnet.trackers, isNotEmpty);

    session.pause();
    expect(session.isPaused, isTrue);
    session.resume();
    expect(session.isPaused, isFalse);

    session.postTorrentUpdates();
    session.postSessionStats();
    session.postDhtStats();
    expect(session.popAlert(), isA<AlertMessage?>());
    expect(
      session.waitForAlert(maxWait: const Duration(milliseconds: 10)),
      isA<AlertMessage?>(),
    );
    expect(session.popAlerts(maxCount: 2), isA<List<AlertMessage>>());
    expect(session.popAlertInfoLegacy(), isA<AlertInfo?>());
    final alertInfo = session.popAlertInfo();
    if (alertInfo != null) {
      expect(alertInfo.type, greaterThan(0));
      expect(alertInfo.what, isNotEmpty);
      expect(alertInfo.message, isNotEmpty);
      expect(alertInfo.dhtSamples, isA<List<DhtSampleInfohash>>());
    }
    session.setProxy(
      const ProxySetting(
        hostname: '127.0.0.1',
        port: 1080,
        type: LibtorrentProxyType.socks5,
      ),
    );

    session.close();
  });

  test('session can be created from tag API', () {
    final session = createSessionFromTags([
      LibtorrentTagItem.intValue(LibtorrentTag.sesAlertMask, 0xFFFFFFFF),
      LibtorrentTagItem.stringValue(
        LibtorrentTag.sesListenInterface,
        '0.0.0.0',
      ),
    ]);

    expect(session.getStatus().hasIncomingConnections, isA<bool>());
    session.close();
  });

  test('session settings item helpers expose shim SETTINGS_* tags', () {
    final session = createConfiguredSession();
    expect(LibtorrentTag.tagEnd, equals(0));
    expect(LibtorrentTag.settingsInt, equals(0x300));
    expect(LibtorrentTag.settingsBool, equals(0x301));
    expect(LibtorrentTag.settingsString, equals(0x302));
    expect(LibtorrentAlertCategory.all, equals(0xFFFFFFFF));
    expect(LibtorrentTorrentState.seeding, equals(5));
    expect(LibtorrentStorageMode.sparse, equals(1));

    session.setSettingsFromTags([
      LibtorrentTagItem.settingsInt(
        LibtorrentSettingsTag.downloadRateLimit,
        1234567,
      ),
    ]);
    session.applySettingsFromTags([
      LibtorrentTagItem.settingsInt(
        LibtorrentSettingsTag.uploadRateLimit,
        7654321,
      ),
    ]);

    final boolItem = LibtorrentTagItem.settingsBool(
      LibtorrentSettingsTag.connectionsLimit,
      true,
    );
    expect(boolItem.tag, equals(LibtorrentTag.settingsBool));
    expect(boolItem.intValue, equals(LibtorrentSettingsTag.connectionsLimit));
    expect(boolItem.size, equals(1));

    session.setSettingsFromTags([
      LibtorrentTagItem.settingsString(
        LibtorrentSettingsTag.proxyHostname,
        '127.0.0.1',
      ),
    ]);

    session.close();
  });

  test('session torrent discovery and dht bridge APIs are callable', () {
    final session = createConfiguredSession();
    final torrent = addSintel(session);

    final torrents = session.getTorrents();
    expect(torrents.map((t) => t.id), contains(torrent.id));
    final statuses = session.getTorrentStatuses();
    expect(statuses, isNotEmpty);
    expect(session.getTorrentStatusesWithFlags(0xFFFFFFFF), isNotEmpty);

    final found = session.findTorrent(sintelInfohashHex);
    expect(found.id, equals(torrent.id));

    session.addDhtNode(hostname: 'router.bittorrent.com', port: 6881);
    expect(session.isDhtRunning, isA<bool>());
    session.stopDht();
    session.startDht();
    session.dhtGetPeers(sintelInfohashHex);
    session.dhtAnnounce(sintelInfohashHex);
    session.dhtGetItem(sintelInfohashHex);
    session.dhtPutItem(
      Uint8List.fromList(const [100, 49, 58, 97, 105, 49, 101, 101]),
    );
    expect(
      session.dhtSampleInfohashes(
        address: '127.0.0.1',
        port: 6881,
        targetHex: sintelInfohashHex,
      ),
      isA<List<DhtSampleInfohash>>(),
    );
    final state = session.getState();
    expect(state, isA<Uint8List>());
    final restored = createSessionFromState(state);
    restored.close();

    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test('session async add and abort proxy APIs are callable', () {
    final session = createConfiguredSession();
    session.addTorrentFromTagsAsync([
      LibtorrentTagItem.stringValue(LibtorrentTag.torMagnetLink, sintelMagnet),
      LibtorrentTagItem.stringValue(LibtorrentTag.torSavePath, '/tmp'),
    ]);
    final proxy = session.abort();
    proxy.close();
  });

  test('session getBoolSetting and secondary proxy setters are callable', () {
    final session = createConfiguredSession();

    // getBoolSetting is the bool interpretation layer on top of getIntSetting.
    // SET_MAX_CONNECTIONS (0x200+5) is readable via session_get_setting.
    expect(session.getBoolSetting(LibtorrentTag.setMaxConnections), isA<bool>());

    // The four per-service proxy setters each call _setProxySetting with a
    // different first tag. setProxy() is already exercised in the lifecycle
    // test; confirm the remaining four do not throw.
    const proxy = ProxySetting(
      hostname: '127.0.0.1',
      port: 1080,
      type: LibtorrentProxyType.socks5,
    );
    expect(() => session.setPeerProxy(proxy), returnsNormally);
    expect(() => session.setWebSeedProxy(proxy), returnsNormally);
    expect(() => session.setTrackerProxy(proxy), returnsNormally);
    expect(() => session.setDhtProxy(proxy), returnsNormally);

    session.close();
  });

  test('session remove supports delete_partfile flag', () {
    final session = createConfiguredSession();
    final torrent = addSintel(session);
    session.removeTorrent(torrent, deleteFiles: false, deletePartfile: true);
    session.close();
  });

  test('torrent file create/load/add workflows are callable', () {
    final tempDir = Directory.systemTemp.createTempSync('libtorrent_dart_');
    try {
      final payload = File('${tempDir.path}/payload.bin');
      payload.writeAsBytesSync(List<int>.generate(4096, (i) => i % 251));
      final torrentData = createTorrentData(
        sourcePath: payload.path,
        trackerUrl: 'http://127.0.0.1/announce',
      );
      expect(torrentData, isNotEmpty);

      final torrentFile = File('${tempDir.path}/payload.torrent');
      createTorrentFile(
        sourcePath: payload.path,
        outputPath: torrentFile.path,
        trackerUrl: 'http://127.0.0.1/announce',
      );
      final loaded = loadTorrentFile(torrentFile.path);
      expect(loaded.infohashHex, hasLength(40));
      expect(loaded.name, isNotEmpty);
      expect(loaded.totalSize, greaterThan(0));
      expect(loaded.numFiles, greaterThan(0));

      final sessionFromFile = createConfiguredSession();
      final torFromFile = sessionFromFile.addTorrentFile(
        torrentPath: torrentFile.path,
        savePath: tempDir.path,
      );
      expect(torFromFile.id, greaterThanOrEqualTo(0));
      torFromFile.cancel(deleteFiles: false);
      sessionFromFile.close();

      final sessionFromData = createConfiguredSession();
      final torFromData = sessionFromData.addTorrentData(
        torrentData: torrentData,
        savePath: tempDir.path,
      );
      expect(torFromData.id, greaterThanOrEqualTo(0));
      torFromData.cancel(deleteFiles: false);
      sessionFromData.close();
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
