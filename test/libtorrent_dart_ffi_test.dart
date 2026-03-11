import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;
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

void _noopProgress(
  int tor,
  Pointer<ffi.TorrentStatusNative> status,
  Pointer<Void> userdata,
) {}

void main() {
  test('raw ffi symbols invoke native library and return expected shapes', () {
    final ses = ffi.session_create_default();
    expect(ses, isNot(nullptr));

    final magnet = _sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final savePath = '/tmp'.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor = ffi.session_add_magnet(ses, magnet, savePath, 0, 0);
    calloc.free(magnet);
    calloc.free(savePath);
    expect(tor, greaterThanOrEqualTo(0));

    final sst = calloc<ffi.SessionStatusNative>();
    expect(
      ffi.session_get_status(ses, sst, sizeOf<ffi.SessionStatusNative>()),
      equals(0),
    );

    final setSize = calloc<Int32>()..value = sizeOf<Int32>();
    final setVal = calloc<Int32>();
    expect(
      ffi.session_get_setting(ses, 0x200 + 5, setVal.cast<Void>(), setSize),
      equals(0),
    );

    expect(
      ffi.session_set_int_setting(ses, 0x300, 0x4000 + 97, 180),
      equals(0),
    );
    final pHost = '127.0.0.1'.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(
      ffi.session_set_string_setting(ses, 0x302, 0x0000 + 5, pHost),
      equals(0),
    );
    calloc.free(pHost);

    final alertBuf = calloc<Int8>(2048);
    final category = calloc<Int32>();
    ffi.session_pop_alert(ses, alertBuf.cast<Char>(), 2048, category);

    final cb = Pointer.fromFunction<ffi.ProgressCallbackC>(_noopProgress);
    expect(ffi.torrent_set_progress_callback(tor, cb, nullptr), equals(0));
    ffi.torrent_poll_progress(tor);
    ffi.torrent_clear_progress_callback(tor);

    expect(ffi.torrent_pause(tor), equals(0));
    expect(ffi.torrent_resume(tor), equals(0));

    final tst = calloc<ffi.TorrentStatusNative>();
    expect(
      ffi.torrent_get_status(tor, tst, sizeOf<ffi.TorrentStatusNative>()),
      equals(0),
    );

    final torSetSize = calloc<Int32>()..value = sizeOf<Int32>();
    final torSetVal = calloc<Int32>();
    expect(
      ffi.torrent_get_setting(
        tor,
        0x200 + 5,
        torSetVal.cast<Void>(),
        torSetSize,
      ),
      equals(0),
    );
    expect(ffi.torrent_set_int_setting(tor, 0x200 + 5, 90), equals(0));

    final tags = calloc<ffi.LtTagItemNative>(2);
    tags[0].tag = 0x200 + 1;
    tags[0].int_value = 1000000;
    tags[1].tag = 0x200;
    tags[1].int_value = 1000000;
    expect(ffi.torrent_set_settings_items(tor, tags, 2), equals(0));
    expect(ffi.session_set_settings_items(ses, tags, 2), equals(0));

    final addTags = calloc<ffi.LtTagItemNative>(2);
    final m2 = _sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final p2 = '/tmp'.toNativeUtf8(allocator: calloc).cast<Char>();
    addTags[0].tag = 0x100 + 5;
    addTags[0].string_value = m2;
    addTags[1].tag = 0x100 + 9;
    addTags[1].string_value = p2;
    final tor2 = ffi.session_add_torrent_items(ses, addTags, 2);
    expect(tor2, greaterThanOrEqualTo(0));

    expect(ffi.torrent_cancel(ses, tor2, 0), equals(0));
    ffi.session_remove_torrent(ses, tor, 0);

    final err = calloc<ffi.LtErrorNative>();
    expect(ffi.lt_last_error(err, sizeOf<ffi.LtErrorNative>()), equals(0));
    ffi.lt_clear_error();

    calloc.free(m2);
    calloc.free(p2);
    calloc.free(addTags);
    calloc.free(tags);
    calloc.free(torSetVal);
    calloc.free(torSetSize);
    calloc.free(tst);
    calloc.free(category);
    calloc.free(alertBuf);
    calloc.free(setVal);
    calloc.free(setSize);
    calloc.free(sst);
    calloc.free(err);
    ffi.session_close(ses);
  });
}
