# libtorrent API Port Coverage (Spec vs Current Port)

This document compares the holistic C++ API described in `docs/LIBTORRENT_API_SPEC.md` (libtorrent 2.0.11) against the current `libtorrent_dart` port.

## How this comparison was done

- **Baseline spec**: `docs/LIBTORRENT_API_SPEC.md` (272 headers, 50+ classes/structs, 100+ methods, 200+ settings).
- **Current implementation surface**:
  - C shim: `src/c/libtorrent.h`
  - Raw Dart FFI: `lib/src/ffi/native_functions.dart`, `lib/src/ffi/native_structs.dart`
  - High-level Dart API: `lib/src/high_level/session.dart`, `lib/src/high_level/torrent_handle.dart`, `lib/src/high_level/models.dart`, `lib/src/high_level/tags.dart`

Legend:

- **Migrated**: implemented and callable in current port.
- **Partially migrated**: available but reduced semantics/coverage versus C++ API.
- **Not migrated**: missing from current C shim and Dart API.

---

## Executive summary

- The current port is **not a full C++ API mirror**; it is a **targeted C shim + Dart wrapper** focused on common session/torrent control paths.
- Broadly:
  - **Core session lifecycle, torrent control, alerts, DHT basics, trackers, resume/state I/O, status structs**: largely migrated.
  - **Advanced C++ objects and ecosystems** (full `settings_pack`, `file_storage`, full alert type hierarchy, peer class management, port mapping APIs, IP/port filters, BEP52-rich data structures, many utility/header domains): not migrated.
- Quantitatively (surface size only):
  - `docs/LIBTORRENT_API_SPEC.md`: documents **272 headers** and a holistic API.
  - `src/c/libtorrent.h`: **~114 exported C shim functions**.
  - `lib/src/ffi/native_functions.dart`: **110 FFI extern bindings**.

---

## Detailed coverage by major spec section

## 1) Session Management (`session`, `session_handle`, `session_proxy`)

### Migrated

- Session lifecycle:
  - create/close/abort via `createSession`, `createSessionFromTags`, `createSessionFromState`, `Session.close()`, `Session.abort()`, `SessionProxy.close()`
- Torrent management from session:
  - add magnet / add via tags / async add / remove
  - find torrent, list torrents, list torrent statuses (with and without flags)
- Session control:
  - `pause`, `resume`, `isPaused`
- Alert polling basics:
  - `popAlert`, `popAlerts`, `waitForAlert`, `popAlertInfo`, `popAlertInfoLegacy`
- Stats posting:
  - `postTorrentUpdates`, `postSessionStats`, `postDhtStats`
- Listen ports:
  - `listenPort`, `sslListenPort`
- DHT core:
  - start/stop/is running, get peers, announce, add node, get/put item, sample infohashes
- DHT and discovery settings (client-facing):
  - DHT upload rate limit, announce interval, max peers, max DHT items
  - enable/disable DHT, LSD, UPnP, NAT-PMP
- Session limit controls (client-facing):
  - upload/download rate limit
  - connections limit and unchoke slots limit
- Session state serialization:
  - `getState(flags)` and restore-from-state constructor

### Partially migrated

- `apply_settings(settings_pack)` equivalent exists only through tag-based setting APIs and scalar getters/setters.
- Alert interaction is primarily message/type/category based; full typed C++ alert object ecosystem is not exposed.
- DHT APIs support core immutable item paths and sampling, but not full mutable-item callback signature semantics from C++.

### Not migrated

- `session_handle` parity as a distinct non-owning handle type.
- `set_alert_notify()` callback model.
- Peer class management (`create_peer_class`, `set_peer_class`, etc.).
- Port mapping APIs (`add_port_mapping`, `delete_port_mapping`) from the spec.
- IP/port filter management at session level (`set_ip_filter`, `get_ip_filter`, `set_port_filter`).
- Session key/peer-id APIs (`set_key`, `key`, `set_peer_id`, `id`).
- Structured `dht_settings` object APIs (`set_dht_settings` / `get_dht_settings`) and full `dht_state` setters.

---

## 2) Torrent Operations (`torrent_handle`)

### Migrated

- Status and update posting:
  - `getStatus`, `postDownloadQueue`, `postPeerInfo`, `postTrackers`
- Piece operations:
  - `havePiece`, `readPiece`, `addPiece`
- Resume data:
  - `saveResumeData`, `getResumeData`, `needSaveResumeData`
- Control:
  - `pause`, `resume`, `setFlags`, `setFlagsWithMask`, `unsetFlags`, `flags`
  - `flushCache`, `forceRecheck`, `forceDhtAnnounce`
  - `forceLsdAnnounce`, `forceReannounce`, `forceReannounceWithFlags`, `scrapeTracker`
  - `clearPeers`
  - explicit per-torrent limits: upload/download limits, max uploads, max connections
- Tracker/web seed management:
  - `addTracker`, `replaceTrackers`, `getTrackers`
  - `add/remove URL seed`, `add/remove HTTP seed`, getters for both seed lists
