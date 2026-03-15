import 'dart:async';

import 'package:libtorrent_dart/src/libtorrent_dart.dart';
import 'package:path_provider/path_provider.dart';

const sintelMagnet =
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

const sintelInfohashHex = '08ada5a7a6183aae1e09d831df6748d566095a10';

// Platform-appropriate temp directory, initialized by initTestTempPath().
String _tempPath = '/tmp';
String get testTempPath => _tempPath;

/// Call in setUpAll() before any test that touches the filesystem.
Future<void> initTestTempPath() async {
  _tempPath = (await getTemporaryDirectory()).path;
}

Session createConfiguredSession() {
  final session = createSession();
  session.setIntSetting(LibtorrentSettingsTag.downloadRateLimit, 5000000);
  session.setIntSetting(LibtorrentSettingsTag.uploadRateLimit, 1000000);
  session.setIntSetting(LibtorrentSettingsTag.connectionsLimit, 200);
  return session;
}

TorrentHandle addSintel(Session session) {
  return session.addMagnet(magnetUri: sintelMagnet, savePath: _tempPath);
}

Future<void> waitForStatus(
  List<TorrentStatus> statuses, {
  Duration timeout = const Duration(seconds: 6),
  Duration tick = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (statuses.isEmpty && DateTime.now().isBefore(deadline)) {
    await Future.delayed(tick);
  }
}
