import 'dart:async';
import 'dart:io';

import 'package:libtorrent_dart/src/libtorrent_dart.dart';

import 'torrent_session.dart';

// ─── formatting helpers ───────────────────────────────────────────────────────

String stateLabel(int state) => switch (state) {
  1 => 'checking files',
  2 => 'fetching metadata',
  3 => 'downloading',
  4 => 'finished',
  5 => 'seeding',
  7 => 'checking resume',
  _ => 'state $state',
};

String formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes} B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatRate(double bytesPerSec) =>
    '${formatBytes(bytesPerSec.round())}/s';

String progressBar(double progress, {int width = 28}) {
  final filled = (progress * width).round().clamp(0, width);
  return '[${('=' * filled).padRight(width)}]';
}

String eta(int totalWanted, int totalDone, double downloadRate) {
  final remaining = totalWanted - totalDone;
  if (downloadRate < 100 || remaining <= 0) return '--:--';
  final secs = (remaining / downloadRate).round();
  final m = secs ~/ 60;
  final s = secs % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ─── prompts ──────────────────────────────────────────────────────────────────

String promptMagnet() {
  stdout.writeln('Magnet URI (leave empty to use the Sintel demo magnet):');
  stdout.write('> ');
  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty ? defaultMagnet : input;
}

String promptSavePath() {
  stdout.writeln('\nSave path (leave empty to use $defaultSavePath):');
  stdout.write('> ');
  final input = stdin.readLineSync()?.trim() ?? '';
  final path = input.isEmpty ? defaultSavePath : input;

  final dir = Directory(path);
  if (!dir.existsSync()) {
    try {
      dir.createSync(recursive: true);
    } catch (e) {
      stderr.writeln('Warning: could not create directory "$path": $e');
    }
  }

  return path;
}

// ─── download UI loop ─────────────────────────────────────────────────────────

Future<void> runDownloadUI(DownloadSession dl) async {
  stdout.writeln('');
  stdout.writeln('Saving to: ${dl.savePath}');
  stdout.writeln('Controls:  p = pause/resume   x = cancel & exit   q = quit');
  stdout.writeln('');

  final done = Completer<void>();

  void finish({bool deleteFiles = false}) {
    if (done.isCompleted) return;
    dl.cancel(deleteFiles: deleteFiles);
    done.complete();
  }

  stdin
    ..echoMode = false
    ..lineMode = false;

  StreamSubscription<List<int>>? keySub;
  keySub = stdin.listen((bytes) {
    final ch = String.fromCharCode(bytes.first).toLowerCase();
    switch (ch) {
      case 'p':
        if (dl.paused) {
          dl.resume();
          stdout.writeln('\n▶  Resumed');
        } else {
          dl.pause();
          stdout.writeln('\n⏸  Paused');
        }
      case 'x':
      case 'q':
        stdout.writeln('\nCancelling...');
        keySub?.cancel();
        finish(deleteFiles: true);
    }
  });

  final sub = dl.listenProgress((TorrentStatus s) {
    if (done.isCompleted) return;

    if (s.error.isNotEmpty) {
      stdout.writeln('\nerror: ${s.error}');
      return;
    }

    final pct = (s.progress * 100).toStringAsFixed(1).padLeft(5);
    final bar = progressBar(s.progress);
    final down = formatRate(s.downloadRate);
    final up = formatRate(s.uploadRate);
    final etaStr = eta(s.totalWanted, s.totalDone, s.downloadRate);
    final doneBytes = formatBytes(s.totalDone);
    final total = s.totalWanted > 0 ? formatBytes(s.totalWanted) : '?';
    final state = stateLabel(s.state);
    final pausedTag = s.paused ? ' [PAUSED]' : '';

    stdout.write(
      '\r\x1B[2K'
      '$bar $pct%  '
      '$doneBytes / $total  '
      '↓ $down  ↑ $up  '
      'ETA $etaStr  '
      '$state$pausedTag   ',
    );

    if (s.state == 4 || s.state == 5) {
      stdout.writeln('\n\nDownload complete! Files saved to: ${dl.savePath}');
      keySub?.cancel();
      finish();
    }
  });

  await done.future;
  await sub.cancel();

  try {
    stdin
      ..echoMode = true
      ..lineMode = true;
  } catch (_) {}
}
