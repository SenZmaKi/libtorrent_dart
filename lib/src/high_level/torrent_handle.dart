part of '../libtorrent_dart.dart';

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

  void pause() {
    if (ffi.torrent_pause(id) != 0) {
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

  void flushCache() {
    if (ffi.torrent_flush_cache(id) != 0) {
      _throwLastError('Failed to flush torrent cache');
    }
  }

  void forceRecheck() {
    if (ffi.torrent_force_recheck(id) != 0) {
      _throwLastError('Failed to force torrent recheck');
    }
  }

  void forceReannounce({int seconds = 0, int trackerIndex = -1}) {
    if (ffi.torrent_force_reannounce(id, seconds, trackerIndex) != 0) {
      _throwLastError('Failed to force torrent reannounce');
    }
  }

  void forceDhtAnnounce() {
    if (ffi.torrent_force_dht_announce(id) != 0) {
      _throwLastError('Failed to force DHT announce');
    }
  }

  void scrapeTracker({int trackerIndex = -1}) {
    if (ffi.torrent_scrape_tracker(id, trackerIndex) != 0) {
      _throwLastError('Failed to scrape tracker');
    }
  }

  void clearError() {
    if (ffi.torrent_clear_error(id) != 0) {
      _throwLastError('Failed to clear torrent error');
    }
  }

  void queuePositionUp() {
    if (ffi.torrent_queue_position_up(id) != 0) {
      _throwLastError('Failed to move queue position up');
    }
  }

  void queuePositionDown() {
    if (ffi.torrent_queue_position_down(id) != 0) {
      _throwLastError('Failed to move queue position down');
    }
  }

  void queuePositionTop() {
    if (ffi.torrent_queue_position_top(id) != 0) {
      _throwLastError('Failed to move queue position to top');
    }
  }

  void queuePositionBottom() {
    if (ffi.torrent_queue_position_bottom(id) != 0) {
      _throwLastError('Failed to move queue position to bottom');
    }
  }

  void setQueuePosition(int value) {
    if (ffi.torrent_queue_position_set(id, value) != 0) {
      _throwLastError('Failed to set queue position');
    }
  }

  int get queuePosition {
    final queue = calloc<Int32>();
    try {
      if (ffi.torrent_queue_position_get(id, queue) != 0) {
        _throwLastError('Failed to get queue position');
      }
      return queue.value;
    } finally {
      calloc.free(queue);
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
}
