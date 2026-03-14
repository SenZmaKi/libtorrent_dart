/// High-level Dart bindings for [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).
///
/// Exposes a Session/TorrentHandle API with settings, progress callbacks,
/// pause/resume/cancel, DHT, and torrent-file utilities.
///
/// For direct FFI access to the underlying C functions and structs see
/// `package:libtorrent_dart/libtorrent_dart_ffi.dart`.
library;

export 'src/libtorrent_dart.dart';
