import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/nai_agent/node_runtime_environment.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import 'nai_agent_workspace_provider.dart';

AgentSettings watchNaiAgentInventorySettings(
  Ref ref,
  String? workspaceId, {
  bool includeSkills = false,
}) {
  ref.watch(
    naiAgentUiPreferencesProvider.select((preferences) {
      final settings = preferences.settings;
      return jsonEncode([
        for (final item in settings.packages)
          if (item.workspaceId == null || item.workspaceId == workspaceId)
            item.toJson(),
        if (includeSkills) ...[settings.disabledSkills, settings.skillModes],
      ]);
    }),
  );
  return ref.read(naiAgentUiPreferencesProvider).settings;
}

/// Lives for one refresh revision. Auto-disposed views can reuse the latest
/// result per workspace without keeping any inventory views subscribed.
class NaiAgentInventoryCache<T> {
  final _entries = <String?, ({String signature, Future<T> result})>{};

  Future<T> read(
    String? workspaceId,
    Map<String, dynamic> config,
    Future<T> Function() load,
  ) {
    final signature = jsonEncode(config);
    final current = _entries[workspaceId];
    if (current != null && current.signature == signature) {
      return current.result;
    }

    // Pi owns package discovery. Rescan when revisiting enabled package
    // inventories, while still sharing any ongoing request.
    final packages = config['packages'] as Map<String, dynamic>;
    final entries = packages['entries'] as List<Map<String, Object>>;
    final retain = !entries.any((entry) => entry['enabled'] == true);
    final result = Future<T>.sync(load);
    _entries[workspaceId] = (signature: signature, result: result);
    void remove() {
      if (identical(_entries[workspaceId]?.result, result)) {
        _entries.remove(workspaceId);
      }
    }

    unawaited(
      result.then<void>((_) {
        if (!retain) remove();
      }, onError: (Object _, StackTrace __) => remove()),
    );
    return result;
  }
}

/// Run the same local resolver as the host, without starting a session.
Future<Map<String, dynamic>> readNaiAgentInventory({
  required String node,
  required String script,
  required Map<String, dynamic> config,
  required Duration timeout,
}) async {
  final process = await Process.start(
    node,
    [script],
    workingDirectory: p.dirname(script),
    environment: nodeRuntimeEnvironment(node),
  );
  final stdout = process.stdout.transform(utf8.decoder).join();
  unawaited(process.stderr.drain<void>());
  process.stdin.writeln(jsonEncode(config));
  await process.stdin.close();
  try {
    final (output, exitCode) = await (
      stdout,
      process.exitCode,
    ).wait.timeout(timeout);
    if (exitCode != 0) {
      throw ProcessException(
        node,
        [script],
        'Agent inventory failed',
        exitCode,
      );
    }
    final value =
        jsonDecode(const LineSplitter().convert(output).first)
            as Map<String, dynamic>;
    if (value['error'] case final String error) throw StateError(error);
    return value;
  } on TimeoutException {
    process.kill();
    rethrow;
  }
}
