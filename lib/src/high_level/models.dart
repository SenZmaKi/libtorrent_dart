part of '../libtorrent_dart.dart';

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
