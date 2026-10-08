import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
// Native drag is stubbed through the existing super_drag_and_drop dependencies.
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/image_share_sanitizer.dart';
import 'package:nai_launcher/core/utils/nai_resolution_adapter.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/history_panel.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/selectable_image_card.dart';
import '../../../../helpers/light_theme_contrast.dart';
import '../../../../helpers/studio_capture_fonts.dart';

class HistoryCaptureStorage extends InMemoryLocalStorageService {
  @override
  String getHistoryClickBehavior() =>
      HistoryClickBehavior.selectPreview.storageValue;
}

// Read-only prototype assets; preparation uses their paths without creating
// generated files, querying galleries, or calling generation services.
List<GeneratedImage> historyCaptureImages({bool mixed = false}) {
  final now = DateTime.now();
  final names = mixed
      ? ['canvas', 'g19', 'g07', 'g18']
      : ['canvas', 'h1', 'h2', 'g18'];
  final counts = mixed ? [1, 2, 2, 1] : [1, 2, 4, 2];
  final minutes = [42, 38, 31, 20];
  return [
    for (var batch = 0; batch < names.length; batch++)
      for (var index = 0; index < counts[batch]; index++)
        () {
          final file = File(
            '../../mockups/generation/assets/${names[batch]}.jpg',
          );
          final bytes = file.readAsBytesSync();
          final dimensions = NaiResolutionAdapter.readImageSize(bytes)!;
          return GeneratedImage(
            id: 'capture-${mixed ? 'mixed' : 'prototype'}-$batch-$index',
            bytes: bytes,
            width: dimensions.$1,
            height: dimensions.$2,
            createdAt: DateTime(
              now.year,
              now.month,
              now.day,
              16,
              minutes[batch],
            ),
            generationRunId: batch + 1,
            batchIndex: index,
            operation: batch == 0 ? ImageOperation.upscale : null,
            kind: mixed && batch == 3
                ? GeneratedImageKind.failedStreamSnapshot
                : GeneratedImageKind.completed,
          );
        }(),
  ];
}

Future<void> prepareHistoryCaptureImages(List<GeneratedImage> images) async {
  final service = ShareImagePreparationService.instance;
  for (final image in images.where((image) => image.canDrag)) {
    final batch = image.generationRunId! - 1;
    final mixed = image.id.contains('mixed');
    final names = mixed
        ? ['canvas', 'g19', 'g07', 'g18']
        : ['canvas', 'h1', 'h2', 'g18'];
    service.enqueue(
      imageId: image.id,
      imageBytes: image.bytes,
      fileName: '${image.id}.jpg',
      stripMetadata: false,
      sourceFilePath: File(
        '../../mockups/generation/assets/${names[batch]}.jpg',
      ).absolute.path,
    );
    await service
        .waitUntilReady(image.id, stripMetadata: false)
        .timeout(const Duration(seconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final drag = MockMessageChannelContext()
    ..registerMockMethodCallHandler('DropManager', (_) async => null)
    ..registerMockMethodCallHandler('DragManager', (_) async => null);
  setContextOverride(drag);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  setUpAll(loadStudioCaptureFonts);
  if (Platform.environment['CAPTURE_UIUX_HISTORY'] != '1') {
    test('history fixture has four requests and nine images', () {
      final images = historyCaptureImages();
      expect(images.length, 9);
      expect(images.where((image) => image.batchIndex == 0).length, 4);
    });
    return;
  }
  testWidgets('history real-font ratio, state, language and width captures', (
    tester,
  ) async {
    final root = Directory('.dart_tool/uiux-task06/captures')
      ..createSync(recursive: true);
    final measurements = <Map<String, Object?>>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['zh', 'en', 'ja', 'ko']) {
      for (final dark in [false, true]) {
        for (final width in [200.0, 210.0, 400.0]) {
          for (final mode in ['prototype', 'mixed', 'multi']) {
            final mixed = mode != 'prototype';
            final images = historyCaptureImages(mixed: mixed);
            final container = createStorageFreeContainer(
              overrides: [
                localStorageServiceProvider.overrideWithValue(
                  HistoryCaptureStorage(),
                ),
              ],
            );
            final notifier = container.read(
              imageGenerationNotifierProvider.notifier,
            );
            notifier.state = notifier.state.copyWith(
              status: mixed
                  ? GenerationStatus.generating
                  : GenerationStatus.idle,
              history: images,
              generationRunId: 99,
              totalImages: mixed ? 4 : 0,
              currentImage: 1,
              progress: .42,
              batchWidth: 832,
              batchHeight: 1216,
            );
            container
                .read(generationPreviewSelectionProvider.notifier)
                .select(images.first.id);
            await tester.runAsync(() => prepareHistoryCaptureImages(images));
            final height = mixed ? (width == 400 ? 2400.0 : 1400.0) : 1120.0;
            tester.view.physicalSize = Size(width, height);
            final theme = dark ? GeistTheme.dark : GeistTheme.light;
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: theme,
                  locale: Locale(language),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: Scaffold(
                    body: RepaintBoundary(
                      key: const Key('capture'),
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 36),
                          child: HistoryPanel(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            // Complete real asynchronous image decoding, then paint it.
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
            await tester.pump();
            if (mode == 'multi') {
              await tester.tap(find.byKey(const Key('history-multi-select')));
              await tester.pumpAndSettle();
              for (final id in [images.first.id, images[3].id]) {
                final target = find.byKey(ValueKey(id));
                await tester.ensureVisible(target);
                await tester.pumpAndSettle();
                await tester.tap(target);
                await tester.pumpAndSettle();
              }
            }
            tester
                .state<ScrollableState>(find.byType(Scrollable))
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            if (mode == 'mixed') {
              final target = find.byKey(ValueKey(images[1].id));
              await mouse.addPointer(location: tester.getCenter(target));
              await tester.pump(const Duration(milliseconds: 300));
            }
            expect(tester.takeException(), isNull);
            expect(
              tester
                  .widgetList<RawImage>(find.byType(RawImage))
                  .every((image) => image.image != null),
              isTrue,
            );
            final name =
                'history-$mode-$language-${dark ? 'dark' : 'light'}-${width.toInt()}';
            Rect rect(Finder finder) => tester.getRect(finder);
            Map<String, double> jsonRect(Rect value) => {
              'x': value.left,
              'y': value.top,
              'width': value.width,
              'height': value.height,
            };
            measurements.add({
              'file': '$name.png',
              'locale': language,
              'dark': dark,
              'width': width,
              'height': height,
              'mode': mode,
              'header': jsonRect(
                rect(find.byKey(const Key('history-panel-header'))),
              ),
              'list': jsonRect(rect(find.byType(ListView))),
              'imageAreas': tester
                  .elementList(
                    find.byKey(const Key('history-image-display-area')),
                  )
                  .map((element) {
                    final box = element.findRenderObject()! as RenderBox;
                    return jsonRect(box.localToGlobal(Offset.zero) & box.size);
                  })
                  .toList(),
              'selected': tester
                  .widgetList<SelectableImageCard>(
                    find.byType(SelectableImageCard),
                  )
                  .where((card) => card.isSelected)
                  .map((card) => card.imageIdentity)
                  .toList(),
            });
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '${root.path}/$name.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
            if (mode == 'mixed') await mouse.removePointer();
            await tester.pumpWidget(const SizedBox());
            container.dispose();
          }
        }
      }
    }
    File('${root.parent.path}/measurements.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(measurements),
    );
  });
}
