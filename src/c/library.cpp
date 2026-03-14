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

#include "libtorrent/alert.hpp"
#include "libtorrent/alert_types.hpp"
#include "libtorrent/bdecode.hpp"
#include "libtorrent/disk_interface.hpp"
#include "libtorrent/entry.hpp"
#include "libtorrent/hex.hpp"
#include "libtorrent/magnet_uri.hpp"
#include "libtorrent/create_torrent.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/session_params.hpp"
#include "libtorrent/session_status.hpp"
#include "libtorrent/settings_pack.hpp"
#include "libtorrent/peer_info.hpp"
#include "libtorrent/torrent_handle.hpp"
#include "libtorrent/torrent_flags.hpp"
#include "libtorrent/torrent_status.hpp"
#include "libtorrent/version.hpp"
#include "libtorrent/write_resume_data.hpp"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <exception>
#include <libtorrent.h>
#include <new>
#include <set>
#include <stdarg.h>
#include <string>
#include <vector>
#include <utility>
#include <iterator>


// TORRENT_EXPORT is no longer needed on Windows: __declspec(dllexport) is
// already present on the declarations in libtorrent.h (via LTD_API), so
// putting it again on the definitions would cause MSVC C2375 "different
// linkage" errors.  Keep the macro as a no-op so the function bodies compile
// unchanged on all platforms.
#ifdef TORRENT_EXPORT
#undef TORRENT_EXPORT
#endif
#define TORRENT_EXPORT

namespace {
std::vector<lt::torrent_handle> handles;

struct progress_callback_entry {
  torrent_progress_callback cb;
  void *userdata;
  progress_callback_entry() : cb(nullptr), userdata(nullptr) {}
};

std::vector<progress_callback_entry> progress_callbacks;
thread_local int g_last_error_code = 0;
thread_local std::string g_last_error_message;

int find_handle(lt::torrent_handle h) {
  std::vector<lt::torrent_handle>::const_iterator i =
      std::find(handles.begin(), handles.end(), h);
  if (i == handles.end())
    return -1;
  return i - handles.begin();
}

lt::torrent_handle get_handle(int i) {
  if (i < 0 || i >= int(handles.size()))
    return lt::torrent_handle();
  return handles[i];
}

int add_handle(lt::torrent_handle const &h) {
  std::vector<lt::torrent_handle>::iterator i =
      std::find_if(handles.begin(), handles.end(),
                   [](lt::torrent_handle const &h) { return !h.is_valid(); });
  if (i != handles.end()) {
    *i = h;
    return i - handles.begin();
  }

  handles.push_back(h);
  return handles.size() - 1;
}

progress_callback_entry *get_progress_callback(int i) {
  if (i < 0 || i >= int(progress_callbacks.size()))
    return nullptr;
  return &progress_callbacks[i];
}

void ensure_progress_callback_capacity(int i) {
  if (i < 0)
    return;
  if (i >= int(progress_callbacks.size()))
    progress_callbacks.resize(i + 1);
}

int set_int_value(void *dst, int *size, int val) {
  if (*size < sizeof(int))
    return -2;
  *((int *)dst) = val;
  *size = sizeof(int);
  return 0;
}

void clear_last_error();
void set_last_error(int code, char const *message);
void set_last_error(int code, std::string const &message);

int apply_session_int_setting(void *ses, int setting, int value,
                              char const *context) {
  clear_last_error();
  try {
    auto *s = reinterpret_cast<lt::session *>(ses);
    if (!s) {
      set_last_error(-1, "invalid session handle");
      return -1;
    }
    lt::settings_pack pack;
    pack.set_int(setting, value);
    s->apply_settings(pack);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, context);
    return -1;
  }
}

int apply_session_bool_setting(void *ses, int setting, bool value,
                               char const *context) {
  clear_last_error();
  try {
    auto *s = reinterpret_cast<lt::session *>(ses);
    if (!s) {
      set_last_error(-1, "invalid session handle");
      return -1;
    }
    lt::settings_pack pack;
    pack.set_bool(setting, value);
    s->apply_settings(pack);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, context);
    return -1;
  }
}

int read_session_int_setting(void *ses, int setting, int *value,
                             char const *context) {
  clear_last_error();
  try {
    auto *s = reinterpret_cast<lt::session *>(ses);
    if (!s || !value) {
      set_last_error(-1, "invalid session setting read arguments");
      return -1;
    }
    lt::settings_pack pack = s->get_settings();
    *value = pack.get_int(setting);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, context);
    return -1;
  }
}

int read_session_bool_setting(void *ses, int setting, int *value,
                              char const *context) {
  clear_last_error();
  try {
    auto *s = reinterpret_cast<lt::session *>(ses);
    if (!s || !value) {
      set_last_error(-1, "invalid session setting read arguments");
      return -1;
    }
    lt::settings_pack pack = s->get_settings();
    *value = pack.get_bool(setting) ? 1 : 0;
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, context);
    return -1;
  }
}

void copy_proxy_setting(lt::aux::proxy_settings *s, proxy_setting const *ps) {
  s->hostname.assign(ps->hostname);
  s->port = std::uint16_t(ps->port);
  s->username.assign(ps->username);
  s->password.assign(ps->password);
  s->type = (lt::settings_pack::proxy_type_t)ps->type;
}

void clear_last_error() {
  g_last_error_code = 0;
  g_last_error_message.clear();
}

void set_last_error(int code, char const *message) {
  g_last_error_code = code;
  g_last_error_message = message ? message : "";
}

void set_last_error(int code, std::string const &message) {
  g_last_error_code = code;
  g_last_error_message = message;
}

lt_tag_item const *find_tag_item(lt_tag_item const *items, int const num_items,
                                 int const tag) {
  if (!items || num_items <= 0)
    return nullptr;
  for (int i = 0; i < num_items; ++i) {
    if (items[i].tag == tag)
      return &items[i];
  }
  return nullptr;
}

int apply_session_setting_pack_items(lt::settings_pack &pack,
                                     lt_tag_item const *items,
                                     int const num_items) {
  for (int i = 0; i < num_items; ++i) {
    lt_tag_item const &item = items[i];
    switch (item.tag) {
    case SET_UPLOAD_RATE_LIMIT:
      pack.set_int(lt::settings_pack::upload_rate_limit, item.int_value);
      break;
    case SET_DOWNLOAD_RATE_LIMIT:
      pack.set_int(lt::settings_pack::download_rate_limit, item.int_value);
      break;
    case SET_LOCAL_UPLOAD_RATE_LIMIT:
      pack.set_int(lt::settings_pack::local_upload_rate_limit, item.int_value);
      break;
    case SET_LOCAL_DOWNLOAD_RATE_LIMIT:
      pack.set_int(lt::settings_pack::local_download_rate_limit,
                   item.int_value);
      break;
    case SET_MAX_UPLOAD_SLOTS:
      pack.set_int(lt::settings_pack::unchoke_slots_limit, item.int_value);
      break;
    case SET_MAX_CONNECTIONS:
      pack.set_int(lt::settings_pack::connections_limit, item.int_value);
      break;
    case SET_HALF_OPEN_LIMIT:
      pack.set_int(lt::settings_pack::half_open_limit, item.int_value);
      break;
    case SETTINGS_INT:
      pack.set_int(item.int_value, item.size);
      break;
    case SETTINGS_BOOL:
      pack.set_bool(item.int_value, item.size != 0);
      break;
    case SETTINGS_STRING:
      if (!item.string_value)
        return -1;
      pack.set_str(item.int_value, item.string_value);
      break;
    case SET_PEER_PROXY:
    case SET_WEB_SEED_PROXY:
    case SET_TRACKER_PROXY:
    case SET_DHT_PROXY:
    case SET_PROXY: {
      if (!item.ptr_value)
        return -1;
      lt::aux::proxy_settings ps;
      copy_proxy_setting(
          &ps, reinterpret_cast<proxy_setting const *>(item.ptr_value));
      pack.set_str(lt::settings_pack::proxy_hostname, ps.hostname);
      pack.set_int(lt::settings_pack::proxy_port, ps.port);
      pack.set_str(lt::settings_pack::proxy_username, ps.username);
      pack.set_str(lt::settings_pack::proxy_password, ps.password);
      pack.set_int(lt::settings_pack::proxy_type, ps.type);
      break;
    }
    case SET_ALERT_MASK:
      pack.set_int(lt::settings_pack::alert_mask, item.int_value);
      break;
    default:
      break;
    }
  }
  return 0;
}

bool parse_infohash_hex(char const *infohash_hex, lt::sha1_hash &out) {
  if (!infohash_hex)
    return false;
  if (std::strlen(infohash_hex) != 40)
    return false;
  lt::from_hex(infohash_hex, 40, reinterpret_cast<char *>(out.data()));
  return true;
}

void sha1_to_hex(lt::sha1_hash const &hash, char out[41]) {
  static char const hex_chars[] = "0123456789abcdef";
  auto bytes = hash.data();
  for (int i = 0; i < 20; ++i) {
    unsigned char const b = static_cast<unsigned char>(bytes[i]);
    out[i * 2] = hex_chars[(b >> 4) & 0x0f];
    out[i * 2 + 1] = hex_chars[b & 0x0f];
  }
  out[40] = '\0';
}

std::string parent_path(std::string const &path) {
  std::size_t const pos = path.find_last_of("/\\");
  if (pos == std::string::npos)
    return ".";
  if (pos == 0)
    return path.substr(0, 1);
  return path.substr(0, pos);
}

