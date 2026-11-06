import 'dart:io';

import 'package:path/path.dart' as p;

/// Node does not inherit Dart's HttpOverrides or Windows' system proxy.
/// The Agent process follows Studio's resolved proxy, including explicit DIRECT.
Map<String, String> piHostEnvironment(
  String nodeExecutable, {
  String? proxyAddress,
}) {
  final proxy = proxyAddress == null ? '' : 'http://$proxyAddress';
  return {
    ...?nodeRuntimeEnvironment(nodeExecutable),
    'NODE_USE_ENV_PROXY': '1',
    'HTTP_PROXY': proxy,
    'HTTPS_PROXY': proxy,
    'http_proxy': proxy,
    'https_proxy': proxy,
    'ALL_PROXY': '',
    'all_proxy': '',
    'NO_PROXY': 'localhost,127.0.0.1,::1',
    'no_proxy': 'localhost,127.0.0.1,::1',
  };
}

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
  return {
    'PATH': '${p.posix.dirname(p.posix.absolute(nodeExecutable))}:$systemPath',
  };
}
