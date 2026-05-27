part of '../libtorrent_dart.dart';

class _MarshaledTagItems {
  _MarshaledTagItems(this.items, this.allocations);
  final Pointer<ffi.LtTagItemNative> items;
  final List<Pointer<Void>> allocations;

  void dispose() {
    for (final ptr in allocations) {
      calloc.free(ptr);
    }
    calloc.free(items);
  }
}

_MarshaledTagItems _marshalTagItems(List<LibtorrentTagItem> src) {
  final items = calloc<ffi.LtTagItemNative>(src.length);
  final allocations = <Pointer<Void>>[];
  for (var i = 0; i < src.length; i++) {
    final s = src[i];
    final d = (items + i).ref;
    d.tag = s.tag;
    d.int_value = s.intValue;
    d.size = s.size;
    d.string_value = nullptr;
    d.ptr_value = s.pointerValue ?? nullptr;
    if (s.stringValue != null) {
      final p = s.stringValue!.toNativeUtf8(allocator: calloc).cast<Char>();
      d.string_value = p;
      allocations.add(p.cast<Void>());
    }
    if (s.renamedFilesValue != null) {
      final values =
          s.renamedFilesValue!.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      final array = calloc<ffi.LtRenamedFileEntryNative>(values.length);
      allocations.add(array.cast<Void>());
      for (var j = 0; j < values.length; j++) {
        final p = values[j].value.toNativeUtf8(allocator: calloc).cast<Char>();
        final entry = (array + j).ref;
        entry.file_index = values[j].key;
        entry.new_filename = p;
        allocations.add(p.cast<Void>());
      }
      d.ptr_value = array.cast<Void>();
      d.size = values.length;
    }
    if (s.bytesValue != null) {
      final b = calloc<Uint8>(s.bytesValue!.length);
      b.asTypedList(s.bytesValue!.length).setAll(0, s.bytesValue!);
      d.ptr_value = b.cast<Void>();
      d.size = s.bytesValue!.length;
      allocations.add(b.cast<Void>());
    }
  }
  return _MarshaledTagItems(items, allocations);
}
