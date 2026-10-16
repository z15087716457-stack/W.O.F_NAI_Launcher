import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';

/// Keep model migration bounded without loading a whole model into memory.
Future<String> fileSha256(File file) async {
  if (!Platform.isWindows || await file.length() < 1024 * 1024) {
    return (await sha256.bind(file.openRead()).first).toString();
  }
  return _WindowsSha256.instance.hash(file);
}

class _WindowsSha256 {
  _WindowsSha256() {
    final pointer = calloc<Pointer<Void>>();
    final name = 'SHA256'.toNativeUtf16();
    try {
      _check(_open(pointer, name, nullptr, 0));
      _algorithm = pointer.value;
    } finally {
      calloc.free(pointer);
      calloc.free(name);
    }
  }

  static final instance = _WindowsSha256();
  static final _library = DynamicLibrary.open('bcrypt.dll');
  static final _open = _library
      .lookupFunction<
        Int32 Function(
          Pointer<Pointer<Void>>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Uint32,
        ),
        int Function(
          Pointer<Pointer<Void>>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          int,
        )
      >('BCryptOpenAlgorithmProvider');
  static final _create = _library
      .lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Pointer<Void>>,
          Pointer<Uint8>,
          Uint32,
          Pointer<Uint8>,
          Uint32,
          Uint32,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Pointer<Void>>,
          Pointer<Uint8>,
          int,
          Pointer<Uint8>,
          int,
          int,
        )
      >('BCryptCreateHash');
  static final _update = _library
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Uint8>, Uint32, Uint32),
        int Function(Pointer<Void>, Pointer<Uint8>, int, int)
      >('BCryptHashData');
  static final _finish = _library
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Uint8>, Uint32, Uint32),
        int Function(Pointer<Void>, Pointer<Uint8>, int, int)
      >('BCryptFinishHash');
  static final _destroy = _library
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('BCryptDestroyHash');
  late final Pointer<Void> _algorithm;

  Future<String> hash(File file) async {
    final handle = calloc<Pointer<Void>>();
    final output = calloc<Uint8>(32);
    final bufferSize = math.min(await file.length(), 4 * 1024 * 1024);
    final buffer = calloc<Uint8>(bufferSize);
    RandomAccessFile? input;
    try {
      // Windows 7+ allocates/frees the hash object when buffer/length are null/0.
      _check(_create(_algorithm, handle, nullptr, 0, nullptr, 0, 0));
      input = await file.open();
      final bytes = buffer.asTypedList(bufferSize);
      while (true) {
        final count = await input.readInto(bytes);
        if (count == 0) break;
        _check(_update(handle.value, buffer, count, 0));
      }
      _check(_finish(handle.value, output, 32, 0));
      return output
          .asTypedList(32)
          .map((value) => value.toRadixString(16).padLeft(2, '0'))
          .join();
    } finally {
      await input?.close();
      if (handle.value != nullptr) _destroy(handle.value);
      calloc.free(handle);
      calloc.free(output);
      calloc.free(buffer);
    }
  }

  static void _check(int status) {
    if (status < 0) {
      throw FileSystemException('Windows SHA-256 failed: $status');
    }
  }
}