- Piece deadlines:
  - set/reset/clear
- Priorities:
  - file and piece set/get + batch prioritize + batch read
- Queue position:
  - up/down/top/bottom/set/get
- Peer connect:
  - `connectPeer(address, port)`
- Data extraction:
  - download queue, peer info, file progress, file status, file entries
- Progress callback bridge:
  - `listenProgress(...)` through C callback + polling

### Partially migrated

- `connect_peer` in C++ supports source/PEX flag richness; current API is simplified address+port only.
- String-list tracker/seed access is newline-encoded text bridge, not rich C++ tracker structs.
- `getFiles()` returns reduced file entry shape from shim struct, not full `torrent_info`/`file_storage` capabilities.
- Torrent settings are tag/scalar based, not full C++ typed settings objects.

### Not migrated

- `torrent_file()` / `torrent_file_with_hashes()` object APIs.
- peer class assignment on torrent handle.
- Metadata injection (`set_metadata`) and `is_valid()/in_session()` semantics as C++ handle introspection.
- Info-hash typed APIs (`info_hash`, `info_hashes`) on `TorrentHandle`.
- Comparison/hash operators are naturally absent in Dart wrapper form.

---

## 3) Alert System

### Migrated

- Alert polling and waiting (message + category).
- Typed alert bridge with:
  - `type`, `category`, `what`, `message`, `torrentId`
  - DHT sample payload extraction (`dhtSamples`, endpoint host/port).

### Partially migrated

- Only a compact alert representation is exposed.
- The spec’s broad typed alert class hierarchy (30+ alert types with rich per-type fields) is not represented as Dart type hierarchy.

### Not migrated

- Full `alert` subclass model from `alert_types.hpp`.
- Timestamp and many per-alert structured payload fields across all alert families.

---

## 4) Settings & Configuration (`settings_pack`)

### Migrated

- Core set/get pathways:
  - `session_get_setting`, `session_set_int_setting`, `session_set_string_setting`
  - high-level helpers `getIntSetting/getStringSetting/getBoolSetting`
  - tag-item batch application (`setSettingsFromTags`)
- Torrent-scope equivalents:
  - `torrent_get_setting`, `torrent_set_int_setting`, `torrent_set_settings_items`
- Common setting tags/constants exposed in `LibtorrentSettingsTag` and `LibtorrentTag`.
- Proxy configuration bridge:
  - peer/web seed/tracker/DHT/general proxy setters using `ProxySetting`.

### Partially migrated

- Only a **small subset** of `settings_pack` int/bool/string settings is represented by constants/helpers.
- Tag-based API provides flexibility but not full typed parity with all spec enums and helper methods.

### Not migrated

- Full `settings_pack` enum universe (200+ settings) and complete typed interface.
- Many advanced protocol/network/disk/utp/algorithm toggles documented in spec remain unrepresented.
- Getter APIs for structured proxy objects (`peer_proxy()`, `web_seed_proxy()`, etc.) are not exposed.

---

## 5) File & Storage (`file_storage`, storage defs)

### Migrated

- Read-only runtime-ish file data from a torrent via shim:
  - file progress, open file status, file entries (`index/size/offset/flags/path`).
- Storage mode constants exist (`LibtorrentStorageMode` allocate/sparse).

### Partially migrated

- File information access is indirect and limited to shim-exposed snapshots.

### Not migrated

- `file_storage` class API (num files, map file, add/rename file, hash/symlink/mtime, iterators, piece mapping).
- Allocation mode APIs and broader storage definitions as first-class objects.

---

## 6) Peer Management (`peer_info`, peer connection interface)

### Migrated

- Peer info retrieval (`getPeerInfo`) with key fields:
  - endpoint, client string, speeds, totals, flags, source.
- Basic direct peer connection (`connectPeer`).

### Partially migrated

- `peer_info` is reduced to a compact struct. Many advanced fields from spec are absent (bitfields, queue internals, RTT/peaks, endpoints, progress ppm, etc.).

### Not migrated

- `bt_peer_connection_handle` interface (`send_have`, `send_suggest`, `send_dht_port`, etc.).
- Rich peer-class interaction across session/torrent dimensions.

---

## 7) Tracker Management (`announce_entry`, endpoints)

### Migrated

- Add/replace trackers.
- Trigger scrape/reannounce.
- Fetch tracker URLs as string list.

### Partially migrated

- Tracker metadata is string-level only; no structured `announce_entry`/`announce_endpoint` model is exposed.

### Not migrated

- Rich tracker state fields (fail counters, next announce times, endpoint stats, messages, errors, tier lifecycle methods).

---

## 8) DHT Operations

### Migrated

- Core operational API:
  - start/stop/running
  - get peers / announce
  - add node
  - immutable get/put style item bridge
  - sample infohashes

### Partially migrated

