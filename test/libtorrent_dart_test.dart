import 'dart:async';

import 'package:libtorrent_dart/src/libtorrent_dart.dart';
import 'package:test/test.dart';

const _sintelMagnet =
    'magnet:?xt=urn:btih:08ada5a7a6183aae1e09d831df6748d566095a10'
    '&dn=Sintel'
    '&tr=udp%3A%2F%2Fexplodie.org%3A6969'
    '&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969'
    '&tr=udp%3A%2F%2Ftracker.empire-js.us%3A1337'
    '&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969'
    '&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337'
    '&tr=wss%3A%2F%2Ftracker.btorrent.xyz'
    '&tr=wss%3A%2F%2Ftracker.fastcast.nz'
    '&tr=wss%3A%2F%2Ftracker.openwebtorrent.com'
    '&ws=https%3A%2F%2Fwebtorrent.io%2Ftorrents%2F'
    '&xs=https%3A%2F%2Fwebtorrent.io%2Ftorrents%2Fsintel.torrent';

void main() {
  test('can create session and poll progress', () async {
    final session = _createSession();
    final torrent = _addSintel(session);

    final statuses = <TorrentStatus>[];
    final sub = torrent.listenProgress(
      onData: (status) {
        statuses.add(status);
        expect(status.progress, greaterThanOrEqualTo(0));
        expect(status.progress, lessThanOrEqualTo(1));
      },
      interval: const Duration(seconds: 1),
    );

    await _waitForStatus(statuses);
    await sub.cancel();
    torrent.cancel(deleteFiles: false);
    session.close();

    expect(statuses, isNotEmpty);
  });

  test('pause and resume updates status', () async {
    final session = _createSession();
    final torrent = _addSintel(session);

    final statuses = <TorrentStatus>[];
    final sub = torrent.listenProgress(
      onData: statuses.add,
      interval: const Duration(seconds: 1),
    );

    await _waitForStatus(statuses);
    torrent.pause();
    final pausedObserved = await _waitForStatusMatch(
      statuses,
      predicate: (status) => status.paused,
    );

    torrent.resume();
    final resumedObserved = await _waitForStatusMatch(
      statuses,
      predicate: (status) => !status.paused,
    );
    await sub.cancel();
    torrent.cancel(deleteFiles: false);
    session.close();

    expect(statuses, isNotEmpty);
    expect(pausedObserved, isTrue);
    expect(resumedObserved, isTrue);
  });

  test('cancel stops torrent without errors', () async {
    final session = _createSession();
    final torrent = _addSintel(session);

    final statuses = <TorrentStatus>[];
    final sub = torrent.listenProgress(
      onData: statuses.add,
      interval: const Duration(seconds: 1),
    );

    await _waitForStatus(statuses);
    torrent.cancel(deleteFiles: false);
    await Future.delayed(const Duration(seconds: 1));
    await sub.cancel();
    session.close();

    expect(statuses, isNotEmpty);
  });

  test('session and torrent settings/status APIs are callable', () async {
    final session = _createSession();
    final torrent = _addSintel(session);

    final sessionStatus = session.getStatus();
    expect(sessionStatus.uploadRate, greaterThanOrEqualTo(0));

    final connectionsLimit = session.getIntSetting(0x200 + 5);
    expect(connectionsLimit, equals(200));

    final torrentConnections = torrent.getIntSetting(0x200 + 5);
    expect(torrentConnections, greaterThanOrEqualTo(-1));

    final torrentStatus = torrent.getStatus();
    expect(torrentStatus.progress, greaterThanOrEqualTo(0));
    expect(torrentStatus.progress, lessThanOrEqualTo(1));

    final alert = session.popAlert();
    if (alert != null) {
      expect(alert.message, isA<String>());
    }

    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test('array tag APIs cover variadic-compatible paths', () async {
    final session = createSession();
    session.setSettingsFromTags([
      LibtorrentTagItem.intValue(LibtorrentTag.setMaxConnections, 150),
      LibtorrentTagItem.intValue(LibtorrentTag.setAlertMask, 0xFFFFFFFF),
    ]);

    final torrent = session.addTorrentFromTags([
      LibtorrentTagItem.stringValue(LibtorrentTag.torMagnetLink, _sintelMagnet),
      LibtorrentTagItem.stringValue(LibtorrentTag.torSavePath, '/tmp'),
    ]);

    torrent.setSettingsFromTags([
      LibtorrentTagItem.intValue(LibtorrentTag.setDownloadRateLimit, 2000000),
      LibtorrentTagItem.intValue(LibtorrentTag.setUploadRateLimit, 1000000),
      LibtorrentTagItem.intValue(LibtorrentTag.setMaxConnections, 120),
    ]);

    expect(session.getIntSetting(LibtorrentTag.setMaxConnections), equals(150));
    expect(torrent.getIntSetting(LibtorrentTag.setMaxConnections), equals(120));

    torrent.cancel(deleteFiles: false);
    session.close();
  });

  test(
    'proxy settings are configurable through public session setting API',
    () {
      final session = createSession();
      session.setIntSetting(LibtorrentSettingsTag.proxyType, 5);
      session.setIntSetting(LibtorrentSettingsTag.proxyPort, 8080);
      session.setStringSetting(
        LibtorrentSettingsTag.proxyHostname,
        '127.0.0.1',
      );
      session.setStringSetting(LibtorrentSettingsTag.proxyUsername, 'user');
      session.setStringSetting(LibtorrentSettingsTag.proxyPassword, 'pass');
      session.close();
    },
  );

  test('error propagation surfaces native validation failures', () {
    final session = createSession();
    expect(
      () => session.addTorrentFromTags(const []),
      throwsA(isA<LibtorrentException>()),
    );
    session.close();
  });

  test('session can be created from tag-based API', () {
    final session = createSessionFromTags([
      LibtorrentTagItem.intValue(LibtorrentTag.sesAlertMask, 0xFFFFFFFF),
      LibtorrentTagItem.stringValue(
        LibtorrentTag.sesListenInterface,
        '0.0.0.0',
      ),
    ]);
    final status = session.getStatus();
    expect(status.hasIncomingConnections, isA<bool>());
    session.close();
  });

  test('removeTorrent bridge path is callable', () {
    final session = _createSession();
    final torrent = _addSintel(session);
    session.removeTorrent(torrent, deleteFiles: false);
    session.close();
  });
}

Session _createSession() {
  final session = createSession();
  session.setIntSetting(LibtorrentSettingsTag.downloadRateLimit, 5000000);
  session.setIntSetting(LibtorrentSettingsTag.uploadRateLimit, 1000000);
  session.setIntSetting(LibtorrentSettingsTag.connectionsLimit, 200);
  return session;
}

TorrentHandle _addSintel(Session session) {
  return session.addMagnet(magnetUri: _sintelMagnet, savePath: '/tmp');
}

Future<void> _waitForStatus(
  List<TorrentStatus> statuses, {
  Duration timeout = const Duration(seconds: 6),
  Duration tick = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (statuses.isEmpty && DateTime.now().isBefore(deadline)) {
    await Future.delayed(tick);
  }
}

Future<bool> _waitForStatusMatch(
  List<TorrentStatus> statuses, {
  required bool Function(TorrentStatus) predicate,
  Duration timeout = const Duration(seconds: 10),
  Duration tick = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (statuses.any(predicate)) return true;
    await Future.delayed(tick);
  }
  return statuses.any(predicate);
}
