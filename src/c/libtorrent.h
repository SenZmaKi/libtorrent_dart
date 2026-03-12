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

/* torrent_flags_t bit values (matches lt::torrent_flags in torrent_flags.hpp)
 */
enum torrent_flag_bits {
  LTD_FLAG_SEED_MODE = 1 << 0,
  LTD_FLAG_UPLOAD_MODE = 1 << 1,
  LTD_FLAG_SHARE_MODE = 1 << 2,
  LTD_FLAG_APPLY_IP_FILTER = 1 << 3,
  LTD_FLAG_PAUSED = 1 << 4,
  LTD_FLAG_AUTO_MANAGED = 1 << 5,
  LTD_FLAG_DUPLICATE_IS_ERROR = 1 << 6,
  LTD_FLAG_UPDATE_SUBSCRIBE = 1 << 7,
  LTD_FLAG_SUPER_SEEDING = 1 << 8,
  LTD_FLAG_SEQUENTIAL_DOWNLOAD = 1 << 9,
  LTD_FLAG_STOP_WHEN_READY = 1 << 10,
  LTD_FLAG_OVERRIDE_TRACKERS = 1 << 11,
  LTD_FLAG_OVERRIDE_WEB_SEEDS = 1 << 12,
  LTD_FLAG_DISABLE_DHT = 1 << 19,
  LTD_FLAG_DISABLE_LSD = 1 << 20,
  LTD_FLAG_DISABLE_PEX = 1 << 21,
  LTD_FLAG_NO_VERIFY_FILES = 1 << 22,
  LTD_FLAG_DEFAULT_DONT_DOWNLOAD = 1 << 23
};

/* pause_flags_t bit values */
enum pause_flag_bits { LTD_PAUSE_GRACEFUL = 1 << 0 };

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
LTD_API int session_add_magnet(void *ses, char const *magnet_uri,
                               char const *save_path, int download_rate_limit,
                               int upload_rate_limit);

// use TOR_* tags in tag list
LTD_API int session_add_torrent(void *ses, int first_tag, ...);
LTD_API void session_remove_torrent(void *ses, int tor, int flags);

// return < 0 if there are no alerts. Otherwise returns the
// type of alert that was returned
LTD_API int session_pop_alert(void *ses, char *dest, int len, int *category);

LTD_API int session_get_status(void *ses, struct session_status *s,
                               int struct_size);

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
LTD_API int session_set_settings_items(void *ses,
                                       struct lt_tag_item const *items,
                                       int num_items);

LTD_API int torrent_get_status(int tor, struct torrent_status *s,
                               int struct_size);

LTD_API int torrent_pause(int tor, int graceful);
LTD_API int torrent_resume(int tor);
LTD_API int torrent_cancel(void *ses, int tor, int delete_files);
LTD_API long long torrent_get_flags(int tor);
LTD_API void torrent_set_flags(int tor, long long flags);
LTD_API void torrent_unset_flags(int tor, long long flags);
LTD_API int torrent_force_recheck(int tor);
LTD_API int torrent_force_reannounce(int tor, int seconds, int tracker_idx);
LTD_API int torrent_move_storage(int tor, const char *path, int flags);
LTD_API int torrent_get_name(int tor, char *dest, int len);
LTD_API int torrent_get_save_path(int tor, char *dest, int len);
LTD_API int torrent_get_info_hash(int tor, char *dest, int len);
LTD_API int torrent_queue_position(int tor);
LTD_API void torrent_queue_position_up(int tor);
LTD_API void torrent_queue_position_down(int tor);
LTD_API void torrent_queue_position_top(int tor);
LTD_API void torrent_queue_position_bottom(int tor);
LTD_API void torrent_queue_position_set(int tor, int pos);
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

// error reporting helpers for FFI layers
LTD_API int lt_last_error(struct lt_error *error, int struct_size);
LTD_API void lt_clear_error(void);

#ifdef __cplusplus
}
#endif

#endif
