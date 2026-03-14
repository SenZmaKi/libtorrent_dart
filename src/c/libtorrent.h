/*

Copyright (c) 2009, Arvid Norberg
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

*/

#ifndef LIBTORRENT_H
#define LIBTORRENT_H

#if defined(_WIN32)
#if defined(libtorrent_dart_EXPORTS)
#define LTD_API __declspec(dllexport)
#else
#define LTD_API __declspec(dllimport)
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define LTD_API __attribute__((visibility("default")))
#else
#define LTD_API
#endif

enum tags {
  TAG_END = 0,

  SES_FINGERPRINT,      // char const*, 2 character string
  SES_LISTENPORT,       // int
  SES_LISTENPORT_END,   // int
  SES_VERSION_MAJOR,    // int
  SES_VERSION_MINOR,    // int
  SES_VERSION_TINY,     // int
  SES_VERSION_TAG,      // int
  SES_FLAGS,            // int
  SES_ALERT_MASK,       // int
  SES_LISTEN_INTERFACE, // char const*

  // === add_torrent tags ===

  // identifying the torrent to add
  TOR_FILENAME = 0x100, // char const*
  TOR_TORRENT,      // char const*, specify size of buffer with TOR_TORRENT_SIZE
  TOR_TORRENT_SIZE, // int
  TOR_INFOHASH,     // char const*, must point to a 20 byte array
  TOR_INFOHASH_HEX, // char const*, must point to a 40 byte string
  TOR_MAGNETLINK,   // char const*, url

  TOR_TRACKER_URL,          // char const*
  TOR_RESUME_DATA,          // char const*
  TOR_RESUME_DATA_SIZE,     // int
  TOR_SAVE_PATH,            // char const*
  TOR_NAME,                 // char const*
  TOR_PAUSED,               // int
  TOR_AUTO_MANAGED,         // int
  TOR_DUPLICATE_IS_ERROR,   // int
  TOR_USER_DATA,            // void*
  TOR_SEED_MODE,            // int
  TOR_OVERRIDE_RESUME_DATA, // int
  TOR_STORAGE_MODE,         // int

  SET_UPLOAD_RATE_LIMIT = 0x200, // int
  SET_DOWNLOAD_RATE_LIMIT,       // int
  SET_LOCAL_UPLOAD_RATE_LIMIT,   // int
  SET_LOCAL_DOWNLOAD_RATE_LIMIT, // int
  SET_MAX_UPLOAD_SLOTS,          // int
  SET_MAX_CONNECTIONS,           // int
  SET_SEQUENTIAL_DOWNLOAD,       // int, torrent only
  SET_SUPER_SEEDING,             // int, torrent only
  SET_HALF_OPEN_LIMIT,           // int, session only
  SET_PEER_PROXY,                // proxy_setting const*, session_only
  SET_WEB_SEED_PROXY,            // proxy_setting const*, session_only
  SET_TRACKER_PROXY,             // proxy_setting const*, session_only
  SET_DHT_PROXY,                 // proxy_setting const*, session_only
  SET_PROXY,                     // proxy_setting const*, session_only
  SET_ALERT_MASK,                // int, session_only
  // new settings_pack tags
  SETTINGS_INT = 0x300, // int (settings_pack::int_types)
  SETTINGS_BOOL,        // int (settings_pack::bool_types)
  SETTINGS_STRING,      // char const*
};

struct proxy_setting {
  char hostname[256];
  int port;

  char username[256];
  char password[256];

  int type;
};

enum category_t {
  cat_error = 0x1,
  cat_peer = 0x2,
  cat_port_mapping = 0x4,
  cat_storage = 0x8,
  cat_tracker = 0x10,
  cat_debug = 0x20,
  cat_status = 0x40,
  cat_progress = 0x80,
  cat_ip_block = 0x100,
  cat_performance_warning = 0x200,
  cat_dht = 0x400,

  cat_all_categories = 0xffffffff
};

enum proxy_type_t {
  proxy_none,
  proxy_socks4,
  proxy_socks5,
  proxy_socks5_pw,
  proxy_http,
  proxy_http_pw
};

