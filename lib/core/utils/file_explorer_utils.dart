import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;

typedef FileExplorerProcessLauncher =
    Future<void> Function(String executable, List<String> arguments);

typedef _CoInitializeNative = Int32 Function(Pointer<Void> pvReserved);
typedef _CoInitializeDart = int Function(Pointer<Void> pvReserved);

typedef _CoUninitializeNative = Void Function();
typedef _CoUninitializeDart = void Function();

typedef _CoTaskMemFreeNative = Void Function(Pointer<Void> pv);
typedef _CoTaskMemFreeDart = void Function(Pointer<Void> pv);

typedef _CoTaskMemAllocNative = Pointer<Void> Function(IntPtr cb);
typedef _CoTaskMemAllocDart = Pointer<Void> Function(int cb);

typedef _SHParseDisplayNameNative =
    Int32 Function(
      Pointer<Uint16> pszName,
      Pointer<Void> pbc,
      Pointer<Pointer<Void>> ppidl,
      Uint32 sfgaoIn,
      Pointer<Uint32> psfgaoOut,
    );
typedef _SHParseDisplayNameDart =
    int Function(
      Pointer<Uint16> pszName,
      Pointer<Void> pbc,
      Pointer<Pointer<Void>> ppidl,
      int sfgaoIn,
      Pointer<Uint32> psfgaoOut,
    );

typedef _SHOpenFolderAndSelectItemsNative =
    Int32 Function(
      Pointer<Void> pidlFolder,
      Uint32 cidl,
      Pointer<Pointer<Void>> apidl,
      Uint32 dwFlags,
    );
typedef _SHOpenFolderAndSelectItemsDart =
    int Function(
      Pointer<Void> pidlFolder,
      int cidl,
      Pointer<Pointer<Void>> apidl,
      int dwFlags,
    );

class FileExplorerUtils {
  FileExplorerUtils._();

  static List<String> windowsRevealFileArguments(String filePath) {
    return ['/select,', filePath];
  }

