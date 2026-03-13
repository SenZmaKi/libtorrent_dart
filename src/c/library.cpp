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
#include "libtorrent/hex.hpp"
#include "libtorrent/magnet_uri.hpp"
#include "libtorrent/session.hpp"
#include "libtorrent/session_params.hpp"
#include "libtorrent/session_status.hpp"
#include "libtorrent/settings_pack.hpp"
#include "libtorrent/torrent_handle.hpp"
#include "libtorrent/torrent_status.hpp"

#include <algorithm>
#include <cstdio>
#include <cstring>
#include <exception>
#include <libtorrent.h>
#include <new>
#include <stdarg.h>
#include <string>
#include <vector>


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
          set_last_error(-1, ec.message());
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
        lt::from_hex(item.string_value, 40,
                     reinterpret_cast<char *>(ih.data()));
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
      params.ti.reset(new (std::nothrow)
                          torrent_info(torrent_data, torrent_size, ec));
      if (ec) {
        set_last_error(-1, ec.message());
        return -1;
      }
    }
    if (resume_data && resume_size > 0) {
      params.resume_data.assign(resume_data, resume_data + resume_size);
    }
    if (magnet_url) {
      parse_magnet_uri(magnet_url, params, ec);
      if (ec) {
        set_last_error(-1, ec.message());
        return -1;
      }
    }

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

TORRENT_EXPORT int torrent_get_status(int tor, torrent_status *s,
                                      int struct_size) {
  clear_last_error();
  lt::torrent_handle h = get_handle(tor);
  if (!h.is_valid()) {
    set_last_error(-1, "invalid torrent handle");
    return -1;
  }

  lt::torrent_status ts = h.status();

  if (struct_size != sizeof(torrent_status))
    return -1;

  s->state = (state_t)ts.state;
  s->paused = (ts.flags & lt::torrent_flags::paused) ? 1 : 0;
  s->progress = ts.progress;
  strncpy(s->error, ts.errc ? ts.errc.message().c_str() : "",
          sizeof(s->error) - 1);
  s->error[sizeof(s->error) - 1] = '\0';
  s->next_announce = int(lt::total_seconds(ts.next_announce));
  s->announce_interval = 0;
  strncpy(s->current_tracker, ts.current_tracker.c_str(),
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
  //	s->storage_mode = (storage_mode_t)ts.storage_mode;
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

} // extern "C"
