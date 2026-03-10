import 'dart:async';

import 'package:libtorrent_dart/libtorrent_dart.dart';
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
    await _waitForNewStatus(statuses);
    final pausedObserved = statuses.any((status) => status.paused);

    torrent.resume();
    await _waitForNewStatus(statuses);
    await sub.cancel();
    torrent.cancel(deleteFiles: false);
    session.close();

    expect(statuses, isNotEmpty);
    expect(pausedObserved, isTrue);
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

Future<void> _waitForNewStatus(
  List<TorrentStatus> statuses, {
  Duration timeout = const Duration(seconds: 6),
  Duration tick = const Duration(milliseconds: 200),
}) async {
  final startCount = statuses.length;
  final deadline = DateTime.now().add(timeout);
  while (statuses.length == startCount && DateTime.now().isBefore(deadline)) {
    await Future.delayed(tick);
  }
}
