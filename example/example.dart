import 'package:libtorrent_dart/src/libtorrent_dart.dart';

Future<void> main() async {
  final session = createSession();

  final torrent = session.addMagnet(
    magnetUri:
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
        '&xs=https%3A%2F%2Fwebtorrent.io%2Ftorrents%2Fsintel.torrent',
    savePath: '/tmp/downloads',
    downloadRateLimit: 5000000,
    uploadRateLimit: 1000000,
  );

  session.setIntSetting(LibtorrentSettingsTag.connectionsLimit, 200);

  final sub = torrent.listenProgress(
    onData: (status) {
      print(
        'progress=${(status.progress * 100).toStringAsFixed(1)}% '
        'down=${status.downloadRate} up=${status.uploadRate}',
      );
      if (status.error.isNotEmpty) {
        print('error: ${status.error}');
      }
    },
  );

  // torrent.pause();
  // torrent.resume();
  // torrent.cancel(deleteFiles: true);

  // sub.cancel();
  // session.close();

  await sub.asFuture();
}
