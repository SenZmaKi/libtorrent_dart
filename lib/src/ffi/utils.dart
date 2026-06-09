part of '../libtorrent_dart_ffi.dart';

String int8ArrayToString(Array<Int8> array, int length) {
  final bytes = <int>[];
  for (var i = 0; i < length; i++) {
    final value = array[i];
    if (value == 0) break;
    bytes.add(value.toUnsigned(8));
  }
  return utf8.decode(bytes, allowMalformed: true);
}