int parse_add_torrent_items(lt_tag_item const *items, int const num_items,
                            lt::add_torrent_params &params,
                            std::string &error_message) {
  using namespace lt;

  if (!items || num_items <= 0) {
    error_message = "invalid add_torrent_items arguments";
    return -1;
  }

  error_code ec;
  char const *torrent_data = nullptr;
  int torrent_size = 0;
  char const *resume_data = nullptr;
  int resume_size = 0;
  char const *magnet_url = nullptr;

  for (int i = 0; i < num_items; ++i) {
    lt_tag_item const &item = items[i];
    switch (item.tag) {
    case TOR_FILENAME:
      if (!item.string_value)
        break;
      params.ti.reset(new (std::nothrow) torrent_info(item.string_value, ec));
      if (ec) {
        error_message = ec.message();
        return -1;
      }
      break;
    case TOR_TORRENT:
      torrent_data = reinterpret_cast<char const *>(item.ptr_value);
      if (item.size > 0)
        torrent_size = item.size;
      break;
    case TOR_TORRENT_SIZE:
      torrent_size = item.int_value;
      break;
    case TOR_INFOHASH:
      if (!item.ptr_value)
        break;
      params.info_hashes.v1 =
          lt::sha1_hash(reinterpret_cast<char const *>(item.ptr_value));
      break;
    case TOR_INFOHASH_HEX: {
      if (!item.string_value)
        break;
      lt::sha1_hash ih;
      lt::from_hex(item.string_value, 40, reinterpret_cast<char *>(ih.data()));
      params.info_hashes.v1 = ih;
      break;
    }
    case TOR_MAGNETLINK:
      magnet_url = item.string_value;
      break;
    case TOR_TRACKER_URL:
      if (!item.string_value)
        break;
      params.trackers.push_back(item.string_value);
      params.tracker_tiers.push_back(0);
      break;
    case TOR_RESUME_DATA:
      resume_data = reinterpret_cast<char const *>(item.ptr_value);
      if (item.size > 0)
        resume_size = item.size;
      break;
    case TOR_RESUME_DATA_SIZE:
      resume_size = item.int_value;
      break;
    case TOR_SAVE_PATH:
      if (item.string_value)
        params.save_path = item.string_value;
      break;
    case TOR_NAME:
      if (item.string_value)
        params.name = item.string_value;
      break;
    case TOR_PAUSED:
      if (item.int_value != 0)
        params.flags |= lt::torrent_flags::paused;
      break;
    case TOR_AUTO_MANAGED:
      if (item.int_value != 0)
        params.flags |= lt::torrent_flags::auto_managed;
      break;
    case TOR_DUPLICATE_IS_ERROR:
      if (item.int_value != 0)
        params.flags |= lt::torrent_flags::duplicate_is_error;
      break;
    case TOR_USER_DATA:
      params.userdata = const_cast<void *>(item.ptr_value);
      break;
    case TOR_SEED_MODE:
      if (item.int_value != 0)
        params.flags |= lt::torrent_flags::seed_mode;
      break;
    case TOR_OVERRIDE_RESUME_DATA:
      if (item.int_value != 0)
        params.flags |= lt::torrent_flags::override_resume_data;
      break;
    case TOR_STORAGE_MODE:
      params.storage_mode = static_cast<lt::storage_mode_t>(item.int_value);
      break;
    default:
      break;
    }
  }

  if (!params.ti && torrent_data && torrent_size > 0) {
    params.ti.reset(new (std::nothrow) torrent_info(torrent_data, torrent_size, ec));
    if (ec) {
      error_message = ec.message();
      return -1;
    }
  }
  if (resume_data && resume_size > 0) {
    params.resume_data.assign(resume_data, resume_data + resume_size);
  }
  if (magnet_url) {
    parse_magnet_uri(magnet_url, params, ec);
    if (ec) {
      error_message = ec.message();
      return -1;
    }
  }
  return 0;
}

int write_joined_strings(std::vector<std::string> const &values, char *dest,
                         int len) {
  if (!dest || len <= 0)
    return -1;
  std::string joined;
  for (std::size_t i = 0; i < values.size(); ++i) {
    if (i > 0)
      joined.push_back('\n');
    joined.append(values[i]);
  }
  std::strncpy(dest, joined.c_str(), static_cast<std::size_t>(len) - 1);
  dest[len - 1] = '\0';
  return 0;
}

int write_joined_strings(std::set<std::string> const &values, char *dest,
                         int len) {
  std::vector<std::string> list;
  list.reserve(values.size());
  for (std::string const &value : values) {
    list.push_back(value);
  }
  return write_joined_strings(list, dest, len);
}

void write_torrent_status(torrent_status *s, lt::torrent_status const &ts) {
  s->state = (state_t)ts.state;
  s->paused = (ts.flags & lt::torrent_flags::paused) ? 1 : 0;
  s->progress = ts.progress;
  std::strncpy(s->error, ts.errc ? ts.errc.message().c_str() : "",
               sizeof(s->error) - 1);
  s->error[sizeof(s->error) - 1] = '\0';
  s->next_announce = int(lt::total_seconds(ts.next_announce));
  s->announce_interval = 0;
  std::strncpy(s->current_tracker, ts.current_tracker.c_str(),
               sizeof(s->current_tracker) - 1);
  s->current_tracker[sizeof(s->current_tracker) - 1] = '\0';
  s->total_download = ts.total_download;
  s->total_upload = ts.total_upload;
  s->total_payload_download = ts.total_payload_download;
  s->total_payload_upload = ts.total_payload_upload;
  s->total_failed_bytes = ts.total_failed_bytes;
  s->total_redundant_bytes = ts.total_redundant_bytes;
  s->download_rate = ts.download_rate;
  s->upload_rate = ts.upload_rate;
  s->download_payload_rate = ts.download_payload_rate;
  s->upload_payload_rate = ts.upload_payload_rate;
  s->num_seeds = ts.num_seeds;
  s->num_peers = ts.num_peers;
  s->num_complete = ts.num_complete;
  s->num_incomplete = ts.num_incomplete;
  s->list_seeds = ts.list_seeds;
  s->list_peers = ts.list_peers;
  s->connect_candidates = ts.connect_candidates;
  s->num_pieces = ts.num_pieces;
  s->total_done = ts.total_done;
  s->total_wanted_done = ts.total_wanted_done;
  s->total_wanted = ts.total_wanted;
  s->distributed_copies = ts.distributed_copies;
  s->block_size = ts.block_size;
  s->num_uploads = ts.num_uploads;
  s->num_connections = ts.num_connections;
  s->uploads_limit = ts.uploads_limit;
  s->connections_limit = ts.connections_limit;
  s->up_bandwidth_queue = ts.up_bandwidth_queue;
  s->down_bandwidth_queue = ts.down_bandwidth_queue;
  s->all_time_upload = ts.all_time_upload;
  s->all_time_download = ts.all_time_download;
  s->active_time = ts.active_time;
  s->seeding_time = ts.seeding_time;
  s->seed_rank = ts.seed_rank;
  s->last_scrape = ts.last_scrape;
  s->has_incoming = ts.has_incoming;
  s->seed_mode = ts.seed_mode;
}

} // namespace