  static String normalizeWindowsExplorerPath(String filePath) {
    final normalized = filePath.trim().replaceAll('/', r'\');
    if (normalized.startsWith(r'\\?\UNC\')) {
      return r'\\' + normalized.substring(r'\\?\UNC\'.length);
    }
    if (normalized.startsWith(r'\\?\')) {
      return normalized.substring(r'\\?\'.length);
    }
    return normalized;
  }

  static Future<void> openDirectory(
    String directoryPath, {
    FileExplorerProcessLauncher? startProcess,
  }) async {
    final dir = Directory(directoryPath.trim());
    if (dir.path.isEmpty) {
      throw ArgumentError.value(directoryPath, 'directoryPath', 'is empty');
    }
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dir.path);
    }

    final launcher = startProcess ?? _startProcess;
    final absolutePath = Platform.isWindows
        ? normalizeWindowsExplorerPath(dir.absolute.path)
        : dir.absolute.path;
    if (Platform.isWindows) {
      await launcher('explorer.exe', [absolutePath]);
    } else if (Platform.isMacOS) {
      await launcher('open', [absolutePath]);
    } else if (Platform.isLinux) {
      await launcher('xdg-open', [absolutePath]);
    }
  }

  static Future<void> revealFile(
    String filePath, {
    FileExplorerProcessLauncher? startProcess,
  }) async {
    final file = File(filePath.trim());
    if (file.path.isEmpty) {
      throw ArgumentError.value(filePath, 'filePath', 'is empty');
    }
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', file.path);
    }

    final launcher = startProcess ?? _startProcess;
    final absolutePath = Platform.isWindows
        ? normalizeWindowsExplorerPath(file.absolute.path)
        : file.absolute.path;
    if (Platform.isWindows) {
      if (startProcess == null && _tryRevealFileWithShellApi(absolutePath)) {
        return;
      }
      await launcher('explorer.exe', windowsRevealFileArguments(absolutePath));
    } else if (Platform.isMacOS) {
      await launcher('open', ['-R', absolutePath]);
    } else if (Platform.isLinux) {
      await launcher('xdg-open', [path.dirname(absolutePath)]);
    }
  }

  static Future<void> _startProcess(
    String executable,
    List<String> arguments,
  ) async {
    await Process.start(executable, arguments);
  }

  static bool _tryRevealFileWithShellApi(String absolutePath) {
    try {
      return _tryRevealFileWithShellApiUnsafe(absolutePath);
    } catch (_) {
      return false;
    }
  }

  static bool _tryRevealFileWithShellApiUnsafe(String absolutePath) {
    // Explorer's /select command-line parsing is brittle for spaces and
    // extended-length paths; the Shell API selects the parsed item directly.
    final shell32 = DynamicLibrary.open('shell32.dll');
    final ole32 = DynamicLibrary.open('ole32.dll');

    final coInitialize = ole32
        .lookupFunction<_CoInitializeNative, _CoInitializeDart>('CoInitialize');
    final coUninitialize = ole32
        .lookupFunction<_CoUninitializeNative, _CoUninitializeDart>(
          'CoUninitialize',
        );
    final coTaskMemFree = ole32
        .lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>(
          'CoTaskMemFree',
        );
    final coTaskMemAlloc = ole32
        .lookupFunction<_CoTaskMemAllocNative, _CoTaskMemAllocDart>(
          'CoTaskMemAlloc',
        );
    final shParseDisplayName = shell32
        .lookupFunction<_SHParseDisplayNameNative, _SHParseDisplayNameDart>(
          'SHParseDisplayName',
        );
    final shOpenFolderAndSelectItems = shell32
        .lookupFunction<
          _SHOpenFolderAndSelectItemsNative,
          _SHOpenFolderAndSelectItemsDart
        >('SHOpenFolderAndSelectItems');

    final coInitializeResult = coInitialize(nullptr);
    const rpcEChangedMode = -2147417850;
    if (coInitializeResult < 0 && coInitializeResult != rpcEChangedMode) {
      return false;
    }

    final shouldUninitialize =
        coInitializeResult == 0 || coInitializeResult == 1;

    final nativePath = _toNativeUtf16(absolutePath, coTaskMemAlloc);
    final pidl = coTaskMemAlloc(sizeOf<Pointer<Void>>()).cast<Pointer<Void>>();
    final attributes = coTaskMemAlloc(sizeOf<Uint32>()).cast<Uint32>();
    if (nativePath == nullptr || pidl == nullptr || attributes == nullptr) {
      if (nativePath != nullptr) {
        coTaskMemFree(nativePath.cast<Void>());
      }
      if (pidl != nullptr) {
        coTaskMemFree(pidl.cast<Void>());
      }
      if (attributes != nullptr) {
        coTaskMemFree(attributes.cast<Void>());
      }
      if (shouldUninitialize) {
        coUninitialize();
      }
      return false;
    }
    pidl.value = nullptr;
    attributes.value = 0;

    try {
      final parseResult = shParseDisplayName(
        nativePath,
        nullptr,
        pidl,
        0,
        attributes,
      );
      if (parseResult != 0 || pidl.value == nullptr) {
        return false;
      }

      final openResult = shOpenFolderAndSelectItems(
        pidl.value,
        0,
        nullptr.cast<Pointer<Void>>(),
        0,
      );
      return openResult == 0;
    } finally {
      if (pidl.value != nullptr) {
        coTaskMemFree(pidl.value);
      }
      coTaskMemFree(attributes.cast<Void>());
      coTaskMemFree(pidl.cast<Void>());
      coTaskMemFree(nativePath.cast<Void>());
      if (shouldUninitialize) {
        coUninitialize();
      }
    }
  }

  static Pointer<Uint16> _toNativeUtf16(
    String value,
    _CoTaskMemAllocDart allocator,
  ) {
    final codeUnits = value.codeUnits;
    final pointer = allocator(
      (codeUnits.length + 1) * sizeOf<Uint16>(),
    ).cast<Uint16>();
    if (pointer == nullptr) {
      return pointer;
    }
    final nativeString = pointer.asTypedList(codeUnits.length + 1);
    nativeString.setAll(0, codeUnits);
    nativeString[codeUnits.length] = 0;
    return pointer;
  }
}
