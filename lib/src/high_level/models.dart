part of '../libtorrent_dart.dart';

/// An error reported by libtorrent or the Dart wrapper.
class LibtorrentException implements Exception {
  /// Creates an exception with a human-readable [message] and native [code].
  LibtorrentException(this.message, {this.code = 0});

  /// A description of the failed operation.
  final String message;

  /// The native libtorrent error code, or zero when unavailable.
  final int code;

  @override
  String toString() => 'LibtorrentException(code: $code, message: $message)';
}

/// A text alert emitted by a libtorrent session.
class AlertMessage {
  /// Creates an alert with its [message] and category bitmask.
  AlertMessage({required this.message, required this.category});

  /// Human-readable alert text.
  final String message;

  /// The alert category bitmask.
  final int category;
}

/// Structured details for an alert emitted by a session.
class AlertInfo {
  /// Creates structured alert information.
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

  /// The native alert type identifier.
  final int type;

  /// The alert category bitmask.
  final int category;

  /// The native alert name.
  final String what;

  /// Human-readable alert text.
  final String message;

  /// The related torrent identifier, when applicable.
  final int? torrentId;

  /// The related DHT endpoint address, when applicable.
  final String? dhtEndpointAddress;

  /// The related DHT endpoint port, when applicable.
  final int? dhtEndpointPort;

  /// Infohash samples carried by a DHT sample alert.
  final List<DhtSampleInfohash> dhtSamples;
}

/// Metadata extracted from a magnet URI.
class MagnetUriInfo {
  /// Creates parsed magnet metadata.
  const MagnetUriInfo({
    required this.infohashHex,
    required this.name,
    required this.trackers,
  });

  /// The hexadecimal torrent infohash.
  final String infohashHex;

  /// The display name supplied by the magnet URI.
  final String name;

  /// Tracker URLs supplied by the magnet URI.
  final List<String> trackers;
}

/// Basic metadata read from a torrent file.
class TorrentFileInfo {
  /// Creates torrent-file metadata.
  const TorrentFileInfo({
    required this.infohashHex,
    required this.name,
    required this.totalSize,
    required this.numFiles,
  });

  /// The hexadecimal torrent infohash.
  final String infohashHex;

  /// The torrent name.
  final String name;

  /// Total content size in bytes.
  final int totalSize;

  /// Number of files in the torrent.
  final int numFiles;
}

/// High-level settings used to configure a [Session].
class SessionConfig {
  /// Creates a session configuration containing only the supplied overrides.
  const SessionConfig({
    this.uploadRateLimit,
    this.downloadRateLimit,
    this.connectionsLimit,
    this.unchokeSlotsLimit,
    this.activeDownloads,
    this.activeSeeds,
    this.activeLimit,
    this.seedRatioLimit,
    this.seedTimeLimit,
    this.seedTimeRatioLimit,
    this.torrentPort,
    this.outgoingEncryptionPolicy,
    this.incomingEncryptionPolicy,
    this.allowedEncryptionLevel,
    this.anonymousMode,
    this.enableIncomingTcp,
    this.enableIncomingUtp,
    this.enableOutgoingTcp,
    this.enableOutgoingUtp,
    this.autoManagePreferSeeds,
    this.proxy,
  });

  /// Global upload rate limit in bytes per second.
  final int? uploadRateLimit;

  /// Global download rate limit in bytes per second.
  final int? downloadRateLimit;

  /// Maximum number of peer connections.
  final int? connectionsLimit;

  /// Maximum number of unchoked peers.
  final int? unchokeSlotsLimit;

  /// Maximum number of active downloads.
  final int? activeDownloads;

  /// Maximum number of active seeds.
  final int? activeSeeds;

  /// Maximum number of active torrents.
  final int? activeLimit;

  /// Share-ratio limit used by auto-managed torrents.
  final int? seedRatioLimit;

  /// Seed-time limit used by auto-managed torrents.
  final Duration? seedTimeLimit;

  /// Seed-time ratio limit used by auto-managed torrents.
  final int? seedTimeRatioLimit;

  /// TCP and uTP listening port.
  final int? torrentPort;

  /// Outgoing encryption policy from [LibtorrentEncryptionPolicy].
  final int? outgoingEncryptionPolicy;

  /// Incoming encryption policy from [LibtorrentEncryptionPolicy].
  final int? incomingEncryptionPolicy;

  /// Allowed encryption level from [LibtorrentEncryptionLevel].
  final int? allowedEncryptionLevel;

  /// Whether anonymous mode is enabled.
  final bool? anonymousMode;

  /// Whether incoming TCP connections are enabled.
  final bool? enableIncomingTcp;

  /// Whether incoming uTP connections are enabled.
  final bool? enableIncomingUtp;

  /// Whether outgoing TCP connections are enabled.
  final bool? enableOutgoingTcp;

  /// Whether outgoing uTP connections are enabled.
  final bool? enableOutgoingUtp;

  /// Whether auto-management should prefer seeding torrents.
  final bool? autoManagePreferSeeds;

  /// Proxy configuration applied to the session.
  final ProxySetting? proxy;

