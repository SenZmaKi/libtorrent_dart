part of '../libtorrent_dart.dart';

class LibtorrentSettingsTag {
  LibtorrentSettingsTag._();

  static const int listenInterfaces = 0x0000 + 5;
  static const int proxyHostname = 0x0000 + 6;
  static const int proxyUsername = 0x0000 + 7;
  static const int proxyPassword = 0x0000 + 8;

  static const int activeDownloads = 0x4000 + 41;
  static const int activeSeeds = 0x4000 + 42;
  static const int activeLimit = 0x4000 + 47;
  static const int seedTimeLimit = 0x4000 + 50;
  static const int uploadRateLimit = 0x4000 + 78;
  static const int downloadRateLimit = 0x4000 + 79;
  static const int dhtUploadRateLimit = 0x4000 + 82;
  static const int unchokeSlotsLimit = 0x4000 + 83;
  static const int connectionsLimit = 0x4000 + 85;
  static const int shareRatioLimit = 0x4000 + 109;
  static const int seedTimeRatioLimit = 0x4000 + 110;
  static const int outEncPolicy = 0x4000 + 118;
  static const int inEncPolicy = 0x4000 + 119;
  static const int allowedEncLevel = 0x4000 + 120;
  static const int proxyType = 0x4000 + 123;
  static const int proxyPort = 0x4000 + 124;
  static const int alertMask = 0x4000 + 260;

  static const int autoManagePreferSeeds = 0x8000 + 12;
  static const int enableOutgoingUtp = 0x8000 + 32;
  static const int enableIncomingUtp = 0x8000 + 33;
  static const int enableOutgoingTcp = 0x8000 + 34;
  static const int enableIncomingTcp = 0x8000 + 35;
  static const int anonymousMode = 0x8000 + 38;
}

class LibtorrentSettingType {
  LibtorrentSettingType._();

  static const int intType = 0x300;
  static const int boolType = 0x301;
  static const int stringType = 0x302;
}

class LibtorrentTag {
  LibtorrentTag._();

  static const int tagEnd = 0;

  static const int sesFingerprint = 1;
  static const int sesListenPort = 2;
  static const int sesListenPortEnd = 3;
  static const int sesVersionMajor = 4;
  static const int sesVersionMinor = 5;
  static const int sesVersionTiny = 6;
  static const int sesVersionTag = 7;
  static const int sesFlags = 8;
  static const int sesAlertMask = 9;
  static const int sesListenInterface = 10;

  static const int torFilename = 0x100;
  static const int torTorrent = 0x100 + 1;
  static const int torTorrentSize = 0x100 + 2;
  static const int torInfoHash = 0x100 + 3;
  static const int torInfoHashHex = 0x100 + 4;
  static const int torMagnetLink = 0x100 + 5;
  static const int torTrackerUrl = 0x100 + 6;
  static const int torResumeData = 0x100 + 7;
  static const int torResumeDataSize = 0x100 + 8;
  static const int torSavePath = 0x100 + 9;
  static const int torName = 0x100 + 10;
  static const int torPaused = 0x100 + 11;
  static const int torAutoManaged = 0x100 + 12;
  static const int torDuplicateIsError = 0x100 + 13;
  static const int torUserData = 0x100 + 14;
  static const int torSeedMode = 0x100 + 15;
  static const int torOverrideResumeData = 0x100 + 16;
  static const int torStorageMode = 0x100 + 17;
  static const int torRenamedFiles = 0x100 + 18;

  static const int setUploadRateLimit = 0x200;
  static const int setDownloadRateLimit = 0x200 + 1;
  static const int setLocalUploadRateLimit = 0x200 + 2;
  static const int setLocalDownloadRateLimit = 0x200 + 3;
  static const int setMaxUploadSlots = 0x200 + 4;
  static const int setMaxConnections = 0x200 + 5;
  static const int setSequentialDownload = 0x200 + 6;
  static const int setSuperSeeding = 0x200 + 7;
  static const int setHalfOpenLimit = 0x200 + 8;
  static const int setPeerProxy = 0x200 + 9;
  static const int setWebSeedProxy = 0x200 + 10;
  static const int setTrackerProxy = 0x200 + 11;
  static const int setDhtProxy = 0x200 + 12;
  static const int setProxy = 0x200 + 13;
  static const int setAlertMask = 0x200 + 14;

  static const int settingsInt = 0x300;
  static const int settingsBool = 0x300 + 1;
  static const int settingsString = 0x300 + 2;
}

class LibtorrentProxyType {
  LibtorrentProxyType._();

  static const int none = 0;
  static const int socks4 = 1;
  static const int socks5 = 2;
  static const int socks5Password = 3;
  static const int http = 4;
  static const int httpPassword = 5;
}

