import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../utils/app_bundle_paths.dart';
import '../utils/app_logger.dart';
import 'rag_platform.dart';

typedef RagProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
    });

/// Tests running outside an app bundle point this at a local build of the
/// macOS host (`tool/rag/stdio_host.cpp`).
@visibleForTesting
String? debugRagMacOSHostOverride;

/// The POSIX host `scripts/build_macos.sh` builds into the app bundle.
String get ragMacOSHostPath =>
    debugRagMacOSHostOverride ??
    p.join(AppBundlePaths.toolsDirectory, 'rag-stdio-host');

bool _warnedMissingHost = false;

/// A suspended launch joins a Windows Job before Python/uv can spawn children.
/// On macOS the POSIX build of the same host starts them in a process group
/// of their own. Killing the host, or losing the app, reclaims only this
/// launch's descendants.
Future<Process> startRagProcess({
  required Directory directory,
  required String executable,
  required List<String> arguments,
  Map<String, String> environment = const {},
  RagPlatform? platform,
  RagProcessStarter start = Process.start,
}) async {
  final target = platform ?? RagPlatform.host;
  if (target.isMacOS) {
    final host = ragMacOSHostPath;
    if (await File(host).exists()) {
      return start(host, [
        '$pid',
        p.absolute(executable),
        ...arguments,
      ], environment: environment);
    }
    // A bundle built without scripts/build_macos.sh (e.g. a bare flutter run)
    // still works; children then rely on their stdin closing to exit.
    if (!_warnedMissingHost) {
      _warnedMissingHost = true;
      AppLogger.w('Process host missing; starting children directly', 'RAG');
    }
    return start(executable, arguments, environment: environment);
  }
  if (target != RagPlatform.windows) {
    return start(executable, arguments, environment: environment);
  }
  const digest =
      '4713d607f3a9f40561ed3b94675f0e10d42df32d228e841b61d78635498a7ee6';
  final host = File(p.join(directory.path, 'stdio-host-$digest.exe'));
  if (!await host.exists() ||
      sha256.convert(await host.readAsBytes()).toString() != digest) {
    final bytes = await rootBundle.load('assets/rag/windows/stdio_host.exe');
    final data = Uint8List.sublistView(bytes);
    if (sha256.convert(data).toString() != digest) {
      throw const FileSystemException('rag_host_integrity');
    }
    await directory.create(recursive: true);
    await host.writeAsBytes(data, flush: true);
  }
  return start(host.path, [
    '$pid',
    p.absolute(executable),
    ...arguments,
  ], environment: environment);
}
