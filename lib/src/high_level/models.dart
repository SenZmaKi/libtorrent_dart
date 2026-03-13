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
    required this.payloadUploadRate,
    required this.payloadDownloadRate,
    required this.totalDownload,
    required this.totalUpload,
    required this.totalPayloadDownload,
    required this.totalPayloadUpload,
    required this.totalFailedBytes,
    required this.numPeers,
    required this.numUnchoked,
    required this.allowedUploadSlots,
    required this.dhtNodes,
    required this.dhtTorrents,
    required this.dhtGlobalNodes,
  });

  final bool hasIncomingConnections;
  final double uploadRate;
  final double downloadRate;
  final double payloadUploadRate;
  final double payloadDownloadRate;
  final int totalDownload;
  final int totalUpload;
  final int totalPayloadDownload;
  final int totalPayloadUpload;
  final int totalFailedBytes;
  final int numPeers;
  final int numUnchoked;
  final int allowedUploadSlots;
  final int dhtNodes;
  final int dhtTorrents;
  final int dhtGlobalNodes;
}

class TorrentStatus {
  TorrentStatus({
    required this.progress,
    required this.downloadRate,
    required this.uploadRate,
    required this.totalDone,
    required this.totalWanted,
    required this.totalFailedBytes,
    required this.totalRedundantBytes,
    required this.state,
    required this.numComplete,
    required this.numIncomplete,
    required this.numPieces,
    required this.numUploads,
    required this.numConnections,
    required this.paused,
    required this.error,
  });

  final double progress;
  final double downloadRate;
  final double uploadRate;
  final int totalDone;
  final int totalWanted;
  final int totalFailedBytes;
  final int totalRedundantBytes;
  final int state;
  final int numComplete;
  final int numIncomplete;
  final int numPieces;
  final int numUploads;
  final int numConnections;
  final bool paused;
  final String error;
}
