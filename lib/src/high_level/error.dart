part of '../libtorrent_dart.dart';

void _throwLastError(String fallback) {
  final native = calloc<ffi.LtErrorNative>();
  try {
    final rc = ffi.lt_last_error(native, sizeOf<ffi.LtErrorNative>());
    if (rc == 0 && native.ref.code != 0) {
      final message = ffi.int8ArrayToString(native.ref.message, 1024);
      throw LibtorrentException(
        message.isEmpty ? fallback : message,
        code: native.ref.code,
      );
    }
    throw LibtorrentException(fallback, code: -1);
  } finally {
    calloc.free(native);
  }
}
