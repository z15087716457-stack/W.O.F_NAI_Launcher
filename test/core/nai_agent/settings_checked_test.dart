import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-settings-checked-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() => root.delete(recursive: true));
  test(
    'checked writes merge unrelated fields against the latest disk state',
    () async {
      await store.patchSettings({'globalInstructions': 'original'});
      await store.patchSettings({'maxRequestsPerRun': 55});
      final saved = await store.patchSettingsChecked(
        {'globalInstructions': 'edited'},
        expected: {'globalInstructions': 'original'},
      );
      expect(saved.globalInstructions, 'edited');
      expect(saved.maxRequestsPerRun, 55);
      expect(await store.listWorkspaces(), isEmpty);
    },
  );
  test(
    'a stale prompt draft never overwrites a newer saved instruction',
    () async {
      await store.patchSettings({'globalInstructions': 'newer'});
      await expectLater(
        store.patchSettingsChecked(
          {'globalInstructions': 'stale'},
          expected: {'globalInstructions': 'old'},
        ),
        throwsStateError,
      );
      expect((await store.readSettings()).globalInstructions, 'newer');
    },
  );
  test(
    'serialized writers recheck their expected version inside the write lock',
    () async {
      await store.patchSettings({'globalInstructions': 'base'});
      final first = store.patchSettingsChecked(
        {'globalInstructions': 'first'},
        expected: {'globalInstructions': 'base'},
      );
      final second = store.patchSettingsChecked(
        {'globalInstructions': 'second'},
        expected: {'globalInstructions': 'base'},
      );
      await expectLater(second, throwsStateError);
      await first;
      expect((await store.readSettings()).globalInstructions, 'first');
    },
  );
}
