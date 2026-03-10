// ignore_for_file: non_constant_identifier_names, library_private_types_in_public_api
@DefaultAsset('package:libtorrent_dart/src/libtorrent_dart.dart')
library;

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Native function bindings — the Dart SDK resolves all of these to the
// pre-built binary declared in hook/build.dart via the @DefaultAsset above.
// ─────────────────────────────────────────────────────────────────────────────

@Native<Pointer<Void> Function()>()
external Pointer<Void> session_create_default();

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

@Native<
  Int32 Function(
    Int32,
    Pointer<NativeFunction<_ProgressCallbackC>>,
    Pointer<Void>,
  )
>()
external int torrent_set_progress_callback(
  int torrentId,
  Pointer<NativeFunction<_ProgressCallbackC>> callback,
  Pointer<Void> userdata,
);

@Native<Int32 Function(Int32)>()
external int torrent_poll_progress(int torrentId);

@Native<Void Function(Int32)>()
external void torrent_clear_progress_callback(int torrentId);

@Native<Int32 Function(Int32, Int32, Int32)>()
external int torrent_set_int_setting(int torrentId, int tag, int value);

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

class LibtorrentSettingsTag {
  LibtorrentSettingsTag._();

  static const int uploadRateLimit = 0x4000 + 54;
  static const int downloadRateLimit = 0x4000 + 55;
  static const int connectionsLimit = 0x4000 + 97;
  static const int unchokeSlotsLimit = 0x4000 + 73;
  static const int alertMask = 0x4000 + 260;

  static const int proxyType = 0x4000 + 294;
  static const int proxyPort = 0x4000 + 295;
  static const int proxyHostname = 0x0000 + 5;
  static const int proxyUsername = 0x0000 + 6;
  static const int proxyPassword = 0x0000 + 7;
}

class LibtorrentSettingType {
  LibtorrentSettingType._();

  static const int intType = 0x300;
  static const int boolType = 0x301;
  static const int stringType = 0x302;
}

Session createSession() {
  final handle = session_create_default();
  if (handle == nullptr) {
    throw StateError('Failed to create session');
  }
  return Session._(handle);
}

class Session {
  Session._(this._handle);

  final Pointer<Void> _handle;

  TorrentHandle addMagnet({
    required String magnetUri,
    required String savePath,
    int downloadRateLimit = 0,
    int uploadRateLimit = 0,
  }) {
    final magnetPtr = magnetUri.toNativeUtf8(allocator: calloc);
    final pathPtr = savePath.toNativeUtf8(allocator: calloc);
    final tor = session_add_magnet(
      _handle,
      magnetPtr.cast<Char>(),
      pathPtr.cast<Char>(),
      downloadRateLimit,
      uploadRateLimit,
    );
    calloc.free(magnetPtr);
    calloc.free(pathPtr);
    if (tor < 0) {
      throw StateError('Failed to add magnet');
    }
    return TorrentHandle._(_handle, tor);
  }

  void close() {
    session_close(_handle);
  }

  int setIntSetting(int tag, int value) {
    return session_set_int_setting(
      _handle,
      LibtorrentSettingType.intType,
      tag,
      value,
    );
  }

  int setBoolSetting(int tag, bool value) {
    return session_set_int_setting(
      _handle,
      LibtorrentSettingType.boolType,
      tag,
      value ? 1 : 0,
    );
  }

  int setStringSetting(int tag, String value) {
    final valuePtr = value.toNativeUtf8(allocator: calloc);
    final result = session_set_string_setting(
      _handle,
      LibtorrentSettingType.stringType,
      tag,
      valuePtr.cast<Char>(),
    );
    calloc.free(valuePtr);
    return result;
  }
}

class TorrentHandle {
  TorrentHandle._(this._sessionHandle, this.id);

  final Pointer<Void> _sessionHandle;
  final int id;

  StreamSubscription<TorrentStatus> listenProgress({
    required void Function(TorrentStatus status) onData,
    Duration interval = const Duration(seconds: 1),
  }) {
    final callback = Pointer.fromFunction<_ProgressCallbackC>(_progressThunk);
    final userdata = _registerCallback(id, onData);
    final rc = torrent_set_progress_callback(id, callback, userdata);
    if (rc != 0) {
      _unregisterCallback(id);
      throw StateError('Failed to set progress callback');
    }

    return _ProgressSubscription._(
      interval,
      () => torrent_poll_progress(id),
      () {
        torrent_clear_progress_callback(id);
        _unregisterCallback(id);
      },
    );
  }

  void pause() {
    torrent_pause(id);
  }

  void resume() {
    torrent_resume(id);
  }

  void cancel({bool deleteFiles = true}) {
    torrent_cancel(_sessionHandle, id, deleteFiles ? 1 : 0);
  }

  int setIntSetting(int tag, int value) {
    return torrent_set_int_setting(id, tag, value);
  }
}

class TorrentStatus {
  TorrentStatus({
    required this.progress,
    required this.downloadRate,
    required this.uploadRate,
    required this.totalDone,
    required this.totalWanted,
    required this.state,
    required this.paused,
    required this.error,
  });

  final double progress;
  final double downloadRate;
  final double uploadRate;
  final int totalDone;
  final int totalWanted;
  final int state;
  final bool paused;
  final String error;
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress callback plumbing
// ─────────────────────────────────────────────────────────────────────────────

typedef _ProgressCallbackC =
    Void Function(Int32, Pointer<_TorrentStatusNative>, Pointer<Void>);

final Map<int, void Function(TorrentStatus)> _progressHandlers = {};

Pointer<Void> _registerCallback(int tor, void Function(TorrentStatus) handler) {
  _progressHandlers[tor] = handler;
  return Pointer.fromAddress(tor);
}

void _unregisterCallback(int tor) {
  _progressHandlers.remove(tor);
}

void _progressThunk(
  int tor,
  Pointer<_TorrentStatusNative> statusPtr,
  Pointer<Void> userdata,
) {
  final handler = _progressHandlers[tor];
  if (handler == null) return;
  final status = statusPtr.ref;
  handler(
    TorrentStatus(
      progress: status.progress,
      downloadRate: status.download_rate,
      uploadRate: status.upload_rate,
      totalDone: status.total_done,
      totalWanted: status.total_wanted,
      state: status.state,
      paused: status.paused != 0,
      error: _int8ArrayToString(status.error, 1024),
    ),
  );
}

final class _TorrentStatusNative extends Struct {
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

String _int8ArrayToString(Array<Int8> array, int length) {
  final codeUnits = <int>[];
  for (var i = 0; i < length; i++) {
    final value = array[i];
    if (value == 0) break;
    codeUnits.add(value);
  }
  return String.fromCharCodes(codeUnits);
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress subscription
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressSubscription implements StreamSubscription<TorrentStatus> {
  _ProgressSubscription._(this._interval, this._poll, this._onCancel)
    : _timer = Timer.periodic(_interval, (_) => _poll());

  final Duration _interval;
  final void Function() _poll;
  final void Function() _onCancel;
  Timer _timer;

  @override
  Future<void> cancel() async {
    _timer.cancel();
    _onCancel();
  }

  @override
  void onData(void Function(TorrentStatus data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {
    _timer.cancel();
  }

  @override
  void resume() {
    if (_timer.isActive) return;
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  @override
  bool get isPaused => !_timer.isActive;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future<E>.value(futureValue);
}