class LibtorrentEncryptionPolicy {
  LibtorrentEncryptionPolicy._();

  static const int forced = 0;
  static const int enabled = 1;
  static const int disabled = 2;
}

class LibtorrentEncryptionLevel {
  LibtorrentEncryptionLevel._();

  static const int plaintext = 1;
  static const int rc4 = 2;
  static const int both = 3;
}

class LibtorrentAlertCategory {
  LibtorrentAlertCategory._();

  static const int error = 0x1;
  static const int peer = 0x2;
  static const int portMapping = 0x4;
  static const int storage = 0x8;
  static const int tracker = 0x10;
  static const int debug = 0x20;
  static const int status = 0x40;
  static const int progress = 0x80;
  static const int ipBlock = 0x100;
  static const int performanceWarning = 0x200;
  static const int dht = 0x400;
  static const int all = 0xFFFFFFFF;
}

class LibtorrentTorrentState {
  LibtorrentTorrentState._();

  static const int queuedForChecking = 0;
  static const int checkingFiles = 1;
  static const int downloadingMetadata = 2;
  static const int downloading = 3;
  static const int finished = 4;
  static const int seeding = 5;
  static const int allocating = 6;
  static const int checkingResumeData = 7;
}

class LibtorrentStorageMode {
  LibtorrentStorageMode._();

  static const int allocate = 0;
  static const int sparse = 1;
}

class LibtorrentTorrentFlags {
  LibtorrentTorrentFlags._();

  static const int seedMode = 1 << 0;
  static const int uploadMode = 1 << 1;
  static const int shareMode = 1 << 2;
  static const int applyIpFilter = 1 << 3;
  static const int paused = 1 << 4;
  static const int autoManaged = 1 << 5;
  static const int duplicateIsError = 1 << 6;
  static const int updateSubscribe = 1 << 7;
  static const int superSeeding = 1 << 8;
  static const int sequentialDownload = 1 << 9;
  static const int stopWhenReady = 1 << 10;
  static const int overrideTrackers = 1 << 11;
  static const int overrideWebSeeds = 1 << 12;
  static const int needSaveResume = 1 << 13;
  static const int disableDht = 1 << 19;
  static const int disableLsd = 1 << 20;
  static const int disablePex = 1 << 21;
  static const int noVerifyFiles = 1 << 22;
  static const int defaultDontDownload = 1 << 23;
  static const int i2pTorrent = 1 << 24;
}

class LibtorrentRemoveFlags {
  LibtorrentRemoveFlags._();

  static const int deleteFiles = 1;
  static const int deletePartfile = 2;
}

class LibtorrentTagItem {
  const LibtorrentTagItem._({
    required this.tag,
    this.intValue = 0,
    this.stringValue,
    this.renamedFilesValue,
    this.bytesValue,
    this.pointerValue,
    this.size = 0,
  });

  final int tag;
  final int intValue;
  final String? stringValue;
  final Map<int, String>? renamedFilesValue;
  final Uint8List? bytesValue;
  final Pointer<Void>? pointerValue;
  final int size;

  factory LibtorrentTagItem.intValue(int tag, int value) =>
      LibtorrentTagItem._(tag: tag, intValue: value);
  factory LibtorrentTagItem.stringValue(int tag, String value) =>
      LibtorrentTagItem._(tag: tag, stringValue: value);
  factory LibtorrentTagItem.renamedFilesValue(
    int tag,
    Map<int, String> value,
  ) => LibtorrentTagItem._(
    tag: tag,
    renamedFilesValue: Map<int, String>.unmodifiable(value),
    size: value.length,
  );
  factory LibtorrentTagItem.bytesValue(int tag, Uint8List value) =>
      LibtorrentTagItem._(tag: tag, bytesValue: value, size: value.length);
  factory LibtorrentTagItem.pointerValue(
    int tag,
    Pointer<Void> value, {
    int size = 0,
  }) => LibtorrentTagItem._(tag: tag, pointerValue: value, size: size);

  factory LibtorrentTagItem.settingsInt(int settingTag, int value) =>
      LibtorrentTagItem._(
        tag: LibtorrentTag.settingsInt,
        intValue: settingTag,
        size: value,
      );

  factory LibtorrentTagItem.settingsBool(int settingTag, bool value) =>
      LibtorrentTagItem._(
        tag: LibtorrentTag.settingsBool,
        intValue: settingTag,
        size: value ? 1 : 0,
      );

  factory LibtorrentTagItem.settingsString(int settingTag, String value) =>
      LibtorrentTagItem._(
        tag: LibtorrentTag.settingsString,
        intValue: settingTag,
        stringValue: value,
      );
}