extern "C" {

TORRENT_EXPORT void torrent_clear_progress_callback(int tor);

TORRENT_EXPORT void *session_create(int tag, ...) {
  clear_last_error();
  try {
    using namespace lt;

    va_list lp;
    va_start(lp, tag);

    int listen_port = 0;
    int listen_port_end = 0;
    char const *listen_interface = "0.0.0.0";
    int alert_mask = alert::error_notification;

    while (tag != TAG_END) {
      switch (tag) {
      case SES_LISTENPORT:
        listen_port = va_arg(lp, int);
        break;
      case SES_LISTENPORT_END:
        listen_port_end = va_arg(lp, int);
        break;
      case SES_ALERT_MASK:
        alert_mask = va_arg(lp, int);
        break;
      case SES_LISTEN_INTERFACE:
        listen_interface = va_arg(lp, char const *);
        break;
      default:
        va_arg(lp, void *);
        break;
      }

      tag = va_arg(lp, int);
    }
    va_end(lp);

    settings_pack pack;
    pack.set_int(settings_pack::alert_mask, alert_mask);
    if (listen_port > 0) {
      int end_port = listen_port_end > 0 ? listen_port_end : listen_port;
      char buf[64];
      snprintf(buf, sizeof(buf), "%s:%d-%d", listen_interface, listen_port,
               end_port);
      pack.set_str(settings_pack::listen_interfaces, buf);
    }

    session *ret = new (std::nothrow) session(session_params(pack));
    if (ret == nullptr)
      set_last_error(-1, "failed to allocate session");
    return ret;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return nullptr;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_create");
    return nullptr;
  }
}

TORRENT_EXPORT void *session_create_default(void) {
  return session_create(TAG_END);
}

TORRENT_EXPORT void *session_create_state(char const *state, int size,
                                          int flags) {
  clear_last_error();
  try {
    using namespace lt;
    if (!state || size <= 0) {
      set_last_error(-1, "invalid session_create_state arguments");
      return nullptr;
    }
    session_params params = read_session_params(
        span<char const>(state, static_cast<std::size_t>(size)),
        session_handle::save_state_flags_t(static_cast<std::uint32_t>(flags)));
    session *ret = new (std::nothrow) session(std::move(params));
    if (ret == nullptr)
      set_last_error(-1, "failed to allocate session");
    return ret;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return nullptr;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_create_state");
    return nullptr;
  }
}

TORRENT_EXPORT void *session_create_items(lt_tag_item const *items,
                                          int const num_items) {
  clear_last_error();
  try {
    using namespace lt;
    if (!items || num_items < 0) {
      set_last_error(-1, "invalid session_create_items arguments");
      return nullptr;
    }
    int listen_port = 0;
    int listen_port_end = 0;
    char const *listen_interface = "0.0.0.0";
    int alert_mask = alert::error_notification;

    for (int i = 0; i < num_items; ++i) {
      lt_tag_item const &item = items[i];
      switch (item.tag) {
      case SES_LISTENPORT:
        listen_port = item.int_value;
        break;
      case SES_LISTENPORT_END:
        listen_port_end = item.int_value;
        break;
      case SES_ALERT_MASK:
        alert_mask = item.int_value;
        break;
      case SES_LISTEN_INTERFACE:
        if (item.string_value)
          listen_interface = item.string_value;
        break;
      default:
        break;
      }
    }

    settings_pack pack;
    pack.set_int(settings_pack::alert_mask, alert_mask);
    if (listen_port > 0) {
      int const end_port = listen_port_end > 0 ? listen_port_end : listen_port;
      char buf[64];
      snprintf(buf, sizeof(buf), "%s:%d-%d", listen_interface, listen_port,
               end_port);
      pack.set_str(settings_pack::listen_interfaces, buf);
    }

    session *ret = new (std::nothrow) session(session_params(pack));
    if (ret == nullptr)
      set_last_error(-1, "failed to allocate session");
    return ret;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return nullptr;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_create_items");
    return nullptr;
  }
}

TORRENT_EXPORT void session_close(void *ses) { delete (lt::session *)ses; }

TORRENT_EXPORT int session_add_torrent(void *ses, int tag, ...) {
  clear_last_error();
  try {
    using namespace lt;

    va_list lp;
    va_start(lp, tag);
    session *s = (session *)ses;
    if (!s) {
      set_last_error(-1, "invalid session handle");
      return -1;
    }
    add_torrent_params params;

    char const *torrent_data = 0;
    int torrent_size = 0;

    char const *resume_data = 0;
    int resume_size = 0;

    char const *magnet_url = 0;

    error_code ec;

    while (tag != TAG_END) {
      switch (tag) {
      case TOR_FILENAME:
        params.ti.reset(new (std::nothrow)
                            torrent_info(va_arg(lp, char const *), ec));
        if (ec)
          set_last_error(-1, ec.message());
        break;
      case TOR_TORRENT:
        torrent_data = va_arg(lp, char const *);
        break;
      case TOR_TORRENT_SIZE:
        torrent_size = va_arg(lp, int);
        break;
      case TOR_INFOHASH:
        params.info_hashes.v1 = lt::sha1_hash(va_arg(lp, char const *));
        break;
      case TOR_INFOHASH_HEX: {
        lt::sha1_hash ih;
        lt::from_hex(va_arg(lp, char const *), 40, (char *)ih.data());
        params.info_hashes.v1 = ih;
        break;
      }
      case TOR_MAGNETLINK:
        magnet_url = va_arg(lp, char const *);
        break;
      case TOR_TRACKER_URL:
        params.trackers.push_back(va_arg(lp, char const *));
        params.tracker_tiers.push_back(0);
        break;
      case TOR_RESUME_DATA:
        resume_data = va_arg(lp, char const *);
        break;
      case TOR_RESUME_DATA_SIZE:
        resume_size = va_arg(lp, int);
        break;
      case TOR_SAVE_PATH:
        params.save_path = va_arg(lp, char const *);
        break;
      case TOR_NAME:
        params.name = va_arg(lp, char const *);
        break;
      case TOR_PAUSED:
        if (va_arg(lp, int) != 0)
          params.flags |= lt::torrent_flags::paused;
        break;
      case TOR_AUTO_MANAGED:
        if (va_arg(lp, int) != 0)
          params.flags |= lt::torrent_flags::auto_managed;
        break;
      case TOR_DUPLICATE_IS_ERROR:
        if (va_arg(lp, int) != 0)
          params.flags |= lt::torrent_flags::duplicate_is_error;
        break;
      case TOR_USER_DATA:
        params.userdata = va_arg(lp, void *);
        break;
      case TOR_SEED_MODE:
        if (va_arg(lp, int) != 0)
          params.flags |= lt::torrent_flags::seed_mode;
        break;
      case TOR_OVERRIDE_RESUME_DATA:
        if (va_arg(lp, int) != 0)
          params.flags |= lt::torrent_flags::override_resume_data;
        break;
      case TOR_STORAGE_MODE:
        params.storage_mode = (lt::storage_mode_t)va_arg(lp, int);
        break;
      default:
        // ignore unknown tags
        va_arg(lp, void *);
        break;
      }

      tag = va_arg(lp, int);
    }
    va_end(lp);

    if (!params.ti && torrent_data && torrent_size)
      params.ti.reset(new (std::nothrow)
                          torrent_info(torrent_data, torrent_size, ec));

    if (resume_data && resume_size) {
      params.resume_data.assign(resume_data, resume_data + resume_size);
    }
    torrent_handle h;
    if (magnet_url) {
      parse_magnet_uri(magnet_url, params, ec);
      if (ec) {
        set_last_error(-1, ec.message());
        return -1;
      }
    }
    h = s->add_torrent(params, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }

    if (!h.is_valid()) {
      if (g_last_error_message.empty())
        set_last_error(-1, "failed to add torrent");
      return -1;
    }

    int i = find_handle(h);
    if (i == -1)
      i = add_handle(h);

    return i;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_add_torrent");
    return -1;
  }
}

TORRENT_EXPORT int session_add_magnet(void *ses, char const *magnet_uri,
                                      char const *save_path,
                                      int download_rate_limit,
                                      int upload_rate_limit) {
  clear_last_error();
  if (!ses || !magnet_uri || !save_path) {
    set_last_error(-1, "invalid add magnet arguments");
    return -1;
  }
  int tor = session_add_torrent(ses, TOR_MAGNETLINK, magnet_uri, TOR_SAVE_PATH,
                                save_path, TAG_END);
  if (tor < 0)
    return -1;
  if (download_rate_limit > 0 || upload_rate_limit > 0) {
    torrent_set_settings(tor, SET_DOWNLOAD_RATE_LIMIT, download_rate_limit,
                         SET_UPLOAD_RATE_LIMIT, upload_rate_limit, TAG_END);
  }
  return tor;
}

TORRENT_EXPORT int session_add_torrent_items(void *ses,
                                             lt_tag_item const *items,
                                             int const num_items) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = reinterpret_cast<session *>(ses);
    if (!s || !items || num_items <= 0) {
      set_last_error(-1, "invalid add_torrent_items arguments");
      return -1;
    }

    add_torrent_params params;
    std::string error_message;
    if (parse_add_torrent_items(items, num_items, params, error_message) != 0) {
      set_last_error(-1, error_message);
      return -1;
    }
    error_code ec;
    torrent_handle h = s->add_torrent(params, ec);
    if (ec || !h.is_valid()) {
      set_last_error(-1, ec ? ec.message() : "failed to add torrent");
      return -1;
    }
    int i = find_handle(h);
    if (i == -1)
      i = add_handle(h);
    return i;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_add_torrent_items");
    return -1;
  }
}

TORRENT_EXPORT int session_async_add_torrent_items(void *ses,
                                                   lt_tag_item const *items,
                                                   int const num_items) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = reinterpret_cast<session *>(ses);
    if (!s || !items || num_items <= 0) {
      set_last_error(-1, "invalid async_add_torrent_items arguments");
      return -1;
    }
    add_torrent_params params;
    std::string error_message;
    if (parse_add_torrent_items(items, num_items, params, error_message) != 0) {
      set_last_error(-1, error_message);
      return -1;
    }
    s->async_add_torrent(params);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_async_add_torrent_items");
    return -1;
  }
}

TORRENT_EXPORT void session_remove_torrent(void *ses, int tor, int flags) {
  using namespace lt;
  torrent_handle h = get_handle(tor);
  if (!h.is_valid())
    return;

  session *s = (session *)ses;
  torrent_clear_progress_callback(tor);
  lt::remove_flags_t remove_flags = {};
  if (flags & lt::session::delete_files)
    remove_flags |= lt::session::delete_files;
  if (flags & lt::session::delete_partfile)
    remove_flags |= lt::session::delete_partfile;
  s->remove_torrent(h, remove_flags);
}

TORRENT_EXPORT int session_pop_alert(void *ses, char *dest, int len,
                                     int *category) {
  clear_last_error();
  try {
    using namespace lt;

    session *s = (session *)ses;
    if (!s || !dest || len <= 0) {
      set_last_error(-1, "invalid pop_alert arguments");
      return -1;
    }
    std::vector<alert *> alerts;
    s->pop_alerts(&alerts);
    if (alerts.empty())
      return -1;

    alert *a = alerts.front();
    if (category)
      *category = a->category();
    strncpy(dest, a->message().c_str(), len - 1);
    dest[len - 1] = 0;

    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_pop_alert");
    return -1;
  }
}

TORRENT_EXPORT int session_pop_alert_info(void *ses, int *type, int *category,
                                          char *what_dest, int what_len,
                                          char *message_dest,
                                          int message_len) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = (session *)ses;
    if (!s || !what_dest || what_len <= 0 || !message_dest || message_len <= 0) {
      set_last_error(-1, "invalid pop_alert_info arguments");
      return -1;
    }
    std::vector<alert *> alerts;
    s->pop_alerts(&alerts);
    if (alerts.empty())
      return -1;
    alert *a = alerts.front();
    if (type)
      *type = a->type();
    if (category)
      *category = a->category();
    std::strncpy(what_dest, a->what(), static_cast<std::size_t>(what_len) - 1);
    what_dest[what_len - 1] = 0;
    std::strncpy(message_dest, a->message().c_str(),
                 static_cast<std::size_t>(message_len) - 1);
    message_dest[message_len - 1] = 0;
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_pop_alert_info");
    return -1;
  }
}

TORRENT_EXPORT int session_pop_alert_typed(void *ses, lt_alert_info *info,
                                           lt_dht_sample *samples,
                                           int max_samples,
                                           int *total_samples) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = reinterpret_cast<session *>(ses);
    if (!s || !info || max_samples < 0) {
      set_last_error(-1, "invalid pop_alert_typed arguments");
      return -1;
    }
    std::vector<alert *> alerts;
    s->pop_alerts(&alerts);
    if (alerts.empty())
      return -1;

    std::memset(info, 0, sizeof(lt_alert_info));
    info->torrent_id = -1;
    if (total_samples)
      *total_samples = 0;

    alert *a = alerts.front();
    info->type = a->type();
    info->category = a->category();
    std::strncpy(info->what, a->what(), sizeof(info->what) - 1);
    std::strncpy(info->message, a->message().c_str(), sizeof(info->message) - 1);

    if (auto *ta = lt::alert_cast<lt::torrent_alert>(a)) {
      if (ta->handle.is_valid()) {
        int id = find_handle(ta->handle);
        if (id == -1)
          id = add_handle(ta->handle);
        info->torrent_id = id;
      }
    }

    if (auto *sa = lt::alert_cast<lt::dht_sample_infohashes_alert>(a)) {
      std::vector<lt::sha1_hash> sample_hashes = sa->samples();
      info->dht_num_samples = static_cast<int>(sample_hashes.size());
      std::string endpoint_address = sa->endpoint.address().to_string();
      std::strncpy(info->dht_endpoint_address, endpoint_address.c_str(),
                   sizeof(info->dht_endpoint_address) - 1);
      info->dht_endpoint_port = sa->endpoint.port();
      if (total_samples)
        *total_samples = info->dht_num_samples;

      if (samples && max_samples > 0) {
        int const count = std::min(max_samples, info->dht_num_samples);
        for (int i = 0; i < count; ++i) {
          std::memset(samples[i].infohash_hex, 0, sizeof(samples[i].infohash_hex));
          std::memset(samples[i].address, 0, sizeof(samples[i].address));
          sha1_to_hex(sample_hashes[static_cast<std::size_t>(i)],
                      samples[i].infohash_hex);
          std::strncpy(samples[i].address, info->dht_endpoint_address,
                       sizeof(samples[i].address) - 1);
          samples[i].port = info->dht_endpoint_port;
        }
      }
    }

    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_pop_alert_typed");
    return -1;
  }
}

