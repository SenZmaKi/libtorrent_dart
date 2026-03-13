import 'package:libtorrent_dart/src/libtorrent_dart.dart';
import 'package:test/test.dart';

import 'support/test_helpers.dart';

void main() {
  test('session lifecycle and settings APIs are callable', () {
    final session = createConfiguredSession();
    final status = session.getStatus();
    expect(status.uploadRate, greaterThanOrEqualTo(0));

    expect(session.getIntSetting(0x200 + 5), equals(200));

    session.pause();
    expect(session.isPaused, isTrue);
    session.resume();
    expect(session.isPaused, isFalse);

    session.postTorrentUpdates();
    session.postSessionStats();
    session.postDhtStats();

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
}
