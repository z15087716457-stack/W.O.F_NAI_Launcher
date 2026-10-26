import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
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
import 'generation_history_actions_test.dart' show HistoryGeneration;
import 'generation_data_wiring_test.dart' show DataShortcuts;
import 'generation_viewer_window_test.dart' show MemoryViewerWindow;

class _Generation extends HistoryGeneration {
  bool failDelete = false;
  @override
  void removeImages(Set<String> imageIds) {
    if (failDelete) throw StateError('Fixture deletion failed');
    super.removeImages(imageIds);
  }
}

void main() {
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await loadStudioCaptureFonts();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory dir;
  late ProviderContainer container;
  GoRouter? router;
  late _Generation generation;
  late List<GeneratedImage> images;
  late MemoryViewerWindow window;
  setUp(() async {
    router = null;
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('viewer_delete_');
    generation = _Generation();
    window = MemoryViewerWindow();
    final storage = MemoryDraftSettings();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        imageGenerationNotifierProvider.overrideWith(() => generation),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        generationViewerPlatformProvider.overrideWithValue(window),
      ],
    );
    container.read(canvasPinnedNotifierProvider.notifier).debugRepository =
        CanvasPinRepository(storage: storage, directory: dir);
    await container.read(shortcutConfigNotifierProvider.future);
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 64)),
    );
    images = [
      for (final id in ['first', 'middle', 'last'])
        GeneratedImage(
          id: id,
          bytes: bytes,
          width: 64,
          height: 64,
          metadata: const NaiImageMetadata(seed: 111),
          generationRunId: 7,
        ),
    ];
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

  Future<void> open(WidgetTester t, {String selected = 'first'}) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 1000);
    addTearDown(t.view.reset);
    final routing = router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('viewer-home')),
        ),
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

  ImageViewerPage viewer(WidgetTester t) =>
      t.widget<ImageViewerPage>(find.byType(ImageViewerPage));

  for (final selected in ['first', 'middle', 'last']) {
    testWidgets('deleting selected $selected selects a surviving neighbor', (
      t,
    ) async {
      await open(t, selected: selected);
      viewer(t).actions.onDelete(selected);
      await settle(t);
      expect(viewer(t).data.total, 2);
      expect(
        viewer(t).data.items.map((item) => item.key),
        images.where((image) => image.id != selected).map((image) => image.id),
      );
      expect(
        viewer(t).data.currentKey,
        selected == 'first'
            ? 'middle'
            : selected == 'middle'
            ? 'last'
            : 'middle',
      );
      expect(viewer(t).data.position, selected == 'first' ? 0 : 1);
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(2),
      );
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'deleting another image retains selection and navigation uses survivors',
    (t) async {
      await open(t, selected: 'last');
      viewer(t).actions.onDelete('first');
      await settle(t);
      expect(viewer(t).data.currentKey, 'last');
      expect(viewer(t).data.position, 1);
      viewer(t).actions.onStep(-1);
      await settle(t);
      expect(viewer(t).data.currentKey, 'middle');
      expect(viewer(t).data.total, 2);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'deleting the final image closes the viewer and restores fullscreen',
    (t) async {
      await open(t);
      viewer(t).actions.onFullscreenChanged(true);
      await settle(t);
      for (final image in images) {
        viewer(t).actions.onDelete(image.id);
        await settle(t);
      }
      for (
        var i = 0;
        i < 30 && find.byType(GenerationViewerWiring).evaluate().isNotEmpty;
        i++
      ) {
        await settle(t);
      }
      expect(find.byType(GenerationViewerWiring), findsNothing);
      expect(find.text('viewer-home'), findsOneWidget);
      expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
      expect(window.writes, [true, false]);
      expect(
        container.read(generationViewerWindowProvider).fullscreen,
        isFalse,
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('repeated deletion removes a requested image only once', (
    t,
  ) async {
    await open(t);
    viewer(t).actions.onDelete('first');
    viewer(t).actions.onDelete('first');
    await settle(t);
    expect(viewer(t).data.total, 2);
    expect(viewer(t).data.currentKey, 'middle');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('failed history deletion preserves the viewer sequence', (
    t,
  ) async {
    generation.failDelete = true;
    await open(t);
    viewer(t).actions.onDelete('first');
    await settle(t);
    expect(viewer(t).data.total, 3);
    expect(viewer(t).data.currentKey, 'first');
    expect(
      container.read(imageGenerationNotifierProvider).history,
      hasLength(3),
    );
    await t.pumpWidget(const SizedBox());
  });
}