TORRENT_EXPORT int session_wait_for_alert(void *ses, int max_wait_ms, char *dest,
                                          int len, int *category) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = (session *)ses;
    if (!s || !dest || len <= 0 || max_wait_ms < 0) {
      set_last_error(-1, "invalid wait_for_alert arguments");
      return -1;
    }
    alert *a = s->wait_for_alert(lt::milliseconds(max_wait_ms));
    if (!a)
      return -1;
    if (category)
      *category = a->category();
    std::strncpy(dest, a->message().c_str(), len - 1);
    dest[len - 1] = 0;
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_wait_for_alert");
    return -1;
  }
}

TORRENT_EXPORT int session_set_settings(void *ses, int tag, ...) {
  clear_last_error();
  try {
    using namespace lt;

    session *s = (session *)ses;
    if (!s) {
      set_last_error(-1, "invalid session handle");
      return -1;
    }

    va_list lp;
    va_start(lp, tag);

    settings_pack pack;

    while (tag != TAG_END) {
      switch (tag) {
      case SET_UPLOAD_RATE_LIMIT:
        pack.set_int(settings_pack::upload_rate_limit, va_arg(lp, int));
        break;
      case SET_DOWNLOAD_RATE_LIMIT:
        pack.set_int(settings_pack::download_rate_limit, va_arg(lp, int));
        break;
      case SET_LOCAL_UPLOAD_RATE_LIMIT:
        pack.set_int(settings_pack::local_upload_rate_limit, va_arg(lp, int));
        break;
      case SET_LOCAL_DOWNLOAD_RATE_LIMIT:
        pack.set_int(settings_pack::local_download_rate_limit, va_arg(lp, int));
        break;
      case SET_MAX_UPLOAD_SLOTS:
        pack.set_int(settings_pack::unchoke_slots_limit, va_arg(lp, int));
        break;
      case SET_MAX_CONNECTIONS:
        pack.set_int(settings_pack::connections_limit, va_arg(lp, int));
        break;
      case SET_HALF_OPEN_LIMIT:
        pack.set_int(settings_pack::half_open_limit, va_arg(lp, int));
        break;
      case SETTINGS_INT: {
        int setting = va_arg(lp, int);
        int value = va_arg(lp, int);
        pack.set_int(setting, value);
        break;
      }
      case SETTINGS_BOOL: {
        int setting = va_arg(lp, int);
        int value = va_arg(lp, int);
        pack.set_bool(setting, value != 0);
        break;
      }
      case SETTINGS_STRING: {
        int setting = va_arg(lp, int);
        char const *value = va_arg(lp, char const *);
        pack.set_str(setting, value);
        break;
      }
      case SET_PEER_PROXY:
      case SET_WEB_SEED_PROXY:
      case SET_TRACKER_PROXY:
      case SET_DHT_PROXY:
      case SET_PROXY: {
        lt::aux::proxy_settings ps;
        copy_proxy_setting(&ps, va_arg(lp, struct proxy_setting const *));
        pack.set_str(settings_pack::proxy_hostname, ps.hostname);
        pack.set_int(settings_pack::proxy_port, ps.port);
        pack.set_str(settings_pack::proxy_username, ps.username);
        pack.set_str(settings_pack::proxy_password, ps.password);
        pack.set_int(settings_pack::proxy_type, ps.type);
        break;
      }
      case SET_ALERT_MASK:
        pack.set_int(settings_pack::alert_mask, va_arg(lp, int));
        break;
      default:
        va_arg(lp, void *);
        break;
      }

      tag = va_arg(lp, int);
    }
    va_end(lp);
    if (pack.has_val(settings_pack::alert_mask) ||
        pack.has_val(settings_pack::upload_rate_limit) ||
        pack.has_val(settings_pack::download_rate_limit) ||
        pack.has_val(settings_pack::connections_limit) ||
        pack.has_val(settings_pack::unchoke_slots_limit) ||
        pack.has_val(settings_pack::proxy_type)) {
      s->apply_settings(pack);
    }
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_set_settings");
    return -1;
  }
}

TORRENT_EXPORT int session_get_setting(void *ses, int tag, void *value,
                                       int *value_size) {
  clear_last_error();
  using namespace lt;
  session *s = (session *)ses;
  if (!s || !value || !value_size) {
    set_last_error(-1, "invalid get_setting arguments");
    return -1;
  }

  lt::settings_pack pack = s->get_settings();
  int setting = -1;
  int result = 0;

  switch (tag) {
  case SET_UPLOAD_RATE_LIMIT:
    setting = settings_pack::upload_rate_limit;
    break;
  case SET_DOWNLOAD_RATE_LIMIT:
    setting = settings_pack::download_rate_limit;
    break;
  case SET_LOCAL_UPLOAD_RATE_LIMIT:
    setting = settings_pack::local_upload_rate_limit;
    break;
  case SET_LOCAL_DOWNLOAD_RATE_LIMIT:
    setting = settings_pack::local_download_rate_limit;
    break;
  case SET_MAX_UPLOAD_SLOTS:
    setting = settings_pack::unchoke_slots_limit;
    break;
  case SET_MAX_CONNECTIONS:
    setting = settings_pack::connections_limit;
    break;
  case SET_HALF_OPEN_LIMIT:
    setting = settings_pack::half_open_limit;
    break;
  default:
    return -2;
  }

  result = pack.get_int(setting);
  return set_int_value(value, value_size, result);
}

TORRENT_EXPORT int session_set_int_setting(void *ses, int tag_type, int tag,
                                           int value) {
  return session_set_settings(ses, tag_type, tag, value, TAG_END);
}

TORRENT_EXPORT int session_set_string_setting(void *ses, int tag_type, int tag,
                                              char const *value) {
  return session_set_settings(ses, tag_type, tag, value, TAG_END);
}

TORRENT_EXPORT int session_set_settings_items(void *ses,
                                              lt_tag_item const *items,
                                              int const num_items) {
  clear_last_error();
  try {
    using namespace lt;
    session *s = reinterpret_cast<session *>(ses);
    if (!s || !items || num_items <= 0) {
      set_last_error(-1, "invalid set_settings_items arguments");
      return -1;
    }
    settings_pack pack;
    int const rc = apply_session_setting_pack_items(pack, items, num_items);
    if (rc != 0) {
      set_last_error(-1, "invalid settings items");
      return -1;
    }
    s->apply_settings(pack);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_set_settings_items");
    return -1;
  }
}

TORRENT_EXPORT int session_get_status(void *sesptr, struct session_status *s,
                                      int struct_size) {
  clear_last_error();
  lt::session *ses = (lt::session *)sesptr;
  if (!ses || !s) {
    set_last_error(-1, "invalid session status arguments");
    return -1;
  }

  lt::session_status ss = ses->status();
  if (struct_size != sizeof(session_status))
    return -1;

  s->has_incoming_connections = ss.has_incoming_connections;

  s->upload_rate = ss.upload_rate;
  s->download_rate = ss.download_rate;
  s->total_download = ss.total_download;
  s->total_upload = ss.total_upload;

  s->payload_upload_rate = ss.payload_upload_rate;
  s->payload_download_rate = ss.payload_download_rate;
  s->total_payload_download = ss.total_payload_download;
  s->total_payload_upload = ss.total_payload_upload;

  s->ip_overhead_upload_rate = ss.ip_overhead_upload_rate;
  s->ip_overhead_download_rate = ss.ip_overhead_download_rate;
  s->total_ip_overhead_download = ss.total_ip_overhead_download;
  s->total_ip_overhead_upload = ss.total_ip_overhead_upload;

  s->dht_upload_rate = ss.dht_upload_rate;
  s->dht_download_rate = ss.dht_download_rate;
  s->total_dht_download = ss.total_dht_download;
  s->total_dht_upload = ss.total_dht_upload;

  s->tracker_upload_rate = ss.tracker_upload_rate;
  s->tracker_download_rate = ss.tracker_download_rate;
  s->total_tracker_download = ss.total_tracker_download;
  s->total_tracker_upload = ss.total_tracker_upload;

  s->total_redundant_bytes = ss.total_redundant_bytes;
  s->total_failed_bytes = ss.total_failed_bytes;

  s->num_peers = ss.num_peers;
  s->num_unchoked = ss.num_unchoked;
  s->allowed_upload_slots = ss.allowed_upload_slots;

  s->up_bandwidth_queue = ss.up_bandwidth_queue;
  s->down_bandwidth_queue = ss.down_bandwidth_queue;

  s->up_bandwidth_bytes_queue = ss.up_bandwidth_bytes_queue;
  s->down_bandwidth_bytes_queue = ss.down_bandwidth_bytes_queue;

  s->optimistic_unchoke_counter = ss.optimistic_unchoke_counter;
  s->unchoke_counter = ss.unchoke_counter;

  s->dht_nodes = ss.dht_nodes;
  s->dht_node_cache = ss.dht_node_cache;
  s->dht_torrents = ss.dht_torrents;
  s->dht_global_nodes = ss.dht_global_nodes;
  return 0;
}

TORRENT_EXPORT int session_pause(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->pause();
  return 0;
}

TORRENT_EXPORT int session_listen_port(void *ses, int *port) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !port) {
    set_last_error(-1, "invalid listen_port arguments");
    return -1;
  }
  *port = static_cast<int>(s->listen_port());
  return 0;
}

TORRENT_EXPORT int session_ssl_listen_port(void *ses, int *port) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !port) {
    set_last_error(-1, "invalid ssl_listen_port arguments");
    return -1;
  }
  *port = static_cast<int>(s->ssl_listen_port());
  return 0;
}

TORRENT_EXPORT int session_resume(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->resume();
  return 0;
}

TORRENT_EXPORT int session_is_paused(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  return s->is_paused() ? 1 : 0;
}

