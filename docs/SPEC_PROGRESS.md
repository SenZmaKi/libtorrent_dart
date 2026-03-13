# LIBTORRENT API Spec Progress

This tracks progress against `docs/LIBTORRENT_API_SPEC.md` for the currently implemented C shim (`src/c/libtorrent.h` + `src/c/library.cpp`), Dart FFI bindings, and high-level Dart wrapper.

## Coverage Table

| Spec Area | Status | Implemented in this repo | Not Implemented / Notes |
|---|---|---|---|
| Session lifecycle | Partial | `session_create_default`, `session_create_items`, `session_close`, `session_get_status` | Full C++ constructor/flags matrix is not exposed as-is; Dart uses FFI-safe item APIs |
| Session control | Partial | `session_pause`, `session_resume`, `session_is_paused` | No async `abort/session_proxy` equivalent |
| Session torrent management | Partial | `session_add_magnet`, `session_add_torrent_items`, `session_remove_torrent` | `find_torrent`, `get_torrents`, filtered `get_torrent_status` not exposed |
| Session settings | Partial | `session_get_setting`, `session_set_int_setting`, `session_set_string_setting`, `session_set_settings_items` | Variadic `session_set_settings` available in C ABI but consumed in Dart via item-based wrappers |
| Session alerts/stats posting | Partial | `session_pop_alert`, `session_post_torrent_updates`, `session_post_session_stats`, `session_post_dht_stats` | Rich typed alert hierarchy is not exposed; currently message/category pop model |
| Torrent status/info | Partial | `torrent_get_status`, progress callback APIs | Peer list, tracker list, file queue/status APIs are not exposed |
| Torrent control | Partial | `torrent_pause`, `torrent_resume`, `torrent_cancel`, `torrent_flush_cache`, `torrent_force_recheck`, `torrent_force_reannounce`, `torrent_force_dht_announce`, `torrent_scrape_tracker`, `torrent_clear_error` | Flag-rich variants are not fully surfaced |
| Torrent settings/limits | Partial | `torrent_get_setting`, `torrent_set_int_setting`, `torrent_set_settings_items` | Piece/file priority APIs and deadlines not exposed |
| Queue management | Partial | `torrent_queue_position_up/down/top/bottom/set/get` | Full queue/state orchestration remains limited to basic position operations |
| DHT operations | Partial | `session_post_dht_stats`, `torrent_force_dht_announce` | General DHT item/get/put/announce/node APIs are not exposed |
| Tracker management | Partial | `torrent_scrape_tracker` | Add/replace trackers + web seed management not exposed |
| File/storage APIs | Not implemented | — | `file_storage`, file progress/status, storage backends are not wrapped |
| Peer management APIs | Not implemented | — | `peer_info`, peer classes, peer connection operations not wrapped |
| Utility/version helpers | Not implemented | — | Spec utility helpers (`version()`, `parse_magnet_uri`, create/write/read resume-data utilities) are not wrapped directly |

## Nuances Observed During Implementation

1. The Dart FFI layer cannot safely call C variadic functions, so parity is provided through explicit `*_items` APIs in the shim.
2. The upstream libtorrent C++ API is much broader than a practical stable C ABI; this project intentionally maintains a narrower C shim surface and maps high-value operations first.
3. Alert handling currently prioritizes a simple pull model (`message + category`) rather than exposing all 50+ typed alert payloads.
4. Queue position and some control APIs are exposed as lightweight int-based wrappers to keep the C ABI stable across language boundaries.
5. Source layout was modularized in Dart (`lib/src/ffi/*`, `lib/src/high_level/*`) and tests (`test/*_session_*`, `*_torrent_*`, `*_ffi_*`) so each layer mirrors concrete responsibility boundaries.
