part of '../libtorrent_dart_ffi.dart';

@Native<Pointer<Void> Function()>()
external Pointer<Void> session_create_default();

@Native<Pointer<Void> Function(Pointer<LtTagItemNative>, Int32)>()
external Pointer<Void> session_create_items(
  Pointer<LtTagItemNative> items,
  int numItems,
);

@Native<Void Function(Pointer<Void>)>()
external void session_close(Pointer<Void> session);

@Native<
  Int32 Function(Pointer<Void>, Pointer<Char>, Pointer<Char>, Int32, Int32)
>()
external int session_add_magnet(
  Pointer<Void> session,
  Pointer<Char> magnet,
  Pointer<Char> savePath,
  int downloadRateLimit,
  int uploadRateLimit,
);

@Native<Void Function(Pointer<Void>, Int32, Int32)>()
external void session_remove_torrent(
  Pointer<Void> session,
  int torrentId,
  int flags,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>, Int32, Pointer<Int32>)>()
external int session_pop_alert(
  Pointer<Void> session,
  Pointer<Char> dest,
  int len,
  Pointer<Int32> category,
);

@Native<Int32 Function(Pointer<Void>, Pointer<SessionStatusNative>, Int32)>()
external int session_get_status(
  Pointer<Void> session,
  Pointer<SessionStatusNative> status,
  int structSize,
);

@Native<Int32 Function(Pointer<Void>, Int32, Pointer<Void>, Pointer<Int32>)>()
external int session_get_setting(
  Pointer<Void> session,
  int tag,
  Pointer<Void> value,
  Pointer<Int32> valueSize,
);

@Native<Int32 Function(Pointer<Void>, Int32, Int32, Int32)>()
external int session_set_int_setting(
  Pointer<Void> session,
  int type,
  int tag,
  int value,
);

@Native<Int32 Function(Pointer<Void>, Int32, Int32, Pointer<Char>)>()
external int session_set_string_setting(
  Pointer<Void> session,
  int type,
  int tag,
  Pointer<Char> value,
);

@Native<Int32 Function(Pointer<Void>, Pointer<LtTagItemNative>, Int32)>()
external int session_add_torrent_items(
  Pointer<Void> session,
  Pointer<LtTagItemNative> items,
  int numItems,
);

@Native<Int32 Function(Pointer<Void>, Pointer<LtTagItemNative>, Int32)>()
external int session_set_settings_items(
  Pointer<Void> session,
  Pointer<LtTagItemNative> items,
  int numItems,
);

@Native<Int32 Function(Pointer<Void>)>()
external int session_pause(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_resume(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_is_paused(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_torrent_updates(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_session_stats(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_dht_stats(Pointer<Void> session);

@Native<Int32 Function(Int32)>()
external int torrent_pause(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_resume(int torrentId);

@Native<Int32 Function(Pointer<Void>, Int32, Int32)>()
external int torrent_cancel(
  Pointer<Void> session,
  int torrentId,
  int deleteFiles,
);

typedef ProgressCallbackC =
    Void Function(Int32, Pointer<TorrentStatusNative>, Pointer<Void>);

@Native<
  Int32 Function(
    Int32,
    Pointer<NativeFunction<ProgressCallbackC>>,
    Pointer<Void>,
  )
>()
external int torrent_set_progress_callback(
  int torrentId,
  Pointer<NativeFunction<ProgressCallbackC>> callback,
  Pointer<Void> userdata,
);

@Native<Int32 Function(Int32)>()
external int torrent_poll_progress(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_clear_progress_callback(int torrentId);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_set_int_setting(int torrentId, int tag, int value);

@Native<Int32 Function(Int32, Pointer<LtTagItemNative>, Int32)>()
external int torrent_set_settings_items(
  int torrentId,
  Pointer<LtTagItemNative> items,
  int numItems,
);

@Native<Int32 Function(Int32, Pointer<TorrentStatusNative>, Int32)>()
external int torrent_get_status(
  int torrentId,
  Pointer<TorrentStatusNative> status,
  int structSize,
);

@Native<Int32 Function(Int32, Int32, Pointer<Void>, Pointer<Int32>)>()
external int torrent_get_setting(
  int torrentId,
  int tag,
  Pointer<Void> value,
  Pointer<Int32> valueSize,
);

@Native<Int32 Function(Int32)>()
external int torrent_flush_cache(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_force_recheck(int torrentId);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_force_reannounce(int torrentId, int seconds, int trackerIdx);

@Native<Int32 Function(Int32)>()
external int torrent_force_dht_announce(int torrentId);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_scrape_tracker(int torrentId, int trackerIdx);

@Native<Int32 Function(Int32)>()
external int torrent_clear_error(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_queue_position_up(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_queue_position_down(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_queue_position_top(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_queue_position_bottom(int torrentId);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_queue_position_set(int torrentId, int queuePosition);

@Native<Int32 Function(Int32, Pointer<Int32>)>()
external int torrent_queue_position_get(int torrentId, Pointer<Int32> queuePosition);

@Native<Int32 Function(Pointer<LtErrorNative>, Int32)>()
external int lt_last_error(Pointer<LtErrorNative> error, int structSize);

@Native<Void Function()>()
external void lt_clear_error();
