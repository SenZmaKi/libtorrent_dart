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
    totalDone: status.total_done,
    totalWanted: status.total_wanted,
    totalFailedBytes: status.total_failed_bytes,
    totalRedundantBytes: status.total_redundant_bytes,
    state: status.state,
    numComplete: status.num_complete,
    numIncomplete: status.num_incomplete,
    numPieces: status.num_pieces,
    numUploads: status.num_uploads,
    numConnections: status.num_connections,
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
