import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:nai_launcher/core/rag/rag_model_download.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_model_download_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/rag_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import '../../../helpers/studio_capture_fonts.dart';

class _FakeRag extends RagController {
  void showInstallation() => state = state.copyWith(
    installPhase: 'cuda',
    installElapsed: 75,
    installDetail: 'Downloading torch (2.5 GiB)',
  );
  final previews = <RagSource>[];
  final starts = <RagSource>[];
  @override
  Future<Map<String, dynamic>> preview({
    RagSource source = RagSource.tags,
  }) async {
    previews.add(source);
    return {
      'plan_id': 'preview-${source.name}',
      'documents': 20,
      'total': 60,
      'images': 40,
      'parameter_chunks': 20,
    };
  }

  @override
  Future<void> start(
    String planId, {
    bool rebuild = false,
    RagSource source = RagSource.tags,
  }) async {
    expect(planId, 'preview-${source.name}');
    starts.add(source);
  }

  @override
  RagStatus build() => const RagStatus(
    phase: 'partial',
    indexed: 1200,
    total: 5000,
    partial: true,
    bytes: 5242880,
    sources: {
      RagSource.wiki: RagStatus(
        phase: 'partial',
        indexed: 64,
        total: 180,
        partial: true,
        bytes: 2097152,
      ),
      RagSource.blocks: RagStatus(
        phase: 'ready',
        indexed: 40,
        total: 40,
        complete: true,
        bytes: 1048576,
      ),
      RagSource.gallery: RagStatus(
        phase: 'partial',
        indexed: 38,
        total: 60,
        partial: true,
        details: {
          'visual_indexed': 32,
          'images': 40,
          'parameters_indexed': 6,
          'skipped': 1,
        },
      ),
    },
  );
}

class _FakeDownloads extends RagModelDownloads {
  @override
  RagModelDownloadState build() => const RagModelDownloadState();
  void showDownload() => state = const RagModelDownloadState(
    kind: 'embedding',
    progress: RagModelDownloadProgress(500000000, 1525808822),
  );
}

class _EnabledSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(
    enabled: true,
    wikiEnabled: true,
    blocksEnabled: true,
    galleryEnabled: true,
  );
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final width in [280.0, 760.0]) {
        testWidgets('RAG settings ${locale.toLanguageTag()} $brightness $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width + 32, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ragControllerProvider.overrideWith(_FakeRag.new),
                ragModelDownloadProvider.overrideWith(_FakeDownloads.new),
                ragSettingsProvider.overrideWith(_EnabledSettings.new),
                ragRuntimeInfoProvider.overrideWith(
                  (ref) async => const RagRuntimeInfo(
                    python: 'C:/RAG/runtime/Scripts/python.exe',
                    ready: true,
                    cuda: true,
                  ),
                ),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: settingsUiTheme(
                  ThemeData(
                    brightness: brightness,
                    fontFamily: 'HarmonyOS Sans SC',
                  ),
                ),
                home: RepaintBoundary(
                  key: key,
                  child: Scaffold(
                    body: SettingsTypographyScope(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          controller: scroll,
                          child: const RagSettingsSection(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final directory = Directory(
            '.dart_tool/feedback-r6-20261015/captures',
          );
          Future<void> capture(String part) async {
            await tester.runAsync(() async {
              await directory.create(recursive: true);
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              await File(
                '${directory.path}/settings-${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}-$part.png',
              ).writeAsBytes(data!.buffer.asUint8List());
            });
          }

          await capture('top');
          if ((locale.languageCode == 'en' && width == 280) ||
              (locale.languageCode == 'zh' && width == 760)) {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(RagSettingsSection)),
            );
            (container.read(ragModelDownloadProvider.notifier)
                    as _FakeDownloads)
                .showDownload();
            await tester.pump();
            expect(tester.takeException(), isNull);
            await capture('download');
            (container.read(ragControllerProvider.notifier) as _FakeRag)
                .showInstallation();
            await tester.pump();
            expect(tester.takeException(), isNull);
            await capture('install');
          }
          await tester.ensureVisible(find.byKey(const Key('rag-wiki-index')));
          await tester.pump();
          expect(tester.takeException(), isNull);
          await capture('wiki');
          await tester.ensureVisible(
            find.byKey(const Key('rag-gallery-index')),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await capture('gallery');
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await capture('bottom');
        });
      }
    }
  }
  testWidgets(
    'text collections preview before starting only the confirmed source',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          ragControllerProvider.overrideWith(_FakeRag.new),
          ragSettingsProvider.overrideWith(_EnabledSettings.new),
          ragRuntimeInfoProvider.overrideWith(
            (ref) async => const RagRuntimeInfo(
              python: 'C:/RAG/runtime/Scripts/python.exe',
              ready: true,
              cuda: true,
            ),
          ),
          ragGalleryRootsProvider.overrideWithValue(
            () async => ['C:/Gallery/NAI', 'D:/Pictures'],
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: RagSettingsSection()),
            ),
          ),
        ),
      );
      final controller =
          container.read(ragControllerProvider.notifier) as _FakeRag;
      for (final source in [
        RagSource.wiki,
        RagSource.blocks,
        RagSource.gallery,
      ]) {
        final button = find.byKey(Key('rag-${source.name}-preview'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(controller.previews.last, source);
        expect(find.textContaining('20'), findsWidgets);
        expect(controller.starts, isEmpty);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(controller.starts, isEmpty);
      }
      final button = find.byKey(const Key('rag-wiki-preview'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final start = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!.rag_start;
      await tester.tap(find.widgetWithText(FilledButton, start));
      await tester.pumpAndSettle();
      expect(controller.starts, [RagSource.wiki]);
      expect(tester.takeException(), isNull);
    },
  );
}
