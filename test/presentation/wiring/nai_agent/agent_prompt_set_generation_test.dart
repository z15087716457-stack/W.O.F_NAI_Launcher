import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
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
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
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

  test("a card's failed Generate says why and what to do, as the error card "
      'does, and the raw error only when it cannot name it', () async {
    addTearDown(() => setCurrentL10nLocale(const Locale('zh')));
    final request = RequestOptions(path: '/ai/generate-image');
    DioException rejected(int status) => DioException.badResponse(
      statusCode: status,
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: status),
    );
    for (final locale in const [Locale('zh'), Locale('en')]) {
      setCurrentL10nLocale(locale);
      final l = lookupAppLocalizations(locale);
      Future<String> shown(Map<String, dynamic> result) async {
        try {
          await recordAgentPromptSetImages(
            workspace: workspace,
            setId: id,
            index: 0,
            result: result,
            check: () {},
          );
        } on NaiAgentToolError catch (error) {
          expect(error.code, 'generation_failed');
          return error.message;
        }
        fail('$result did not fail');
      }

      Future<String> failed(String? error) =>
          shown({'status': 'error', 'error': error});
      // The card asks for one image in one request: a 429 that waited out
      // its time is any 429 there (it has no remaining images and no Retry).
      for (final error in [
        generationConcurrencyStoppedError(
          'API_ERROR_429|Concurrent generation is locked',
        ),
        generationConcurrencyStoppedError(rejected(429)),
      ]) {
        expect(
          await failed(error),
          '${l.api_error_429}\n${l.api_error_429_hint}',
          reason: '$locale $error',
        );
      }
      for (final (status, title, hint) in [
        // Generate writes this item's prompt into the draft again, so a
        // prompt fixed on the canvas would not go out: a 400 points to the
        // parameters or to Agent. The other hints work on the card as they
        // read on the page (the import leaves parameters, model and account).
        (400, l.api_error_400, l.ag_psError400Hint),
        (401, l.api_error_401, l.api_error_401_hint),
        (402, l.api_error_402, l.api_error_402_hint),
        (403, l.api_error_403, l.api_error_403_hint),
        (404, l.api_error_404, l.api_error_404_hint),
        (500, l.api_error_500, l.api_error_500_hint),
      ]) {
        // The one request failed, streamed or not (dio's text).
        for (final error in [
          'API_ERROR_$status|Synthetic $status',
          rejected(status).toString(),
        ]) {
          expect(
            await failed(error),
            '$title\n$hint',
            reason: '$locale $error',
          );
        }
      }
      // What the error card cannot name either reads as it was, without the
      // stop marker; with no error at all, the general message.
      expect(
        await failed('No images returned from generation'),
        'No images returned from generation',
      );
      expect(
        await failed(generationStatusStoppedError('API_ERROR_UNKNOWN|odd')),
        'API_ERROR_UNKNOWN|odd',
      );
      for (final error in [null, '', generationStatusStoppedError('')]) {
        expect(await failed(error), l.naiAgent_error, reason: '$error');
      }
      expect(await shown({'status': 'interrupted'}), l.naiAgent_error);
    }
    expect((await sets.read(id))!['images'], isEmpty);
  });

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

  testWidgets(
    "the toast of a card's failed Generate gives the reason and what to do, "
    'not the internal stop marker',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final native = (await tester.runAsync(
        () async =>
            container.read(imageGenerationNotifierProvider.notifier)
                as ControlledAgentGeneration,
      ))!;
      await harness.pump(tester);
      final action = harness.panel(tester).actions.onPromptSetAction!;
      await tester.runAsync(() async {
        final generate = action(id, 0, AgentPromptSetAction.generate);
        await waitForAgentStart(native);
        // NovelAI kept the account busy (429) for the whole wait.
        native.finish(
          status: GenerationStatus.error,
          errorMessage: generationConcurrencyStoppedError(
            'API_ERROR_429|Concurrent generation is locked',
          ),
        );
        expect(await generate, isTrue);
      });
      await tester.pump();
      final l = lookupAppLocalizations(const Locale('zh'));
      expect(find.text(l.toast_titleError), findsOneWidget);
      expect(find.textContaining('GENERATION_'), findsNothing);
      expect(find.textContaining('API_ERROR_'), findsNothing);
      expect(
        find.text('${l.api_error_429}\n${l.api_error_429_hint}'),
        findsOneWidget,
      );
      final restarted = (await tester.runAsync(
        () => NaiAgentPromptSets(workspace.agentDirectory).read(id),
      ))!;
      expect(restarted['images'], isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    "after a 400 a card's Generate toast sends a prompt fix to Agent, since "
    "Generate writes the item's prompt over the one on the canvas",
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final native = (await tester.runAsync(
        () async =>
            container.read(imageGenerationNotifierProvider.notifier)
                as ControlledAgentGeneration,
      ))!;
      await harness.pump(tester);
      final action = harness.panel(tester).actions.onPromptSetAction!;
      final set = (await tester.runAsync(() => sets.read(id)))!;
      final item = container.read(agentPromptSetActionsProvider).merged(set, 0);
      await tester.runAsync(() async {
        // The prompt as the user fixed it on the canvas, as the page's 400
        // hint asks ...
        container
            .read(generationParamsNotifierProvider.notifier)
            .updatePromptImmediately('best quality, 1girl, fixed on canvas');
        final generate = action(id, 0, AgentPromptSetAction.generate);
        await waitForAgentStart(native);
        // ... does not go out: the card wrote its item's prompt back first.
        expect(native.requests.single.prompt, item['prompt']);
        expect(native.requests.single.prompt, isNot(contains('canvas')));
        native.finish(
          status: GenerationStatus.error,
          errorMessage: 'API_ERROR_400|Invalid request',
        );
        expect(await generate, isTrue);
      });
      await tester.pump();
      final l = lookupAppLocalizations(const Locale('zh'));
      expect(find.text(l.toast_titleError), findsOneWidget);
      expect(find.textContaining('API_ERROR_'), findsNothing);
      // The reason as on the page; what to do points to the parameters, or
      // to Agent for this item's prompt, then to the card's Generate.
      expect(find.textContaining(l.api_error_400_hint), findsNothing);
      expect(
        find.text('${l.api_error_400}\n${l.ag_psError400Hint}'),
        findsOneWidget,
      );
      final restarted = (await tester.runAsync(
        () => NaiAgentPromptSets(workspace.agentDirectory).read(id),
      ))!;
      expect(restarted['images'], isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
