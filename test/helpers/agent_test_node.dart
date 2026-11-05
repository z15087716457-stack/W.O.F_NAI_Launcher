import 'dart:io';

/// Uses the pinned runtime in CI and the developer's Node on PATH locally.
final agentTestNode = Platform.environment['NAI_AGENT_NODE'] ?? _nodeOnPath();

String _nodeOnPath() {
  final result = Process.runSync('node', ['-p', 'process.execPath']);
  if (result.exitCode != 0) {
    throw StateError('Could not resolve the Agent test Node: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}
