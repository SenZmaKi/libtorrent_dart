part of '../libtorrent_dart_ffi.dart';

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
