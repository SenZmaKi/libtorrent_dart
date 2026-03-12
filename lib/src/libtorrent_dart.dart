import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'libtorrent_dart_ffi.dart' as ffi;

class LibtorrentException implements Exception {
  LibtorrentException(this.message, {this.code = 0});
  final String message;
  final int code;

  @override
  String toString() => 'LibtorrentException(code: $code, message: $message)';
}

class AlertMessage {
  AlertMessage({required this.message, required this.category});
  final String message;
  final int category;
}

class SessionStatus {
  SessionStatus({
    required this.hasIncomingConnections,
    required this.uploadRate,
    required this.downloadRate,
    required this.totalDownload,
    required this.totalUpload,
    required this.numPeers,
  });

  final bool hasIncomingConnections;
  final double uploadRate;
  final double downloadRate;
  final int totalDownload;
  final int totalUpload;
  final int numPeers;
}

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

class LibtorrentTag {
  LibtorrentTag._();

  static const int sesListenPort = 1;
  static const int sesListenPortEnd = 2;
  static const int sesAlertMask = 8;
  static const int sesListenInterface = 9;

  static const int torMagnetLink = 0x100 + 5;
  static const int torSavePath = 0x100 + 9;
  static const int setUploadRateLimit = 0x200;
  static const int setDownloadRateLimit = 0x200 + 1;
  static const int setMaxUploadSlots = 0x200 + 4;
  static const int setMaxConnections = 0x200 + 5;
  static const int setAlertMask = 0x200 + 14;
}

class LibtorrentTagItem {
  const LibtorrentTagItem._({
    required this.tag,
    this.intValue = 0,
    this.stringValue,
    this.bytesValue,
    this.pointerValue,
    this.size = 0,
  });

  final int tag;
  final int intValue;
  final String? stringValue;
  final Uint8List? bytesValue;
  final Pointer<Void>? pointerValue;
  final int size;

  factory LibtorrentTagItem.intValue(int tag, int value) =>
      LibtorrentTagItem._(tag: tag, intValue: value);
  factory LibtorrentTagItem.stringValue(int tag, String value) =>
      LibtorrentTagItem._(tag: tag, stringValue: value);
  factory LibtorrentTagItem.bytesValue(int tag, Uint8List value) =>
      LibtorrentTagItem._(tag: tag, bytesValue: value, size: value.length);
  factory LibtorrentTagItem.pointerValue(
    int tag,
    Pointer<Void> value, {
    int size = 0,
  }) => LibtorrentTagItem._(tag: tag, pointerValue: value, size: size);
}

class TorrentFlag {
  TorrentFlag._();

  static const int seedMode = 1 << 0;
  static const int uploadMode = 1 << 1;
  static const int shareMode = 1 << 2;
  static const int applyIpFilter = 1 << 3;
  static const int paused = 1 << 4;
  static const int autoManaged = 1 << 5;
  static const int duplicateIsError = 1 << 6;
  static const int updateSubscribe = 1 << 7;
  static const int superSeeding = 1 << 8;
  static const int sequentialDownload = 1 << 9;
  static const int stopWhenReady = 1 << 10;
  static const int overrideTrackers = 1 << 11;
  static const int overrideWebSeeds = 1 << 12;
  static const int disableDht = 1 << 19;
  static const int disableLsd = 1 << 20;
  static const int disablePex = 1 << 21;
  static const int noVerifyFiles = 1 << 22;
  static const int defaultDontDownload = 1 << 23;
}

Session createSession() {
  final handle = ffi.session_create_default();
  if (handle == nullptr) {
    _throwLastError('Failed to create session');
  }
  return Session._(handle);
}

