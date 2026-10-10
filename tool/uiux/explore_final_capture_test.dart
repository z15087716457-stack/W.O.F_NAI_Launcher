// This tool runs under flutter test; these two native/storage hooks are test APIs.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_candidate_detail_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_preference_sort_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_start_evolution_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_adopt_block_dialog.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import '../../test/helpers/studio_capture_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/common/workspace_typography_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 的异步写盘永不完成，
/// 因此 widget 测试不落盘，只验证 UI 与 provider 协作）。
import 'explore_prototype_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  final outputRoot =
      Platform.environment['EXPLORE_CAPTURE_ROOT'] ??
      '.dart_tool/uiux-explore-final';
  final output = Directory('$outputRoot/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('final full-page production widget matrix, no generation API', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      // Retain the originating layout widget when the matrix assertion fails.
      print(details.toString());
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles =
        <({String scene, int width, String locale, bool dark, String model})>[
          for (final scene in [
            'main',
            'running',
            'failed',
            'selection',
            'evolution',
            'viewer',
            'compare',
            'start-evolution',
            'save',
            'onboarding',
            'dropdown',
          ])
            for (final locale in ['zh', 'en', 'ja', 'ko'])
              for (final dark in [false, true])
                (
                  scene: scene,
                  width: 1600,
                  locale: locale,
                  dark: dark,
                  model: 'nai-diffusion-5-full',
                ),
          for (final scene in [
            'main',
            'running',
            'failed',
            'selection',
            'evolution',
            'viewer',
            'compare',
            'start-evolution',
            'save',
            'onboarding',
            'dropdown',
          ])
            for (final dark in [false, true])
              (
                scene: scene,
                width: 1280,
                locale: 'zh',
                dark: dark,
                model: 'nai-diffusion-5-full',
              ),
          for (final width in [1100, 1920])
            for (final locale in ['zh', 'en', 'ja', 'ko'])
              for (final dark in [false, true])
                (
                  scene: 'main',
                  width: width,
                  locale: locale,
                  dark: dark,
                  model: 'nai-diffusion-5-full',
                ),
          for (final model in ['nai-diffusion-4-5-full', 'nai-diffusion-3'])
            for (final dark in [false, true])
              (
                scene: 'main',
                width: 1600,
                locale: 'zh',
                dark: dark,
                model: model,
              ),
        ];
    final limit = int.tryParse(
      Platform.environment['EXPLORE_CAPTURE_LIMIT'] ?? '',
    );
    final geometry = <Object>[];
    for (final profile in limit == null ? profiles : profiles.take(limit)) {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.physicalSize = Size(profile.width.toDouble(), 1000);
      final run = finalCaptureRun(profile.scene, profile.model),
          storage = ExploreCaptureRunStorage(),
          local = ExploreCaptureSettings(),
          runner = ExploreCaptureRunner(),
          capture = ExploreCaptureManual(),
          gen = ExploreCaptureGeneration(),
          boundary = GlobalKey();
      await storage.putRun(run);
      if (profile.scene == 'dropdown') {
        await storage.putRun(
          run.copyWith(
            id: 'old',
            name: '冷色厚涂对比',
            updatedAt: run.updatedAt.subtract(const Duration(days: 1)),
          ),
        );
        await storage.putRun(
          run.copyWith(
            id: 'older',
            name: '赛璐璐 × 水彩',
            updatedAt: run.updatedAt.subtract(const Duration(days: 8)),
          ),
        );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith((_) => local),
            styleExploreRunStorageProvider.overrideWithValue(storage),
            promptBlockLibraryNotifierProvider.overrideWith(
              () => ExploreCaptureLibrary(profile.dark),
            ),
            pillWorkspaceProvider.overrideWith(ExploreCaptureWorkspace.new),
            generationParamsNotifierProvider.overrideWith(
              () => ExploreCaptureParams(profile.model),
            ),
            vibeLibraryNotifierProvider.overrideWith(ExploreCaptureVibes.new),
            vibeLibraryStorageServiceProvider.overrideWithValue(
              ExploreCaptureVibeStorage(),
            ),
            generationCooldownProvider.overrideWith(ExploreCaptureCooldown.new),
            exploreGenerateFnProvider.overrideWithValue((params) async => null),
            exploreRunRunnerProvider.overrideWith(() => runner),
            exploreManualCaptureProvider.overrideWith(() => capture),
            imageGenerationNotifierProvider.overrideWith(() => gen),
            characterPromptNotifierProvider.overrideWith(
              ExploreCaptureCharacters.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => ExploreCaptureKrita(),
            ),
            subscriptionNotifierProvider.overrideWith(
              ExploreCaptureSubscription.new,
            ),
            estimatedCostProvider.overrideWith((_) => 0),
            estimatedCostForBatchSizeProvider(1).overrideWith((_) => 0),
            isFreeGenerationProvider.overrideWith((_) => true),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: (profile.dark ? GeistTheme.dark : GeistTheme.light).copyWith(
              platform: TargetPlatform.windows,
            ),
            locale: Locale(profile.locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => RepaintBoundary(
              key: boundary,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: WorkspaceTypographyScope(child: child!),
              ),
            ),
            home: const IntegratedTitleBarShell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 48, child: ExploreCaptureRail()),
                  Expanded(child: StyleExploreScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.read(exploreActiveRunIdProvider.notifier).state =
          profile.scene == 'onboarding' ? null : run.id;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (profile.scene == 'running') {
        runner.set(
          ExploreRunRunnerState(
            runId: run.id,
            isRunning: true,
            processedCount: 8,
            totalCount: 12,
          ),
        );
      }
      if (profile.scene != 'onboarding') {
        container
            .read(exploreFocusedCandidateIdProvider.notifier)
            .state = run.candidates.length > 26
            ? run
                  .candidates[['evolution', 'compare'].contains(profile.scene)
                      ? 23
                      : 26]
                  .id
            : run.candidates.first.id;
      }
      if (['evolution', 'compare'].contains(profile.scene)) {
        container.read(exploreStageTabProvider.notifier).state =
            ExploreStageTab.evolution;
        container.read(exploreActiveFamilyIdProvider.notifier).state = 'line';
        container.read(exploreSelectionProvider.notifier).selectAll([
          'c24',
          'c27',
          'c30',
        ]);
      }
      if (profile.scene == 'selection') {
        container.read(exploreSelectionModeProvider.notifier).state = true;
        container
            .read(exploreSelectionProvider.notifier)
            .selectAll(run.candidates.skip(26).take(3).map((c) => c.id));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (['evolution', 'compare'].contains(profile.scene)) {
        await tester.enterText(
          find.byKey(const Key('explore-deep-round-count-set3')),
          '8',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        container.read(exploreFocusedCandidateIdProvider.notifier).state =
            run.candidates[23].id;
        await tester.pump();
      }
      final host = tester.element(find.byType(StyleExploreScreen));
      if (profile.scene == 'viewer') {
        unawaited(
          ExploreCandidateDetailDialog.show(
            host,
            runId: run.id,
            candidateIds: run.candidates.map((c) => c.id).toList(),
            initialIndex: 26,
          ),
        );
      }
      if (profile.scene == 'compare') {
        unawaited(
          ExplorePreferenceSortDialog.show(
            host,
            runId: run.id,
            parentSet: run.parentSetById('set3')!,
          ),
        );
      }
      if (profile.scene == 'start-evolution') {
        unawaited(
          ExploreStartEvolutionDialog.show(
            host,
            run: run,
            candidates: [
              for (final i in [26, 28, 29, 32]) run.candidates[i],
            ],
          ),
        );
      }
      if (profile.scene == 'save') {
        unawaited(
          ExploreAdoptBlockDialog.show(
            host,
            initialTitle: '柔光画风 · 精选 3',
            candidates: [
              for (final i in [26, 28, 29]) run.candidates[i],
            ],
            sequenceNumber: 27,
          ),
        );
      }
      if (profile.scene == 'start-evolution' || profile.scene == 'save') {
        await tester.pumpAndSettle();
        if (profile.scene == 'start-evolution') {
          await tester.enterText(
            find.byKey(const Key('explore-family-name')),
            '柔光主线',
          );
          await tester.enterText(
            find.byKey(const Key('explore-evolution-count')),
            '8',
          );
        } else {
          tester
              .widget<DropdownButtonFormField<String>>(
                find.byKey(const Key('explore-adopt-folder')),
              )
              .onChanged
              ?.call('style');
        }
        await tester.pump();
      }
      if (profile.scene == 'dropdown') {
        await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (profile.scene == 'compare') {
        for (var answer = 0; answer < 2; answer++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (tester
            .renderObjectList<RenderImage>(find.byType(RawImage))
            .every((r) => r.image != null)) {
          break;
        }
      }
      expect(tester.takeException(), isNull, reason: profile.toString());
      final stage = tester.getRect(
            find.byKey(const Key('style-explore-stage')),
          ),
          editor = tester.getRect(
            find.byKey(const Key('style-explore-main-editor')),
          );
      final inspector = find.byKey(const Key('style-explore-inspector'));
      expect(stage.width, greaterThanOrEqualTo(480));
      if (profile.width <= 1280) expect(inspector, findsNothing);
      final name =
          '${profile.scene}-${profile.locale}-${profile.dark ? 'dark' : 'light'}-${profile.width}-${profile.model}';
      geometry.add({
        'name': name,
        'stageWidth': stage.width,
        'editorWidth': editor.width,
        'inspector': inspector.evaluate().isNotEmpty,
      });
      await tester.runAsync(() async {
        final im =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await im.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        File('${output.path}/$name.png').writeAsBytesSync(bytes);
        im.dispose();
      });
      print('CAPTURE $name');
    }
    File('$outputRoot/geometry.json').writeAsStringSync(jsonEncode(geometry));
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 8)));
}
