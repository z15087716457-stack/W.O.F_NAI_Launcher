import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
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
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_prompt_set_actions.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_prompt_set_mapper.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';
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
  setUpAll(loadStudioCaptureFonts);
  late Directory root;
  late AgentWiringHarness harness;
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
    harness = AgentWiringHarness();
    await harness.init(
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
    container = harness.container;
    await container.read(promptBlockLibraryNotifierProvider.future);
    workspace = harness.c.selected!.workspace;
    sets = NaiAgentPromptSets(workspace.agentDirectory);
    id =
        (await sets.execute(
              promptSetInput(),
              NaiAgentCancellation(),
            ))['details']['set_id']
            as String;
  });
  tearDown(() async {
    await harness.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  test(
    'idle chat click starts exactly one image with no broker gate; completion persists thumbnail across restart',
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
      // Even when the main draft asks for many images, the card authorizes one.
      final params = container.read(generationParamsNotifierProvider);
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(params.copyWith(nSamples: 7));
      container.read(imagesPerRequestProvider.notifier).state = 4;
      final approvals = container.read(naiAgentGenerationApprovalsProvider);
      final pendingCounts = <int>[];
      void observe() =>
          pendingCounts.add(approvals.forChat('idle-chat').length);
      approvals.addListener(observe);
      addTearDown(() => approvals.removeListener(observe));
      expect(approvals.forChat('idle-chat'), isEmpty);
      final future = tools.requestUserGeneration(NaiAgentCancellation());
      expect(approvals.forChat('idle-chat'), isEmpty);
      final native =
          container.read(imageGenerationNotifierProvider.notifier)
              as ControlledAgentGeneration;
      await waitForAgentStart(native);
      expect(approvals.forChat('idle-chat'), isEmpty);
      expect(native.requests.single.nSamples, 1);
      expect(native.sizes, [1]);
      native.finish();
      final result = (await future)['details'] as Map<String, dynamic>;
      expect(result['balance_before_anlas'], 10000);
      expect(result['authorization']['source'], 'user_button');
      final backup = jsonDecode(
        await File(result['backup_path'] as String).readAsString(),
      );
      expect(backup['generation']['kind'], 'generation_before_run');
      expect(approvals.forChat('idle-chat'), isEmpty);
      expect(pendingCounts, everyElement(0));
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
    'native cancellation and failure append no fake image and never queue approval',
    () async {
      final key = (workspace.directory.path, workspace.id, 'idle-chat');
      final subscription = container.listen(
        agentPromptSetGenerationProvider(key),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final tools = container.read(agentPromptSetGenerationProvider(key)),
          approvals = container.read(naiAgentGenerationApprovalsProvider);
      final token = NaiAgentCancellation();
      final running = tools.requestUserGeneration(token);
      final native =
          container.read(imageGenerationNotifierProvider.notifier)
              as ControlledAgentGeneration;
      await waitForAgentStart(native);
      expect(approvals.forChat('idle-chat'), isEmpty);
      token.cancel();
      final result = (await running)['details'] as Map<String, dynamic>;
      expect(result['status'], 'cancelled');
      expect(native.cancels, 1);
      await recordAgentPromptSetImages(
        workspace: workspace,
        setId: id,
        index: 0,
        result: result,
        check: () {},
      );
      expect((await sets.read(id))!['images'], isEmpty);
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
      expect(approvals.forChat('idle-chat'), isEmpty);
    },
  );

  test(
    'draft change during controlled backup refuses before native start',
    () async {
      final key = (workspace.directory.path, workspace.id, 'idle-chat');
      final subscription = container.listen(
        agentPromptSetGenerationProvider(key),
        (_, __) {},
      );
      addTearDown(subscription.close);
      final bound = container.read(agentPromptSetGenerationProvider(key));
      final entered = Completer<void>(), release = Completer<void>();
      // Use production input reads, native start and real backup, but hold its
      // asynchronous return so the edit is deterministic rather than gate-timed.
      final tools = NaiAgentGenerationTools(
        readInput: bound.readInput,
        approve: bound.approve,
        isAlive: bound.isAlive,
        start: bound.start,
        backup: (input) async {
          final path = await bound.backup(input);
          entered.complete();
          await release.future;
          return path;
        },
      );
      final future = tools.requestUserGeneration(NaiAgentCancellation());
      final assertion = expectLater(
        future,
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_changed',
          ),
        ),
      );
      await entered.future;
      final approvals = container.read(naiAgentGenerationApprovalsProvider);
      expect(approvals.forChat('idle-chat'), isEmpty);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('user edited during backup');
      release.complete();
      await assertion;
      final native =
          container.read(imageGenerationNotifierProvider.notifier)
              as ControlledAgentGeneration;
      expect(native.requests, isEmpty);
      expect((await sets.read(id))!['images'], isEmpty);
      expect(approvals.forChat('idle-chat'), isEmpty);
    },
  );

  testWidgets(
    'card callback locks pending import/backup and running action; no synthetic gate',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Create the fake's completion future on the real async clock before the
      // widget reads it. Otherwise finish() queues completion in the fake zone
      // while runAsync waits for it, preventing that zone from being pumped.
      final native = (await tester.runAsync(
        () async =>
            container.read(imageGenerationNotifierProvider.notifier)
                as ControlledAgentGeneration,
      ))!;
      await harness.pump(tester);
      final action = harness.panel(tester).actions.onPromptSetAction!;
      final approvals = container.read(naiAgentGenerationApprovalsProvider);
      final chat = harness.c.selected!.chat.id;
      final pendingCounts = <int>[];
      void observe() => pendingCounts.add(approvals.forChat(chat).length);
      approvals.addListener(observe);
      addTearDown(() => approvals.removeListener(observe));
      expect(approvals.forChat(chat), isEmpty);
      await tester.runAsync(() async {
        final first = action(id, 0, AgentPromptSetAction.generate);
        // Both callbacks race the disk read; the second post-read guard must
        // reject one even before a busy projection is rendered.
        final second = action(id, 0, AgentPromptSetAction.generate);
        await waitForAgentStart(native);
        expect(native.requests.single.nSamples, 1);
        expect(native.sizes, [1]);
        expect(approvals.forChat(chat), isEmpty);
        expect(await action(id, 1, AgentPromptSetAction.generate), false);
        expect(native.requests, hasLength(1));
        native.finish();
        expect(
          await Future.wait([first, second]),
          unorderedEquals([true, false]),
        );
      });
      await tester.pump();
      expect(approvals.forChat(chat), isEmpty);
      expect(pendingCounts, everyElement(0));
      expect(harness.panel(tester).data.composer.pending, isEmpty);
      expect(harness.c.calls, isNot(contains('send')));
      final restarted = (await tester.runAsync(
        () => NaiAgentPromptSets(workspace.agentDirectory).read(id),
      ))!;
      expect(restarted['images']['0'], hasLength(1));
      expect(restarted['images']['1'], isNull);
      expect(tester.takeException(), isNull);
      // No app navigation, running model turn or extra approval was needed.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