- Mutable-item callback workflows and richer typed DHT state/settings from C++ are not surfaced as equivalent Dart callbacks/types.

### Not migrated

- Full `dht_state` object management parity.
- Full mutable item signing callback semantics as in C++ API.
- Additional DHT settings object controls.

---

## 9) Network & Connectivity

### Migrated

- Proxy basics (host/port/user/pass/type) through tag+struct bridge.
- Listen port querying (`listenPort`, `sslListenPort`).

### Partially migrated

- Proxy type support is present but reduced compared to spec’s full option set and behavior flags.

### Not migrated

- Address/address_v4/address_v6 type APIs.
- `ip_filter` object API and export/access operations.
- Port filter object API.
- Port mapping protocol/transport APIs.
- Full proxy behavior booleans (`proxy_hostnames`, `proxy_peer_connections`, etc.) and I2P proxy type semantics.

---

## 10) Data Structures (`add_torrent_params`, `torrent_status`, `session_status`)

### Migrated

- `torrent_status` and `session_status` are bridged with substantial field coverage in native structs + Dart models.
- Add-torrent behavior is supported via tag-item pattern and helper methods (`addTorrentFile`, `addTorrentData`, `addTorrentFromTags`).

### Partially migrated

- `add_torrent_params` is represented procedurally (tags/items), not as a full typed object with all spec fields.
- `torrent_status`/`session_status` cover many core counters but not all spec fields (e.g., several timing/UTP/disk and extended state fields).

### Not migrated

- Full rich `add_torrent_params` object model including BEP52-heavy and advanced fields.
- Complete `torrent_status` superset fields from C++ object model.
- Extra `session_status` fields (notably UTP and disk queues from spec) beyond shim struct.

---

## Enumerations & constants coverage

### Migrated

- Key enums/flags represented in `tags.dart`:
  - torrent state
  - storage mode (basic)
  - alert categories
  - torrent flags (subset-like mapping)
  - remove flags
  - proxy types
  - major tag constants for session/torrent/settings shim

### Partially migrated

- Some flags in spec have conceptual support via integer arguments (e.g., status flags, reannounce flags), but not all are first-class typed constants in Dart.

### Not migrated

- Many enum families are absent as dedicated Dart constants/types:
  - pause flags, deadline flags, full resume-data flags set, full save-state flags set
  - full port mapping protocol/transport constants
  - full peer source and PEX flag sets as first-class surfaced API (only reduced `source` integer in peer info)

---

## Utility functions coverage

### Migrated

- Magnet:
  - parse magnet (`lt_parse_magnet_uri`)
  - make magnet URI from torrent (`lt_make_magnet_uri`)
- Torrent file:
  - load torrent file (`lt_load_torrent_file`)
  - create torrent data and file (`lt_create_torrent_data`, `createTorrentFile`)
- Version:
  - `lt_version` exposed via `getLibtorrentVersion()`
- Resume data bridge:
  - save/get/need resume data per torrent handle path

### Partially migrated

- Utility APIs generally return simplified structs/bytes rather than full C++ object graphs (`add_torrent_params`, `entry`, bdecode trees).

### Not migrated

- Full C++ `load_torrent_buffer`, `load_torrent_parsed`, and broader bdecode-node based workflows.
- Full `create_torrent` class surface (flags, hash setters, metadata richness).
- Full typed read/write resume-data utilities (`read_resume_data`, `write_resume_data`) at the C++ object level.

---

## Header inventory domains from the spec vs current port

The spec’s header inventory spans many domains. Current port status by domain:

- **Core Session & Torrent Management**: **Partially migrated** (strong core control path).
- **Status & Information**: **Partially migrated** (core counters yes; full richness no).
- **Alerts & Events**: **Partially migrated** (polling/typed subset).
- **Settings & Configuration**: **Partially migrated** (subset + tag bridge).
- **File & Storage**: **Partially migrated** (limited file snapshots; no `file_storage` API).
- **Torrent File Operations**: **Partially migrated** (file load/create basics present).
- **Peer Management**: **Partially migrated** (core peer list + connect; no advanced handles).
- **Network & Connectivity**: **Mostly not migrated** (proxy basics only).
- **Trackers & Discovery**: **Partially migrated** (URL-level tracker ops).
- **DHT**: **Partially migrated** (core operational subset).
- **Hashing & Cryptography**: **Mostly not migrated**.
- **Data Encoding**: **Mostly not migrated**.
- **Piece Management**: **Partially migrated** (piece read/add/have/priorities/deadlines).
- **Utilities & Support**: **Partially migrated** (selected helpers only).
- **Extensions**: **Not migrated**.

---

## Practical interpretation

If your target is:

- **Common torrent client operations in Dart** (session lifecycle, add/remove torrents, status, alerts, trackers, DHT basics, priorities, resume/state): current port already covers a substantial subset.
- **Holistic libtorrent C++ API parity** (all objects/enums/settings/headers and rich typed semantics): current port is **far from complete** and would need significant shim + Dart surface expansion.