Session createSessionFromTags(List<LibtorrentTagItem> items) {
  final marshaled = _marshalTagItems(items);
  try {
    ffi.lt_clear_error();
    final handle = ffi.session_create_items(marshaled.items, items.length);
    if (handle == nullptr) {
      _throwLastError('Failed to create session from tags');
    }
    return Session._(handle);
  } finally {
    marshaled.dispose();
  }
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
    final tor = ffi.session_add_magnet(
      _handle,
      magnetPtr.cast<Char>(),
      pathPtr.cast<Char>(),
      downloadRateLimit,
      uploadRateLimit,
    );
    calloc.free(magnetPtr);
    calloc.free(pathPtr);
    if (tor < 0) {
      _throwLastError('Failed to add magnet');
    }
    return TorrentHandle._(_handle, tor);
  }

  TorrentHandle addTorrentFromTags(List<LibtorrentTagItem> items) {
    final marshaled = _marshalTagItems(items);
    try {
      final tor = ffi.session_add_torrent_items(
        _handle,
        marshaled.items,
        items.length,
      );
      if (tor < 0) {
        _throwLastError('Failed to add torrent from tags');
      }
      return TorrentHandle._(_handle, tor);
    } finally {
      marshaled.dispose();
    }
  }

  SessionStatus getStatus() {
    final status = calloc<ffi.SessionStatusNative>();
    try {
      final rc = ffi.session_get_status(
        _handle,
        status,
        sizeOf<ffi.SessionStatusNative>(),
      );
      if (rc != 0) {
        _throwLastError('Failed to read session status');
      }
      return SessionStatus(
        hasIncomingConnections: status.ref.has_incoming_connections != 0,
        uploadRate: status.ref.upload_rate,
        downloadRate: status.ref.download_rate,
        totalDownload: status.ref.total_download,
        totalUpload: status.ref.total_upload,
        numPeers: status.ref.num_peers,
      );
    } finally {
      calloc.free(status);
    }
  }

  AlertMessage? popAlert() {
    final category = calloc<Int32>();
    final buf = calloc<Int8>(4096);
    try {
      final rc = ffi.session_pop_alert(
        _handle,
        buf.cast<Char>(),
        4096,
        category,
      );
      if (rc < 0) return null;
      return AlertMessage(
        message: buf.cast<Utf8>().toDartString(),
        category: category.value,
      );
    } finally {
      calloc.free(category);
      calloc.free(buf);
    }
  }

  int getIntSetting(int tag) {
    final value = calloc<Int32>();
    final size = calloc<Int32>()..value = sizeOf<Int32>();
    try {
      final rc = ffi.session_get_setting(
        _handle,
        tag,
        value.cast<Void>(),
        size,
      );
      if (rc != 0) {
        _throwLastError('Failed to get session setting');
      }
      return value.value;
    } finally {
      calloc.free(value);
      calloc.free(size);
    }
  }

  int setIntSetting(int tag, int value) {
    final rc = ffi.session_set_int_setting(
      _handle,
      LibtorrentSettingType.intType,
      tag,
      value,
    );
    if (rc != 0) {
      _throwLastError('Failed to set int setting');
    }
    return rc;
  }

  int setBoolSetting(int tag, bool value) {
    final rc = ffi.session_set_int_setting(
      _handle,
      LibtorrentSettingType.boolType,
      tag,
      value ? 1 : 0,
    );
    if (rc != 0) {
      _throwLastError('Failed to set bool setting');
    }
    return rc;
  }

  int setStringSetting(int tag, String value) {
    final valuePtr = value.toNativeUtf8(allocator: calloc);
    final result = ffi.session_set_string_setting(
      _handle,
      LibtorrentSettingType.stringType,
      tag,
      valuePtr.cast<Char>(),
    );
    calloc.free(valuePtr);
    if (result != 0) {
      _throwLastError('Failed to set string setting');
    }
    return result;
  }

  void setSettingsFromTags(List<LibtorrentTagItem> items) {
    final marshaled = _marshalTagItems(items);
    try {
      final rc = ffi.session_set_settings_items(
        _handle,
        marshaled.items,
        items.length,
      );
      if (rc != 0) {
        _throwLastError('Failed to set session settings from tags');
      }
    } finally {
      marshaled.dispose();
    }
  }

  void removeTorrent(TorrentHandle torrent, {bool deleteFiles = true}) {
    ffi.session_remove_torrent(_handle, torrent.id, deleteFiles ? 1 : 0);
  }

  void close() {
    ffi.session_close(_handle);
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
    final callback = Pointer.fromFunction<ffi.ProgressCallbackC>(
      _progressThunk,
    );
    final userdata = _registerCallback(id, onData);
    final rc = ffi.torrent_set_progress_callback(id, callback, userdata);
    if (rc != 0) {
      _unregisterCallback(id);
      _throwLastError('Failed to set progress callback');
    }

    return _ProgressSubscription._(
      interval,
      () => ffi.torrent_poll_progress(id),
      () {
        ffi.torrent_clear_progress_callback(id);
        _unregisterCallback(id);
      },
    );
  }

  void pause({bool graceful = false}) {
    if (ffi.torrent_pause(id, graceful ? 1 : 0) != 0) {
      _throwLastError('Failed to pause torrent');
    }
  }

  void resume() {
    if (ffi.torrent_resume(id) != 0) {
      _throwLastError('Failed to resume torrent');
    }
  }

  void cancel({bool deleteFiles = true}) {
    if (ffi.torrent_cancel(_sessionHandle, id, deleteFiles ? 1 : 0) != 0) {
      _throwLastError('Failed to cancel torrent');
    }
  }

  int setIntSetting(int tag, int value) {
    final rc = ffi.torrent_set_int_setting(id, tag, value);
    if (rc != 0) {
      _throwLastError('Failed to set torrent int setting');
    }
    return rc;
  }

  void setSettingsFromTags(List<LibtorrentTagItem> items) {
    final marshaled = _marshalTagItems(items);
    try {
      final rc = ffi.torrent_set_settings_items(
        id,
        marshaled.items,
        items.length,
      );
      if (rc != 0) {
        _throwLastError('Failed to set torrent settings from tags');
      }
    } finally {
      marshaled.dispose();
    }
  }

  TorrentStatus getStatus() {
    final status = calloc<ffi.TorrentStatusNative>();
    try {
      final rc = ffi.torrent_get_status(
        id,
        status,
        sizeOf<ffi.TorrentStatusNative>(),
      );
      if (rc != 0) {
        _throwLastError('Failed to get torrent status');
      }
      return _mapStatus(status.ref);
    } finally {
      calloc.free(status);
    }
  }

  int getIntSetting(int tag) {
    final value = calloc<Int32>();
    final size = calloc<Int32>()..value = sizeOf<Int32>();
    try {
      final rc = ffi.torrent_get_setting(id, tag, value.cast<Void>(), size);
      if (rc != 0) {
        _throwLastError('Failed to get torrent setting');
      }
      return value.value;
    } finally {
      calloc.free(value);
      calloc.free(size);
    }
  }

  void forceRecheck() {
    if (ffi.torrent_force_recheck(id) != 0) {
      _throwLastError('Failed to force recheck');
    }
  }

  void forceReannounce({int seconds = 0, int trackerIndex = -1}) {
    if (ffi.torrent_force_reannounce(id, seconds, trackerIndex) != 0) {
      _throwLastError('Failed to force reannounce');
    }
  }

  void moveStorage(String path, {int flags = 0}) {
    final pathPtr = path.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_move_storage(id, pathPtr.cast<Char>(), flags) != 0) {
        _throwLastError('Failed to move storage');
      }
    } finally {
      calloc.free(pathPtr);
    }
  }

  String name() {
    final buf = calloc<Int8>(512);
    try {
      ffi.torrent_get_name(id, buf, 512);
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  String savePath() {
    final buf = calloc<Int8>(4096);
    try {
      ffi.torrent_get_save_path(id, buf, 4096);
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  String infoHash() {
    final buf = calloc<Int8>(65);
    try {
      ffi.torrent_get_info_hash(id, buf, 65);
      return buf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buf);
    }
  }

  int queuePosition() => ffi.torrent_queue_position(id);

  void queuePositionSet(int pos) => ffi.torrent_queue_position_set(id, pos);

  void queuePositionUp() => ffi.torrent_queue_position_up(id);

  void queuePositionDown() => ffi.torrent_queue_position_down(id);

  void queuePositionTop() => ffi.torrent_queue_position_top(id);

  void queuePositionBottom() => ffi.torrent_queue_position_bottom(id);

  int getFlags() => ffi.torrent_get_flags(id);

  void setFlags(int flags) => ffi.torrent_set_flags(id, flags);

  void unsetFlags(int flags) => ffi.torrent_unset_flags(id, flags);
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
    required this.numSeeds,
    required this.numPeers,
    required this.numComplete,
    required this.numIncomplete,
    required this.listSeeds,
    required this.listPeers,
    required this.numConnections,
    required this.numUploads,
    required this.allTimeUpload,
    required this.allTimeDownload,
    required this.activeTime,
    required this.seedingTime,
    required this.currentTracker,
    required this.seedMode,
    required this.hasIncoming,
  });

  final double progress;
  final double downloadRate;
  final double uploadRate;
  final int totalDone;
  final int totalWanted;
  final int state;
  final bool paused;
  final String error;
  final int numSeeds;
  final int numPeers;
  final int numComplete;
  final int numIncomplete;
  final int listSeeds;
  final int listPeers;
  final int numConnections;
  final int numUploads;
  final int allTimeUpload;
  final int allTimeDownload;
  final int activeTime;
  final int seedingTime;
  final String currentTracker;
  final bool seedMode;
  final bool hasIncoming;
}

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
  Pointer<ffi.TorrentStatusNative> statusPtr,
  Pointer<Void> userdata,
) {
  final handler = _progressHandlers[tor];
  if (handler == null) {
    return;
  }
  handler(_mapStatus(statusPtr.ref));
}

