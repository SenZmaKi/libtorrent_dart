part of '../libtorrent_dart.dart';

Session createSession() {
  ffi.lt_clear_error();
  final handle = ffi.session_create_default();
  if (handle == nullptr) {
    _throwLastError('Failed to create session');
  }
  return Session._(handle);
}

String getLibtorrentVersion() {
  final buf = calloc<Int8>(64);
  try {
    if (ffi.lt_version(buf.cast<Char>(), 64) != 0) {
      _throwLastError('Failed to read libtorrent version');
    }
    return buf.cast<Utf8>().toDartString();
  } finally {
    calloc.free(buf);
  }
}

MagnetUriInfo parseMagnetUri(String magnetUri) {
  final uriPtr = magnetUri.toNativeUtf8(allocator: calloc);
  final info = calloc<ffi.LtMagnetInfoNative>();
  try {
    if (ffi.lt_parse_magnet_uri(uriPtr.cast<Char>(), info) != 0) {
      _throwLastError('Failed to parse magnet URI');
    }
    final trackersRaw = ffi.int8ArrayToString(info.ref.trackers, 2048);
    final trackers =
        trackersRaw.isEmpty
            ? const <String>[]
            : trackersRaw.split('\n').where((line) => line.isNotEmpty).toList();
    return MagnetUriInfo(
      infohashHex: ffi.int8ArrayToString(info.ref.infohash_hex, 41),
      name: ffi.int8ArrayToString(info.ref.name, 256),
      trackers: trackers,
    );
  } finally {
    calloc.free(uriPtr);
    calloc.free(info);
  }
}

TorrentFileInfo loadTorrentFile(String path) {
  final pathPtr = path.toNativeUtf8(allocator: calloc);
  final info = calloc<ffi.LtTorrentFileInfoNative>();
  try {
    if (ffi.lt_load_torrent_file(pathPtr.cast<Char>(), info) != 0) {
      _throwLastError('Failed to load torrent file');
    }
    return TorrentFileInfo(
      infohashHex: ffi.int8ArrayToString(info.ref.infohash_hex, 41),
      name: ffi.int8ArrayToString(info.ref.name, 256),
      totalSize: info.ref.total_size,
      numFiles: info.ref.num_files,
    );
  } finally {
    calloc.free(pathPtr);
    calloc.free(info);
  }
}

Uint8List createTorrentData({
  required String sourcePath,
  String? trackerUrl,
  int pieceSize = 0,
}) {
  final sourcePathPtr = sourcePath.toNativeUtf8(allocator: calloc);
  final hasTrackerUrl = trackerUrl != null;
  final trackerUrlPtr =
      hasTrackerUrl
          ? trackerUrl.toNativeUtf8(allocator: calloc).cast<Char>()
          : nullptr.cast<Char>();
  final requiredLen = calloc<Int32>();
  try {
    var rc = ffi.lt_create_torrent_data(
      sourcePathPtr.cast<Char>(),
      trackerUrlPtr,
      pieceSize,
      nullptr.cast<Char>(),
      0,
      requiredLen,
    );
    if (rc != 0) {
      _throwLastError('Failed to query torrent data length');
    }
    if (requiredLen.value <= 0) {
      return Uint8List(0);
    }
    final buf = calloc<Int8>(requiredLen.value);
    try {
      rc = ffi.lt_create_torrent_data(
        sourcePathPtr.cast<Char>(),
        trackerUrlPtr,
        pieceSize,
        buf.cast<Char>(),
        requiredLen.value,
        requiredLen,
      );
      if (rc != 0) {
        _throwLastError('Failed to create torrent data');
      }
      return Uint8List.fromList(
        buf.cast<Uint8>().asTypedList(requiredLen.value),
      );
    } finally {
      calloc.free(buf);
    }
  } finally {
    if (hasTrackerUrl) {
      calloc.free(trackerUrlPtr.cast<Void>());
    }
    calloc.free(sourcePathPtr);
    calloc.free(requiredLen);
  }
}