  /// Converts the configured values into libtorrent setting tag items.
  List<LibtorrentTagItem> toSettingsItems() {
    final torrentPort = this.torrentPort;
    return [
      if (uploadRateLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.uploadRateLimit,
          uploadRateLimit!,
        ),
      if (downloadRateLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.downloadRateLimit,
          downloadRateLimit!,
        ),
      if (connectionsLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.connectionsLimit,
          connectionsLimit!,
        ),
      if (unchokeSlotsLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.unchokeSlotsLimit,
          unchokeSlotsLimit!,
        ),
      if (activeDownloads != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.activeDownloads,
          activeDownloads!,
        ),
      if (activeSeeds != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.activeSeeds,
          activeSeeds!,
        ),
      if (activeLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.activeLimit,
          activeLimit!,
        ),
      if (seedRatioLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.shareRatioLimit,
          seedRatioLimit!,
        ),
      if (seedTimeLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.seedTimeLimit,
          seedTimeLimit!.inSeconds,
        ),
      if (seedTimeRatioLimit != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.seedTimeRatioLimit,
          seedTimeRatioLimit!,
        ),
      if (torrentPort != null)
        LibtorrentTagItem.settingsString(
          LibtorrentSettingsTag.listenInterfaces,
          SessionConfig.listenInterfacesForPort(torrentPort),
        ),
      if (outgoingEncryptionPolicy != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.outEncPolicy,
          outgoingEncryptionPolicy!,
        ),
      if (incomingEncryptionPolicy != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.inEncPolicy,
          incomingEncryptionPolicy!,
        ),
      if (allowedEncryptionLevel != null)
        LibtorrentTagItem.settingsInt(
          LibtorrentSettingsTag.allowedEncLevel,
          allowedEncryptionLevel!,
        ),
      if (anonymousMode != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.anonymousMode,
          anonymousMode!,
        ),
      if (enableIncomingTcp != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.enableIncomingTcp,
          enableIncomingTcp!,
        ),
      if (enableIncomingUtp != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.enableIncomingUtp,
          enableIncomingUtp!,
        ),
      if (enableOutgoingTcp != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.enableOutgoingTcp,
          enableOutgoingTcp!,
        ),
      if (enableOutgoingUtp != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.enableOutgoingUtp,
          enableOutgoingUtp!,
        ),
      if (autoManagePreferSeeds != null)
        LibtorrentTagItem.settingsBool(
          LibtorrentSettingsTag.autoManagePreferSeeds,
          autoManagePreferSeeds!,
        ),
    ];
  }

  /// Builds IPv4 and IPv6 listen-interface values for [port].
  static String listenInterfacesForPort(int port) {
    if (port < 0 || port > 65535) {
      throw RangeError.range(port, 0, 65535, 'port');
    }
    return '0.0.0.0:$port,[::]:$port';
  }
}

/// Describes a file currently held open by libtorrent.
class OpenFileState {
  /// Creates an open-file state snapshot.
  const OpenFileState({
    required this.fileIndex,
    required this.openMode,
    required this.lastUseMs,
  });

  /// Index of the file within the torrent.
  final int fileIndex;

  /// Native file open-mode flags.
  final int openMode;

  /// Milliseconds since the file was last used.
  final int lastUseMs;
}

/// Metadata for one file within a torrent.
class TorrentFileEntry {
  /// Creates a torrent file entry.
  const TorrentFileEntry({
    required this.index,
    required this.size,
    required this.offset,
    required this.flags,
    required this.path,
  });

  /// Index of the file within the torrent.
  final int index;

  /// File size in bytes.
  final int size;

  /// Byte offset within the torrent payload.
  final int offset;

  /// Native libtorrent file flags.
  final int flags;

  /// Relative file path.
  final String path;
}

/// A snapshot of aggregate session transfer and DHT statistics.
class SessionStatus {
  /// Creates a session status snapshot.
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

/// A snapshot of a torrent's transfer, peer, and lifecycle state.
class TorrentStatus {
  /// Creates a torrent status snapshot.
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

/// Proxy settings for peer, tracker, and DHT traffic.
class ProxySetting {
  /// Creates a proxy configuration.
  const ProxySetting({
    required this.hostname,
    required this.port,
    this.username = '',
    this.password = '',
    this.type = LibtorrentProxyType.none,
  });

  /// Proxy host name or IP address.
  final String hostname;

  /// Proxy port.
  final int port;

  /// Optional proxy username.
  final String username;

  /// Optional proxy password.
  final String password;

  /// Proxy type from [LibtorrentProxyType].
  final int type;
}

/// Download-block counts for a partially completed piece.
class PartialPieceInfo {
  /// Creates partial-piece information.
  const PartialPieceInfo({
    required this.pieceIndex,
    required this.blocksInPiece,
    required this.finished,
    required this.writing,
    required this.requested,
  });

  /// Torrent piece index.
  final int pieceIndex;

  /// Number of blocks in the piece.
  final int blocksInPiece;

  /// Number of finished blocks.
  final int finished;

  /// Number of blocks being written.
  final int writing;

  /// Number of requested blocks.
  final int requested;
}

/// Transfer and connection information for a peer.
class PeerInfo {
  /// Creates a peer information snapshot.
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

  /// Peer IP address.
  final String ip;

  /// Peer port.
  final int port;

  /// Reported BitTorrent client name.
  final String client;

  /// Upload speed in bytes per second.
  final int upSpeed;

  /// Download speed in bytes per second.
  final int downSpeed;

  /// Payload upload speed in bytes per second.
  final int payloadUpSpeed;

  /// Payload download speed in bytes per second.
  final int payloadDownSpeed;

  /// Total bytes downloaded from this peer.
  final int totalDownload;

  /// Total bytes uploaded to this peer.
  final int totalUpload;

  /// Native peer flags.
  final int flags;

  /// Native peer discovery-source flags.
  final int source;
}

/// An infohash and endpoint returned by a DHT sample alert.
class DhtSampleInfohash {
  /// Creates a DHT sample entry.
  const DhtSampleInfohash({
    required this.infohashHex,
    required this.address,
    required this.port,
  });

  /// Sampled hexadecimal infohash.
  final String infohashHex;

  /// Address of the DHT node that supplied the sample.
  final String address;

  /// Port of the DHT node that supplied the sample.
  final int port;
}
