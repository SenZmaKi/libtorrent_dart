# API Compatibility Status: libtorrent Dart FFI

## Scope and current reality
Compatibility is tracked against `src/c/libtorrent.h` (the package C ABI surface).
The Dart package now exposes:
- `src/libtorrent_dart_ffi.dart` for direct FFI calls
- `src/libtorrent_dart.dart` for high-level wrappers

The current state is **functionally complete for Dart FFI usage**, with variadic C functions fully represented through array-based `*_items` equivalents.

## Critical decisions
1. Keep variadic C APIs in C for native compatibility, but expose **FFI-safe array wrappers** for Dart.
2. Split Dart surface into two files:
   - `lib/src/libtorrent_dart_ffi.dart` (raw/native `@Native` bindings)
   - `lib/src/libtorrent_dart.dart` (high-level consumer API)
3. Standardize error propagation with `lt_last_error`/`lt_clear_error` and `LibtorrentException`.

## Compatibility matrix (Dart-usable surface)

### Session APIs
- [x] `session_create_items` (array wrapper for variadic create)
- [x] `session_create_default`
- [x] `session_close`
- [x] `session_add_magnet`
- [x] `session_add_torrent_items` (array wrapper for variadic add)
- [x] `session_remove_torrent`
- [x] `session_pop_alert`
- [x] `session_get_status`
- [x] `session_get_setting`
- [x] `session_set_int_setting`
- [x] `session_set_string_setting`
- [x] `session_set_settings_items` (array wrapper for variadic settings)
- [x] `session_create` via `session_create_items`
- [x] `session_add_torrent` via `session_add_torrent_items`
- [x] `session_set_settings` via `session_set_settings_items`

### Torrent APIs
- [x] `torrent_get_status`
- [x] `torrent_pause`
- [x] `torrent_resume`
- [x] `torrent_cancel`
- [x] `torrent_set_progress_callback`
- [x] `torrent_poll_progress`
- [x] `torrent_clear_progress_callback`
- [x] `torrent_get_setting`
- [x] `torrent_set_int_setting`
- [x] `torrent_set_settings_items` (array wrapper for variadic settings)
- [x] `torrent_set_settings` via `torrent_set_settings_items`

### Error propagation
- [x] `lt_last_error`
- [x] `lt_clear_error`
- [x] Dart exception mapping (`LibtorrentException`)

## Test coverage status
Current tests cover:
- direct raw FFI invocation for all exported non-variadic methods plus variadic-equivalent array wrappers
- progress callback flow
- pause/resume/cancel
- session/torrent status and setting getters
- array-wrapper paths for add_torrent and settings
- proxy setting APIs via public session setters
- native validation failure propagation through `LibtorrentException`

Literal vararg ABI calls are intentionally not invoked from Dart (FFI limitation), and parity is provided through the `*_items` wrappers above.

## Memory management sweep
- Executed malloc ownership audit on Dart and C bridge allocations (`calloc`/`free`, `new`/`delete`) and verified paired ownership paths in bridge code.
- Attempted runtime leak tooling (`leaks`, ASAN/LSAN) in this environment; both are blocked by platform/debug policy constraints for this process model.
