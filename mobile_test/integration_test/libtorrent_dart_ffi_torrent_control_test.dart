import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;

import 'support/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestTempPath();
  });

  test('raw ffi torrent control APIs from spec are callable', () {
    final ses = ffi.session_create_default();
    expect(ses, isNot(nullptr));

    final magnet = sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final savePath = testTempPath.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor = ffi.session_add_magnet(ses, magnet, savePath, 0, 0);
    calloc.free(magnet);
    calloc.free(savePath);
    expect(tor, greaterThanOrEqualTo(0));

    expect(ffi.torrent_flush_cache(tor), equals(0));
    expect(ffi.torrent_pause(tor), equals(0));
    expect(ffi.torrent_resume(tor), equals(0));
    expect(ffi.torrent_post_download_queue(tor), equals(0));
    expect(ffi.torrent_post_peer_info(tor), equals(0));
    expect(ffi.torrent_post_trackers(tor), equals(0));
    final status = calloc<ffi.TorrentStatusNative>();
    expect(
      ffi.torrent_get_status(tor, status, sizeOf<ffi.TorrentStatusNative>()),
      equals(0),
    );
    calloc.free(status);
    final totalPieces = calloc<Int32>();
    expect(
      ffi.torrent_get_download_queue(
        tor,
        nullptr.cast<ffi.LtPartialPieceInfoNative>(),
        0,
        totalPieces,
      ),
      equals(0),
    );
    final totalPeers = calloc<Int32>();
    expect(
      ffi.torrent_get_peer_info(
        tor,
        nullptr.cast<ffi.LtPeerInfoNative>(),
        0,
        totalPeers,
      ),
      equals(0),
    );
    final totalFiles = calloc<Int32>();
    expect(
      ffi.torrent_get_file_progress(tor, nullptr, 0, totalFiles, 0),
      equals(0),
    );
    expect(
      ffi.torrent_get_file_status(
        tor,
        nullptr.cast<ffi.LtOpenFileStateNative>(),
        0,
        totalFiles,
      ),
      equals(0),
    );
    expect(
      ffi.torrent_get_files(
        tor,
        nullptr.cast<ffi.LtFileEntryNative>(),
        0,
        totalFiles,
      ),
      anyOf(equals(0), equals(-1)),
    );
    final flagValue = calloc<Uint64>();
    expect(ffi.torrent_set_flags(tor, 1 << 4), equals(0));
    expect(ffi.torrent_get_flags(tor, flagValue), equals(0));
    expect(flagValue.value & (1 << 4), isNot(0));
    expect(ffi.torrent_unset_flags(tor, 1 << 4), equals(0));
    expect(ffi.torrent_set_flags_mask(tor, 1 << 7, 1 << 7), equals(0));
    calloc.free(flagValue);
    calloc.free(totalFiles);
    calloc.free(totalPeers);
    calloc.free(totalPieces);
    expect(ffi.torrent_force_reannounce(tor, 0, -1), equals(0));
    expect(ffi.torrent_force_reannounce_flags(tor, 0, -1, 0), equals(0));
    expect(ffi.torrent_force_dht_announce(tor), equals(0));
    expect(ffi.torrent_force_lsd_announce(tor), equals(0));
    expect(ffi.torrent_read_piece(tor, -1), equals(-1));
    final pieceData = calloc<Int8>(1)..value = 0;
    expect(
      ffi.torrent_add_piece(tor, -1, pieceData.cast<Char>(), 1, 0),
      equals(-1),
    );
    expect(ffi.torrent_have_piece(tor, -1), equals(-1));
    final badPeer =
        'invalid-address'.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(ffi.torrent_connect_peer(tor, badPeer, 6881), equals(-1));
    calloc.free(badPeer);
    calloc.free(pieceData);
    expect(ffi.torrent_save_resume_data(tor, 0), anyOf(equals(0), equals(-1)));
    final resumeRequired = calloc<Int32>();
    expect(
      ffi.torrent_get_resume_data(
        tor,
        nullptr.cast<Char>(),
        0,
        resumeRequired,
        0,
      ),
      anyOf(equals(0), equals(-1)),
    );
    expect(
      ffi.torrent_need_save_resume_data(tor, -1),
      anyOf(equals(0), equals(1)),
    );
    calloc.free(resumeRequired);
    expect(ffi.torrent_scrape_tracker(tor, -1), equals(0));
    expect(ffi.torrent_clear_error(tor), equals(0));
    expect(ffi.torrent_clear_peers(tor), equals(0));
    expect(ffi.torrent_queue_position_up(tor), equals(0));
    expect(ffi.torrent_queue_position_down(tor), equals(0));
    expect(ffi.torrent_queue_position_top(tor), equals(0));
    expect(ffi.torrent_queue_position_bottom(tor), equals(0));
    expect(ffi.torrent_queue_position_set(tor, 0), equals(0));
    final trackerUrl =
        'udp://tracker.opentrackr.org:1337/announce'
            .toNativeUtf8(allocator: calloc)
            .cast<Char>();
    final seedUrl =
        'https://webtorrent.io/torrents/'
            .toNativeUtf8(allocator: calloc)
            .cast<Char>();
    expect(ffi.torrent_add_tracker(tor, trackerUrl, 0), equals(0));
    final replaceUrls = calloc<Pointer<Char>>(1);
    replaceUrls[0] = trackerUrl;
    final replaceTiers = calloc<Int32>(1)..value = 0;
    expect(
      ffi.torrent_replace_trackers(tor, replaceUrls, replaceTiers, 1),
      equals(0),
    );
    calloc.free(replaceUrls);
    calloc.free(replaceTiers);
    final textBuf = calloc<Int8>(8192);
    expect(
      ffi.torrent_get_trackers(tor, textBuf.cast<Char>(), 8192),
      equals(0),
    );
    expect(ffi.torrent_add_url_seed(tor, seedUrl), equals(0));
    expect(
      ffi.torrent_get_url_seeds(tor, textBuf.cast<Char>(), 8192),
      equals(0),
    );
    expect(ffi.torrent_remove_url_seed(tor, seedUrl), equals(0));
    expect(ffi.torrent_add_http_seed(tor, seedUrl), equals(0));
    expect(
      ffi.torrent_get_http_seeds(tor, textBuf.cast<Char>(), 8192),
      equals(0),
    );
    expect(ffi.torrent_remove_http_seed(tor, seedUrl), equals(0));
    expect(
      ffi.torrent_set_piece_deadline(tor, 0, 1000, 0),
      anyOf(equals(0), equals(-1)),
    );
    expect(
      ffi.torrent_reset_piece_deadline(tor, 0),
      anyOf(equals(0), equals(-1)),
    );
    expect(ffi.torrent_clear_piece_deadlines(tor), equals(0));
    expect(
      ffi.torrent_set_file_priority(tor, 0, 1),
      anyOf(equals(0), equals(-1)),
    );
    final filePriority = calloc<Int32>();
    expect(
      ffi.torrent_get_file_priority(tor, 0, filePriority),
      anyOf(equals(0), equals(-1)),
    );
    calloc.free(filePriority);
    expect(
      ffi.torrent_set_piece_priority(tor, 0, 1),
      anyOf(equals(0), equals(-1)),
    );
    final piecePriority = calloc<Int32>();
    expect(
      ffi.torrent_get_piece_priority(tor, 0, piecePriority),
      anyOf(equals(0), equals(-1)),
    );
    calloc.free(piecePriority);
    expect(ffi.torrent_set_int_setting(tor, 0x200 + 5, 64), equals(0));
    final torrentSettingValue = calloc<Int32>();
    final torrentSettingSize = calloc<Int32>()..value = sizeOf<Int32>();
    expect(
      ffi.torrent_get_setting(
        tor,
        0x200 + 5,
        torrentSettingValue.cast<Void>(),
        torrentSettingSize,
      ),
      equals(0),
    );
    expect(torrentSettingValue.value, equals(64));
    calloc.free(torrentSettingValue);
    calloc.free(torrentSettingSize);

    final torrentItems = calloc<ffi.LtTagItemNative>(1);
    torrentItems[0].tag = 0x200 + 5;
    torrentItems[0].int_value = 80;
    expect(ffi.torrent_set_settings_items(tor, torrentItems, 1), equals(0));
    calloc.free(torrentItems);

    final filePriorityTotal = calloc<Int32>();
    expect(
      ffi.torrent_get_file_priorities(
        tor,
        nullptr.cast<Int32>(),
        0,
        filePriorityTotal,
      ),
      anyOf(equals(0), equals(-1)),
    );
    final piecePriorityTotal = calloc<Int32>();
    expect(
      ffi.torrent_get_piece_priorities(
        tor,
        nullptr.cast<Int32>(),
        0,
        piecePriorityTotal,
      ),
      anyOf(equals(0), equals(-1)),
    );
    final onePriority = calloc<Int32>(1)..value = 1;
    expect(
      ffi.torrent_prioritize_files(tor, onePriority, 1),
      anyOf(equals(0), equals(-1)),
    );
    expect(
      ffi.torrent_prioritize_pieces(tor, onePriority, 1),
      anyOf(equals(0), equals(-1)),
    );
    calloc.free(onePriority);
    calloc.free(filePriorityTotal);
    calloc.free(piecePriorityTotal);
    calloc.free(textBuf);
    calloc.free(trackerUrl);
    calloc.free(seedUrl);

    final queuePosition = calloc<Int32>();
    expect(ffi.torrent_queue_position_get(tor, queuePosition), equals(0));
    expect(queuePosition.value, greaterThanOrEqualTo(0));
    expect(ffi.torrent_force_recheck(tor), equals(0));

    calloc.free(queuePosition);
    ffi.torrent_cancel(ses, tor, 0);
    ffi.session_close(ses);
  });
}
