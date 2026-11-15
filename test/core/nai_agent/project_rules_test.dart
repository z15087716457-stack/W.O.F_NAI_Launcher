import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-project-rules-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));

  test('new workspaces do not create a separate rule file', () async {
    final workspace = await store.createWorkspace('New');
    expect(
      await File(
        p.join(workspace.agentDirectory.path, 'instructions.md'),
      ).exists(),
      false,
    );
    expect(
      await File(p.join(workspace.directory.path, 'AGENTS.md')).exists(),
      false,
    );
    await store.effectiveSystemPrompt(workspace.id);
    expect(
      await File(p.join(workspace.directory.path, 'AGENTS.md')).exists(),
      false,
    );
  });

  test('legacy rules are backed up, consolidated once and retired', () async {
    final workspace = await store.createWorkspace('Legacy');
    final metadata = File(
      p.join(workspace.agentDirectory.path, 'workspace.json'),
    );
    final value =
        jsonDecode(await metadata.readAsString()) as Map<String, dynamic>;
    await metadata.writeAsString(jsonEncode({...value, 'schema': 1}));
    final project = File(p.join(workspace.directory.path, 'AGENTS.md'));
    await project.writeAsString('PROJECT_ORIGINAL');
    final active = File(
      p.join(workspace.agentDirectory.path, 'instructions.md'),
    );
    final misplaced = File(p.join(workspace.directory.path, 'instructions.md'));
    await active.writeAsString('LEGACY_ACTIVE');
    await misplaced.writeAsString('LEGACY_EDITOR');

    final prompt = await store.effectiveSystemPrompt(workspace.id);
    expect(
      prompt,
      contains('PROJECT_ORIGINAL\n\nLEGACY_ACTIVE\n\nLEGACY_EDITOR'),
    );
    expect(await active.exists(), false);
    expect(await misplaced.exists(), false);
    final history = await Directory(
      p.join(workspace.agentDirectory.path, 'prompt-history'),
    ).list().toList();
    expect(history, hasLength(1));
    final backup =
        jsonDecode(await File(history.single.path).readAsString()) as Map;
    expect(backup['projectRules'], 'PROJECT_ORIGINAL');
    expect((backup['retiredFiles'] as Map).values.toSet(), {
      'LEGACY_ACTIVE',
      'LEGACY_EDITOR',
    });
    final bytes = await project.readAsBytes();
    await AgentWorkspaceStore(root).effectiveSystemPrompt(workspace.id);
    expect(await project.readAsBytes(), bytes);
    expect(
      await Directory(
        p.join(workspace.agentDirectory.path, 'prompt-history'),
      ).list().length,
      1,
    );
  });

  test(
    'retired filenames are not a rule source in current workspaces',
    () async {
      final workspace = await store.createWorkspace('Current');
      await File(
        p.join(workspace.agentDirectory.path, 'instructions.md'),
      ).writeAsString('UNUSED_RULE');
      final project = File(p.join(workspace.directory.path, 'AGENTS.md'));
      await project.writeAsString('CURRENT_RULE');
      final prompt = await store.effectiveSystemPrompt(workspace.id);
      expect(prompt, contains('CURRENT_RULE'));
      expect(prompt, isNot(contains('UNUSED_RULE')));
      expect('CURRENT_RULE'.allMatches(prompt), hasLength(1));
    },
  );
}
