import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_focus_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_section.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_inspector_panel.dart';

import '../../../helpers/app_logger_test_isolation.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;

class _Gallery extends LocalGalleryNotifier {
  final records = <String, LocalImageRecord>{};
  Completer<void>? gate;
  List<LocalImageRecord>? response;
  int loads = 0;

  @override
  LocalGalleryState build() => const LocalGalleryState();

  @override
  LocalImageRecord? cachedRecord(String path) => records[path];

  @override
  Future<List<LocalImageRecord>> loadRecords(List<String> paths) async {
    loads++;
    final result = response ?? [for (final path in paths) ?records[path]];
    await gate?.future;
    if (response != null) {
      for (final record in result) {
        publish(record);
      }
    }
    return result;
  }

  void publish(LocalImageRecord record) {
    records[record.path] = record;
    state = state.copyWith(recordsRevision: state.recordsRevision + 1);
  }
}

void main() {
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await loadStudioCaptureFonts();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory dir;
  late _Gallery gallery;
  late LocalImageRecord original;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('inspector_revision_');
    gallery = _Gallery();
    original = LocalImageRecord(
      path: '${dir.path}/fixture.png',
      size: 68,
      modifiedAt: DateTime(2026),
      metadata: const NaiImageMetadata(seed: 11111, prompt: 'original prompt'),
    );
    gallery.records[original.path] = original;
    container = ProviderContainer(
      overrides: [
        localGalleryNotifierProvider.overrideWith(() => gallery),
        kritaBridgeNotifierProvider.overrideWith(
          (ref) => KritaBridgeNotifier(),
        ),
      ],
    );
    container
        .read(localGalleryFocusNotifierProvider.notifier)
        .focus(original.path);
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<void> open(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1200, 1100);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: refsApp(
          Center(
            child: SizedBox(
              width: 340,
              child: GalleryInspectorPanel(
                onAction: (_, _) async {},
                onOpenViewer: (_) {},
                onClose: () {},
                onFavoriteMenu: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  void expectPrompt(WidgetTester t, String value) {
    expect(t.widget<PromptSection>(find.byType(PromptSection)).content, value);
  }

  testWidgets(
    'same-path metadata backfill updates seed and prompt without rereading',
    (t) async {
      await open(t);
      expect(find.text('11111'), findsOneWidget);
      gallery.publish(
        original.copyWith(
          metadata: const NaiImageMetadata(
            seed: 22222,
            prompt: 'backfilled prompt',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('22222'), findsOneWidget);
      expect(find.text('11111'), findsNothing);
      expectPrompt(t, 'backfilled prompt');
      expect(gallery.loads, 1);
    },
  );

  testWidgets(
    'favorite-only and unrelated revisions retain the loaded metadata',
    (t) async {
      await open(t);
      gallery.publish(original.copyWith(isFavorite: true));
      gallery.publish(original.copyWith(path: '${dir.path}/other.png'));
      await t.pumpAndSettle();
      expect(find.text('11111'), findsOneWidget);
      expectPrompt(t, 'original prompt');
      expect(gallery.loads, 1);
    },
  );

  testWidgets('a new file version without metadata clears the old seed', (
    t,
  ) async {
    await open(t);
    gallery.publish(
      original.copyWith(
        modifiedAt: DateTime(2026, 2),
        size: 99,
        metadata: null,
      ),
    );
    await t.pump();
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump();
    }
    expect(find.text('11111'), findsNothing);
    expect(find.byType(PromptSection), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('late initial load cannot replace a newer same-path backfill', (
    t,
  ) async {
    final gate = gallery.gate = Completer<void>();
    await open(t);
    gallery.publish(
      original.copyWith(
        metadata: const NaiImageMetadata(seed: 22222, prompt: 'new prompt'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('22222'), findsOneWidget);
    gate.complete();
    await t.pumpAndSettle();
    expect(find.text('22222'), findsOneWidget);
    expectPrompt(t, 'new prompt');
    expect(gallery.loads, 1);
  });

  testWidgets(
    'new selection still loads records to refresh a stale cached record',
    (t) async {
      gallery.response = [
        original.copyWith(
          metadata: const NaiImageMetadata(
            seed: 22222,
            prompt: 'refreshed prompt',
          ),
        ),
      ];
      await open(t);
      expect(gallery.loads, 1);
      expect(find.text('22222'), findsOneWidget);
      container.read(localGalleryFocusNotifierProvider.notifier).clear();
      await t.pumpAndSettle();
      container
          .read(localGalleryFocusNotifierProvider.notifier)
          .focus(original.path);
      await t.pumpAndSettle();
      expect(gallery.loads, 2);
    },
  );

  testWidgets('clearing selection retires an outstanding load', (t) async {
    final gate = gallery.gate = Completer<void>();
    await open(t);
    container.read(localGalleryFocusNotifierProvider.notifier).clear();
    await t.pumpAndSettle();
    gate.complete();
    await t.pumpAndSettle();
    expect(find.text('11111'), findsNothing);
    expect(find.byType(PromptSection), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'disposal before load completion does not update the removed panel',
    (t) async {
      final gate = gallery.gate = Completer<void>();
      await open(t);
      await t.pumpWidget(const SizedBox());
      gate.complete();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
