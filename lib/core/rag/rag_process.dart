import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// A suspended launch joins a Windows Job before Python/uv can spawn children.
/// Killing the host, or losing the app, reclaims only this launch's descendants.
Future<Process> startRagProcess({
  required Directory directory,
  required String executable,
  required List<String> arguments,
  Map<String, String> environment = const {},
}) async {
  if (!Platform.isWindows) {
    return Process.start(executable, arguments, environment: environment);
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
  return Process.start(host.path, [
    '$pid',
    p.absolute(executable),
    ...arguments,
  ], environment: environment);
}
