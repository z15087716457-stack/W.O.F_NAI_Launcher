// Independent in-memory workbench. No auth, generation, user storage or tray.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_controls.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_adopt_block_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_candidate_detail_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_preference_sort_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_start_evolution_dialog.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_text_coverage.dart';
import 'package:nai_launcher/presentation/widgets/common/workspace_typography_scope.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'explore_prototype_fixture.dart';

const _output = String.fromEnvironment('EXPLORE_CAPTURE_OUTPUT');
final _boundary = GlobalKey(), _host = GlobalKey();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  var scene = 'main', locale = 'zh', model = 'nai-diffusion-5-full';
  var width = 1600.0;
  final dark = args.contains('--dark');
  for (final arg in args) {
    if (arg.startsWith('--scene=')) scene = arg.substring(8);
    if (arg.startsWith('--width=')) width = double.parse(arg.substring(8));
    if (arg.startsWith('--locale=')) locale = arg.substring(9);
    if (arg.startsWith('--model=')) model = arg.substring(8);
  }
  final errors = <String>[];
  FlutterError.onError = (details) {
    errors.add(details.toString());
  };
  await windowManager.ensureInitialized();
  await windowManager.setTitle('Explore UI capture — independent fixture');
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setSize(Size(width, 1000));
  await StudioTextCoverage.preload();
  final run = finalCaptureRun(scene == 'help' ? 'evolution' : scene, model),
      storage = ExploreCaptureRunStorage();
  await storage.putRun(run);
  final settings = ExploreCaptureSettings(), runner = ExploreCaptureRunner();
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWith((_) => settings),
      styleExploreRunStorageProvider.overrideWithValue(storage),
      promptBlockLibraryNotifierProvider.overrideWith(
        () => ExploreCaptureLibrary(dark),
      ),
      pillWorkspaceProvider.overrideWith(ExploreCaptureWorkspace.new),
      generationParamsNotifierProvider.overrideWith(
        () => ExploreCaptureParams(model),
      ),
      vibeLibraryNotifierProvider.overrideWith(ExploreCaptureVibes.new),
      vibeLibraryStorageServiceProvider.overrideWithValue(
        ExploreCaptureVibeStorage(),
      ),
      generationCooldownProvider.overrideWith(ExploreCaptureCooldown.new),
      exploreGenerateFnProvider.overrideWithValue((_) async => null),
      exploreRunRunnerProvider.overrideWith(() => runner),
      exploreManualCaptureProvider.overrideWith(ExploreCaptureManual.new),
      imageGenerationNotifierProvider.overrideWith(
        ExploreCaptureGeneration.new,
      ),
      characterPromptNotifierProvider.overrideWith(
        ExploreCaptureCharacters.new,
      ),
      promptTokenUsageProvider(PromptTokenCountTarget.positive).overrideWith(
        (_) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
      ),
      promptTokenUsageProvider(PromptTokenCountTarget.negative).overrideWith(
        (_) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
      ),
      kritaBridgeNotifierProvider.overrideWith((_) => ExploreCaptureKrita()),
      subscriptionNotifierProvider.overrideWith(ExploreCaptureSubscription.new),
      estimatedCostProvider.overrideWith((_) => 0),
      estimatedCostForBatchSizeProvider(1).overrideWith((_) => 0),
      isFreeGenerationProvider.overrideWith((_) => true),
    ],
  );
  await container.read(exploreRunListNotifierProvider.future);
  container.read(exploreActiveRunIdProvider.notifier).state =
      scene == 'onboarding' ? null : run.id;
  if (scene == 'running') {
    runner.set(
      ExploreRunRunnerState(
        runId: run.id,
        isRunning: true,
        processedCount: 8,
        totalCount: 12,
      ),
    );
  }
  if (scene == 'selection') {
    container.read(exploreSelectionModeProvider.notifier).state = true;
    container.read(exploreSelectionProvider.notifier).selectAll([
      for (final i in [26, 28, 29, 32]) run.candidates[i].id,
    ]);
  }
  if (['evolution', 'compare', 'help'].contains(scene)) {
    container.read(exploreStageTabProvider.notifier).state =
        ExploreStageTab.evolution;
  }
  if (run.candidates.isNotEmpty) {
    container.read(exploreFocusedCandidateIdProvider.notifier).state = run
        .candidates[['evolution', 'compare', 'help'].contains(scene) ? 23 : 26]
        .id;
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
          platform: TargetPlatform.windows,
        ),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => RepaintBoundary(
          key: _boundary,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: WorkspaceTypographyScope(child: child!),
          ),
        ),
        home: IntegratedTitleBarShell(
          child: Row(
            children: [
              const SizedBox(width: 48, child: ExploreCaptureRail()),
              Expanded(child: StyleExploreScreen(key: _host)),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  final initialView = ui.PlatformDispatcher.instance.views.first;
  final client = initialView.physicalSize / initialView.devicePixelRatio;
  if ((client.width - width).abs() > .1 || (client.height - 1000).abs() > .1) {
    await windowManager.setSize(
      Size(width + width - client.width, 1000 + 1000 - client.height),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  if (run.candidates.isNotEmpty) {
    container.read(exploreFocusedCandidateIdProvider.notifier).state = run
        .candidates[['evolution', 'compare', 'help'].contains(scene) ? 23 : 26]
        .id;
  }
  if (['evolution', 'compare', 'help'].contains(scene)) {
    container.read(exploreActiveFamilyIdProvider.notifier).state = 'line';
    container.read(exploreSelectionProvider.notifier).selectAll([
      'c24',
      'c27',
      'c30',
    ]);
  }
  final context = _host.currentContext!;
  if (!context.mounted) exit(1);
  if (['evolution', 'compare', 'help'].contains(scene)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final entry = _elementWithKey(
      context as Element,
      'explore-deep-round-count-set3',
    )?.widget;
    if (entry is TextField) entry.controller!.text = '8';
    container.read(exploreFocusedCandidateIdProvider.notifier).state =
        run.candidates[23].id;
  }
  if (scene == 'main') {
    final hovered = _elementWithKey(
      context as Element,
      'explore-candidate-c29',
    );
    final box = hovered?.findRenderObject();
    if (box is RenderBox) {
      final point = box.localToGlobal(Offset(box.size.width / 2, 100));
      WidgetsBinding.instance.handlePointerEvent(
        PointerAddedEvent(
          device: 42,
          kind: PointerDeviceKind.mouse,
          position: point,
        ),
      );
      WidgetsBinding.instance.handlePointerEvent(
        PointerHoverEvent(
          device: 42,
          kind: PointerDeviceKind.mouse,
          position: point,
        ),
      );
    }
  }
  if (scene == 'help') {
    final button = _elementWithKey(
      context as Element,
      'explore-evolution-help',
    )?.widget;
    if (button is! ExploreButton || button.onPressed == null) {
      throw StateError('Missing tutorial entry');
    }
    button.onPressed!();
  }
  if (scene == 'viewer') {
    if (!context.mounted) exit(1);
    unawaited(
      ExploreCandidateDetailDialog.show(
        context,
        runId: run.id,
        candidateIds: run.candidates.map((c) => c.id).toList(),
        initialIndex: 26,
      ),
    );
  }
  if (scene == 'compare') {
    if (!context.mounted) exit(1);
    unawaited(
      ExplorePreferenceSortDialog.show(
        context,
        runId: run.id,
        parentSet: run.parentSetById('set3')!,
      ),
    );
  }
  if (scene == 'start-evolution') {
    if (!context.mounted) exit(1);
    unawaited(
      ExploreStartEvolutionDialog.show(
        context,
        run: run,
        candidates: [
          for (final i in [26, 28, 29, 32]) run.candidates[i],
        ],
      ),
    );
  }
  if (scene == 'save') {
    if (!context.mounted) exit(1);
    unawaited(
      ExploreAdoptBlockDialog.show(
        context,
        initialTitle: '柔光画风 · 精选 3',
        candidates: [
          for (final i in [26, 28, 29]) run.candidates[i],
        ],
        sequenceNumber: 27,
      ),
    );
  }
  if (scene == 'start-evolution' || scene == 'save') {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final root = WidgetsBinding.instance.rootElement!;
    if (scene == 'start-evolution') {
      final name = _elementWithKey(root, 'explore-family-name')?.widget;
      final count = _elementWithKey(root, 'explore-evolution-count')?.widget;
      if (name is TextField) name.controller!.text = '柔光主线';
      if (count is TextField) {
        count.controller!.text = '8';
        count.onChanged?.call('8');
      }
    } else {
      final folder = _elementWithKey(root, 'explore-adopt-folder')?.widget;
      if (folder is DropdownButtonFormField<String>) {
        folder.onChanged?.call('style');
      }
    }
  }
  if (scene == 'compare') {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (var answer = 0; answer < 2; answer++) {
      final skip = _elementWithKey(
        WidgetsBinding.instance.rootElement!,
        'explore-sort-skip',
      )?.widget;
      if (skip is ExploreButton) skip.onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  final render =
      _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final view = ui.PlatformDispatcher.instance.views.first;
  final stem =
      '$scene-$locale-${dark ? 'dark' : 'light'}-${width.toInt()}-${StudioTextCoverage.exponent}';
  final dir = Directory(_output);
  await dir.create(recursive: true);
  for (final scale in [1.0, view.devicePixelRatio]) {
    final image = await render.toImage(pixelRatio: scale);
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$_output/$stem-${scale == 1 ? 'logical' : 'physical'}.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }
  await File('$_output/$stem.json').writeAsString(
    jsonEncode({
      'pid': pid,
      'scene': scene,
      'logicalSize': [render.size.width, render.size.height],
      'physicalSize': [view.physicalSize.width, view.physicalSize.height],
      'devicePixelRatio': view.devicePixelRatio,
      'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
      'coverageExponent': dark ? 1 : StudioTextCoverage.exponent,
      'errors': errors,
      'storage': 'memory only',
      'generationCalls': 0,
    }),
  );
  // Close through WM_CLOSE so the runner destroys its view before quitting.
  runApp(const SizedBox.shrink());
  await WidgetsBinding.instance.endOfFrame;
  container.dispose();
  await windowManager.setPreventClose(false);
  await windowManager.close();
}

Element? _elementWithKey(Element root, String key) {
  if (root.widget.key == ValueKey(key)) return root;
  Element? found;
  root.visitChildren((child) {
    found ??= _elementWithKey(child, key);
  });
  return found;
}