TORRENT_EXPORT void *session_abort(void *ses) {
  clear_last_error();
  try {
    lt::session *s = reinterpret_cast<lt::session *>(ses);
    if (!s) {
      set_last_error(-1, "invalid session handle");
      return nullptr;
    }
    auto *proxy = new (std::nothrow) lt::session_proxy(std::move(s->abort()));
    if (!proxy) {
      set_last_error(-1, "failed to allocate session_proxy");
      return nullptr;
    }
    return proxy;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return nullptr;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_abort");
    return nullptr;
  }
}

TORRENT_EXPORT void session_proxy_close(void *proxy) {
  delete reinterpret_cast<lt::session_proxy *>(proxy);
}

TORRENT_EXPORT int session_post_torrent_updates(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->post_torrent_updates();
  return 0;
}

TORRENT_EXPORT int session_post_session_stats(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->post_session_stats();
  return 0;
}

TORRENT_EXPORT int session_post_dht_stats(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->post_dht_stats();
  return 0;
}

TORRENT_EXPORT int session_find_torrent(void *ses, char const *infohash_hex) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !infohash_hex) {
    set_last_error(-1, "invalid find_torrent arguments");
    return -1;
  }
  lt::sha1_hash hash;
  if (!parse_infohash_hex(infohash_hex, hash)) {
    set_last_error(-1, "invalid infohash hex");
    return -1;
  }
  lt::torrent_handle h = s->find_torrent(hash);
  if (!h.is_valid()) {
    set_last_error(-1, "torrent not found");
    return -1;
  }
  int idx = find_handle(h);
  if (idx == -1)
    idx = add_handle(h);
  return idx;
}

TORRENT_EXPORT int session_get_torrents(void *ses, int *torrent_ids,
                                        int max_torrents,
                                        int *total_torrents) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !total_torrents || max_torrents < 0) {
    set_last_error(-1, "invalid get_torrents arguments");
    return -1;
  }
  std::vector<lt::torrent_handle> torrents = s->get_torrents();
  *total_torrents = static_cast<int>(torrents.size());
  if (!torrent_ids || max_torrents == 0)
    return 0;
  int const count = std::min(max_torrents, *total_torrents);
  for (int i = 0; i < count; ++i) {
    int idx = find_handle(torrents[i]);
    if (idx == -1)
      idx = add_handle(torrents[i]);
    torrent_ids[i] = idx;
  }
  return 0;
}

TORRENT_EXPORT int session_get_torrent_statuses(void *ses,
                                                torrent_status *statuses,
                                                int max_statuses,
                                                int *total_statuses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !total_statuses || max_statuses < 0) {
    set_last_error(-1, "invalid get_torrent_statuses arguments");
    return -1;
  }
  std::vector<lt::torrent_handle> torrents = s->get_torrents();
  *total_statuses = static_cast<int>(torrents.size());
  if (!statuses || max_statuses == 0)
    return 0;
  int const count = std::min(max_statuses, *total_statuses);
  for (int i = 0; i < count; ++i) {
    write_torrent_status(&statuses[i], torrents[i].status());
  }
  return 0;
}

TORRENT_EXPORT int session_get_torrent_statuses_flags(void *ses,
                                                      torrent_status *statuses,
                                                      int max_statuses,
                                                      int *total_statuses,
                                                      int flags) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !total_statuses || max_statuses < 0) {
    set_last_error(-1, "invalid get_torrent_statuses_flags arguments");
    return -1;
  }
  std::vector<lt::torrent_handle> torrents = s->get_torrents();
  *total_statuses = static_cast<int>(torrents.size());
  if (!statuses || max_statuses == 0)
    return 0;
  int const count = std::min(max_statuses, *total_statuses);
  for (int i = 0; i < count; ++i) {
    write_torrent_status(
        &statuses[i],
        torrents[i].status(
            lt::status_flags_t(static_cast<std::uint32_t>(flags))));
  }
  return 0;
}

TORRENT_EXPORT int session_dht_get_peers(void *ses, char const *infohash_hex) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !infohash_hex) {
    set_last_error(-1, "invalid dht_get_peers arguments");
    return -1;
  }
  lt::sha1_hash hash;
  if (!parse_infohash_hex(infohash_hex, hash)) {
    set_last_error(-1, "invalid infohash hex");
    return -1;
  }
  s->dht_get_peers(hash);
  return 0;
}

TORRENT_EXPORT int session_dht_announce(void *ses, char const *infohash_hex,
                                        int port) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !infohash_hex) {
    set_last_error(-1, "invalid dht_announce arguments");
    return -1;
  }
  lt::sha1_hash hash;
  if (!parse_infohash_hex(infohash_hex, hash)) {
    set_last_error(-1, "invalid infohash hex");
    return -1;
  }
  s->dht_announce(hash, port);
  return 0;
}

TORRENT_EXPORT int session_add_dht_node(void *ses, char const *hostname,
                                        int port) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !hostname || port <= 0) {
    set_last_error(-1, "invalid add_dht_node arguments");
    return -1;
  }
  s->add_dht_node(std::make_pair(std::string(hostname), port));
  return 0;
}

TORRENT_EXPORT int session_is_dht_running(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  return s->is_dht_running() ? 1 : 0;
}

TORRENT_EXPORT int session_start_dht(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->start_dht();
  return 0;
}

TORRENT_EXPORT int session_stop_dht(void *ses) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  s->stop_dht();
  return 0;
}

TORRENT_EXPORT int session_dht_get_item(void *ses, char const *target_hex) {
  clear_last_error();
  lt::session *s = reinterpret_cast<lt::session *>(ses);
  if (!s || !target_hex) {
    set_last_error(-1, "invalid dht_get_item arguments");
    return -1;
  }
  lt::sha1_hash target;
  if (!parse_infohash_hex(target_hex, target)) {
    set_last_error(-1, "invalid target hex");
    return -1;
  }
  s->dht_get_item(target);
  return 0;
}

TORRENT_EXPORT int session_dht_put_item(void *ses, char const *bencoded_data,
                                        int size) {
  clear_last_error();
  try {
    lt::session *s = reinterpret_cast<lt::session *>(ses);
    if (!s || !bencoded_data || size <= 0) {
      set_last_error(-1, "invalid dht_put_item arguments");
      return -1;
    }
    lt::error_code ec;
    lt::bdecode_node node;
    lt::bdecode(bencoded_data, bencoded_data + size, node, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }
    lt::entry data(node);
    s->dht_put_item(data);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_dht_put_item");
    return -1;
  }
}

TORRENT_EXPORT int session_dht_sample_infohashes(void *ses, char const *address,
                                                 int port,
                                                 char const *target_hex,
                                                 lt_dht_sample *samples,
                                                 int max_samples,
                                                 int *total_samples) {
  clear_last_error();
  try {
    lt::session *s = reinterpret_cast<lt::session *>(ses);
    if (!s || !address || !target_hex || !total_samples || max_samples < 0) {
      set_last_error(-1, "invalid dht_sample_infohashes arguments");
      return -1;
    }
    lt::sha1_hash target;
    if (!parse_infohash_hex(target_hex, target)) {
      set_last_error(-1, "invalid target hex");
      return -1;
    }
    lt::error_code ec;
    lt::address addr = lt::make_address(address, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }
    s->dht_sample_infohashes(lt::udp::endpoint(addr, port), target);

    std::vector<lt::alert *> alerts;
    s->pop_alerts(&alerts);
    for (lt::alert *a : alerts) {
      auto *sample_alert = lt::alert_cast<lt::dht_sample_infohashes_alert>(a);
      if (!sample_alert)
        continue;
      std::vector<lt::sha1_hash> sample_hashes = sample_alert->samples();
      *total_samples = static_cast<int>(sample_hashes.size());
      if (!samples || max_samples == 0)
        return 0;
      int const count = std::min(max_samples, *total_samples);
      std::string endpoint_address = sample_alert->endpoint.address().to_string();
      int endpoint_port = sample_alert->endpoint.port();
      for (int i = 0; i < count; ++i) {
        std::memset(samples[i].infohash_hex, 0, sizeof(samples[i].infohash_hex));
        std::memset(samples[i].address, 0, sizeof(samples[i].address));
        sha1_to_hex(sample_hashes[static_cast<std::size_t>(i)],
                    samples[i].infohash_hex);
        if (!endpoint_address.empty()) {
          std::strncpy(samples[i].address, endpoint_address.c_str(),
                       sizeof(samples[i].address) - 1);
        }
        samples[i].port = endpoint_port;
      }
      return 0;
    }
    *total_samples = 0;
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_dht_sample_infohashes");
    return -1;
  }
}

TORRENT_EXPORT int session_get_state(void *ses, char *dest, int len,
                                     int *required_len, int flags) {
  clear_last_error();
  try {
    lt::session *s = reinterpret_cast<lt::session *>(ses);
    if (!s || !required_len || len < 0) {
      set_last_error(-1, "invalid get_state arguments");
      return -1;
    }
    auto const save_flags = lt::session_handle::save_state_flags_t(
        static_cast<std::uint32_t>(flags));
    lt::session_params state = s->session_state(save_flags);
    std::vector<char> buf = lt::write_session_params_buf(state, save_flags);
    *required_len = static_cast<int>(buf.size());
    if (!dest || len == 0)
      return 0;
    int const to_copy = std::min(len, *required_len);
    std::memcpy(dest, buf.data(), static_cast<std::size_t>(to_copy));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in session_get_state");
    return -1;
  }
}

TORRENT_EXPORT int session_set_upload_rate_limit(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::upload_rate_limit, value,
      "unknown exception in session_set_upload_rate_limit");
}

TORRENT_EXPORT int session_get_upload_rate_limit(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::upload_rate_limit, value,
      "unknown exception in session_get_upload_rate_limit");
}

TORRENT_EXPORT int session_set_download_rate_limit(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::download_rate_limit, value,
      "unknown exception in session_set_download_rate_limit");
}

TORRENT_EXPORT int session_get_download_rate_limit(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::download_rate_limit, value,
      "unknown exception in session_get_download_rate_limit");
}

TORRENT_EXPORT int session_set_connections_limit(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::connections_limit, value,
      "unknown exception in session_set_connections_limit");
}

TORRENT_EXPORT int session_get_connections_limit(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::connections_limit, value,
      "unknown exception in session_get_connections_limit");
}

