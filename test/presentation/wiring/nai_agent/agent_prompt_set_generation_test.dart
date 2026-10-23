import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/prompt_set_tools.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_pending_mapper.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_prompt_set_actions.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_prompt_set_mapper.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../core/nai_agent/prompt_set_tools_test.dart' show promptSetInput;
import '../../providers/krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import '../../providers/nai_agent/generation_binding_test.dart'
    show
        GenerationTestAuth,
        GenerationTestLibrary,
        GenerationTestVibes,
        ControlledAgentGeneration,
        waitForAgentStart;

void main() {
  late Directory root;
  late ProviderContainer container;
  late AgentWorkspace workspace;
  late NaiAgentPromptSets sets;
  late String id;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('prompt-set-generation-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(storage),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        imageGenerationNotifierProvider.overrideWith(
          ControlledAgentGeneration.new,
        ),
        authNotifierProvider.overrideWith(GenerationTestAuth.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    workspace = await AgentWorkspaceStore(root).createWorkspace('sets');
    sets = NaiAgentPromptSets(workspace.agentDirectory);
    id =
        (await sets.execute(
              promptSetInput(),
              NaiAgentCancellation(),
            ))['details']['set_id']
            as String;
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  test(
    'idle chat standard Agent gate quotes exactly one image; completion persists thumbnail across restart',
    () async {
      final key = (workspace.directory.path, workspace.id, 'idle-chat');
      final subscription = container.listen(
        agentPromptSetGenerationProvider(key),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final tools = container.read(agentPromptSetGenerationProvider(key));
      final set = (await sets.read(id))!;
      await container
          .read(agentPromptSetActionsProvider)
          .importItem(workspace, set, 0, (_) {});
      final future = tools.requestUserGeneration(NaiAgentCancellation());
      await Future<void>.delayed(Duration.zero);
      final approvals = container.read(naiAgentGenerationApprovalsProvider),
          pending = approvals.forChat('idle-chat').single;
      final gate = agentGenerationGate(pending, currentL10n);
      expect(gate, isA<AgentGate>());
      expect(gate.requests, 1);
      expect(gate.batch, 1);
      expect(gate.balanceAnlas, 10000);
      final native =
          container.read(imageGenerationNotifierProvider.notifier)
              as ControlledAgentGeneration;
      expect(native.requests, isEmpty);
      approvals.decide(pending.id, generate: true);
      await waitForAgentStart(native);
      expect(native.requests.single.nSamples, 1);
      expect(native.sizes, [1]);
      native.finish();
      final result = (await future)['details'] as Map<String, dynamic>;
      await recordAgentPromptSetImages(
        workspace: workspace,
        setId: id,
        index: 0,
        result: result,
        check: () {},
      );
      final restarted = (await NaiAgentPromptSets(
        workspace.agentDirectory,
      ).read(id))!;
      expect(restarted['images']['0'], hasLength(1));
      expect(restarted['images']['0'][0]['image_id'], 'native-image');
      final resources = AgentResources(() {});
      addTearDown(resources.dispose);
      agentPromptSetData(restarted, workspace, resources, {});
      await resources.settle();
      expect(
        agentPromptSetData(restarted, workspace, resources, {}).images[0],
        hasLength(1),
      );
    },
  );
  test(
    'decline and failure append nothing; stale quote rejected after draft changes',
    () async {
      final key = (workspace.directory.path, workspace.id, 'idle-chat');
      final subscription = container.listen(
        agentPromptSetGenerationProvider(key),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final tools = container.read(agentPromptSetGenerationProvider(key)),
          approvals = container.read(naiAgentGenerationApprovalsProvider);
      final decline = tools.requestUserGeneration(NaiAgentCancellation());
      await Future<void>.delayed(Duration.zero);
      approvals.decide(
        approvals.forChat('idle-chat').single.id,
        generate: false,
      );
      final result = (await decline)['details'] as Map<String, dynamic>;
      await recordAgentPromptSetImages(
        workspace: workspace,
        setId: id,
        index: 0,
        result: result,
        check: () {},
      );
      expect((await sets.read(id))!['images'], isEmpty);
      final stale = tools.requestUserGeneration(NaiAgentCancellation());
      final assertion = expectLater(
        stale,
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_changed',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('user edited');
      approvals.decide(
        approvals.forChat('idle-chat').single.id,
        generate: true,
      );
      await assertion;
      await expectLater(
        recordAgentPromptSetImages(
          workspace: workspace,
          setId: id,
          index: 0,
          result: {'status': 'failed', 'error': 'Synthetic failure'},
          check: () {},
        ),
        throwsA(isA<NaiAgentToolError>()),
      );
      expect((await sets.read(id))!['images'], isEmpty);
    },
  );
}