TorrentStatus _mapStatus(ffi.TorrentStatusNative status) {
  return TorrentStatus(
    progress: status.progress,
    downloadRate: status.download_rate,
    uploadRate: status.upload_rate,
    totalDone: status.total_done,
    totalWanted: status.total_wanted,
    state: status.state,
    paused: status.paused != 0,
    error: ffi.int8ArrayToString(status.error, 1024),
    numSeeds: status.num_seeds,
    numPeers: status.num_peers,
    numComplete: status.num_complete,
    numIncomplete: status.num_incomplete,
    listSeeds: status.list_seeds,
    listPeers: status.list_peers,
    numConnections: status.num_connections,
    numUploads: status.num_uploads,
    allTimeUpload: status.all_time_upload,
    allTimeDownload: status.all_time_download,
    activeTime: status.active_time,
    seedingTime: status.seeding_time,
    currentTracker: ffi.int8ArrayToString(status.current_tracker, 512),
    seedMode: status.seed_mode != 0,
    hasIncoming: status.has_incoming != 0,
  );
}

void _throwLastError(String fallback) {
  final native = calloc<ffi.LtErrorNative>();
  try {
    final rc = ffi.lt_last_error(native, sizeOf<ffi.LtErrorNative>());
    if (rc == 0 && native.ref.code != 0) {
      final message = ffi.int8ArrayToString(native.ref.message, 1024);
      throw LibtorrentException(
        message.isEmpty ? fallback : message,
        code: native.ref.code,
      );
    }
    throw LibtorrentException(fallback, code: -1);
  } finally {
    calloc.free(native);
  }
}