TORRENT_EXPORT int session_set_unchoke_slots_limit(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::unchoke_slots_limit, value,
      "unknown exception in session_set_unchoke_slots_limit");
}

TORRENT_EXPORT int session_get_unchoke_slots_limit(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::unchoke_slots_limit, value,
      "unknown exception in session_get_unchoke_slots_limit");
}

TORRENT_EXPORT int session_set_dht_upload_rate_limit(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::dht_upload_rate_limit, value,
      "unknown exception in session_set_dht_upload_rate_limit");
}

TORRENT_EXPORT int session_get_dht_upload_rate_limit(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::dht_upload_rate_limit, value,
      "unknown exception in session_get_dht_upload_rate_limit");
}

TORRENT_EXPORT int session_set_dht_announce_interval(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::dht_announce_interval, value,
      "unknown exception in session_set_dht_announce_interval");
}

TORRENT_EXPORT int session_get_dht_announce_interval(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::dht_announce_interval, value,
      "unknown exception in session_get_dht_announce_interval");
}

TORRENT_EXPORT int session_set_dht_max_peers(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::dht_max_peers, value,
      "unknown exception in session_set_dht_max_peers");
}

TORRENT_EXPORT int session_get_dht_max_peers(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::dht_max_peers, value,
      "unknown exception in session_get_dht_max_peers");
}

TORRENT_EXPORT int session_set_dht_max_dht_items(void *ses, int value) {
  return apply_session_int_setting(
      ses, lt::settings_pack::dht_max_dht_items, value,
      "unknown exception in session_set_dht_max_dht_items");
}

TORRENT_EXPORT int session_get_dht_max_dht_items(void *ses, int *value) {
  return read_session_int_setting(
      ses, lt::settings_pack::dht_max_dht_items, value,
      "unknown exception in session_get_dht_max_dht_items");
}

TORRENT_EXPORT int session_set_enable_dht(void *ses, int enabled) {
  return apply_session_bool_setting(
      ses, lt::settings_pack::enable_dht, enabled != 0,
      "unknown exception in session_set_enable_dht");
}

TORRENT_EXPORT int session_get_enable_dht(void *ses, int *enabled) {
  return read_session_bool_setting(
      ses, lt::settings_pack::enable_dht, enabled,
      "unknown exception in session_get_enable_dht");
}

TORRENT_EXPORT int session_set_enable_lsd(void *ses, int enabled) {
  return apply_session_bool_setting(
      ses, lt::settings_pack::enable_lsd, enabled != 0,
      "unknown exception in session_set_enable_lsd");
}

TORRENT_EXPORT int session_get_enable_lsd(void *ses, int *enabled) {
  return read_session_bool_setting(
      ses, lt::settings_pack::enable_lsd, enabled,
      "unknown exception in session_get_enable_lsd");
}

TORRENT_EXPORT int session_set_enable_upnp(void *ses, int enabled) {
  return apply_session_bool_setting(
      ses, lt::settings_pack::enable_upnp, enabled != 0,
      "unknown exception in session_set_enable_upnp");
}

TORRENT_EXPORT int session_get_enable_upnp(void *ses, int *enabled) {
  return read_session_bool_setting(
      ses, lt::settings_pack::enable_upnp, enabled,
      "unknown exception in session_get_enable_upnp");
}

TORRENT_EXPORT int session_set_enable_natpmp(void *ses, int enabled) {
  return apply_session_bool_setting(
      ses, lt::settings_pack::enable_natpmp, enabled != 0,
      "unknown exception in session_set_enable_natpmp");
}

TORRENT_EXPORT int session_get_enable_natpmp(void *ses, int *enabled) {
  return read_session_bool_setting(
      ses, lt::settings_pack::enable_natpmp, enabled,
      "unknown exception in session_get_enable_natpmp");
}

TORRENT_EXPORT int torrent_get_status(int tor, torrent_status *s,
                                      int struct_size) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }

  if (struct_size != sizeof(torrent_status))
    return -1;
  write_torrent_status(s, h.status());
  return 0;
}

TORRENT_EXPORT int torrent_post_download_queue(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.post_download_queue();
  return 0;
}

TORRENT_EXPORT int torrent_post_peer_info(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.post_peer_info();
  return 0;
}

TORRENT_EXPORT int torrent_post_trackers(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.post_trackers();
  return 0;
}

TORRENT_EXPORT int torrent_get_download_queue(int tor,
                                              lt_partial_piece_info *pieces,
                                              int max_pieces,
                                              int *total_pieces) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !total_pieces || max_pieces < 0) {
    set_last_error(-1, "invalid get_download_queue arguments");
    return -1;
  }
  std::vector<lt::partial_piece_info> queue = h.get_download_queue();
  *total_pieces = static_cast<int>(queue.size());
  if (!pieces || max_pieces == 0)
    return 0;
  int const count = std::min(max_pieces, *total_pieces);
  for (int i = 0; i < count; ++i) {
    pieces[i].piece_index = static_cast<int>(queue[i].piece_index);
    pieces[i].blocks_in_piece = queue[i].blocks_in_piece;
    pieces[i].finished = queue[i].finished;
    pieces[i].writing = queue[i].writing;
    pieces[i].requested = queue[i].requested;
  }
  return 0;
}

TORRENT_EXPORT int torrent_get_peer_info(int tor, lt_peer_info *peers,
                                         int max_peers, int *total_peers) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !total_peers || max_peers < 0) {
    set_last_error(-1, "invalid get_peer_info arguments");
    return -1;
  }
  std::vector<lt::peer_info> info;
  h.get_peer_info(info);
  *total_peers = static_cast<int>(info.size());
  if (!peers || max_peers == 0)
    return 0;
  int const count = std::min(max_peers, *total_peers);
  for (int i = 0; i < count; ++i) {
    std::string const ip = info[i].ip.address().to_string();
    std::strncpy(peers[i].ip, ip.c_str(), sizeof(peers[i].ip) - 1);
    peers[i].ip[sizeof(peers[i].ip) - 1] = '\0';
    peers[i].port = static_cast<int>(info[i].ip.port());
    std::strncpy(peers[i].client, info[i].client.c_str(),
                 sizeof(peers[i].client) - 1);
    peers[i].client[sizeof(peers[i].client) - 1] = '\0';
    peers[i].up_speed = info[i].up_speed;
    peers[i].down_speed = info[i].down_speed;
    peers[i].payload_up_speed = info[i].payload_up_speed;
    peers[i].payload_down_speed = info[i].payload_down_speed;
    peers[i].total_download = info[i].total_download;
    peers[i].total_upload = info[i].total_upload;
    peers[i].flags = static_cast<int>(static_cast<std::uint32_t>(info[i].flags));
    peers[i].source =
        static_cast<int>(static_cast<std::uint8_t>(info[i].source));
  }
  return 0;
}

TORRENT_EXPORT int torrent_get_file_progress(int tor, long long *progress,
                                             int max_files, int *total_files,
                                             int flags) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !total_files || max_files < 0) {
    set_last_error(-1, "invalid get_file_progress arguments");
    return -1;
  }
  std::vector<std::int64_t> values = h.file_progress(lt::file_progress_flags_t(
      static_cast<std::uint8_t>(flags)));
  *total_files = static_cast<int>(values.size());
  if (!progress || max_files == 0)
    return 0;
  int const count = std::min(max_files, *total_files);
  for (int i = 0; i < count; ++i) {
    progress[i] = values[i];
  }
  return 0;
}

TORRENT_EXPORT int torrent_get_file_status(int tor, lt_open_file_state *files,
                                           int max_files, int *total_files) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !total_files || max_files < 0) {
    set_last_error(-1, "invalid get_file_status arguments");
    return -1;
  }
  std::vector<lt::open_file_state> status = h.file_status();
  *total_files = static_cast<int>(status.size());
  if (!files || max_files == 0)
    return 0;
  int const count = std::min(max_files, *total_files);
  for (int i = 0; i < count; ++i) {
    files[i].file_index = static_cast<int>(status[i].file_index);
    files[i].open_mode =
        static_cast<int>(static_cast<std::uint8_t>(status[i].open_mode));
    files[i].last_use_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                               status[i].last_use.time_since_epoch())
                               .count();
  }
  return 0;
}

TORRENT_EXPORT int torrent_get_files(int tor, lt_file_entry *files, int max_files,
                                     int *total_files) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !total_files || max_files < 0) {
    set_last_error(-1, "invalid get_files arguments");
    return -1;
  }
  std::shared_ptr<const lt::torrent_info> ti = h.torrent_file();
  if (!ti) {
    set_last_error(-1, "torrent metadata unavailable");
    return -1;
  }
  lt::file_storage const &fs = ti->files();
  *total_files = fs.num_files();
  if (!files || max_files == 0)
    return 0;
  int const count = std::min(max_files, *total_files);
  for (int i = 0; i < count; ++i) {
    std::memset(files + i, 0, sizeof(lt_file_entry));
    files[i].index = i;
    files[i].size = fs.file_size(lt::file_index_t(i));
    files[i].offset = fs.file_offset(lt::file_index_t(i));
    files[i].flags = fs.file_flags(lt::file_index_t(i));
    std::string path = fs.file_path(lt::file_index_t(i));
    std::strncpy(files[i].path, path.c_str(), sizeof(files[i].path) - 1);
  }
  return 0;
}

TORRENT_EXPORT int torrent_pause(int tor) {
  clear_last_error();
  using namespace lt;
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.pause();
  return 0;
}

TORRENT_EXPORT int torrent_resume(int tor) {
  clear_last_error();
  using namespace lt;
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.resume();
  return 0;
}

TORRENT_EXPORT int torrent_cancel(void *ses, int tor, int delete_files) {
  clear_last_error();
  using namespace lt;
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  torrent_clear_progress_callback(tor);
  lt::session *s = (lt::session *)ses;
  if (!s) {
    set_last_error(-1, "invalid session handle");
    return -1;
  }
  lt::remove_flags_t flags = {};
  if (delete_files)
    flags |= lt::session::delete_files;
  s->remove_torrent(h, flags);
  return 0;
}

TORRENT_EXPORT int torrent_read_piece(int tor, int piece) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || piece < 0) {
      set_last_error(-1, "invalid read_piece arguments");
      return -1;
    }
    h.read_piece(lt::piece_index_t(piece));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_read_piece");
    return -1;
  }
}

