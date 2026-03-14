import 'dart:async';
import 'dart:io';

import 'package:libtorrent_dart/src/libtorrent_dart.dart';

const _defaultMagnet =
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

String get _defaultSavePath {
  if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      return '$userProfile\\Downloads\\libtorrent_dart';
    }
    return r'C:\Downloads\libtorrent_dart';
  }
  return '/tmp/downloads/libtorrent_dart';
}

String get defaultMagnet => _defaultMagnet;
String get defaultSavePath => _defaultSavePath;

class DownloadSession {
  DownloadSession._({
    required Session session,
    required TorrentHandle torrent,
    required this.savePath,
  }) : _session = session,
       _torrent = torrent;

  final Session _session;
  final TorrentHandle _torrent;
  final String savePath;

  bool _paused = false;
  bool get paused => _paused;

  static DownloadSession start({
    required String magnetUri,
    required String savePath,
    int downloadRateLimit = 5 * 1024 * 1024,
    int uploadRateLimit = 1 * 1024 * 1024,
    int connectionsLimit = 200,
  }) {
    final session = createSession();
    session.setIntSetting(
      LibtorrentSettingsTag.connectionsLimit,
      connectionsLimit,
    );
    session.setIntSetting(
      LibtorrentSettingsTag.downloadRateLimit,
      downloadRateLimit,
    );
    session.setIntSetting(
      LibtorrentSettingsTag.uploadRateLimit,
      uploadRateLimit,
    );

    final torrent = session.addMagnet(magnetUri: magnetUri, savePath: savePath);
    // Disable auto-management and start manually for explicit pause/resume control.
    torrent.unsetFlags(LibtorrentTorrentFlags.autoManaged);
    torrent.resume();

    return DownloadSession._(
      session: session,
      torrent: torrent,
      savePath: savePath,
    );
  }

  StreamSubscription<TorrentStatus> listenProgress(
    void Function(TorrentStatus) onData,
  ) => _torrent.listenProgress(onData: onData);

  void pause() {
    _torrent.pause();
    _paused = true;
  }

  void resume() {
    _torrent.resume();
    _paused = false;
  }

  void cancel({bool deleteFiles = true}) {
    _torrent.cancel(deleteFiles: deleteFiles);
    _session.close();
  }

  void close() {
    _session.close();
  }
}
