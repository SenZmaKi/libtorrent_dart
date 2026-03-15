import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;

import 'support/test_helpers.dart';

void _noopProgress(
  int tor,
  Pointer<ffi.TorrentStatusNative> status,
  Pointer<Void> userdata,
) {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestTempPath();
  });

  test('raw ffi core APIs and new session controls are callable', () {
    ffi.lt_clear_error();
    final initialErr = calloc<ffi.LtErrorNative>();
    expect(
      ffi.lt_last_error(initialErr, sizeOf<ffi.LtErrorNative>()),
      equals(0),
    );
    calloc.free(initialErr);

    final version = calloc<Int8>(64);
    expect(ffi.lt_version(version.cast<Char>(), 64), equals(0));
    expect(version.cast<Utf8>().toDartString(), isNotEmpty);
    calloc.free(version);
    final parsedMagnet = calloc<ffi.LtMagnetInfoNative>();
    final magnetUri = sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(ffi.lt_parse_magnet_uri(magnetUri, parsedMagnet), equals(0));
    expect(
      ffi.int8ArrayToString(parsedMagnet.ref.infohash_hex, 41),
      equals(sintelInfohashHex),
    );
    calloc.free(magnetUri);
    calloc.free(parsedMagnet);

    final tempDir = Directory(testTempPath).createTempSync('libtorrent_dart_ffi_');
    try {
      final payload = File('${tempDir.path}/payload.bin');
      payload.writeAsBytesSync(List<int>.generate(2048, (i) => i % 251));
      final sourcePath =
          payload.path.toNativeUtf8(allocator: calloc).cast<Char>();
      final tracker =
          'http://127.0.0.1/announce'
              .toNativeUtf8(allocator: calloc)
              .cast<Char>();
      final requiredLen = calloc<Int32>();
      expect(
        ffi.lt_create_torrent_data(
          sourcePath,
          tracker,
          0,
          nullptr.cast<Char>(),
          0,
          requiredLen,
        ),
        equals(0),
      );
      expect(requiredLen.value, greaterThan(0));
      final torrentData = calloc<Int8>(requiredLen.value);
      expect(
        ffi.lt_create_torrent_data(
          sourcePath,
          tracker,
          0,
          torrentData.cast<Char>(),
          requiredLen.value,
          requiredLen,
        ),
        equals(0),
      );

      final torrentFile = File('${tempDir.path}/payload.torrent');
      torrentFile.writeAsBytesSync(
        torrentData.cast<Uint8>().asTypedList(requiredLen.value),
      );
      final loaded = calloc<ffi.LtTorrentFileInfoNative>();
      final torrentPath =
          torrentFile.path.toNativeUtf8(allocator: calloc).cast<Char>();
      expect(ffi.lt_load_torrent_file(torrentPath, loaded), equals(0));
      expect(ffi.int8ArrayToString(loaded.ref.infohash_hex, 41), hasLength(40));
      expect(ffi.int8ArrayToString(loaded.ref.name, 256), isNotEmpty);
      expect(loaded.ref.total_size, greaterThan(0));
      expect(loaded.ref.num_files, greaterThan(0));

      calloc.free(torrentPath);
      calloc.free(loaded);
      calloc.free(torrentData);
      calloc.free(requiredLen);
      calloc.free(sourcePath);
      calloc.free(tracker);
    } finally {
      tempDir.deleteSync(recursive: true);
    }

    final ses = ffi.session_create_default();
    expect(ses, isNot(nullptr));
    final sesItems = calloc<ffi.LtTagItemNative>(1);
    sesItems[0].tag = 9; // SES_ALERT_MASK
    sesItems[0].int_value = 0xFFFFFFFF;
    final sesFromItems = ffi.session_create_items(sesItems, 1);
    expect(sesFromItems, isNot(nullptr));
    ffi.session_close(sesFromItems);
    calloc.free(sesItems);

    final magnet = sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    final savePath = testTempPath.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor = ffi.session_add_magnet(ses, magnet, savePath, 0, 0);
    calloc.free(magnet);
    calloc.free(savePath);
    expect(tor, greaterThanOrEqualTo(0));
    final magnetLen = calloc<Int32>();
    final makeMagnetRc = ffi.lt_make_magnet_uri(
      tor,
      nullptr.cast<Char>(),
      0,
      magnetLen,
    );
    expect(makeMagnetRc, anyOf(equals(0), equals(-1)));
    if (makeMagnetRc == 0 && magnetLen.value > 0) {
      final torrentMagnet = calloc<Int8>(magnetLen.value);
      try {
        expect(
          ffi.lt_make_magnet_uri(
            tor,
            torrentMagnet.cast<Char>(),
            magnetLen.value,
            magnetLen,
          ),
          equals(0),
        );
        expect(torrentMagnet.cast<Utf8>().toDartString(), contains('magnet:?'));
      } finally {
        calloc.free(torrentMagnet);
      }
    }
    calloc.free(magnetLen);

    expect(ffi.session_pause(ses), equals(0));
    expect(ffi.session_is_paused(ses), equals(1));
    expect(ffi.session_resume(ses), equals(0));
    expect(ffi.session_is_paused(ses), equals(0));
    expect(ffi.session_post_torrent_updates(ses), equals(0));
    expect(ffi.session_post_session_stats(ses), equals(0));
    expect(ffi.session_post_dht_stats(ses), equals(0));
    expect(ffi.session_stop_dht(ses), equals(0));
    expect(ffi.session_start_dht(ses), equals(0));
    final requiredState = calloc<Int32>();
    expect(
      ffi.session_get_state(ses, nullptr, 0, requiredState, 0xFFFFFFFF),
      equals(0),
    );
    final stateBuf = calloc<Int8>(
      requiredState.value > 0 ? requiredState.value : 1,
    );
    expect(
      ffi.session_get_state(
        ses,
        stateBuf.cast<Char>(),
        requiredState.value > 0 ? requiredState.value : 1,
        requiredState,
        0xFFFFFFFF,
      ),
      equals(0),
    );
    final restored = ffi.session_create_state(
      stateBuf.cast<Char>(),
      requiredState.value > 0 ? requiredState.value : 1,
      0xFFFFFFFF,
    );
    expect(restored, isNot(nullptr));
    ffi.session_close(restored);
    calloc.free(stateBuf);
    calloc.free(requiredState);
    final alertBuf = calloc<Int8>(4096);
    final alertCategory = calloc<Int32>();
    expect(
      ffi.session_pop_alert(ses, alertBuf.cast<Char>(), 4096, alertCategory),
      anyOf(equals(0), equals(-1)),
    );
    expect(
      ffi.session_wait_for_alert(
        ses,
        10,
        alertBuf.cast<Char>(),
        4096,
        alertCategory,
      ),
      anyOf(equals(0), equals(-1)),
    );
    final alertType = calloc<Int32>();
    final alertWhat = calloc<Int8>(256);
    final alertMessage = calloc<Int8>(4096);
    expect(
      ffi.session_pop_alert_info(
        ses,
        alertType,
        alertCategory,
        alertWhat.cast<Char>(),
        256,
        alertMessage.cast<Char>(),
        4096,
      ),
      anyOf(equals(0), equals(-1)),
    );
    final alertInfo = calloc<ffi.LtAlertInfoNative>();
    final alertSamples = calloc<ffi.LtDhtSampleNative>(8);
    final alertSampleCount = calloc<Int32>();
    expect(
      ffi.session_pop_alert_typed(
        ses,
        alertInfo,
        alertSamples,
        8,
        alertSampleCount,
      ),
      anyOf(equals(0), equals(-1)),
    );
    calloc.free(alertInfo);
    calloc.free(alertSamples);
    calloc.free(alertSampleCount);
    calloc.free(alertType);
    calloc.free(alertWhat);
    calloc.free(alertMessage);
    calloc.free(alertBuf);
    calloc.free(alertCategory);
    final infohash =
        sintelInfohashHex.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(ffi.session_find_torrent(ses, infohash), greaterThanOrEqualTo(0));
    final total = calloc<Int32>();
    expect(
      ffi.session_get_torrents(ses, nullptr.cast<Int32>(), 0, total),
      equals(0),
    );
    expect(total.value, greaterThanOrEqualTo(1));
    final ids = calloc<Int32>(total.value);
    expect(ffi.session_get_torrents(ses, ids, total.value, total), equals(0));
    expect(ids[0], greaterThanOrEqualTo(0));
    final totalStatuses = calloc<Int32>();
    expect(
      ffi.session_get_torrent_statuses(
        ses,
        nullptr.cast<ffi.TorrentStatusNative>(),
        0,
        totalStatuses,
      ),
      equals(0),
    );
    expect(totalStatuses.value, greaterThanOrEqualTo(1));
    final statuses = calloc<ffi.TorrentStatusNative>(totalStatuses.value);
    expect(
      ffi.session_get_torrent_statuses_flags(
        ses,
        statuses,
        totalStatuses.value,
        totalStatuses,
        0xFFFFFFFF,
      ),
      equals(0),
    );
    expect(
      ffi.session_get_torrent_statuses(
        ses,
        statuses,
        totalStatuses.value,
        totalStatuses,
      ),
      equals(0),
    );
    calloc.free(statuses);
    calloc.free(totalStatuses);
    final dhtHost =
        'router.bittorrent.com'.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(ffi.session_add_dht_node(ses, dhtHost, 6881), equals(0));
    expect(ffi.session_is_dht_running(ses), anyOf(equals(0), equals(1)));
    expect(ffi.session_dht_get_item(ses, infohash), equals(0));
    final dhtEntry = calloc<Uint8>(8);
    dhtEntry.asTypedList(8).setAll(0, const [
      100,
      49,
      58,
      97,
      105,
      49,
      101,
      101,
    ]);
    expect(ffi.session_dht_put_item(ses, dhtEntry.cast<Char>(), 8), equals(0));
    calloc.free(dhtEntry);
    expect(ffi.session_dht_get_peers(ses, infohash), equals(0));
    expect(ffi.session_dht_announce(ses, infohash, 0), equals(0));
    final totalSamples = calloc<Int32>();
    final sampleHost = '127.0.0.1'.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(
      ffi.session_dht_sample_infohashes(
        ses,
        sampleHost,
        6881,
        infohash,
        nullptr.cast<ffi.LtDhtSampleNative>(),
        0,
        totalSamples,
      ),
      equals(0),
    );
    expect(totalSamples.value, greaterThanOrEqualTo(0));
    calloc.free(sampleHost);
    calloc.free(totalSamples);
    calloc.free(dhtHost);
    calloc.free(ids);
    calloc.free(total);
    calloc.free(infohash);
    expect(
      ffi.session_set_int_setting(ses, 0x300, 0x4000 + 97, 180),
      equals(0),
    );
    final hostname = '127.0.0.1'.toNativeUtf8(allocator: calloc).cast<Char>();
    expect(
      ffi.session_set_string_setting(ses, 0x302, 0x0000 + 5, hostname),
      equals(0),
    );
    calloc.free(hostname);
    final settingValue = calloc<Int32>();
    final settingSize = calloc<Int32>()..value = sizeOf<Int32>();
    expect(
      ffi.session_get_setting(
        ses,
        0x200 + 5,
        settingValue.cast<Void>(),
        settingSize,
      ),
      equals(0),
    );
    expect(settingValue.value, greaterThanOrEqualTo(0));
    calloc.free(settingValue);
    calloc.free(settingSize);

    final sessionSettingValue = calloc<Int32>();
    expect(ffi.session_set_upload_rate_limit(ses, 1300000), equals(0));
    expect(
      ffi.session_get_upload_rate_limit(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(1300000));
    expect(ffi.session_set_download_rate_limit(ses, 2300000), equals(0));
    expect(
      ffi.session_get_download_rate_limit(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(2300000));
    expect(ffi.session_set_connections_limit(ses, 220), equals(0));
    expect(
      ffi.session_get_connections_limit(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(220));
    expect(ffi.session_set_unchoke_slots_limit(ses, 32), equals(0));
    expect(
      ffi.session_get_unchoke_slots_limit(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(32));
    expect(ffi.session_set_dht_upload_rate_limit(ses, 4096), equals(0));
    expect(
      ffi.session_get_dht_upload_rate_limit(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(4096));
    expect(ffi.session_set_dht_announce_interval(ses, 210), equals(0));
    expect(
      ffi.session_get_dht_announce_interval(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(210));
    expect(ffi.session_set_dht_max_peers(ses, 300), equals(0));
    expect(ffi.session_get_dht_max_peers(ses, sessionSettingValue), equals(0));
    expect(sessionSettingValue.value, equals(300));
    expect(ffi.session_set_dht_max_dht_items(ses, 500), equals(0));
    expect(
      ffi.session_get_dht_max_dht_items(ses, sessionSettingValue),
      equals(0),
    );
    expect(sessionSettingValue.value, equals(500));
    expect(ffi.session_set_enable_dht(ses, 1), equals(0));
    expect(ffi.session_get_enable_dht(ses, sessionSettingValue), equals(0));
    expect(sessionSettingValue.value, equals(1));
    expect(ffi.session_set_enable_lsd(ses, 1), equals(0));
    expect(ffi.session_get_enable_lsd(ses, sessionSettingValue), equals(0));
    expect(sessionSettingValue.value, equals(1));
    expect(ffi.session_set_enable_upnp(ses, 1), equals(0));
    expect(ffi.session_get_enable_upnp(ses, sessionSettingValue), equals(0));
    expect(sessionSettingValue.value, equals(1));
    expect(ffi.session_set_enable_natpmp(ses, 1), equals(0));
    expect(ffi.session_get_enable_natpmp(ses, sessionSettingValue), equals(0));
    expect(sessionSettingValue.value, equals(1));
    calloc.free(sessionSettingValue);

    final settingsItems = calloc<ffi.LtTagItemNative>(1);
    settingsItems[0].tag = 0x200 + 1;
    settingsItems[0].int_value = 1900000;
    expect(ffi.session_set_settings_items(ses, settingsItems, 1), equals(0));
    calloc.free(settingsItems);

    final sst = calloc<ffi.SessionStatusNative>();
    expect(
      ffi.session_get_status(ses, sst, sizeOf<ffi.SessionStatusNative>()),
      equals(0),
    );
    final listenPort = calloc<Int32>();
    final sslListenPort = calloc<Int32>();
    expect(ffi.session_listen_port(ses, listenPort), equals(0));
    expect(ffi.session_ssl_listen_port(ses, sslListenPort), equals(0));
    calloc.free(listenPort);
    calloc.free(sslListenPort);

    final cb = Pointer.fromFunction<ffi.ProgressCallbackC>(_noopProgress);
    expect(ffi.torrent_set_progress_callback(tor, cb, nullptr), equals(0));
    ffi.torrent_poll_progress(tor);
    ffi.torrent_clear_progress_callback(tor);

    final addItems = calloc<ffi.LtTagItemNative>(2);
    addItems[0].tag = 0x100 + 5;
    addItems[0].string_value =
        sintelMagnet.toNativeUtf8(allocator: calloc).cast<Char>();
    addItems[1].tag = 0x100 + 9;
    addItems[1].string_value =
        testTempPath.toNativeUtf8(allocator: calloc).cast<Char>();
    final tor2 = ffi.session_add_torrent_items(ses, addItems, 2);
    expect(tor2, greaterThanOrEqualTo(0));
    expect(ffi.session_async_add_torrent_items(ses, addItems, 2), equals(0));
    calloc.free(addItems[0].string_value.cast<Void>());
    calloc.free(addItems[1].string_value.cast<Void>());
    calloc.free(addItems);
    ffi.torrent_cancel(ses, tor2, 0);
    final proxy = ffi.session_abort(ses);
    expect(proxy, isNot(nullptr));
    ffi.session_proxy_close(proxy);

    ffi.session_remove_torrent(ses, tor, 0);
    calloc.free(sst);
    ffi.session_close(ses);
  });
}
