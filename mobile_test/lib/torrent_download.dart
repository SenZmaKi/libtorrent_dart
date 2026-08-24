import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libtorrent_dart/libtorrent_dart.dart';
import 'package:path_provider/path_provider.dart';

const _sintelMagnet =
    'magnet:?xt=urn:btih:08ada5a7a6183aae1e09d831df6748d566095a10'
    '&dn=Sintel'
    '&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337';

class TorrentDownloadPage extends StatefulWidget {
  const TorrentDownloadPage({super.key});

  @override
  State<TorrentDownloadPage> createState() => _TorrentDownloadPageState();
}

class _TorrentDownloadPageState extends State<TorrentDownloadPage> {
  final _magnetController = TextEditingController(text: _sintelMagnet);
  Session? _session;
  TorrentHandle? _torrent;
  StreamSubscription<TorrentStatus>? _progressSubscription;
  TorrentStatus? _status;
  String? _savePath;
  String? _error;
  bool _starting = false;
  bool _stopping = false;
  bool _disposed = false;

  bool get _isDownloading => _torrent != null;

  Future<void> _start() async {
    final magnetUri = _magnetController.text.trim();
    if (magnetUri.isEmpty || _starting || _isDownloading) return;
    setState(() {
      _starting = true;
      _error = null;
      _status = null;
    });

    try {
      final documents = await getApplicationDocumentsDirectory();
      final savePath = '${documents.path}/libtorrent_dart';
      final session = createSession();
      _session = session;
      session.applyConfig(
        const SessionConfig(
          connectionsLimit: 200,
          downloadRateLimit: 5 * 1024 * 1024,
          uploadRateLimit: 1024 * 1024,
        ),
      );
      final torrent = session.addMagnet(
        magnetUri: magnetUri,
        savePath: savePath,
      );
      torrent.unsetFlags(LibtorrentTorrentFlags.autoManaged);
      torrent.resume();
      _torrent = torrent;
      _savePath = savePath;
      _progressSubscription = torrent.listenProgress(onData: _onProgress);
    } catch (error) {
      await _closeDownload(deleteFiles: false);
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _onProgress(TorrentStatus status) {
    if (!mounted || _torrent == null) return;
    setState(() {
      _status = status;
      _error = status.error.isEmpty ? null : status.error;
    });
    if (status.error.isNotEmpty || status.state == 4 || status.state == 5) {
      unawaited(_closeDownload(deleteFiles: false, preserveStatus: true));
    }
  }

  void _togglePaused() {
    final torrent = _torrent;
    if (torrent == null) return;
    (_status?.paused ?? false) ? torrent.resume() : torrent.pause();
  }

  Future<void> _cancel() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await _closeDownload(deleteFiles: true);
    if (mounted) setState(() => _stopping = false);
  }

  Future<void> _closeDownload({
    required bool deleteFiles,
    bool preserveStatus = false,
  }) async {
    final subscription = _progressSubscription;
    final torrent = _torrent;
    final session = _session;
    _progressSubscription = null;
    _torrent = null;
    _session = null;
    await subscription?.cancel();
    torrent?.cancel(deleteFiles: deleteFiles);
    session?.close();
    if (mounted && !_disposed) {
      setState(() {
        if (!preserveStatus) _status = null;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _magnetController.dispose();
    unawaited(_closeDownload(deleteFiles: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final progress = status?.progress.clamp(0.0, 1.0) ?? 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('libtorrent_dart example')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _magnetController,
            enabled: !_isDownloading && !_starting,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Magnet URI',
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: status == null ? null : progress),
          const SizedBox(height: 12),
          Text('${(progress * 100).toStringAsFixed(1)}%'),
          if (status != null)
            Text(
              'Down: ${_formatRate(status.downloadRate)}  '
              'Up: ${_formatRate(status.uploadRate)}  '
              'Peers: ${status.numPeers}',
            ),
          if (_savePath != null) Text('Save path: $_savePath'),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _isDownloading || _starting ? null : _start,
                icon: const Icon(Icons.download),
                label: Text(_starting ? 'Starting…' : 'Download'),
              ),
              OutlinedButton.icon(
                onPressed: _isDownloading ? _togglePaused : null,
                icon: Icon(
                  status?.paused ?? false ? Icons.play_arrow : Icons.pause,
                ),
                label: Text(status?.paused ?? false ? 'Resume' : 'Pause'),
              ),
              OutlinedButton.icon(
                onPressed: _isDownloading && !_stopping ? _cancel : null,
                icon: const Icon(Icons.cancel),
                label: Text(_stopping ? 'Cancelling…' : 'Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatRate(double bytesPerSecond) {
  if (bytesPerSecond < 1024) return '${bytesPerSecond.round()} B/s';
  if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  }
  return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}
