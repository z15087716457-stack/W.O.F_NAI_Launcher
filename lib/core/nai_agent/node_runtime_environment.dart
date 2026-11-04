import 'dart:io';

import 'package:path/path.dart' as p;

/// Finder does not inherit a shell's PATH. Agent helpers and their children
/// must use the Node/npm shipped together, including when the app path has spaces.
Map<String, String>? nodeRuntimeEnvironment(
  String nodeExecutable, {
  bool? isMacOS,
  String? inheritedPath,
}) {
  if (!(isMacOS ?? Platform.isMacOS)) return null;
  final path = inheritedPath ?? Platform.environment['PATH'] ?? '';
  final systemPath = path.isEmpty ? '/usr/bin:/bin:/usr/sbin:/sbin' : path;
  return {'PATH': '${p.posix.dirname(p.posix.absolute(nodeExecutable))}:$systemPath'};
}
