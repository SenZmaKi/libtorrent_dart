part of '../libtorrent_dart.dart';

Session createSession() {
  ffi.lt_clear_error();
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

  void pause() {
    if (ffi.session_pause(_handle) != 0) {
      _throwLastError('Failed to pause session');
    }
  }

  void resume() {
    if (ffi.session_resume(_handle) != 0) {
      _throwLastError('Failed to resume session');
    }
  }

  bool get isPaused {
    final rc = ffi.session_is_paused(_handle);
    if (rc < 0) {
      _throwLastError('Failed to read session paused state');
    }
    return rc != 0;
  }

  void postTorrentUpdates() {
    if (ffi.session_post_torrent_updates(_handle) != 0) {
      _throwLastError('Failed to post torrent updates');
    }
  }

  void postSessionStats() {
    if (ffi.session_post_session_stats(_handle) != 0) {
      _throwLastError('Failed to post session stats');
    }
  }

  void postDhtStats() {
    if (ffi.session_post_dht_stats(_handle) != 0) {
      _throwLastError('Failed to post dht stats');
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