enum storage_mode_t { storage_mode_allocate = 0, storage_mode_sparse };

enum state_t {
  queued_for_checking,
  checking_files,
  downloading_metadata,
  downloading,
  finished,
  seeding,
  allocating,
  checking_resume_data
};

struct torrent_status {
  enum state_t state;
  int paused;
  float progress;
  char error[1024];
  int next_announce;
  int announce_interval;
  char current_tracker[512];
  long long total_download;
  long long total_upload;
  long long total_payload_download;
  long long total_payload_upload;
  long long total_failed_bytes;
  long long total_redundant_bytes;
  float download_rate;
  float upload_rate;
  float download_payload_rate;
  float upload_payload_rate;
  int num_seeds;
  int num_peers;
  int num_complete;
  int num_incomplete;
  int list_seeds;
  int list_peers;
  int connect_candidates;

  // what to do?
  //	bitfield pieces;

  int num_pieces;
  long long total_done;
  long long total_wanted_done;
  long long total_wanted;
  float distributed_copies;
  int block_size;
  int num_uploads;
  int num_connections;
  int uploads_limit;
  int connections_limit;
  //	enum storage_mode_t storage_mode;
  int up_bandwidth_queue;
  int down_bandwidth_queue;
  long long all_time_upload;
  long long all_time_download;
  int active_time;
  int seeding_time;
  int seed_rank;
  int last_scrape;
  int has_incoming;
  int seed_mode;
};

typedef void (*torrent_progress_callback)(int tor,
                                          const struct torrent_status *status,
                                          void *userdata);

struct lt_error {
  int code;
  char message[1024];
};

struct lt_tag_item {
  int tag;
  int int_value;
  char const *string_value;
  void const *ptr_value;
  int size;
};

struct lt_partial_piece_info {
  int piece_index;
  int blocks_in_piece;
  int finished;
  int writing;
  int requested;
};

struct lt_peer_info {
  char ip[64];
  int port;
  char client[128];
  int up_speed;
  int down_speed;
  int payload_up_speed;
  int payload_down_speed;
  long long total_download;
  long long total_upload;
  int flags;
  int source;
};

struct lt_dht_sample {
  char infohash_hex[41];
  char address[64];
  int port;
};

struct lt_alert_info {
  int type;
  int category;
  int torrent_id;
  int dht_num_samples;
  int dht_endpoint_port;
  char what[64];
  char message[1024];
  char dht_endpoint_address[64];
};

struct lt_magnet_info {
  char infohash_hex[41];
  char name[256];
  char trackers[2048];
};

struct lt_torrent_file_info {
  char infohash_hex[41];
  char name[256];
  long long total_size;
  int num_files;
};

struct lt_open_file_state {
  int file_index;
  int open_mode;
  long long last_use_ms;
};

struct lt_file_entry {
  int index;
  long long size;
  long long offset;
  int flags;
  char path[512];
};

struct session_status {
  int has_incoming_connections;

  float upload_rate;
  float download_rate;
  long long total_download;
  long long total_upload;

  float payload_upload_rate;
  float payload_download_rate;
  long long total_payload_download;
  long long total_payload_upload;

  float ip_overhead_upload_rate;
  float ip_overhead_download_rate;
  long long total_ip_overhead_download;
  long long total_ip_overhead_upload;

  float dht_upload_rate;
  float dht_download_rate;
  long long total_dht_download;
  long long total_dht_upload;

  float tracker_upload_rate;
  float tracker_download_rate;
  long long total_tracker_download;
  long long total_tracker_upload;

  long long total_redundant_bytes;
  long long total_failed_bytes;

  int num_peers;
  int num_unchoked;
  int allowed_upload_slots;

  int up_bandwidth_queue;
  int down_bandwidth_queue;

  int up_bandwidth_bytes_queue;
  int down_bandwidth_bytes_queue;

  int optimistic_unchoke_counter;
  int unchoke_counter;

  int dht_nodes;
  int dht_node_cache;
  int dht_torrents;
  long long dht_global_nodes;
  //	std::vector<dht_lookup> active_requests;
};

