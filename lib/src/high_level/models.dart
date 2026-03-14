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

class AlertInfo {
  AlertInfo({
    required this.type,
    required this.category,
    required this.what,
    required this.message,
    this.torrentId,
    this.dhtEndpointAddress,
    this.dhtEndpointPort,
    this.dhtSamples = const <DhtSampleInfohash>[],
  });
  final int type;
  final int category;
  final String what;
  final String message;
  final int? torrentId;
  final String? dhtEndpointAddress;
  final int? dhtEndpointPort;
  final List<DhtSampleInfohash> dhtSamples;
}

class MagnetUriInfo {
  const MagnetUriInfo({
    required this.infohashHex,
    required this.name,
    required this.trackers,
  });
  final String infohashHex;
  final String name;
  final List<String> trackers;
}

class TorrentFileInfo {
  const TorrentFileInfo({
    required this.infohashHex,
    required this.name,
    required this.totalSize,
    required this.numFiles,
  });

  final String infohashHex;
  final String name;
  final int totalSize;
  final int numFiles;
}

class OpenFileState {
  const OpenFileState({
    required this.fileIndex,
    required this.openMode,
    required this.lastUseMs,
  });
  final int fileIndex;
  final int openMode;
  final int lastUseMs;
}

class TorrentFileEntry {
  const TorrentFileEntry({
    required this.index,
    required this.size,
    required this.offset,
    required this.flags,
    required this.path,
  });
  final int index;
  final int size;
  final int offset;
  final int flags;
  final String path;
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
    required this.ipOverheadUploadRate,
    required this.ipOverheadDownloadRate,
    required this.totalIpOverheadDownload,
    required this.totalIpOverheadUpload,
    required this.dhtUploadRate,
    required this.dhtDownloadRate,
    required this.totalDhtDownload,
    required this.totalDhtUpload,
    required this.trackerUploadRate,
    required this.trackerDownloadRate,
    required this.totalTrackerDownload,
    required this.totalTrackerUpload,
    required this.totalRedundantBytes,
    required this.totalFailedBytes,
    required this.numPeers,
    required this.numUnchoked,
    required this.allowedUploadSlots,
    required this.upBandwidthQueue,
    required this.downBandwidthQueue,
    required this.upBandwidthBytesQueue,
    required this.downBandwidthBytesQueue,
    required this.optimisticUnchokeCounter,
    required this.unchokeCounter,
    required this.dhtNodes,
    required this.dhtNodeCache,
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
  final double ipOverheadUploadRate;
  final double ipOverheadDownloadRate;
  final int totalIpOverheadDownload;
  final int totalIpOverheadUpload;
  final double dhtUploadRate;
  final double dhtDownloadRate;
  final int totalDhtDownload;
  final int totalDhtUpload;
  final double trackerUploadRate;
  final double trackerDownloadRate;
  final int totalTrackerDownload;
  final int totalTrackerUpload;
  final int totalRedundantBytes;
  final int totalFailedBytes;
  final int numPeers;
  final int numUnchoked;
  final int allowedUploadSlots;
  final int upBandwidthQueue;
  final int downBandwidthQueue;
  final int upBandwidthBytesQueue;
  final int downBandwidthBytesQueue;
  final int optimisticUnchokeCounter;
  final int unchokeCounter;
  final int dhtNodes;
  final int dhtNodeCache;
  final int dhtTorrents;
  final int dhtGlobalNodes;
}

class TorrentStatus {
  TorrentStatus({
    required this.progress,
    required this.downloadRate,
    required this.uploadRate,
    required this.downloadPayloadRate,
    required this.uploadPayloadRate,
    required this.totalDone,
    required this.totalWanted,
    required this.totalDownload,
    required this.totalUpload,
    required this.totalPayloadDownload,
    required this.totalPayloadUpload,
    required this.totalFailedBytes,
    required this.totalRedundantBytes,
    required this.state,
    required this.nextAnnounce,
    required this.announceInterval,
    required this.currentTracker,
    required this.numSeeds,
    required this.numPeers,
    required this.numComplete,
    required this.numIncomplete,
    required this.listSeeds,
    required this.listPeers,
    required this.connectCandidates,
    required this.numPieces,
    required this.totalWantedDone,
    required this.distributedCopies,
    required this.blockSize,
    required this.numUploads,
    required this.numConnections,
    required this.uploadsLimit,
    required this.connectionsLimit,
    required this.upBandwidthQueue,
    required this.downBandwidthQueue,
    required this.allTimeUpload,
    required this.allTimeDownload,
    required this.activeTime,
    required this.seedingTime,
    required this.seedRank,
    required this.lastScrape,
    required this.hasIncoming,
    required this.seedMode,
    required this.paused,
    required this.error,
  });

  final double progress;
  final double downloadRate;
  final double uploadRate;
  final double downloadPayloadRate;
  final double uploadPayloadRate;
  final int totalDone;
  final int totalWanted;
  final int totalDownload;
  final int totalUpload;
  final int totalPayloadDownload;
  final int totalPayloadUpload;
  final int totalFailedBytes;
  final int totalRedundantBytes;
  final int state;
  final int nextAnnounce;
  final int announceInterval;
  final String currentTracker;
  final int numSeeds;
  final int numPeers;
  final int numComplete;
  final int numIncomplete;
  final int listSeeds;
  final int listPeers;
  final int connectCandidates;
  final int numPieces;
  final int totalWantedDone;
  final double distributedCopies;
  final int blockSize;
  final int numUploads;
  final int numConnections;
  final int uploadsLimit;
  final int connectionsLimit;
  final int upBandwidthQueue;
  final int downBandwidthQueue;
  final int allTimeUpload;
  final int allTimeDownload;
  final int activeTime;
  final int seedingTime;
  final int seedRank;
  final int lastScrape;
  final bool hasIncoming;
  final bool seedMode;
  final bool paused;
  final String error;
}

class ProxySetting {
  const ProxySetting({
    required this.hostname,
    required this.port,
    this.username = '',
    this.password = '',
    this.type = LibtorrentProxyType.none,
  });

  final String hostname;
  final int port;
  final String username;
  final String password;
  final int type;
}

class PartialPieceInfo {
  const PartialPieceInfo({
    required this.pieceIndex,
    required this.blocksInPiece,
    required this.finished,
    required this.writing,
    required this.requested,
  });

  final int pieceIndex;
  final int blocksInPiece;
  final int finished;
  final int writing;
  final int requested;
}

class PeerInfo {
  const PeerInfo({
    required this.ip,
    required this.port,
    required this.client,
    required this.upSpeed,
    required this.downSpeed,
    required this.payloadUpSpeed,
    required this.payloadDownSpeed,
    required this.totalDownload,
    required this.totalUpload,
    required this.flags,
    required this.source,
  });

  final String ip;
  final int port;
  final String client;
  final int upSpeed;
  final int downSpeed;
  final int payloadUpSpeed;
  final int payloadDownSpeed;
  final int totalDownload;
  final int totalUpload;
  final int flags;
  final int source;
}

class DhtSampleInfohash {
  const DhtSampleInfohash({
    required this.infohashHex,
    required this.address,
    required this.port,
  });

  final String infohashHex;
  final String address;
  final int port;
}
