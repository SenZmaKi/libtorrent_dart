import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;
import 'package:test/test.dart';

import 'support/test_helpers.dart';

void main() {
  test('raw ffi torrent control APIs from spec are callable', () {
    final ses = ffi.session_create_default();
    expect(ses, isNot(nullptr));

    final magnet = sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final savePath = '/tmp'.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor = ffi.session_add_magnet(ses, magnet, savePath, 0, 0);
    calloc.free(magnet);
    calloc.free(savePath);
    expect(tor, greaterThanOrEqualTo(0));

    expect(ffi.torrent_flush_cache(tor), equals(0));
    expect(ffi.torrent_force_reannounce(tor, 0, -1), equals(0));
    expect(ffi.torrent_force_dht_announce(tor), equals(0));
    expect(ffi.torrent_scrape_tracker(tor, -1), equals(0));
    expect(ffi.torrent_clear_error(tor), equals(0));
    expect(ffi.torrent_queue_position_up(tor), equals(0));
    expect(ffi.torrent_queue_position_down(tor), equals(0));
    expect(ffi.torrent_queue_position_top(tor), equals(0));
    expect(ffi.torrent_queue_position_bottom(tor), equals(0));
    expect(ffi.torrent_queue_position_set(tor, 0), equals(0));

    final queuePosition = calloc<Int32>();
    expect(ffi.torrent_queue_position_get(tor, queuePosition), equals(0));
    expect(queuePosition.value, greaterThanOrEqualTo(0));
    expect(ffi.torrent_force_recheck(tor), equals(0));

    calloc.free(queuePosition);
    ffi.torrent_cancel(ses, tor, 0);
    ffi.session_close(ses);
  });
}
