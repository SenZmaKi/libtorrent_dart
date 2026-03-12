import 'ui.dart';
import 'torrent_session.dart';

Future<void> main() async {
  final magnetUri = promptMagnet();
  final savePath = promptSavePath();

  final dl = DownloadSession.start(
    magnetUri: magnetUri,
    savePath: savePath,
  );

  await runDownloadUI(dl);
}