void createTorrentFile({
  required String sourcePath,
  required String outputPath,
  String? trackerUrl,
  int pieceSize = 0,
}) {
  final data = createTorrentData(
    sourcePath: sourcePath,
    trackerUrl: trackerUrl,
    pieceSize: pieceSize,
  );
  File(outputPath).writeAsBytesSync(data, flush: true);
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

Session createSessionFromState(Uint8List state, {int flags = 0}) {
  final statePtr = calloc<Uint8>(state.length);
  statePtr.asTypedList(state.length).setAll(0, state);
  try {
    ffi.lt_clear_error();
    final handle = ffi.session_create_state(
      statePtr.cast<Char>(),
      state.length,
      flags,
    );
    if (handle == nullptr) {
      _throwLastError('Failed to create session from serialized state');
    }
    return Session._(handle);
  } finally {
    calloc.free(statePtr);
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

  TorrentHandle addTorrentFile({
    required String torrentPath,
    required String savePath,
  }) {
    return addTorrentFromTags([
      LibtorrentTagItem.stringValue(LibtorrentTag.torFilename, torrentPath),
      LibtorrentTagItem.stringValue(LibtorrentTag.torSavePath, savePath),
    ]);
  }

  TorrentHandle addTorrentData({
    required Uint8List torrentData,
    required String savePath,
  }) {
    return addTorrentFromTags([
      LibtorrentTagItem.bytesValue(LibtorrentTag.torTorrent, torrentData),
      LibtorrentTagItem.intValue(
        LibtorrentTag.torTorrentSize,
        torrentData.length,
      ),
      LibtorrentTagItem.stringValue(LibtorrentTag.torSavePath, savePath),
    ]);
  }

  void addTorrentFromTagsAsync(List<LibtorrentTagItem> items) {
    final marshaled = _marshalTagItems(items);
    try {
      final rc = ffi.session_async_add_torrent_items(
        _handle,
        marshaled.items,
        items.length,
      );
      if (rc != 0) {
        _throwLastError('Failed to async add torrent from tags');
      }
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
        payloadUploadRate: status.ref.payload_upload_rate,
        payloadDownloadRate: status.ref.payload_download_rate,
        totalDownload: status.ref.total_download,
        totalUpload: status.ref.total_upload,
        totalPayloadDownload: status.ref.total_payload_download,
        totalPayloadUpload: status.ref.total_payload_upload,
        ipOverheadUploadRate: status.ref.ip_overhead_upload_rate,
        ipOverheadDownloadRate: status.ref.ip_overhead_download_rate,
        totalIpOverheadDownload: status.ref.total_ip_overhead_download,
        totalIpOverheadUpload: status.ref.total_ip_overhead_upload,
        dhtUploadRate: status.ref.dht_upload_rate,
        dhtDownloadRate: status.ref.dht_download_rate,
        totalDhtDownload: status.ref.total_dht_download,
        totalDhtUpload: status.ref.total_dht_upload,
        trackerUploadRate: status.ref.tracker_upload_rate,
        trackerDownloadRate: status.ref.tracker_download_rate,
        totalTrackerDownload: status.ref.total_tracker_download,
        totalTrackerUpload: status.ref.total_tracker_upload,
        totalRedundantBytes: status.ref.total_redundant_bytes,
        totalFailedBytes: status.ref.total_failed_bytes,
        numPeers: status.ref.num_peers,
        numUnchoked: status.ref.num_unchoked,
        allowedUploadSlots: status.ref.allowed_upload_slots,
        upBandwidthQueue: status.ref.up_bandwidth_queue,
        downBandwidthQueue: status.ref.down_bandwidth_queue,
        upBandwidthBytesQueue: status.ref.up_bandwidth_bytes_queue,
        downBandwidthBytesQueue: status.ref.down_bandwidth_bytes_queue,
        optimisticUnchokeCounter: status.ref.optimistic_unchoke_counter,
        unchokeCounter: status.ref.unchoke_counter,
        dhtNodes: status.ref.dht_nodes,
        dhtNodeCache: status.ref.dht_node_cache,
        dhtTorrents: status.ref.dht_torrents,
        dhtGlobalNodes: status.ref.dht_global_nodes,
      );
    } finally {
      calloc.free(status);
    }
  }

  int get listenPort {
    final port = calloc<Int32>();
    try {
      if (ffi.session_listen_port(_handle, port) != 0) {
        _throwLastError('Failed to get listen port');
      }
      return port.value;
    } finally {
      calloc.free(port);
    }
  }

  int get sslListenPort {
    final port = calloc<Int32>();
    try {
      if (ffi.session_ssl_listen_port(_handle, port) != 0) {
        _throwLastError('Failed to get SSL listen port');
      }
      return port.value;
    } finally {
      calloc.free(port);
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

  List<AlertMessage> popAlerts({int maxCount = 64}) {
    final alerts = <AlertMessage>[];
    while (alerts.length < maxCount) {
      final alert = popAlert();
      if (alert == null) break;
      alerts.add(alert);
    }
    return alerts;
  }

  AlertInfo? popAlertInfoLegacy() {
    final type = calloc<Int32>();
    final category = calloc<Int32>();
    final what = calloc<Int8>(256);
    final message = calloc<Int8>(4096);
    try {
      final rc = ffi.session_pop_alert_info(
        _handle,
        type,
        category,
        what.cast<Char>(),
        256,
        message.cast<Char>(),
        4096,
      );
      if (rc < 0) return null;
      return AlertInfo(
        type: type.value,
        category: category.value,
        what: what.cast<Utf8>().toDartString(),
        message: message.cast<Utf8>().toDartString(),
      );
    } finally {
      calloc.free(type);
      calloc.free(category);
      calloc.free(what);
      calloc.free(message);
    }
  }

  AlertInfo? popAlertInfo() {
    final info = calloc<ffi.LtAlertInfoNative>();
    const maxSamples = 256;
    final samples = calloc<ffi.LtDhtSampleNative>(maxSamples);
    final totalSamples = calloc<Int32>();
    try {
      final rc = ffi.session_pop_alert_typed(
        _handle,
        info,
        samples,
        maxSamples,
        totalSamples,
      );
      if (rc < 0) return null;
      final sampleCount =
          totalSamples.value < maxSamples ? totalSamples.value : maxSamples;
      final dhtSamples =
          sampleCount <= 0
              ? const <DhtSampleInfohash>[]
              : List<DhtSampleInfohash>.generate(sampleCount, (index) {
                final sample = (samples + index).ref;
                return DhtSampleInfohash(
                  infohashHex: ffi.int8ArrayToString(sample.infohash_hex, 41),
                  address: ffi.int8ArrayToString(sample.address, 64),
                  port: sample.port,
                );
              });
      final torrentId = info.ref.torrent_id >= 0 ? info.ref.torrent_id : null;
      final endpointAddress = ffi.int8ArrayToString(
        info.ref.dht_endpoint_address,
        64,
      );
      final endpointPort =
          info.ref.dht_endpoint_port > 0 ? info.ref.dht_endpoint_port : null;
      return AlertInfo(
        type: info.ref.type,
        category: info.ref.category,
        what: ffi.int8ArrayToString(info.ref.what, 64),
        message: ffi.int8ArrayToString(info.ref.message, 1024),
        torrentId: torrentId,
        dhtEndpointAddress: endpointAddress.isEmpty ? null : endpointAddress,
        dhtEndpointPort: endpointPort,
        dhtSamples: dhtSamples,
      );
    } finally {
      calloc.free(info);
      calloc.free(samples);
      calloc.free(totalSamples);
    }
  }

  AlertMessage? waitForAlert({
    Duration maxWait = const Duration(milliseconds: 200),
  }) {
    final category = calloc<Int32>();
    final buf = calloc<Int8>(4096);
    try {
      final rc = ffi.session_wait_for_alert(
        _handle,
        maxWait.inMilliseconds,
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

  SessionProxy abort() {
    final proxy = ffi.session_abort(_handle);
    if (proxy == nullptr) {
      _throwLastError('Failed to abort session');
    }
    return SessionProxy._(proxy);
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

  TorrentHandle findTorrent(String infohashHex) {
    final infohashPtr = infohashHex.toNativeUtf8(allocator: calloc);
    try {
      final tor = ffi.session_find_torrent(_handle, infohashPtr.cast<Char>());
      if (tor < 0) {
        _throwLastError('Failed to find torrent by infohash');
      }
      return TorrentHandle._(_handle, tor);
    } finally {
      calloc.free(infohashPtr);
    }
  }

  List<TorrentHandle> getTorrents() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.session_get_torrents(_handle, nullptr, 0, total);
      if (rc != 0) {
        _throwLastError('Failed to list torrents');
      }
      if (total.value == 0) return <TorrentHandle>[];
      final ids = calloc<Int32>(total.value);
      try {
        rc = ffi.session_get_torrents(_handle, ids, total.value, total);
        if (rc != 0) {
          _throwLastError('Failed to read torrent ids');
        }
        return List<TorrentHandle>.generate(
          total.value,
          (index) => TorrentHandle._(_handle, ids[index]),
        );
      } finally {
        calloc.free(ids);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<TorrentStatus> getTorrentStatuses() {
    final total = calloc<Int32>();
    try {
      var rc = ffi.session_get_torrent_statuses(
        _handle,
        nullptr.cast<ffi.TorrentStatusNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to list torrent statuses');
      }
      if (total.value == 0) return <TorrentStatus>[];
      final statuses = calloc<ffi.TorrentStatusNative>(total.value);
      try {
        rc = ffi.session_get_torrent_statuses(
          _handle,
          statuses,
          total.value,
          total,
        );
        if (rc != 0) {
          _throwLastError('Failed to read torrent statuses');
        }
        return List<TorrentStatus>.generate(
          total.value,
          (index) => _mapStatus((statuses + index).ref),
        );
      } finally {
        calloc.free(statuses);
      }
    } finally {
      calloc.free(total);
    }
  }

  List<TorrentStatus> getTorrentStatusesWithFlags(int flags) {
    final total = calloc<Int32>();
    try {
      var rc = ffi.session_get_torrent_statuses_flags(
        _handle,
        nullptr.cast<ffi.TorrentStatusNative>(),
        0,
        total,
        flags,
      );
      if (rc != 0) {
        _throwLastError('Failed to list torrent statuses with flags');
      }
      if (total.value == 0) return <TorrentStatus>[];
      final statuses = calloc<ffi.TorrentStatusNative>(total.value);
      try {
        rc = ffi.session_get_torrent_statuses_flags(
          _handle,
          statuses,
          total.value,
          total,
          flags,
        );
        if (rc != 0) {
          _throwLastError('Failed to read torrent statuses with flags');
        }
        return List<TorrentStatus>.generate(
          total.value,
          (index) => _mapStatus((statuses + index).ref),
        );
      } finally {
        calloc.free(statuses);
      }
    } finally {
      calloc.free(total);
    }
  }

  void dhtGetPeers(String infohashHex) {
    final infohashPtr = infohashHex.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.session_dht_get_peers(_handle, infohashPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to request DHT peers');
      }
    } finally {
      calloc.free(infohashPtr);
    }
  }

  void dhtGetItem(String targetHex) {
    final targetPtr = targetHex.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.session_dht_get_item(_handle, targetPtr.cast<Char>()) != 0) {
        _throwLastError('Failed to request DHT item');
      }
    } finally {
      calloc.free(targetPtr);
    }
  }

  void dhtPutItem(Uint8List bencodedData) {
    final data = calloc<Uint8>(bencodedData.length);
    data.asTypedList(bencodedData.length).setAll(0, bencodedData);
    try {
      if (ffi.session_dht_put_item(
            _handle,
            data.cast<Char>(),
            bencodedData.length,
          ) !=
          0) {
        _throwLastError('Failed to put DHT item');
      }
    } finally {
      calloc.free(data);
    }
  }

  List<DhtSampleInfohash> dhtSampleInfohashes({
    required String address,
    required int port,
    required String targetHex,
  }) {
    final addressPtr = address.toNativeUtf8(allocator: calloc);
    final targetPtr = targetHex.toNativeUtf8(allocator: calloc);
    final total = calloc<Int32>();
    try {
      var rc = ffi.session_dht_sample_infohashes(
        _handle,
        addressPtr.cast<Char>(),
        port,
        targetPtr.cast<Char>(),
        nullptr.cast<ffi.LtDhtSampleNative>(),
        0,
        total,
      );
      if (rc != 0) {
        _throwLastError('Failed to query DHT sample size');
      }
      if (total.value == 0) return <DhtSampleInfohash>[];
      final samples = calloc<ffi.LtDhtSampleNative>(total.value);
      try {
        rc = ffi.session_dht_sample_infohashes(
          _handle,
          addressPtr.cast<Char>(),
          port,
          targetPtr.cast<Char>(),
          samples,
          total.value,
          total,
        );
        if (rc != 0) {
          _throwLastError('Failed to read DHT sample infohashes');
        }
        return List<DhtSampleInfohash>.generate(total.value, (index) {
          final sample = (samples + index).ref;
          return DhtSampleInfohash(
            infohashHex: ffi.int8ArrayToString(sample.infohash_hex, 41),
            address: ffi.int8ArrayToString(sample.address, 64),
            port: sample.port,
          );
        });
      } finally {
        calloc.free(samples);
      }
    } finally {
      calloc.free(addressPtr);
      calloc.free(targetPtr);
      calloc.free(total);
    }
  }

  void dhtAnnounce(String infohashHex, {int port = 0}) {
    final infohashPtr = infohashHex.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.session_dht_announce(_handle, infohashPtr.cast<Char>(), port) !=
          0) {
        _throwLastError('Failed to announce on DHT');
      }
    } finally {
      calloc.free(infohashPtr);
    }
  }

  void addDhtNode({required String hostname, required int port}) {
    final hostPtr = hostname.toNativeUtf8(allocator: calloc);
    try {
      if (ffi.session_add_dht_node(_handle, hostPtr.cast<Char>(), port) != 0) {
        _throwLastError('Failed to add DHT node');
      }
    } finally {
      calloc.free(hostPtr);
    }
  }

  bool get isDhtRunning {
    final rc = ffi.session_is_dht_running(_handle);
    if (rc < 0) {
      _throwLastError('Failed to read DHT running state');
    }
    return rc != 0;
  }

  void startDht() {
    if (ffi.session_start_dht(_handle) != 0) {
      _throwLastError('Failed to start DHT');
    }
  }

  void stopDht() {
    if (ffi.session_stop_dht(_handle) != 0) {
      _throwLastError('Failed to stop DHT');
    }
  }

  Uint8List getState({int flags = 0xFFFFFFFF}) {
    final required = calloc<Int32>();
    try {
      var rc = ffi.session_get_state(
        _handle,
        nullptr.cast<Char>(),
        0,
        required,
        flags,
      );
      if (rc != 0) {
        _throwLastError('Failed to query session state size');
      }
      if (required.value == 0) return Uint8List(0);
      final buffer = calloc<Int8>(required.value);
      try {
        rc = ffi.session_get_state(
          _handle,
          buffer.cast<Char>(),
          required.value,
          required,
          flags,
        );
        if (rc != 0) {
          _throwLastError('Failed to read session state');
        }
        return Uint8List.fromList(
          buffer.cast<Uint8>().asTypedList(required.value),
        );
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(required);
    }
  }

  int _readSessionIntValue(
    int Function(Pointer<Void>, Pointer<Int32>) reader,
    String errorMessage,
  ) {
    final value = calloc<Int32>();
    try {
      if (reader(_handle, value) != 0) {
        _throwLastError(errorMessage);
      }
      return value.value;
    } finally {
      calloc.free(value);
    }
  }

  void _writeSessionIntValue(
    int Function(Pointer<Void>, int) writer,
    int value,
    String errorMessage,
  ) {
    if (writer(_handle, value) != 0) {
      _throwLastError(errorMessage);
    }
  }

  bool _readSessionBoolValue(
    int Function(Pointer<Void>, Pointer<Int32>) reader,
    String errorMessage,
  ) {
    return _readSessionIntValue(reader, errorMessage) != 0;
  }

  void _writeSessionBoolValue(
    int Function(Pointer<Void>, int) writer,
    bool value,
    String errorMessage,
  ) {
    _writeSessionIntValue(writer, value ? 1 : 0, errorMessage);
  }

  int getUploadRateLimit() => _readSessionIntValue(
    ffi.session_get_upload_rate_limit,
    'Failed to read upload rate limit',
  );

  void setUploadRateLimit(int value) => _writeSessionIntValue(
    ffi.session_set_upload_rate_limit,
    value,
    'Failed to set upload rate limit',
  );

  int getDownloadRateLimit() => _readSessionIntValue(
    ffi.session_get_download_rate_limit,
    'Failed to read download rate limit',
  );

  void setDownloadRateLimit(int value) => _writeSessionIntValue(
    ffi.session_set_download_rate_limit,
    value,
    'Failed to set download rate limit',
  );

  int getConnectionsLimit() => _readSessionIntValue(
    ffi.session_get_connections_limit,
    'Failed to read connections limit',
  );

  void setConnectionsLimit(int value) => _writeSessionIntValue(
    ffi.session_set_connections_limit,
    value,
    'Failed to set connections limit',
  );

  int getUnchokeSlotsLimit() => _readSessionIntValue(
    ffi.session_get_unchoke_slots_limit,
    'Failed to read unchoke slots limit',
  );

  void setUnchokeSlotsLimit(int value) => _writeSessionIntValue(
    ffi.session_set_unchoke_slots_limit,
    value,
    'Failed to set unchoke slots limit',
  );

  int getDhtUploadRateLimit() => _readSessionIntValue(
    ffi.session_get_dht_upload_rate_limit,
    'Failed to read DHT upload rate limit',
  );

  void setDhtUploadRateLimit(int value) => _writeSessionIntValue(
    ffi.session_set_dht_upload_rate_limit,
    value,
    'Failed to set DHT upload rate limit',
  );

  int getDhtAnnounceInterval() => _readSessionIntValue(
    ffi.session_get_dht_announce_interval,
    'Failed to read DHT announce interval',
  );

  void setDhtAnnounceInterval(int value) => _writeSessionIntValue(
    ffi.session_set_dht_announce_interval,
    value,
    'Failed to set DHT announce interval',
  );

  int getDhtMaxPeers() => _readSessionIntValue(
    ffi.session_get_dht_max_peers,
    'Failed to read DHT max peers',
  );

  void setDhtMaxPeers(int value) => _writeSessionIntValue(
    ffi.session_set_dht_max_peers,
    value,
    'Failed to set DHT max peers',
  );

  int getDhtMaxDhtItems() => _readSessionIntValue(
    ffi.session_get_dht_max_dht_items,
    'Failed to read DHT max DHT items',
  );

  void setDhtMaxDhtItems(int value) => _writeSessionIntValue(
    ffi.session_set_dht_max_dht_items,
    value,
    'Failed to set DHT max DHT items',
  );

  bool isDhtEnabled() => _readSessionBoolValue(
    ffi.session_get_enable_dht,
    'Failed to read DHT enabled setting',
  );

  void setDhtEnabled(bool enabled) => _writeSessionBoolValue(
    ffi.session_set_enable_dht,
    enabled,
    'Failed to set DHT enabled setting',
  );

  bool isLsdEnabled() => _readSessionBoolValue(
    ffi.session_get_enable_lsd,
    'Failed to read LSD enabled setting',
  );

  void setLsdEnabled(bool enabled) => _writeSessionBoolValue(
    ffi.session_set_enable_lsd,
    enabled,
    'Failed to set LSD enabled setting',
  );

  bool isUpnpEnabled() => _readSessionBoolValue(
    ffi.session_get_enable_upnp,
    'Failed to read UPnP enabled setting',
  );

  void setUpnpEnabled(bool enabled) => _writeSessionBoolValue(
    ffi.session_set_enable_upnp,
    enabled,
    'Failed to set UPnP enabled setting',
  );

  bool isNatPmpEnabled() => _readSessionBoolValue(
    ffi.session_get_enable_natpmp,
    'Failed to read NAT-PMP enabled setting',
  );

  void setNatPmpEnabled(bool enabled) => _writeSessionBoolValue(
    ffi.session_set_enable_natpmp,
    enabled,
    'Failed to set NAT-PMP enabled setting',
  );

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

  bool getBoolSetting(int tag) => getIntSetting(tag) != 0;

  String getStringSetting(int tag, {int maxLength = 1024}) {
    final value = calloc<Int8>(maxLength);
    final size = calloc<Int32>()..value = maxLength;
    try {
      final rc = ffi.session_get_setting(
        _handle,
        tag,
        value.cast<Void>(),
        size,
      );
      if (rc != 0) {
        _throwLastError('Failed to get session string setting');
      }
      return value.cast<Utf8>().toDartString();
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

  void applySettingsFromTags(List<LibtorrentTagItem> items) {
    setSettingsFromTags(items);
  }

  void setProxy(ProxySetting setting) {
    _setProxySetting(LibtorrentTag.setProxy, setting);
  }

  void setPeerProxy(ProxySetting setting) {
    _setProxySetting(LibtorrentTag.setPeerProxy, setting);
  }

  void setWebSeedProxy(ProxySetting setting) {
    _setProxySetting(LibtorrentTag.setWebSeedProxy, setting);
  }

  void setTrackerProxy(ProxySetting setting) {
    _setProxySetting(LibtorrentTag.setTrackerProxy, setting);
  }

  void setDhtProxy(ProxySetting setting) {
    _setProxySetting(LibtorrentTag.setDhtProxy, setting);
  }

  void _setProxySetting(int tag, ProxySetting setting) {
    final native = calloc<ffi.ProxySettingNative>();
    try {
      _writeInt8Array(native.ref.hostname, 256, setting.hostname);
      native.ref.port = setting.port;
      _writeInt8Array(native.ref.username, 256, setting.username);
      _writeInt8Array(native.ref.password, 256, setting.password);
      native.ref.type = setting.type;
      setSettingsFromTags([
        LibtorrentTagItem.pointerValue(tag, native.cast<Void>()),
      ]);
    } finally {
      calloc.free(native);
    }
  }

  void removeTorrent(
    TorrentHandle torrent, {
    bool deleteFiles = true,
    bool deletePartfile = false,
  }) {
    var flags = 0;
    if (deleteFiles) flags |= LibtorrentRemoveFlags.deleteFiles;
    if (deletePartfile) flags |= LibtorrentRemoveFlags.deletePartfile;
    ffi.session_remove_torrent(_handle, torrent.id, flags);
  }

  void close() {
    ffi.session_close(_handle);
  }
}

class SessionProxy {
  SessionProxy._(this._handle);
  final Pointer<Void> _handle;

  void close() {
    ffi.session_proxy_close(_handle);
  }
}

void _writeInt8Array(Array<Int8> target, int length, String value) {
  final bytes = utf8.encode(value);
  final maxBytes = length - 1;
  final bytesToWrite = bytes.length < maxBytes ? bytes.length : maxBytes;
  for (var i = 0; i < bytesToWrite; i++) {
    target[i] = bytes[i];
  }
  for (var i = bytesToWrite; i < length; i++) {
    target[i] = 0;
  }
}