TORRENT_EXPORT int torrent_add_piece(int tor, int piece, char const *data,
                                     int size, int flags) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || piece < 0 || !data || size <= 0) {
      set_last_error(-1, "invalid add_piece arguments");
      return -1;
    }
    h.add_piece(lt::piece_index_t(piece), data,
                lt::add_piece_flags_t(static_cast<std::uint8_t>(flags)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_add_piece");
    return -1;
  }
}

TORRENT_EXPORT int torrent_have_piece(int tor, int piece) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || piece < 0) {
      set_last_error(-1, "invalid have_piece arguments");
      return -1;
    }
    return h.have_piece(lt::piece_index_t(piece)) ? 1 : 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_have_piece");
    return -1;
  }
}

TORRENT_EXPORT int torrent_save_resume_data(int tor, int flags) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.save_resume_data(
        lt::resume_data_flags_t(static_cast<std::uint8_t>(flags)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_save_resume_data");
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_resume_data(int tor, char *dest, int len,
                                           int *required_len, int flags) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !required_len || len < 0) {
      set_last_error(-1, "invalid get_resume_data arguments");
      return -1;
    }
    lt::add_torrent_params atp = h.get_resume_data(
        lt::resume_data_flags_t(static_cast<std::uint8_t>(flags)));
    std::vector<char> buf = lt::write_resume_data_buf(atp);
    *required_len = static_cast<int>(buf.size());
    if (!dest || len == 0)
      return 0;
    int const to_copy = std::min(len, *required_len);
    std::memcpy(dest, buf.data(), static_cast<std::size_t>(to_copy));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_get_resume_data");
    return -1;
  }
}

TORRENT_EXPORT int torrent_need_save_resume_data(int tor, int flags) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    if (flags < 0)
      return h.need_save_resume_data() ? 1 : 0;
    return h.need_save_resume_data(
               lt::resume_data_flags_t(static_cast<std::uint8_t>(flags)))
               ? 1
               : 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_need_save_resume_data");
    return -1;
  }
}

TORRENT_EXPORT int torrent_connect_peer(int tor, char const *address, int port) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !address || port <= 0) {
      set_last_error(-1, "invalid connect_peer arguments");
      return -1;
    }
    lt::error_code ec;
    lt::address addr = lt::make_address(address, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }
    h.connect_peer(lt::tcp::endpoint(addr, static_cast<std::uint16_t>(port)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_connect_peer");
    return -1;
  }
}

TORRENT_EXPORT int torrent_set_progress_callback(int tor,
                                                 torrent_progress_callback cb,
                                                 void *userdata) {
  clear_last_error();
  using namespace lt;
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  if (!cb) {
    set_last_error(-1, "callback must not be null");
    return -1;
  }

  ensure_progress_callback_capacity(tor);
  progress_callback_entry *entry = get_progress_callback(tor);
  if (!entry)
    return -1;
  entry->cb = cb;
  entry->userdata = userdata;
  return 0;
}

TORRENT_EXPORT int torrent_poll_progress(int tor) {
  clear_last_error();
  progress_callback_entry *entry = get_progress_callback(tor);
  if (!entry || !entry->cb) {
    set_last_error(-1, "progress callback not set");
    return -1;
  }
  torrent_status ts;
  int rc = torrent_get_status(tor, &ts, sizeof(torrent_status));
  if (rc != 0)
    return -1;
  entry->cb(tor, &ts, entry->userdata);
  return 0;
}

TORRENT_EXPORT void torrent_clear_progress_callback(int tor) {
  progress_callback_entry *entry = get_progress_callback(tor);
  if (!entry)
    return;
  entry->cb = nullptr;
  entry->userdata = nullptr;
}

TORRENT_EXPORT int torrent_set_settings(int tor, int tag, ...) {
  clear_last_error();
  try {
    using namespace lt;
    torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }

    va_list lp;
    va_start(lp, tag);

    while (tag != TAG_END) {
      switch (tag) {
      case SET_UPLOAD_RATE_LIMIT:
        h.set_upload_limit(va_arg(lp, int));
        break;
      case SET_DOWNLOAD_RATE_LIMIT:
        h.set_download_limit(va_arg(lp, int));
        break;
      case SET_MAX_UPLOAD_SLOTS:
        h.set_max_uploads(va_arg(lp, int));
        break;
      case SET_MAX_CONNECTIONS:
        h.set_max_connections(va_arg(lp, int));
        break;
      case SET_SEQUENTIAL_DOWNLOAD:
        h.set_sequential_download(va_arg(lp, int) != 0);
        break;
      case SET_SUPER_SEEDING:
        h.super_seeding(va_arg(lp, int) != 0);
        break;
      default:
        // ignore unknown tags
        va_arg(lp, void *);
        break;
      }

      tag = va_arg(lp, int);
    }
    va_end(lp);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_set_settings");
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_setting(int tor, int tag, void *value,
                                       int *value_size) {
  clear_last_error();
  using namespace lt;
  torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  if (!value || !value_size) {
    set_last_error(-1, "invalid get_setting arguments");
    return -1;
  }

  switch (tag) {
  case SET_UPLOAD_RATE_LIMIT:
    return set_int_value(value, value_size, h.upload_limit());
  case SET_DOWNLOAD_RATE_LIMIT:
    return set_int_value(value, value_size, h.download_limit());
  case SET_MAX_UPLOAD_SLOTS:
    return set_int_value(value, value_size, h.max_uploads());
  case SET_MAX_CONNECTIONS:
    return set_int_value(value, value_size, h.max_connections());
  case SET_SEQUENTIAL_DOWNLOAD:
    return set_int_value(value, value_size, h.is_sequential_download());
  case SET_SUPER_SEEDING:
    return set_int_value(value, value_size, h.super_seeding());
  default:
    return -2;
  }
}

TORRENT_EXPORT int torrent_set_int_setting(int tor, int tag, int value) {
  return torrent_set_settings(tor, tag, value, TAG_END);
}

TORRENT_EXPORT int torrent_set_settings_items(int tor, lt_tag_item const *items,
                                              int const num_items) {
  clear_last_error();
  try {
    using namespace lt;
    torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !items || num_items <= 0) {
      set_last_error(-1, "invalid torrent_set_settings_items arguments");
      return -1;
    }
    for (int i = 0; i < num_items; ++i) {
      lt_tag_item const &item = items[i];
      switch (item.tag) {
      case SET_UPLOAD_RATE_LIMIT:
        h.set_upload_limit(item.int_value);
        break;
      case SET_DOWNLOAD_RATE_LIMIT:
        h.set_download_limit(item.int_value);
        break;
      case SET_MAX_UPLOAD_SLOTS:
        h.set_max_uploads(item.int_value);
        break;
      case SET_MAX_CONNECTIONS:
        h.set_max_connections(item.int_value);
        break;
      case SET_SEQUENTIAL_DOWNLOAD:
        h.set_sequential_download(item.int_value != 0);
        break;
      case SET_SUPER_SEEDING:
        h.super_seeding(item.int_value != 0);
        break;
      default:
        break;
      }
    }
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in torrent_set_settings_items");
    return -1;
  }
}

TORRENT_EXPORT int torrent_flush_cache(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.flush_cache();
  return 0;
}

TORRENT_EXPORT int torrent_force_recheck(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.force_recheck();
  return 0;
}

TORRENT_EXPORT int torrent_force_reannounce(int tor, int seconds,
                                            int tracker_idx) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.force_reannounce(seconds, tracker_idx);
  return 0;
}

TORRENT_EXPORT int torrent_force_reannounce_flags(int tor, int seconds,
                                                  int tracker_idx, int flags) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.force_reannounce(seconds, tracker_idx, lt::reannounce_flags_t(flags));
  return 0;
}

TORRENT_EXPORT int torrent_force_dht_announce(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.force_dht_announce();
  return 0;
}

TORRENT_EXPORT int torrent_force_lsd_announce(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.force_lsd_announce();
  return 0;
}

TORRENT_EXPORT int torrent_scrape_tracker(int tor, int tracker_idx) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.scrape_tracker(tracker_idx);
  return 0;
}

TORRENT_EXPORT int torrent_clear_error(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.clear_error();
  return 0;
}

TORRENT_EXPORT int torrent_clear_peers(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.clear_peers();
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_up(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.queue_position_up();
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_down(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.queue_position_down();
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_top(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.queue_position_top();
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_bottom(int tor) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.queue_position_bottom();
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_set(int tor, int queue_position) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.queue_position_set(lt::queue_position_t(queue_position));
  return 0;
}

TORRENT_EXPORT int torrent_queue_position_get(int tor, int *queue_position) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !queue_position) {
    set_last_error(-1, "invalid queue position arguments");
    return -1;
  }
  *queue_position = static_cast<int>(h.queue_position());
  return 0;
}

TORRENT_EXPORT int torrent_add_tracker(int tor, char const *url, int tier) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !url) {
    set_last_error(-1, "invalid add_tracker arguments");
    return -1;
  }
  lt::announce_entry e(url);
  e.tier = static_cast<std::uint8_t>(tier < 0 ? 0 : tier);
  h.add_tracker(e);
  return 0;
}

TORRENT_EXPORT int torrent_replace_trackers(int tor, char const **urls,
                                            int const *tiers,
                                            int num_trackers) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !urls || num_trackers < 0) {
    set_last_error(-1, "invalid replace_trackers arguments");
    return -1;
  }
  std::vector<lt::announce_entry> entries;
  entries.reserve(static_cast<std::size_t>(num_trackers));
  for (int i = 0; i < num_trackers; ++i) {
    if (!urls[i])
      continue;
    lt::announce_entry e(urls[i]);
    e.tier = static_cast<std::uint8_t>(tiers ? std::max(0, tiers[i]) : 0);
    entries.push_back(e);
  }
  h.replace_trackers(entries);
  return 0;
}

TORRENT_EXPORT int torrent_get_trackers(int tor, char *dest, int len) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  std::vector<lt::announce_entry> trackers = h.trackers();
  std::vector<std::string> urls;
  urls.reserve(trackers.size());
  for (lt::announce_entry const &entry : trackers) {
    urls.push_back(entry.url);
  }
  return write_joined_strings(urls, dest, len);
}

