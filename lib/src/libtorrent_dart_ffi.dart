// ignore_for_file: non_constant_identifier_names
@DefaultAsset('package:libtorrent_dart/src/libtorrent_dart.dart')
library;

import 'dart:ffi';

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

@Native<Int32 Function(Int32, Int32)>()
external int torrent_pause(int torrentId, int graceful);

@Native<Int32 Function(Int32)>()
external int torrent_resume(int torrentId);

@Native<Int32 Function(Pointer<Void>, Int32, Int32)>()
external int torrent_cancel(
  Pointer<Void> session,
  int torrentId,
  int deleteFiles,
);

@Native<Int64 Function(Int32)>()
external int torrent_get_flags(int torrentId);

@Native<Void Function(Int32, Int64)>()
external void torrent_set_flags(int torrentId, int flags);

@Native<Void Function(Int32, Int64)>()
external void torrent_unset_flags(int torrentId, int flags);

@Native<Int32 Function(Int32)>()
external int torrent_force_recheck(int torrentId);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_force_reannounce(
  int torrentId,
  int seconds,
  int trackerIdx,
);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_move_storage(int torrentId, Pointer<Char> path, int flags);

@Native<Int32 Function(Int32, Pointer<Int8>, Int32)>()
external int torrent_get_name(int torrentId, Pointer<Int8> dest, int len);

@Native<Int32 Function(Int32, Pointer<Int8>, Int32)>()
external int torrent_get_save_path(int torrentId, Pointer<Int8> dest, int len);

@Native<Int32 Function(Int32, Pointer<Int8>, Int32)>()
external int torrent_get_info_hash(int torrentId, Pointer<Int8> dest, int len);

@Native<Int32 Function(Int32)>()
external int torrent_queue_position(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_queue_position_up(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_queue_position_down(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_queue_position_top(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_queue_position_bottom(int torrentId);

@Native<Void Function(Int32, Int32)>()
external void torrent_queue_position_set(int torrentId, int pos);

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

@Native<Int32 Function(Pointer<LtErrorNative>, Int32)>()
external int lt_last_error(Pointer<LtErrorNative> error, int structSize);

@Native<Void Function()>()
external void lt_clear_error();

final class LtErrorNative extends Struct {
  @Int32()
  external int code;

  @Array(1024)
  external Array<Int8> message;
}

final class LtTagItemNative extends Struct {
  @Int32()
  external int tag;

  @Int32()
  external int int_value;

  external Pointer<Char> string_value;

  external Pointer<Void> ptr_value;

  @Int32()
  external int size;
}

final class SessionStatusNative extends Struct {
  @Int32()
  external int has_incoming_connections;

  @Float()
  external double upload_rate;

  @Float()
  external double download_rate;

  @Int64()
  external int total_download;

  @Int64()
  external int total_upload;

  @Float()
  external double payload_upload_rate;

  @Float()
  external double payload_download_rate;

  @Int64()
  external int total_payload_download;

  @Int64()
  external int total_payload_upload;

  @Float()
  external double ip_overhead_upload_rate;

  @Float()
  external double ip_overhead_download_rate;

  @Int64()
  external int total_ip_overhead_download;

  @Int64()
  external int total_ip_overhead_upload;

  @Float()
  external double dht_upload_rate;

  @Float()
  external double dht_download_rate;

  @Int64()
  external int total_dht_download;

  @Int64()
  external int total_dht_upload;

  @Float()
  external double tracker_upload_rate;

  @Float()
  external double tracker_download_rate;

  @Int64()
  external int total_tracker_download;

  @Int64()
  external int total_tracker_upload;

  @Int64()
  external int total_redundant_bytes;

  @Int64()
  external int total_failed_bytes;

  @Int32()
  external int num_peers;

  @Int32()
  external int num_unchoked;

  @Int32()
  external int allowed_upload_slots;

  @Int32()
  external int up_bandwidth_queue;

  @Int32()
  external int down_bandwidth_queue;

  @Int32()
  external int up_bandwidth_bytes_queue;

  @Int32()
  external int down_bandwidth_bytes_queue;

  @Int32()
  external int optimistic_unchoke_counter;

  @Int32()
  external int unchoke_counter;

  @Int32()
  external int dht_nodes;

  @Int32()
  external int dht_node_cache;

  @Int32()
  external int dht_torrents;

  @Int64()
  external int dht_global_nodes;
}

final class TorrentStatusNative extends Struct {
  @Int32()
  external int state;

  @Int32()
  external int paused;

  @Float()
  external double progress;

  @Array(1024)
  external Array<Int8> error;

  @Int32()
  external int next_announce;

  @Int32()
  external int announce_interval;

  @Array(512)
  external Array<Int8> current_tracker;

  @Int64()
  external int total_download;

  @Int64()
  external int total_upload;

  @Int64()
  external int total_payload_download;

  @Int64()
  external int total_payload_upload;

  @Int64()
  external int total_failed_bytes;

  @Int64()
  external int total_redundant_bytes;

  @Float()
  external double download_rate;

  @Float()
  external double upload_rate;

  @Float()
  external double download_payload_rate;

  @Float()
  external double upload_payload_rate;

  @Int32()
  external int num_seeds;

  @Int32()
  external int num_peers;

  @Int32()
  external int num_complete;

  @Int32()
  external int num_incomplete;

  @Int32()
  external int list_seeds;

  @Int32()
  external int list_peers;

  @Int32()
  external int connect_candidates;

  @Int32()
  external int num_pieces;

  @Int64()
  external int total_done;

  @Int64()
  external int total_wanted_done;

  @Int64()
  external int total_wanted;

  @Float()
  external double distributed_copies;

  @Int32()
  external int block_size;

  @Int32()
  external int num_uploads;

  @Int32()
  external int num_connections;

  @Int32()
  external int uploads_limit;

  @Int32()
  external int connections_limit;

  @Int32()
  external int up_bandwidth_queue;

  @Int32()
  external int down_bandwidth_queue;

  @Int64()
  external int all_time_upload;

  @Int64()
  external int all_time_download;

  @Int32()
  external int active_time;

  @Int32()
  external int seeding_time;

  @Int32()
  external int seed_rank;

  @Int32()
  external int last_scrape;

  @Int32()
  external int has_incoming;

  @Int32()
  external int seed_mode;
}

String int8ArrayToString(Array<Int8> array, int length) {
  final codeUnits = <int>[];
  for (var i = 0; i < length; i++) {
    final value = array[i];
    if (value == 0) break;
    codeUnits.add(value);
  }
  return String.fromCharCodes(codeUnits);
}
