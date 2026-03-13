part of '../libtorrent_dart_ffi.dart';

String int8ArrayToString(Array<Int8> array, int length) {
  final codeUnits = <int>[];
  for (var i = 0; i < length; i++) {
    final value = array[i];
    if (value == 0) break;
    codeUnits.add(value);
  }
  return String.fromCharCodes(codeUnits);
}
