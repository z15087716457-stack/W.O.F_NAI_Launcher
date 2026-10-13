import '../../data/services/nai_agent/agent_snapshot_files.dart';
import 'agent_tool.dart';

class NaiAgentSnapshotTool {
  NaiAgentSnapshotTool({
    required this.files,
    required this.capture,
    required this.readVersion,
    required this.isBusy,
    required this.isAlive,
    required this.prepare,
    required this.apply,
    required this.readBack,
    this.readWriteContext,
  });
  final AgentSnapshotFiles files;
  final Map<String, dynamic> Function() capture, readBack;
  final String Function() readVersion;
  final bool Function() isBusy, isAlive;
  final Object Function()? readWriteContext;
  // Parsing, validation and (only when necessary) additive block imports happen
  // here. The final draft comparison and synchronous application stay adjacent.
  final Future<Object> Function(Map<String, dynamic>, void Function()) prepare;
  final void Function(Object) apply;

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    final action = params['action'];
    switch (action) {
      case 'list':
        final offset = params['offset'] ?? 0, limit = params['limit'] ?? 20;
        if (offset is! int ||
            offset < 0 ||
            limit is! int ||
            limit < 1 ||
            limit > 50) {
          throw const NaiAgentToolError(
            'invalid_page',
            'Expected offset >= 0 and limit 1 to 50',
          );
        }
        final found = await files.list(offset: offset, limit: limit + 1);
        cancellation.check();
        return naiAgentTextResult({
          'snapshots': found.take(limit).toList(),
          'next_offset': found.length > limit ? offset + limit : null,
        });
      case 'save':
        final name = params['name'];
        if (name is! String) {
          throw const NaiAgentToolError(
            'invalid_name',
            'Provide a snapshot name',
          );
        }
        final frozen = capture();
        cancellation.check();
        final saved = await files.save(name, frozen);
        return naiAgentTextResult({'saved': saved});
      case 'read':
      case 'load':
        final id = params['id'];
        if (id is! String) {
          throw const NaiAgentToolError('invalid_id', 'Provide a snapshot ID');
        }
        final value = await files.read(id);
        cancellation.check();
        final generation = Map<String, dynamic>.from(
          value['generation'] as Map,
        );
        if (action == 'read') {
          // Keep multi-megabyte image bytes out of the model context.
          return naiAgentTextResult({
            'id': id,
            'name': value['name'],
            'draft': generation['draft'],
            'parameters': generation['image']?['params'],
            'image_workflow': generation['image_workflow'],
            'workflow_settings_saved': generation['image_workflow'] != null,
            'block_ids': (generation['blocks'] as List?)
                ?.map((e) => e['id'])
                .toList(),
            'has_source_image':
                generation['image']?['extra']?['sourceImage'] != null,
            'has_mask': generation['image']?['extra']?['maskImage'] != null,
            'vibe_count':
                (generation['image']?['extra']?['vibes'] as List?)?.length ?? 0,
            'precise_count':
                (generation['image']?['extra']?['precise'] as List?)?.length ??
                0,
          });
        }
        final expected = params['expected_version'];
        Object? initialContext;
        void check() {
          cancellation.check();
          if (!isAlive()) {
            throw const NaiAgentToolError('closed', 'Studio binding closed');
          }
          if (isBusy()) {
            throw const NaiAgentToolError(
              'busy',
              'Generation is active; configuration was not loaded',
            );
          }
          if (expected is! String || expected != readVersion()) {
            throw const NaiAgentToolError(
              'draft_conflict',
              'Read studio_context(scope=draft) again and supply its draft_version',
            );
          }
          final context = readWriteContext?.call();
          initialContext ??= context;
          if (context != initialContext) {
            throw const NaiAgentToolError(
              'draft_conflict',
              'Image workflow changed while loading; read it again',
            );
          }
        }
        check();
        final before = capture();
        final backupName = 'Before loading ${value['name']}';
        final backup = await files.save(
          backupName.length > 200 ? backupName.substring(0, 200) : backupName,
          before,
          backup: true,
        );
        check();
        final prepared = await prepare(generation, check);
        check();
        apply(prepared);
        return naiAgentTextResult({
          'loaded': id,
          'backup_path': backup['path'],
          'draft': readBack(),
          'draft_version': readVersion(),
        });
      default:
        throw const NaiAgentToolError(
          'invalid_action',
          'Expected save, list, read or load',
        );
    }
  }
}
