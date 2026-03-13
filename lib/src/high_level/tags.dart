part of '../libtorrent_dart.dart';

class LibtorrentSettingsTag {
  LibtorrentSettingsTag._();

  static const int uploadRateLimit = 0x4000 + 54;
  static const int downloadRateLimit = 0x4000 + 55;
  static const int connectionsLimit = 0x4000 + 97;
  static const int unchokeSlotsLimit = 0x4000 + 73;
  static const int alertMask = 0x4000 + 260;

  static const int proxyType = 0x4000 + 294;
  static const int proxyPort = 0x4000 + 295;
  static const int proxyHostname = 0x0000 + 5;
  static const int proxyUsername = 0x0000 + 6;
  static const int proxyPassword = 0x0000 + 7;
}

class LibtorrentSettingType {
  LibtorrentSettingType._();

  static const int intType = 0x300;
  static const int boolType = 0x301;
  static const int stringType = 0x302;
}

class LibtorrentTag {
  LibtorrentTag._();

  static const int sesListenPort = 1;
  static const int sesListenPortEnd = 2;
  static const int sesAlertMask = 8;
  static const int sesListenInterface = 9;

  static const int torMagnetLink = 0x100 + 5;
  static const int torSavePath = 0x100 + 9;
  static const int setUploadRateLimit = 0x200;
  static const int setDownloadRateLimit = 0x200 + 1;
  static const int setMaxUploadSlots = 0x200 + 4;
  static const int setMaxConnections = 0x200 + 5;
  static const int setAlertMask = 0x200 + 14;
}

class LibtorrentTagItem {
  const LibtorrentTagItem._({
    required this.tag,
    this.intValue = 0,
    this.stringValue,
    this.bytesValue,
    this.pointerValue,
    this.size = 0,
  });

  final int tag;
  final int intValue;
  final String? stringValue;
  final Uint8List? bytesValue;
  final Pointer<Void>? pointerValue;
  final int size;

  factory LibtorrentTagItem.intValue(int tag, int value) =>
      LibtorrentTagItem._(tag: tag, intValue: value);
  factory LibtorrentTagItem.stringValue(int tag, String value) =>
      LibtorrentTagItem._(tag: tag, stringValue: value);
  factory LibtorrentTagItem.bytesValue(int tag, Uint8List value) =>
      LibtorrentTagItem._(tag: tag, bytesValue: value, size: value.length);
  factory LibtorrentTagItem.pointerValue(
    int tag,
    Pointer<Void> value, {
    int size = 0,
  }) => LibtorrentTagItem._(tag: tag, pointerValue: value, size: size);
}
