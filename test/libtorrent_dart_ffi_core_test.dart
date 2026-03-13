import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;
import 'package:test/test.dart';

import 'support/test_helpers.dart';

void _noopProgress(
  int tor,
  Pointer<ffi.TorrentStatusNative> status,
  Pointer<Void> userdata,
) {}

void main() {
  test('raw ffi core APIs and new session controls are callable', () {
    final ses = ffi.session_create_default();
    expect(ses, isNot(nullptr));

    final magnet = sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final savePath = '/tmp'.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor = ffi.session_add_magnet(ses, magnet, savePath, 0, 0);
    calloc.free(magnet);
    calloc.free(savePath);
    expect(tor, greaterThanOrEqualTo(0));

    expect(ffi.session_pause(ses), equals(0));
    expect(ffi.session_is_paused(ses), equals(1));
    expect(ffi.session_resume(ses), equals(0));
    expect(ffi.session_is_paused(ses), equals(0));
    expect(ffi.session_post_torrent_updates(ses), equals(0));
    expect(ffi.session_post_session_stats(ses), equals(0));
    expect(ffi.session_post_dht_stats(ses), equals(0));

    final sst = calloc<ffi.SessionStatusNative>();
    expect(
      ffi.session_get_status(ses, sst, sizeOf<ffi.SessionStatusNative>()),
      equals(0),
    );

    final cb = Pointer.fromFunction<ffi.ProgressCallbackC>(_noopProgress);
    expect(ffi.torrent_set_progress_callback(tor, cb, nullptr), equals(0));
    ffi.torrent_poll_progress(tor);
    ffi.torrent_clear_progress_callback(tor);

    ffi.session_remove_torrent(ses, tor, 0);
    calloc.free(sst);
    ffi.session_close(ses);
  });
}
