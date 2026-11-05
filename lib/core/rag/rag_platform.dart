import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// The machine the local RAG runtime is installed on and runs from.
///
/// Production uses [host]. Services take a value instead of reading the
/// machine, so tests exercise the Windows and macOS paths on any system.
enum RagPlatform {
  /// The x64 Windows app: CUDA or CPU PyTorch, children owned by a Job.
  windows,

  /// Apple silicon: PyPI's PyTorch build, which runs on the GPU through MPS.
  macOSArm64,

  /// Intel Macs: PyTorch stopped publishing macOS x86_64 wheels after 2.2,
  /// so the pinned 2.10 runtime cannot be installed. A compatible
  /// interpreter the user selects is still probed and used.
  macOSX64,

  /// Anything else: no managed runtime; children start directly.
  other;

  static final RagPlatform host = Platform.isWindows
      ? windows
      : Platform.isMacOS
      ? (Abi.current() == Abi.macosArm64 ? macOSArm64 : macOSX64)
      : other;

  bool get isMacOS => this == macOSArm64 || this == macOSX64;

  /// Only the Windows runtime has a CUDA build. Macs use MPS or the CPU.
  bool get supportsCuda => this == windows;

  /// Interpreter of the managed uv environment under the RAG [root].
  String managedPython(String root) => this == windows
      ? p.join(root, 'runtime', 'Scripts', 'python.exe')
      : p.join(root, 'runtime', 'bin', 'python3');
}

/// Total physical memory of this Mac in bytes (`hw.memsize`, read with
/// sysctlbyname). Null on other systems or when it cannot be read.
int? readMacPhysicalMemory() {
  if (!Platform.isMacOS) return null;
  try {
    final sysctl = DynamicLibrary.process()
        .lookupFunction<
          Int Function(
            Pointer<Utf8>,
            Pointer<Void>,
            Pointer<Size>,
            Pointer<Void>,
            Size,
          ),
          int Function(
            Pointer<Utf8>,
            Pointer<Void>,
            Pointer<Size>,
            Pointer<Void>,
            int,
          )
        >('sysctlbyname');
    return using((arena) {
      final value = arena<Uint64>();
      final length = arena<Size>()..value = sizeOf<Uint64>();
      final name = 'hw.memsize'.toNativeUtf8(allocator: arena);
      final ok = sysctl(name, value.cast(), length, nullptr, 0) == 0;
      return ok && length.value == sizeOf<Uint64>() && value.value > 0
          ? value.value
          : null;
    });
  } catch (_) {
    return null;
  }
}
