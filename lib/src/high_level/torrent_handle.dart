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

  void cancel({bool deleteFiles = true, bool deletePartfile = false}) {
    if (deletePartfile) {
      var flags = 0;
      if (deleteFiles) flags |= LibtorrentRemoveFlags.deleteFiles;
      flags |= LibtorrentRemoveFlags.deletePartfile;
      ffi.session_remove_torrent(_sessionHandle, id, flags);
      return;
    }

    if (ffi.torrent_cancel(_sessionHandle, id, deleteFiles ? 1 : 0) != 0) {
      _throwLastError('Failed to cancel torrent');
    }
  }

  String makeMagnetUri() {
    final requiredLen = calloc<Int32>();
    try {
      var rc = ffi.lt_make_magnet_uri(id, nullptr.cast<Char>(), 0, requiredLen);
      if (rc != 0) {
        _throwLastError('Failed to query magnet URI length');
      }
      final buf = calloc<Int8>(requiredLen.value > 0 ? requiredLen.value : 1);
      try {
        rc = ffi.lt_make_magnet_uri(
          id,
          buf.cast<Char>(),
          requiredLen.value > 0 ? requiredLen.value : 1,
          requiredLen,
        );
        if (rc != 0) {
          _throwLastError('Failed to build magnet URI');
        }
        return buf.cast<Utf8>().toDartString();
      } finally {
        calloc.free(buf);
      }
    } finally {
      calloc.free(requiredLen);
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

  void readPiece(int piece) {
    if (ffi.torrent_read_piece(id, piece) != 0) {
      _throwLastError('Failed to read piece');
    }
  }

  void addPiece(int piece, Uint8List data, {int flags = 0}) {
    final buf = calloc<Uint8>(data.length);
    buf.asTypedList(data.length).setAll(0, data);
    try {
      if (ffi.torrent_add_piece(
            id,
            piece,
            buf.cast<Char>(),
            data.length,
            flags,
          ) !=
          0) {
        _throwLastError('Failed to add piece');
      }
    } finally {
      calloc.free(buf);
    }
  }

  bool havePiece(int piece) {
    final rc = ffi.torrent_have_piece(id, piece);
    if (rc < 0) {
      _throwLastError('Failed to query piece availability');
    }
    return rc != 0;
  }

  void saveResumeData({int flags = 0}) {
    if (ffi.torrent_save_resume_data(id, flags) != 0) {
      _throwLastError('Failed to request resume data save');
    }
  }

  Uint8List getResumeData({int flags = 0}) {
    final requiredLen = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_resume_data(
        id,
        nullptr.cast<Char>(),
        0,
        requiredLen,
        flags,
      );
      if (rc != 0) {
        _throwLastError('Failed to query resume data length');
      }
      if (requiredLen.value <= 0) {
        return Uint8List(0);
      }
      final buf = calloc<Uint8>(requiredLen.value);
      try {
        rc = ffi.torrent_get_resume_data(
          id,
          buf.cast<Char>(),
          requiredLen.value,
          requiredLen,
          flags,
        );
        if (rc != 0) {
          _throwLastError('Failed to read resume data');
        }
        return Uint8List.fromList(buf.asTypedList(requiredLen.value));
      } finally {
        calloc.free(buf);
      }
    } finally {
      calloc.free(requiredLen);
    }
  }

  bool needSaveResumeData({int flags = -1}) {
    final rc = ffi.torrent_need_save_resume_data(id, flags);
    if (rc < 0) {
      _throwLastError('Failed to query resume data requirement');
    }
    return rc != 0;
  }

  void connectPeer({required String address, required int port}) {
    final addressPtr = address.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_connect_peer(id, addressPtr.cast<Char>(), port) != 0) {
        _throwLastError('Failed to connect peer');
      }
    } finally {
      calloc.free(addressPtr);
    }
  }

  void forceReannounce({int seconds = 0, int trackerIndex = -1}) {
    if (ffi.torrent_force_reannounce(id, seconds, trackerIndex) != 0) {
      _throwLastError('Failed to force torrent reannounce');
    }
  }

  void forceReannounceWithFlags({
    int seconds = 0,
    int trackerIndex = -1,
    int flags = 0,
  }) {
    if (ffi.torrent_force_reannounce_flags(id, seconds, trackerIndex, flags) !=
        0) {
      _throwLastError('Failed to force torrent reannounce with flags');
    }
  }

  void forceDhtAnnounce() {
    if (ffi.torrent_force_dht_announce(id) != 0) {
      _throwLastError('Failed to force DHT announce');
    }
  }

  void forceLsdAnnounce() {
    if (ffi.torrent_force_lsd_announce(id) != 0) {
      _throwLastError('Failed to force LSD announce');
    }
  }

  void scrapeTracker({int trackerIndex = -1}) {
    if (ffi.torrent_scrape_tracker(id, trackerIndex) != 0) {
      _throwLastError('Failed to scrape tracker');
    }
  }

  void addTracker(String url, {int tier = 0}) {
    final urlPtr = url.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_add_tracker(id, urlPtr.cast<Char>(), tier) != 0) {
        _throwLastError('Failed to add tracker');
      }
    } finally {
      calloc.free(urlPtr);
    }
  }

  void replaceTrackers(List<String> urls, {List<int>? tiers}) {
    if (tiers != null && tiers.length != urls.length) {
      throw ArgumentError('tiers length must match urls length');
    }
    final urlPointers = <Pointer<Char>>[];
    final nativeUrls = calloc<Pointer<Char>>(urls.length);
    final nativeTiers = calloc<Int32>(urls.length);
    try {
      for (var i = 0; i < urls.length; i++) {
        final ptr = urls[i].toNativeUtf8(allocator: calloc).cast<Char>();
        urlPointers.add(ptr);
        nativeUrls[i] = ptr;
        nativeTiers[i] = tiers == null ? 0 : tiers[i];
      }
      if (ffi.torrent_replace_trackers(
            id,
            nativeUrls,
            nativeTiers,
            urls.length,
          ) !=
          0) {
        _throwLastError('Failed to replace trackers');
      }
    } finally {
      for (final ptr in urlPointers) {
        calloc.free(ptr);
      }
      calloc.free(nativeUrls);
      calloc.free(nativeTiers);
    }
  }

  List<String> getTrackers() {
    return _readStringList(
      (dest, len) => ffi.torrent_get_trackers(id, dest, len),
    );
  }

  List<String> getUrlSeeds() {
    return _readStringList(
      (dest, len) => ffi.torrent_get_url_seeds(id, dest, len),
    );
  }

  List<String> getHttpSeeds() {
    return _readStringList(
      (dest, len) => ffi.torrent_get_http_seeds(id, dest, len),
    );
  }

  void addUrlSeed(String url) {
    final urlPtr = url.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_add_url_seed(id, urlPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to add URL seed');
      }
    } finally {
      calloc.free(urlPtr);
    }
  }

  void removeUrlSeed(String url) {
    final urlPtr = url.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_remove_url_seed(id, urlPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to remove URL seed');
      }
    } finally {
      calloc.free(urlPtr);
    }
  }

  void addHttpSeed(String url) {
    final urlPtr = url.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_add_http_seed(id, urlPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to add HTTP seed');
      }
    } finally {
      calloc.free(urlPtr);
    }
  }

  void removeHttpSeed(String url) {
    final urlPtr = url.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.torrent_remove_http_seed(id, urlPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to remove HTTP seed');
      }
    } finally {
      calloc.free(urlPtr);
    }
  }

  void setPieceDeadline(int pieceIndex, int deadline, {int flags = 0}) {
    if (ffi.torrent_set_piece_deadline(id, pieceIndex, deadline, flags) != 0) {
      _throwLastError('Failed to set piece deadline');
    }
  }

  void resetPieceDeadline(int pieceIndex) {
    if (ffi.torrent_reset_piece_deadline(id, pieceIndex) != 0) {
      _throwLastError('Failed to reset piece deadline');
    }
  }

  void clearPieceDeadlines() {
    if (ffi.torrent_clear_piece_deadlines(id) != 0) {
      _throwLastError('Failed to clear piece deadlines');
    }
  }

  void setFilePriority(int fileIndex, int priority) {
    if (ffi.torrent_set_file_priority(id, fileIndex, priority) != 0) {
      _throwLastError('Failed to set file priority');
    }
  }

  int getFilePriority(int fileIndex) {
    final priority = calloc<Int32>();
    try {
      if (ffi.torrent_get_file_priority(id, fileIndex, priority) != 0) {
        _throwLastError('Failed to get file priority');
      }
      return priority.value;
    } finally {
      calloc.free(priority);
    }
  }

  void setPiecePriority(int pieceIndex, int priority) {
    if (ffi.torrent_set_piece_priority(id, pieceIndex, priority) != 0) {
      _throwLastError('Failed to set piece priority');
    }
  }

  int getPiecePriority(int pieceIndex) {
    final priority = calloc<Int32>();
    try {
      if (ffi.torrent_get_piece_priority(id, pieceIndex, priority) != 0) {
        _throwLastError('Failed to get piece priority');
      }
      return priority.value;
    } finally {
      calloc.free(priority);
    }
  }

  void prioritizeFiles(List<int> priorities) {
    final native = calloc<Int32>(priorities.length);
    try {
      for (var i = 0; i < priorities.length; i++) {
        native[i] = priorities[i];
      }
      if (ffi.torrent_prioritize_files(id, native, priorities.length) != 0) {
        _throwLastError('Failed to prioritize files');
      }
    } finally {
      calloc.free(native);
    }
  }

  List<int> getFilePriorities() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_file_priorities(id, nullptr, 0, total);
      if (rc != 0) {
        _throwLastError('Failed to query file priorities size');
      }
      if (total.value == 0) return <int>[];
      final values = calloc<Int32>(total.value);
      try {
        rc = ffi.torrent_get_file_priorities(id, values, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read file priorities');
        }
        return List<int>.generate(total.value, (index) => values[index]);
      } finally {
        calloc.free(values);
      }
    } finally {
      calloc.free(total);
    }
  }

  void prioritizePieces(List<int> priorities) {
    final native = calloc<Int32>(priorities.length);
    try {
      for (var i = 0; i < priorities.length; i++) {
        native[i] = priorities[i];
      }
      if (ffi.torrent_prioritize_pieces(id, native, priorities.length) != 0) {
        _throwLastError('Failed to prioritize pieces');
      }
    } finally {
      calloc.free(native);
    }
  }

  List<int> getPiecePriorities() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_piece_priorities(id, nullptr, 0, total);
      if (rc != 0) {
        _throwLastError('Failed to query piece priorities size');
      }
      if (total.value == 0) return <int>[];
      final values = calloc<Int32>(total.value);
      try {
        rc = ffi.torrent_get_piece_priorities(id, values, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read piece priorities');
        }
        return List<int>.generate(total.value, (index) => values[index]);
      } finally {
        calloc.free(values);
      }
    } finally {
      calloc.free(total);
    }
  }

  void setFlags(int flags) {
    if (ffi.torrent_set_flags(id, flags) != 0) {
      _throwLastError('Failed to set torrent flags');
    }
  }

  void setFlagsWithMask(int flags, int mask) {
    if (ffi.torrent_set_flags_mask(id, flags, mask) != 0) {
      _throwLastError('Failed to set torrent flags with mask');
    }
  }

  void unsetFlags(int flags) {
    if (ffi.torrent_unset_flags(id, flags) != 0) {
      _throwLastError('Failed to unset torrent flags');
    }
  }

  int get flags {
    final value = calloc<Uint64>();
    try {
      if (ffi.torrent_get_flags(id, value) != 0) {
        _throwLastError('Failed to get torrent flags');
      }
      return value.value;
    } finally {
      calloc.free(value);
    }
  }

  List<String> _readStringList(int Function(Pointer<Char>, int) reader) {
    final buffer = calloc<Int8>(8192);
    try {
      if (reader(buffer.cast<Char>(), 8192) != 0) {
        _throwLastError('Failed to read string list');
      }
      final joined = buffer.cast<Utf8>().toDartString();
      if (joined.isEmpty) return <String>[];
      return joined.split('\n');
    } finally {
      calloc.free(buffer);
    }
  }

  void clearError() {
    if (ffi.torrent_clear_error(id) != 0) {
      _throwLastError('Failed to clear torrent error');
    }
  }

  void clearPeers() {
    if (ffi.torrent_clear_peers(id) != 0) {
      _throwLastError('Failed to clear peers');
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

  int setBoolSetting(int tag, bool value) {
    return setIntSetting(tag, value ? 1 : 0);
  }

  void setUploadLimit(int value) {
    setIntSetting(LibtorrentTag.setUploadRateLimit, value);
  }

  int getUploadLimit() {
    return getIntSetting(LibtorrentTag.setUploadRateLimit);
  }

  void setDownloadLimit(int value) {
    setIntSetting(LibtorrentTag.setDownloadRateLimit, value);
  }

  int getDownloadLimit() {
    return getIntSetting(LibtorrentTag.setDownloadRateLimit);
  }

  void setMaxUploads(int value) {
    setIntSetting(LibtorrentTag.setMaxUploadSlots, value);
  }

  int getMaxUploads() {
    return getIntSetting(LibtorrentTag.setMaxUploadSlots);
  }

  void setMaxConnections(int value) {
    setIntSetting(LibtorrentTag.setMaxConnections, value);
  }

  int getMaxConnections() {
    return getIntSetting(LibtorrentTag.setMaxConnections);
  }

  void setSequentialDownload(bool enabled) {
    setBoolSetting(LibtorrentTag.setSequentialDownload, enabled);
  }

  void setSuperSeeding(bool enabled) {
    setBoolSetting(LibtorrentTag.setSuperSeeding, enabled);
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

  void postDownloadQueue() {
    if (ffi.torrent_post_download_queue(id) != 0) {
      _throwLastError('Failed to post download queue');
    }
  }

  void postPeerInfo() {
    if (ffi.torrent_post_peer_info(id) != 0) {
      _throwLastError('Failed to post peer info');
    }
  }

  void postTrackers() {
    if (ffi.torrent_post_trackers(id) != 0) {
      _throwLastError('Failed to post trackers');
    }
  }

  List<PartialPieceInfo> getDownloadQueue() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_download_queue(
        id,
        nullptr.cast<ffi.LtPartialPieceInfoNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to query download queue size');
      }
      if (total.value == 0) return <PartialPieceInfo>[];
      final items = calloc<ffi.LtPartialPieceInfoNative>(total.value);
      try {
        rc = ffi.torrent_get_download_queue(id, items, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read download queue');
        }
        return List<PartialPieceInfo>.generate(total.value, (index) {
          final row = (items + index).ref;
          return PartialPieceInfo(
            pieceIndex: row.piece_index,
            blocksInPiece: row.blocks_in_piece,
            finished: row.finished,
            writing: row.writing,
            requested: row.requested,
          );
        });
      } finally {
        calloc.free(items);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<PeerInfo> getPeerInfo() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_peer_info(
        id,
        nullptr.cast<ffi.LtPeerInfoNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to query peer info size');
      }
      if (total.value == 0) return <PeerInfo>[];
      final peers = calloc<ffi.LtPeerInfoNative>(total.value);
      try {
        rc = ffi.torrent_get_peer_info(id, peers, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read peer info');
        }
        return List<PeerInfo>.generate(total.value, (index) {
          final peer = (peers + index).ref;
          return PeerInfo(
            ip: ffi.int8ArrayToString(peer.ip, 64),
            port: peer.port,
            client: ffi.int8ArrayToString(peer.client, 128),
            upSpeed: peer.up_speed,
            downSpeed: peer.down_speed,
            payloadUpSpeed: peer.payload_up_speed,
            payloadDownSpeed: peer.payload_down_speed,
            totalDownload: peer.total_download,
            totalUpload: peer.total_upload,
            flags: peer.flags,
            source: peer.source,
          );
        });
      } finally {
        calloc.free(peers);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<int> getFileProgress({int flags = 0}) {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_file_progress(id, nullptr, 0, total, flags);
      if (rc != 0) {
        _throwLastError('Failed to query file progress size');
      }
      if (total.value == 0) return <int>[];
      final progress = calloc<Int64>(total.value);
      try {
        rc = ffi.torrent_get_file_progress(
          id,
          progress,
          total.value,
          total,
          flags,
        );
        if (rc != 0) {
          _throwLastError('Failed to read file progress');
        }
        return List<int>.generate(total.value, (index) => progress[index]);
      } finally {
        calloc.free(progress);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<OpenFileState> getFileStatus() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_file_status(
        id,
        nullptr.cast<ffi.LtOpenFileStateNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to query file status size');
      }
      if (total.value == 0) return <OpenFileState>[];
      final files = calloc<ffi.LtOpenFileStateNative>(total.value);
      try {
        rc = ffi.torrent_get_file_status(id, files, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read file status');
        }
        return List<OpenFileState>.generate(total.value, (index) {
          final state = (files + index).ref;
          return OpenFileState(
            fileIndex: state.file_index,
            openMode: state.open_mode,
            lastUseMs: state.last_use_ms,
          );
        });
      } finally {
        calloc.free(files);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<TorrentFileEntry> getFiles() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.torrent_get_files(
        id,
        nullptr.cast<ffi.LtFileEntryNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to query file list size');
      }
      if (total.value == 0) return <TorrentFileEntry>[];
      final files = calloc<ffi.LtFileEntryNative>(total.value);
      try {
        rc = ffi.torrent_get_files(id, files, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read file list');
        }
        return List<TorrentFileEntry>.generate(total.value, (index) {
          final file = (files + index).ref;
          return TorrentFileEntry(
            index: file.index,
            size: file.size,
            offset: file.offset,
            flags: file.flags,
            path: ffi.int8ArrayToString(file.path, 512),
          );
        });
      } finally {
        calloc.free(files);
      }
    } finally {
      calloc.free(total);
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

  bool getBoolSetting(int tag) {
    return getIntSetting(tag) != 0;
  }

  String getStringSetting(int tag, {int maxLength = 1024}) {
    final value = calloc<Int8>(maxLength);
    final size = calloc<Int32>()..value = maxLength;
    try {
      final rc = ffi.torrent_get_setting(id, tag, value.cast<Void>(), size);
      if (rc != 0) {
        _throwLastError('Failed to get torrent string setting');
      }
      return value.cast<Utf8>().toDartString();
    } finally {
      calloc.free(value);
      calloc.free(size);
    }
  }

  void applySettingsFromTags(List<LibtorrentTagItem> items) {
    setSettingsFromTags(items);
  }
}