class _MarshaledTagItems {
  _MarshaledTagItems(this.items, this.allocations);
  final Pointer<ffi.LtTagItemNative> items;
  final List<Pointer<Void>> allocations;

  void dispose() {
    for (final ptr in allocations) {
      calloc.free(ptr);
    }
    calloc.free(items);
  }
}

_MarshaledTagItems _marshalTagItems(List<LibtorrentTagItem> src) {
  final items = calloc<ffi.LtTagItemNative>(src.length);
  final allocations = <Pointer<Void>>[];
  for (var i = 0; i < src.length; i++) {
    final s = src[i];
    final d = (items + i).ref;
    d.tag = s.tag;
    d.int_value = s.intValue;
    d.size = s.size;
    d.string_value = nullptr;
    d.ptr_value = s.pointerValue ?? nullptr;
    if (s.stringValue != null) {
      final p = s.stringValue!.toNativeUtf8(allocator: calloc).cast<Char>();
      d.string_value = p;
      allocations.add(p.cast<Void>());
    }
    if (s.bytesValue != null) {
      final b = calloc<Uint8>(s.bytesValue!.length);
      b.asTypedList(s.bytesValue!.length).setAll(0, s.bytesValue!);
      d.ptr_value = b.cast<Void>();
      d.size = s.bytesValue!.length;
      allocations.add(b.cast<Void>());
    }
  }
  return _MarshaledTagItems(items, allocations);
}

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
    if (_timer.isActive) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  @override
  bool get isPaused => !_timer.isActive;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future<E>.value(futureValue);
}
