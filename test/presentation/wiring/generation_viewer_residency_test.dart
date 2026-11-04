import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/canvas_image_residency_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_viewer_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_viewer_window.dart';

import '../../helpers/app_logger_test_isolation.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings;
import 'generation_data_wiring_test.dart' show DataShortcuts;
import 'generation_history_actions_test.dart' show HistoryGeneration;
import 'generation_viewer_window_test.dart' show MemoryViewerWindow;

/// The viewer tells the canvas which images were looked at, so they keep
/// full resolution there for a while (see canvas_image_residency_test.dart).
void main() {
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await loadStudioCaptureFonts();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory dir;
  late ProviderContainer container;
  late DateTime now;
  GoRouter? router;
  final images = <GeneratedImage>[];

  setUp(() async {
    router = null;
    now = DateTime(2026, 10, 30, 12);
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('viewer_residency_');
    final generation = HistoryGeneration();
    final storage = MemoryDraftSettings();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        imageGenerationNotifierProvider.overrideWith(() => generation),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        generationViewerPlatformProvider.overrideWithValue(
          MemoryViewerWindow(),
        ),
        canvasResidencyClockProvider.overrideWithValue(() => now),
      ],
    );
    container.read(canvasPinnedNotifierProvider.notifier).debugRepository =
        CanvasPinRepository(storage: storage, directory: dir);
    await container.read(shortcutConfigNotifierProvider.future);
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 64)),
    );
    images
      ..clear()
      ..addAll([
        for (final id in ['first', 'middle', 'last'])
          GeneratedImage(
            id: id,
            bytes: bytes,
            width: 64,
            height: 64,
            generationRunId: 7,
          ),
      ]);
    container.read(imageGenerationNotifierProvider);
    generation.publish(ImageGenerationState(history: images));
  });
  tearDown(() {
    router?.dispose();
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester t, String selected) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.reset);
    final routing = router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/viewer',
          builder: (_, _) => GenerationViewerWiring(
            request: GenerationViewerRequest(images, selected),
          ),
        ),
      ],
    );
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: GeistTheme.light,
          routerConfig: routing,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    routing.push<void>('/viewer');
    await t.pump();
    await settle(t);
  }

  Map<String, DateTime> viewed() =>
      container.read(canvasImageResidencyProvider).viewed;

  testWidgets(
    'what the viewer shows counts as looked at, until it moves on or closes',
    (t) async {
      await open(t, 'middle');
      expect(viewed(), {'middle': now}, reason: 'opened');

      final opened = now;
      now = now.add(const Duration(minutes: 2));
      t.widget<ImageViewerPage>(find.byType(ImageViewerPage)).actions.onStep(1);
      await settle(t);
      expect(
        t.widget<ImageViewerPage>(find.byType(ImageViewerPage)).data.currentKey,
        'last',
      );
      expect(viewed().keys, ['middle', 'last']);
      expect(viewed()['middle'], isNot(opened), reason: 'until it moved on');

      now = now.add(const Duration(minutes: 3));
      await t.pumpWidget(const SizedBox());
      await t.pump();
      expect(viewed()['last'], now, reason: 'until the viewer closed');
      expect(t.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
