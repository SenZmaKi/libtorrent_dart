part of '../libtorrent_dart_ffi.dart';

@Native<Pointer<Void> Function()>()
external Pointer<Void> session_create_default();

@Native<Pointer<Void> Function(Pointer<LtTagItemNative>, Int32)>()
external Pointer<Void> session_create_items(
  Pointer<LtTagItemNative> items,
  int numItems,
);

@Native<Pointer<Void> Function(Pointer<Char>, Int32, Int32)>()
external Pointer<Void> session_create_state(
  Pointer<Char> state,
  int size,
  int flags,
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

@Native<
  Int32 Function(
    Pointer<Void>,
    Pointer<Int32>,
    Pointer<Int32>,
    Pointer<Char>,
    Int32,
    Pointer<Char>,
    Int32,
  )
>()
external int session_pop_alert_info(
  Pointer<Void> session,
  Pointer<Int32> type,
  Pointer<Int32> category,
  Pointer<Char> whatDest,
  int whatLen,
  Pointer<Char> messageDest,
  int messageLen,
);

@Native<
  Int32 Function(
    Pointer<Void>,
    Pointer<LtAlertInfoNative>,
    Pointer<LtDhtSampleNative>,
    Int32,
    Pointer<Int32>,
  )
>()
external int session_pop_alert_typed(
  Pointer<Void> session,
  Pointer<LtAlertInfoNative> info,
  Pointer<LtDhtSampleNative> samples,
  int maxSamples,
  Pointer<Int32> totalSamples,
);

@Native<
  Int32 Function(Pointer<Void>, Int32, Pointer<Char>, Int32, Pointer<Int32>)
>()
external int session_wait_for_alert(
  Pointer<Void> session,
  int maxWaitMs,
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

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_listen_port(Pointer<Void> session, Pointer<Int32> port);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_ssl_listen_port(
  Pointer<Void> session,
  Pointer<Int32> port,
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
external int session_async_add_torrent_items(
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

@Native<Pointer<Void> Function(Pointer<Void>)>()
external Pointer<Void> session_abort(Pointer<Void> session);

@Native<Void Function(Pointer<Void>)>()
external void session_proxy_close(Pointer<Void> sessionProxy);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_torrent_updates(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_session_stats(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_post_dht_stats(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>)>()
external int session_find_torrent(
  Pointer<Void> session,
  Pointer<Char> infohashHex,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>, Int32, Pointer<Int32>)>()
external int session_get_torrents(
  Pointer<Void> session,
  Pointer<Int32> torrentIds,
  int maxTorrents,
  Pointer<Int32> totalTorrents,
);

@Native<
  Int32 Function(
    Pointer<Void>,
    Pointer<TorrentStatusNative>,
    Int32,
    Pointer<Int32>,
  )
>()
external int session_get_torrent_statuses(
  Pointer<Void> session,
  Pointer<TorrentStatusNative> statuses,
  int maxStatuses,
  Pointer<Int32> totalStatuses,
);

@Native<
  Int32 Function(
    Pointer<Void>,
    Pointer<TorrentStatusNative>,
    Int32,
    Pointer<Int32>,
    Int32,
  )
>()
external int session_get_torrent_statuses_flags(
  Pointer<Void> session,
  Pointer<TorrentStatusNative> statuses,
  int maxStatuses,
  Pointer<Int32> totalStatuses,
  int flags,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>)>()
external int session_dht_get_peers(
  Pointer<Void> session,
  Pointer<Char> infohashHex,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>, Int32)>()
external int session_dht_announce(
  Pointer<Void> session,
  Pointer<Char> infohashHex,
  int port,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>, Int32)>()
external int session_add_dht_node(
  Pointer<Void> session,
  Pointer<Char> hostname,
  int port,
);

@Native<Int32 Function(Pointer<Void>)>()
external int session_is_dht_running(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_start_dht(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>)>()
external int session_stop_dht(Pointer<Void> session);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>)>()
external int session_dht_get_item(
  Pointer<Void> session,
  Pointer<Char> targetHex,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Char>, Int32)>()
external int session_dht_put_item(
  Pointer<Void> session,
  Pointer<Char> bencodedData,
  int size,
);

@Native<
  Int32 Function(
    Pointer<Void>,
    Pointer<Char>,
    Int32,
    Pointer<Char>,
    Pointer<LtDhtSampleNative>,
    Int32,
    Pointer<Int32>,
  )
>()
external int session_dht_sample_infohashes(
  Pointer<Void> session,
  Pointer<Char> address,
  int port,
  Pointer<Char> targetHex,
  Pointer<LtDhtSampleNative> samples,
  int maxSamples,
  Pointer<Int32> totalSamples,
);

@Native<
  Int32 Function(Pointer<Void>, Pointer<Char>, Int32, Pointer<Int32>, Int32)
>()
external int session_get_state(
  Pointer<Void> session,
  Pointer<Char> dest,
  int len,
  Pointer<Int32> requiredLen,
  int flags,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_upload_rate_limit(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_upload_rate_limit(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_download_rate_limit(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_download_rate_limit(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_connections_limit(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_connections_limit(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_unchoke_slots_limit(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_unchoke_slots_limit(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_dht_upload_rate_limit(
  Pointer<Void> session,
  int value,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_dht_upload_rate_limit(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_dht_announce_interval(
  Pointer<Void> session,
  int value,
);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_dht_announce_interval(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_dht_max_peers(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_dht_max_peers(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_dht_max_dht_items(Pointer<Void> session, int value);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_dht_max_dht_items(
  Pointer<Void> session,
  Pointer<Int32> value,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_enable_dht(Pointer<Void> session, int enabled);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_enable_dht(
  Pointer<Void> session,
  Pointer<Int32> enabled,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_enable_lsd(Pointer<Void> session, int enabled);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_enable_lsd(
  Pointer<Void> session,
  Pointer<Int32> enabled,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_enable_upnp(Pointer<Void> session, int enabled);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_enable_upnp(
  Pointer<Void> session,
  Pointer<Int32> enabled,
);

@Native<Int32 Function(Pointer<Void>, Int32)>()
external int session_set_enable_natpmp(Pointer<Void> session, int enabled);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>()
external int session_get_enable_natpmp(
  Pointer<Void> session,
  Pointer<Int32> enabled,
);

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

@Native<Int32 Function(Int32, Int32)>()
external int torrent_read_piece(int torrentId, int piece);

@Native<Int32 Function(Int32, Int32, Pointer<Char>, Int32, Int32)>()
external int torrent_add_piece(
  int torrentId,
  int piece,
  Pointer<Char> data,
  int size,
  int flags,
);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_have_piece(int torrentId, int piece);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_save_resume_data(int torrentId, int flags);

@Native<Int32 Function(Int32, Pointer<Char>, Int32, Pointer<Int32>, Int32)>()
external int torrent_get_resume_data(
  int torrentId,
  Pointer<Char> dest,
  int len,
  Pointer<Int32> requiredLen,
  int flags,
);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_need_save_resume_data(int torrentId, int flags);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_connect_peer(
  int torrentId,
  Pointer<Char> address,
  int port,
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

@Native<Int32 Function(Int32)>()
external int torrent_post_download_queue(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_post_peer_info(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_post_trackers(int torrentId);

@Native<
  Int32 Function(
    Int32,
    Pointer<LtPartialPieceInfoNative>,
    Int32,
    Pointer<Int32>,
  )
>()
external int torrent_get_download_queue(
  int torrentId,
  Pointer<LtPartialPieceInfoNative> pieces,
  int maxPieces,
  Pointer<Int32> totalPieces,
);

@Native<
  Int32 Function(Int32, Pointer<LtPeerInfoNative>, Int32, Pointer<Int32>)
>()
external int torrent_get_peer_info(
  int torrentId,
  Pointer<LtPeerInfoNative> peers,
  int maxPeers,
  Pointer<Int32> totalPeers,
);

@Native<Int32 Function(Int32, Pointer<Int64>, Int32, Pointer<Int32>, Int32)>()
external int torrent_get_file_progress(
  int torrentId,
  Pointer<Int64> progress,
  int maxFiles,
  Pointer<Int32> totalFiles,
  int flags,
);

@Native<
  Int32 Function(Int32, Pointer<LtOpenFileStateNative>, Int32, Pointer<Int32>)
>()
external int torrent_get_file_status(
  int torrentId,
  Pointer<LtOpenFileStateNative> files,
  int maxFiles,
  Pointer<Int32> totalFiles,
);

@Native<
  Int32 Function(Int32, Pointer<LtFileEntryNative>, Int32, Pointer<Int32>)
>()
external int torrent_get_files(
  int torrentId,
  Pointer<LtFileEntryNative> files,
  int maxFiles,
  Pointer<Int32> totalFiles,
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
external int torrent_force_reannounce(
  int torrentId,
  int seconds,
  int trackerIdx,
);

@Native<Int32 Function(Int32, Int32, Int32, Int32)>()
external int torrent_force_reannounce_flags(
  int torrentId,
  int seconds,
  int trackerIdx,
  int flags,
);

@Native<Int32 Function(Int32)>()
external int torrent_force_dht_announce(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_force_lsd_announce(int torrentId);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_scrape_tracker(int torrentId, int trackerIdx);

@Native<Int32 Function(Int32)>()
external int torrent_clear_error(int torrentId);

@Native<Int32 Function(Int32)>()
external int torrent_clear_peers(int torrentId);

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
external int torrent_queue_position_get(
  int torrentId,
  Pointer<Int32> queuePosition,
);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_add_tracker(int torrentId, Pointer<Char> url, int tier);

@Native<Int32 Function(Int32, Pointer<Pointer<Char>>, Pointer<Int32>, Int32)>()
external int torrent_replace_trackers(
  int torrentId,
  Pointer<Pointer<Char>> urls,
  Pointer<Int32> tiers,
  int numTrackers,
);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_get_trackers(int torrentId, Pointer<Char> dest, int len);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_get_url_seeds(int torrentId, Pointer<Char> dest, int len);

@Native<Int32 Function(Int32, Pointer<Char>, Int32)>()
external int torrent_get_http_seeds(int torrentId, Pointer<Char> dest, int len);

@Native<Int32 Function(Int32, Pointer<Char>)>()
external int torrent_add_url_seed(int torrentId, Pointer<Char> url);

@Native<Int32 Function(Int32, Pointer<Char>)>()
external int torrent_remove_url_seed(int torrentId, Pointer<Char> url);

@Native<Int32 Function(Int32, Pointer<Char>)>()
external int torrent_add_http_seed(int torrentId, Pointer<Char> url);

@Native<Int32 Function(Int32, Pointer<Char>)>()
external int torrent_remove_http_seed(int torrentId, Pointer<Char> url);

@Native<Int32 Function(Int32, Int32, Int32, Int32)>()
external int torrent_set_piece_deadline(
  int torrentId,
  int pieceIndex,
  int deadline,
  int flags,
);

@Native<Int32 Function(Int32, Int32)>()
external int torrent_reset_piece_deadline(int torrentId, int pieceIndex);

@Native<Int32 Function(Int32)>()
external int torrent_clear_piece_deadlines(int torrentId);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_set_file_priority(
  int torrentId,
  int fileIndex,
  int priority,
);

@Native<Int32 Function(Int32, Int32, Pointer<Int32>)>()
external int torrent_get_file_priority(
  int torrentId,
  int fileIndex,
  Pointer<Int32> priority,
);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_set_piece_priority(
  int torrentId,
  int pieceIndex,
  int priority,
);

@Native<Int32 Function(Int32, Int32, Pointer<Int32>)>()
external int torrent_get_piece_priority(
  int torrentId,
  int pieceIndex,
  Pointer<Int32> priority,
);

@Native<Int32 Function(Int32, Pointer<Int32>, Int32)>()
external int torrent_prioritize_files(
  int torrentId,
  Pointer<Int32> priorities,
  int numPriorities,
);

@Native<Int32 Function(Int32, Pointer<Int32>, Int32, Pointer<Int32>)>()
external int torrent_get_file_priorities(
  int torrentId,
  Pointer<Int32> priorities,
  int maxPriorities,
  Pointer<Int32> totalPriorities,
);

@Native<Int32 Function(Int32, Pointer<Int32>, Int32)>()
external int torrent_prioritize_pieces(
  int torrentId,
  Pointer<Int32> priorities,
  int numPriorities,
);

@Native<Int32 Function(Int32, Pointer<Int32>, Int32, Pointer<Int32>)>()
external int torrent_get_piece_priorities(
  int torrentId,
  Pointer<Int32> priorities,
  int maxPriorities,
  Pointer<Int32> totalPriorities,
);

@Native<Int32 Function(Int32, Uint64)>()
external int torrent_set_flags(int torrentId, int flags);

@Native<Int32 Function(Int32, Uint64, Uint64)>()
external int torrent_set_flags_mask(int torrentId, int flags, int mask);

@Native<Int32 Function(Int32, Uint64)>()
external int torrent_unset_flags(int torrentId, int flags);

@Native<Int32 Function(Int32, Pointer<Uint64>)>()
external int torrent_get_flags(int torrentId, Pointer<Uint64> flags);

@Native<Int32 Function(Pointer<LtErrorNative>, Int32)>()
external int lt_last_error(Pointer<LtErrorNative> error, int structSize);

@Native<Void Function()>()
external void lt_clear_error();

@Native<Int32 Function(Pointer<Char>, Int32)>()
external int lt_version(Pointer<Char> dest, int len);

@Native<Int32 Function(Int32, Pointer<Char>, Int32, Pointer<Int32>)>()
external int lt_make_magnet_uri(
  int torrentId,
  Pointer<Char> dest,
  int len,
  Pointer<Int32> requiredLen,
);

@Native<Int32 Function(Pointer<Char>, Pointer<LtMagnetInfoNative>)>()
external int lt_parse_magnet_uri(
  Pointer<Char> uri,
  Pointer<LtMagnetInfoNative> info,
);

@Native<Int32 Function(Pointer<Char>, Pointer<LtTorrentFileInfoNative>)>()
external int lt_load_torrent_file(
  Pointer<Char> path,
  Pointer<LtTorrentFileInfoNative> info,
);

@Native<
  Int32 Function(
    Pointer<Char>,
    Pointer<Char>,
    Int32,
    Pointer<Char>,
    Int32,
    Pointer<Int32>,
  )
>()
external int lt_create_torrent_data(
  Pointer<Char> sourcePath,
  Pointer<Char> trackerUrl,
  int pieceSize,
  Pointer<Char> dest,
  int len,
  Pointer<Int32> requiredLen,
);
