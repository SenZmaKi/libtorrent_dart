part of '../libtorrent_dart.dart';

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
    downloadPayloadRate: status.download_payload_rate,
    uploadPayloadRate: status.upload_payload_rate,
    totalDone: status.total_done,
    totalWanted: status.total_wanted,
    totalDownload: status.total_download,
    totalUpload: status.total_upload,
    totalPayloadDownload: status.total_payload_download,
    totalPayloadUpload: status.total_payload_upload,
    totalFailedBytes: status.total_failed_bytes,
    totalRedundantBytes: status.total_redundant_bytes,
    state: status.state,
    nextAnnounce: status.next_announce,
    announceInterval: status.announce_interval,
    currentTracker: ffi.int8ArrayToString(status.current_tracker, 512),
    numSeeds: status.num_seeds,
    numPeers: status.num_peers,
    numComplete: status.num_complete,
    numIncomplete: status.num_incomplete,
    listSeeds: status.list_seeds,
    listPeers: status.list_peers,
    connectCandidates: status.connect_candidates,
    numPieces: status.num_pieces,
    totalWantedDone: status.total_wanted_done,
    distributedCopies: status.distributed_copies,
    blockSize: status.block_size,
    numUploads: status.num_uploads,
    numConnections: status.num_connections,
    uploadsLimit: status.uploads_limit,
    connectionsLimit: status.connections_limit,
    upBandwidthQueue: status.up_bandwidth_queue,
    downBandwidthQueue: status.down_bandwidth_queue,
    allTimeUpload: status.all_time_upload,
    allTimeDownload: status.all_time_download,
    activeTime: status.active_time,
    seedingTime: status.seeding_time,
    seedRank: status.seed_rank,
    lastScrape: status.last_scrape,
    hasIncoming: status.has_incoming != 0,
    seedMode: status.seed_mode != 0,
    paused: status.paused != 0,
    error: ffi.int8ArrayToString(status.error, 1024),
  );
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