TORRENT_EXPORT int torrent_get_url_seeds(int tor, char *dest, int len) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  return write_joined_strings(h.url_seeds(), dest, len);
}

TORRENT_EXPORT int torrent_get_http_seeds(int tor, char *dest, int len) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  return write_joined_strings(h.http_seeds(), dest, len);
}

TORRENT_EXPORT int torrent_add_url_seed(int tor, char const *url) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !url) {
    set_last_error(-1, "invalid add_url_seed arguments");
    return -1;
  }
  h.add_url_seed(url);
  return 0;
}

TORRENT_EXPORT int torrent_remove_url_seed(int tor, char const *url) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !url) {
    set_last_error(-1, "invalid remove_url_seed arguments");
    return -1;
  }
  h.remove_url_seed(url);
  return 0;
}

TORRENT_EXPORT int torrent_add_http_seed(int tor, char const *url) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !url) {
    set_last_error(-1, "invalid add_http_seed arguments");
    return -1;
  }
  h.add_http_seed(url);
  return 0;
}

TORRENT_EXPORT int torrent_remove_http_seed(int tor, char const *url) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !url) {
    set_last_error(-1, "invalid remove_http_seed arguments");
    return -1;
  }
  h.remove_http_seed(url);
  return 0;
}

TORRENT_EXPORT int torrent_set_piece_deadline(int tor, int piece_index,
                                              int deadline, int flags) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.set_piece_deadline(lt::piece_index_t(piece_index), deadline,
                         lt::deadline_flags_t(flags));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_reset_piece_deadline(int tor, int piece_index) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.reset_piece_deadline(lt::piece_index_t(piece_index));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_clear_piece_deadlines(int tor) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.clear_piece_deadlines();
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_set_file_priority(int tor, int file_index,
                                             int priority) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.file_priority(lt::file_index_t(file_index),
                    lt::download_priority_t(priority));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_file_priority(int tor, int file_index,
                                             int *priority) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !priority) {
      set_last_error(-1, "invalid file priority arguments");
      return -1;
    }
    *priority = static_cast<int>(h.file_priority(lt::file_index_t(file_index)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_set_piece_priority(int tor, int piece_index,
                                              int priority) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid()) {
      set_last_error(-1, "invalid torrent handle");
      return -1;
    }
    h.piece_priority(lt::piece_index_t(piece_index),
                     lt::download_priority_t(priority));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_piece_priority(int tor, int piece_index,
                                              int *priority) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !priority) {
      set_last_error(-1, "invalid piece priority arguments");
      return -1;
    }
    *priority = static_cast<int>(h.piece_priority(lt::piece_index_t(piece_index)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_prioritize_files(int tor, int const *priorities,
                                            int num_priorities) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !priorities || num_priorities < 0) {
      set_last_error(-1, "invalid prioritize_files arguments");
      return -1;
    }
    std::vector<lt::download_priority_t> list;
    list.reserve(static_cast<std::size_t>(num_priorities));
    for (int i = 0; i < num_priorities; ++i) {
      list.push_back(lt::download_priority_t(priorities[i]));
    }
    h.prioritize_files(list);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_file_priorities(int tor, int *priorities,
                                               int max_priorities,
                                               int *total_priorities) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !total_priorities || max_priorities < 0) {
      set_last_error(-1, "invalid get_file_priorities arguments");
      return -1;
    }
    std::vector<lt::download_priority_t> list = h.get_file_priorities();
    *total_priorities = static_cast<int>(list.size());
    if (!priorities || max_priorities == 0)
      return 0;
    int const count = std::min(max_priorities, *total_priorities);
    for (int i = 0; i < count; ++i) {
      priorities[i] = static_cast<int>(list[i]);
    }
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_prioritize_pieces(int tor, int const *priorities,
                                             int num_priorities) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !priorities || num_priorities < 0) {
      set_last_error(-1, "invalid prioritize_pieces arguments");
      return -1;
    }
    std::vector<lt::download_priority_t> list;
    list.reserve(static_cast<std::size_t>(num_priorities));
    for (int i = 0; i < num_priorities; ++i) {
      list.push_back(lt::download_priority_t(priorities[i]));
    }
    h.prioritize_pieces(list);
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_get_piece_priorities(int tor, int *priorities,
                                                int max_priorities,
                                                int *total_priorities) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !total_priorities || max_priorities < 0) {
      set_last_error(-1, "invalid get_piece_priorities arguments");
      return -1;
    }
    std::vector<lt::download_priority_t> list = h.get_piece_priorities();
    *total_priorities = static_cast<int>(list.size());
    if (!priorities || max_priorities == 0)
      return 0;
    int const count = std::min(max_priorities, *total_priorities);
    for (int i = 0; i < count; ++i) {
      priorities[i] = static_cast<int>(list[i]);
    }
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  }
}

TORRENT_EXPORT int torrent_set_flags(int tor, unsigned long long flags) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.set_flags(lt::torrent_flags_t(static_cast<std::uint64_t>(flags)));
  return 0;
}

TORRENT_EXPORT int torrent_set_flags_mask(int tor, unsigned long long flags,
                                          unsigned long long mask) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.set_flags(lt::torrent_flags_t(static_cast<std::uint64_t>(flags)),
              lt::torrent_flags_t(static_cast<std::uint64_t>(mask)));
  return 0;
}

TORRENT_EXPORT int torrent_unset_flags(int tor, unsigned long long flags) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }
  h.unset_flags(lt::torrent_flags_t(static_cast<std::uint64_t>(flags)));
  return 0;
}

TORRENT_EXPORT int torrent_get_flags(int tor, unsigned long long *flags) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid() || !flags) {
    set_last_error(-1, "invalid get_flags arguments");
    return -1;
  }
  *flags = static_cast<unsigned long long>(
      static_cast<std::uint64_t>(h.flags()));
  return 0;
}

TORRENT_EXPORT int lt_last_error(struct lt_error *error, int struct_size) {
  if (!error || struct_size != sizeof(lt_error))
    return -1;
  error->code = g_last_error_code;
  std::strncpy(error->message, g_last_error_message.c_str(),
               sizeof(error->message) - 1);
  error->message[sizeof(error->message) - 1] = '\0';
  return 0;
}

TORRENT_EXPORT void lt_clear_error(void) { clear_last_error(); }

TORRENT_EXPORT int lt_version(char *dest, int len) {
  if (!dest || len <= 0)
    return -1;
  std::strncpy(dest, lt::version(), static_cast<std::size_t>(len) - 1);
  dest[len - 1] = '\0';
  return 0;
}

TORRENT_EXPORT int lt_make_magnet_uri(int tor, char *dest, int len,
                                      int *required_len) {
  clear_last_error();
  try {
    lt::torrent_handle h = get_handle(tor);
    if (!h.is_valid() || !required_len || len < 0) {
      set_last_error(-1, "invalid make_magnet_uri arguments");
      return -1;
    }
    std::string uri = lt::make_magnet_uri(h);
    *required_len = static_cast<int>(uri.size()) + 1;
    if (!dest || len == 0)
      return 0;
    std::strncpy(dest, uri.c_str(), static_cast<std::size_t>(len) - 1);
    dest[len - 1] = '\0';
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in lt_make_magnet_uri");
    return -1;
  }
}

TORRENT_EXPORT int lt_parse_magnet_uri(char const *uri, lt_magnet_info *info) {
  clear_last_error();
  try {
    if (!uri || !info) {
      set_last_error(-1, "invalid parse_magnet_uri arguments");
      return -1;
    }
    lt::error_code ec;
    lt::add_torrent_params params = lt::parse_magnet_uri(uri, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }
    std::memset(info, 0, sizeof(lt_magnet_info));
    sha1_to_hex(params.info_hashes.v1, info->infohash_hex);
    std::strncpy(info->name, params.name.c_str(), sizeof(info->name) - 1);
    write_joined_strings(params.trackers, info->trackers,
                         static_cast<int>(sizeof(info->trackers)));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in lt_parse_magnet_uri");
    return -1;
  }
}

TORRENT_EXPORT int lt_load_torrent_file(char const *path,
                                        lt_torrent_file_info *info) {
  clear_last_error();
  try {
    if (!path || !info) {
      set_last_error(-1, "invalid load_torrent_file arguments");
      return -1;
    }
    lt::error_code ec;
    lt::torrent_info ti(path, ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }
    std::memset(info, 0, sizeof(lt_torrent_file_info));
    sha1_to_hex(ti.info_hashes().v1, info->infohash_hex);
    std::strncpy(info->name, ti.name().c_str(), sizeof(info->name) - 1);
    info->total_size = ti.total_size();
    info->num_files = ti.num_files();
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in lt_load_torrent_file");
    return -1;
  }
}

TORRENT_EXPORT int lt_create_torrent_data(char const *source_path,
                                          char const *tracker_url,
                                          int piece_size, char *dest, int len,
                                          int *required_len) {
  clear_last_error();
  try {
    if (!source_path || !required_len || len < 0) {
      set_last_error(-1, "invalid create_torrent_data arguments");
      return -1;
    }
    lt::file_storage fs;
    lt::add_files(fs, source_path);
    if (fs.num_files() == 0) {
      set_last_error(-1, "no files found for create_torrent_data");
      return -1;
    }
    lt::create_flags_t flags = {};
    lt::create_torrent torrent(fs, piece_size > 0 ? piece_size : 0, flags);
    if (tracker_url && tracker_url[0] != '\0')
      torrent.add_tracker(tracker_url);

    lt::error_code ec;
    lt::set_piece_hashes(torrent, parent_path(source_path), ec);
    if (ec) {
      set_last_error(-1, ec.message());
      return -1;
    }

    lt::entry entry = torrent.generate();
    std::vector<char> encoded;
    lt::bencode(std::back_inserter(encoded), entry);
    *required_len = static_cast<int>(encoded.size());
    if (!dest || len == 0)
      return 0;
    if (len < *required_len) {
      set_last_error(-1, "destination buffer too small for torrent data");
      return -1;
    }
    std::memcpy(dest, encoded.data(), static_cast<std::size_t>(*required_len));
    return 0;
  } catch (std::exception const &e) {
    set_last_error(-1, e.what());
    return -1;
  } catch (...) {
    set_last_error(-1, "unknown exception in lt_create_torrent_data");
    return -1;
  }
}

} // extern "C"