#ifdef __cplusplus
extern "C" {
#endif

// the functions whose signature ends with:
// , int first_tag, ...);
// takes a tag list. The tag list is a series
// of tag-value pairs. The tags are constants
// identifying which property the value controls.
// The type of the value varies between tags.
// The enumeration above specifies which type
// it expects. All tag lists must always be
// terminated by TAG_END.

// use SES_* tags in tag list
LTD_API void *session_create(int first_tag, ...);
LTD_API void session_close(void *ses);

// fixed-signature helpers for FFI
LTD_API void *session_create_default(void);
LTD_API void *session_create_items(struct lt_tag_item const *items,
                                   int num_items);
LTD_API void *session_create_state(char const *state, int size, int flags);
LTD_API int session_add_magnet(void *ses, char const *magnet_uri,
                               char const *save_path, int download_rate_limit,
                               int upload_rate_limit);

// use TOR_* tags in tag list
LTD_API int session_add_torrent(void *ses, int first_tag, ...);
LTD_API void session_remove_torrent(void *ses, int tor, int flags);

// return < 0 if there are no alerts. Otherwise returns the
// type of alert that was returned
LTD_API int session_pop_alert(void *ses, char *dest, int len, int *category);
LTD_API int session_pop_alert_info(void *ses, int *type, int *category,
                                   char *what_dest, int what_len,
                                   char *message_dest, int message_len);
LTD_API int session_pop_alert_typed(void *ses, struct lt_alert_info *info,
                                    struct lt_dht_sample *samples,
                                    int max_samples, int *total_samples);
LTD_API int session_wait_for_alert(void *ses, int max_wait_ms, char *dest,
                                   int len, int *category);

LTD_API int session_get_status(void *ses, struct session_status *s,
                               int struct_size);
LTD_API int session_listen_port(void *ses, int *port);
LTD_API int session_ssl_listen_port(void *ses, int *port);
LTD_API int session_pause(void *ses);
LTD_API int session_resume(void *ses);
LTD_API int session_is_paused(void *ses);
LTD_API void *session_abort(void *ses);
LTD_API void session_proxy_close(void *proxy);
LTD_API int session_post_torrent_updates(void *ses);
LTD_API int session_post_session_stats(void *ses);
LTD_API int session_post_dht_stats(void *ses);
LTD_API int session_find_torrent(void *ses, char const *infohash_hex);
LTD_API int session_get_torrents(void *ses, int *torrent_ids, int max_torrents,
                                 int *total_torrents);
LTD_API int session_get_torrent_statuses(void *ses, struct torrent_status *statuses,
                                         int max_statuses, int *total_statuses);
LTD_API int session_get_torrent_statuses_flags(void *ses,
                                               struct torrent_status *statuses,
                                               int max_statuses,
                                               int *total_statuses, int flags);
LTD_API int session_dht_get_peers(void *ses, char const *infohash_hex);
LTD_API int session_dht_announce(void *ses, char const *infohash_hex, int port);
LTD_API int session_add_dht_node(void *ses, char const *hostname, int port);
LTD_API int session_is_dht_running(void *ses);
LTD_API int session_start_dht(void *ses);
LTD_API int session_stop_dht(void *ses);
LTD_API int session_dht_get_item(void *ses, char const *target_hex);
LTD_API int session_dht_put_item(void *ses, char const *bencoded_data, int size);
LTD_API int session_dht_sample_infohashes(void *ses, char const *address,
                                          int port, char const *target_hex,
                                          struct lt_dht_sample *samples,
                                          int max_samples, int *total_samples);
LTD_API int session_get_state(void *ses, char *dest, int len, int *required_len,
                              int flags);
LTD_API int session_set_upload_rate_limit(void *ses, int value);
LTD_API int session_get_upload_rate_limit(void *ses, int *value);
LTD_API int session_set_download_rate_limit(void *ses, int value);
LTD_API int session_get_download_rate_limit(void *ses, int *value);
LTD_API int session_set_connections_limit(void *ses, int value);
LTD_API int session_get_connections_limit(void *ses, int *value);
LTD_API int session_set_unchoke_slots_limit(void *ses, int value);
LTD_API int session_get_unchoke_slots_limit(void *ses, int *value);
LTD_API int session_set_dht_upload_rate_limit(void *ses, int value);
LTD_API int session_get_dht_upload_rate_limit(void *ses, int *value);
LTD_API int session_set_dht_announce_interval(void *ses, int value);
LTD_API int session_get_dht_announce_interval(void *ses, int *value);
LTD_API int session_set_dht_max_peers(void *ses, int value);
LTD_API int session_get_dht_max_peers(void *ses, int *value);
LTD_API int session_set_dht_max_dht_items(void *ses, int value);
LTD_API int session_get_dht_max_dht_items(void *ses, int *value);
LTD_API int session_set_enable_dht(void *ses, int enabled);
LTD_API int session_get_enable_dht(void *ses, int *enabled);
LTD_API int session_set_enable_lsd(void *ses, int enabled);
LTD_API int session_get_enable_lsd(void *ses, int *enabled);
LTD_API int session_set_enable_upnp(void *ses, int enabled);
LTD_API int session_get_enable_upnp(void *ses, int *enabled);
LTD_API int session_set_enable_natpmp(void *ses, int enabled);
LTD_API int session_get_enable_natpmp(void *ses, int *enabled);

// use SET_* tags in tag list
LTD_API int session_set_settings(void *ses, int first_tag, ...);
LTD_API int session_get_setting(void *ses, int tag, void *value,
                                int *value_size);
LTD_API int session_set_int_setting(void *ses, int tag_type, int tag,
                                    int value);
LTD_API int session_set_string_setting(void *ses, int tag_type, int tag,
                                       char const *value);
LTD_API int session_add_torrent_items(void *ses,
                                      struct lt_tag_item const *items,
                                      int num_items);
LTD_API int session_async_add_torrent_items(void *ses,
                                            struct lt_tag_item const *items,
                                            int num_items);
LTD_API int session_set_settings_items(void *ses,
                                       struct lt_tag_item const *items,
                                       int num_items);

LTD_API int torrent_get_status(int tor, struct torrent_status *s,
                               int struct_size);
LTD_API int torrent_post_download_queue(int tor);
LTD_API int torrent_post_peer_info(int tor);
LTD_API int torrent_post_trackers(int tor);
LTD_API int torrent_get_download_queue(int tor,
                                       struct lt_partial_piece_info *pieces,
                                       int max_pieces, int *total_pieces);
LTD_API int torrent_get_peer_info(int tor, struct lt_peer_info *peers,
                                  int max_peers, int *total_peers);
LTD_API int torrent_get_file_progress(int tor, long long *progress,
                                      int max_files, int *total_files,
                                      int flags);
LTD_API int torrent_get_file_status(int tor, struct lt_open_file_state *files,
                                    int max_files, int *total_files);
LTD_API int torrent_get_files(int tor, struct lt_file_entry *files, int max_files,
                              int *total_files);

LTD_API int torrent_pause(int tor);
LTD_API int torrent_resume(int tor);
LTD_API int torrent_cancel(void *ses, int tor, int delete_files);
LTD_API int torrent_read_piece(int tor, int piece);
LTD_API int torrent_add_piece(int tor, int piece, char const *data, int size,
                              int flags);
LTD_API int torrent_have_piece(int tor, int piece);
LTD_API int torrent_save_resume_data(int tor, int flags);
LTD_API int torrent_get_resume_data(int tor, char *dest, int len,
                                    int *required_len, int flags);
LTD_API int torrent_need_save_resume_data(int tor, int flags);
LTD_API int torrent_connect_peer(int tor, char const *address, int port);
LTD_API int torrent_set_progress_callback(int tor, torrent_progress_callback cb,
                                          void *userdata);
LTD_API int torrent_poll_progress(int tor);
LTD_API void torrent_clear_progress_callback(int tor);

// use SET_* tags in tag list
LTD_API int torrent_set_settings(int tor, int first_tag, ...);
LTD_API int torrent_get_setting(int tor, int tag, void *value, int *value_size);
LTD_API int torrent_set_int_setting(int tor, int tag, int value);
LTD_API int torrent_set_settings_items(int tor, struct lt_tag_item const *items,
                                       int num_items);
LTD_API int torrent_flush_cache(int tor);
LTD_API int torrent_force_recheck(int tor);
LTD_API int torrent_force_reannounce(int tor, int seconds, int tracker_idx);
LTD_API int torrent_force_reannounce_flags(int tor, int seconds, int tracker_idx,
                                           int flags);
LTD_API int torrent_force_dht_announce(int tor);
LTD_API int torrent_force_lsd_announce(int tor);
LTD_API int torrent_scrape_tracker(int tor, int tracker_idx);
LTD_API int torrent_clear_error(int tor);
LTD_API int torrent_clear_peers(int tor);
LTD_API int torrent_queue_position_up(int tor);
LTD_API int torrent_queue_position_down(int tor);
LTD_API int torrent_queue_position_top(int tor);
LTD_API int torrent_queue_position_bottom(int tor);
LTD_API int torrent_queue_position_set(int tor, int queue_position);
LTD_API int torrent_queue_position_get(int tor, int *queue_position);
LTD_API int torrent_add_tracker(int tor, char const *url, int tier);
LTD_API int torrent_replace_trackers(int tor, char const **urls,
                                     int const *tiers, int num_trackers);
LTD_API int torrent_get_trackers(int tor, char *dest, int len);
LTD_API int torrent_get_url_seeds(int tor, char *dest, int len);
LTD_API int torrent_get_http_seeds(int tor, char *dest, int len);
LTD_API int torrent_add_url_seed(int tor, char const *url);
LTD_API int torrent_remove_url_seed(int tor, char const *url);
LTD_API int torrent_add_http_seed(int tor, char const *url);
LTD_API int torrent_remove_http_seed(int tor, char const *url);
LTD_API int torrent_set_piece_deadline(int tor, int piece_index, int deadline,
                                       int flags);
LTD_API int torrent_reset_piece_deadline(int tor, int piece_index);
LTD_API int torrent_clear_piece_deadlines(int tor);
LTD_API int torrent_set_file_priority(int tor, int file_index, int priority);
LTD_API int torrent_get_file_priority(int tor, int file_index, int *priority);
LTD_API int torrent_set_piece_priority(int tor, int piece_index, int priority);
LTD_API int torrent_get_piece_priority(int tor, int piece_index, int *priority);
LTD_API int torrent_prioritize_files(int tor, int const *priorities,
                                     int num_priorities);
LTD_API int torrent_get_file_priorities(int tor, int *priorities,
                                        int max_priorities,
                                        int *total_priorities);
LTD_API int torrent_prioritize_pieces(int tor, int const *priorities,
                                      int num_priorities);
LTD_API int torrent_get_piece_priorities(int tor, int *priorities,
                                         int max_priorities,
                                         int *total_priorities);
LTD_API int torrent_set_flags(int tor, unsigned long long flags);
LTD_API int torrent_set_flags_mask(int tor, unsigned long long flags,
                                   unsigned long long mask);
LTD_API int torrent_unset_flags(int tor, unsigned long long flags);
LTD_API int torrent_get_flags(int tor, unsigned long long *flags);

// error reporting helpers for FFI layers
LTD_API int lt_last_error(struct lt_error *error, int struct_size);
LTD_API void lt_clear_error(void);
LTD_API int lt_version(char *dest, int len);
LTD_API int lt_make_magnet_uri(int tor, char *dest, int len, int *required_len);
LTD_API int lt_parse_magnet_uri(char const *uri, struct lt_magnet_info *info);
LTD_API int lt_load_torrent_file(char const *path,
                                 struct lt_torrent_file_info *info);
LTD_API int lt_create_torrent_data(char const *source_path,
                                   char const *tracker_url, int piece_size,
                                   char *dest, int len, int *required_len);

#ifdef __cplusplus
}
#endif

#endif
