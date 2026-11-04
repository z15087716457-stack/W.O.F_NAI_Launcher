import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/metadata/metadata_import_options.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/drop/image_destination_dialog.dart';
import '../../../helpers/studio_capture_fonts.dart';

const _metadata = NaiImageMetadata(
  prompt: 'source prompt never previewed',
  negativePrompt: 'source negative never previewed',
  steps: 28,
  seed: 123,
  width: 1024,
  height: 1536,
  characterPrompts: ['role one', 'role two'],
);
final _capture = GlobalKey();
late Uint8List _portrait;
late Uint8List _landscape;

Future<Uint8List> _fixture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        [const Color(0xff51726b), const Color(0xffbdd0c0)],
      ),
  );
  canvas.drawRect(
    Rect.fromLTWH(width * .35, height * .2, width * .3, height * .65),
    Paint()..color = const Color(0xffece9dc),
  );
  for (final offset in [
    Offset.zero,
    Offset(width - 10, 0),
    Offset(0, height - 10),
    Offset(width - 10, height - 10),
  ]) {
    canvas.drawRect(
      offset & const Size(10, 10),
      Paint()..color = const Color(0xff175b48),
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Future<void> _mount(
  WidgetTester tester, {
  NaiImageMetadata? metadata = _metadata,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  Size size = const Size(1000, 780),
  double scale = 1,
  bool portrait = true,
  VibeReference? vibe,
  bool bundle = false,
  ValueChanged<ImageDestinationResult?>? onResult,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final base = brightness == Brightness.light
      ? GeistTheme.light
      : GeistTheme.dark;
  await tester.pumpWidget(
    MaterialApp(
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: StudioTypography.sans,
          fontFamilyFallback: StudioTypography.fallback,
        ),
      ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await ImageDestinationDialog.show(
                context,
                imageBytes: portrait ? _portrait : _landscape,
                fileName: portrait ? 'portrait.png' : 'landscape.png',
                metadata: metadata,
                detectedVibe: vibe,
                isBundle: bundle,
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => precacheImage(
      MemoryImage(portrait ? _portrait : _landscape),
      tester.element(find.byKey(const Key('image-use-preview'))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    _portrait = await _fixture(120, 180);
    _landscape = await _fixture(180, 120);
  });
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final portrait in [true, false]) {
        for (final narrow in [false, true]) {
          testWidgets(
            'layout ${locale.toLanguageTag()} ${brightness.name} portrait=$portrait narrow=$narrow',
            (tester) async {
              await _mount(
                tester,
                metadata: _metadata.copyWith(
                  usedVibeTransfer: true,
                  usedPreciseReference: true,
                  usedInpainting: true,
                ),
                locale: locale,
                brightness: brightness,
                portrait: portrait,
                size: narrow ? const Size(360, 640) : const Size(1000, 780),
                scale: narrow ? 1.3 : 1,
                onResult: (_) {},
              );
              expect(find.byType(ImageDestinationDialog), findsOneWidget);
              expect(
                tester
                    .widget<Image>(find.byKey(const Key('image-use-preview')))
                    .fit,
                BoxFit.contain,
              );
              expect(find.text(_metadata.prompt), findsNothing);
              expect(find.text(_metadata.negativePrompt), findsNothing);
              expect(
                tester
                    .getRect(find.byKey(const Key('image-use-import')))
                    .bottom,
                lessThan(640 + (narrow ? 0 : 140)),
              );
              expect(tester.takeException(), isNull);
              if (!narrow &&
                  locale.languageCode == 'zh' &&
                  locale.countryCode == null) {
                expect(
                  tester
                      .getSize(find.byKey(const Key('image-use-prompt')))
                      .height,
                  lessThan(82),
                );
                if (Platform.environment['CAPTURE_IMAGE_USE'] == '1') {
                  await tester.runAsync(() async {
                    final boundary =
                        _capture.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary;
                    final image = await boundary.toImage();
                    final bytes = await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    final file = File(
                      '.dart_tool/image-use-captures/${brightness.name}-${portrait ? 'portrait' : 'landscape'}.png',
                    );
                    await file.parent.create(recursive: true);
                    await file.writeAsBytes(bytes!.buffer.asUint8List());
                    image.dispose();
                  });
                }
              }
            },
          );
        }
      }
    }
  }
  testWidgets('selection and append mode are returned by one confirmation', (
    tester,
  ) async {
    ImageDestinationResult? result;
    await _mount(tester, onResult: (r) => result = r);
    await tester.tap(find.byKey(const Key('image-use-seed')));
    await tester.tap(find.byKey(const Key('image-use-negative')));
    await tester.tap(find.byKey(const Key('image-use-character-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('追加角色').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('image-use-import')));
    await tester.pumpAndSettle();
    expect(result!.destination, ImageDestination.extractMetadata);
    expect(result!.selection!.importSeed, isTrue);
    expect(result!.selection!.importNegativePrompt, isFalse);
    expect(
      result!.selection!.characterMode,
      OfficialCharacterImportMode.append,
    );
    expect(find.byType(ImageDestinationDialog), findsNothing);
  });
  testWidgets('select all skips unavailable settings, seed and references', (
    tester,
  ) async {
    ImageDestinationResult? result;
    await _mount(
      tester,
      metadata: const NaiImageMetadata(prompt: 'only prompt'),
      onResult: (r) => result = r,
    );
    await tester.tap(find.byKey(const Key('image-use-select-all')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('image-use-import')));
    await tester.pumpAndSettle();
    final selection = result!.selection!;
    expect(selection.importSeed, isFalse);
    expect(selection.importGenerationParams, isFalse);
    expect(selection.importVibeReferences, isFalse);
    expect(selection.importPreciseReferences, isFalse);
  });
  testWidgets(
    'usage badges explain missing references and do not enable import',
    (tester) async {
      ImageDestinationResult? result;
      await _mount(
        tester,
        metadata: NaiImageMetadata.fromNaiComment({
          'prompt': 'source',
          'reference_strength_multiple': [.6],
          'director_reference_strengths': [1.0],
          'request_type': 'NativeInfillingRequest',
        }),
        onResult: (value) => result = value,
      );
      for (final id in ['vibe', 'pr', 'inpaint']) {
        expect(find.byKey(Key('image-use-recorded-$id')), findsOneWidget);
      }
      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(
              of: find.byKey(const Key('image-use-recorded-pr')),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, contains('未附带可导入的参考素材'));
      final left = tester.getRect(
        find.byKey(const Key('image-use-character-mode')),
      );
      final right = tester.getRect(
        find.byKey(const Key('image-use-recorded-vibe')),
      );
      expect(right.left, greaterThan(left.right));
      expect((right.center.dy - left.center.dy).abs(), lessThan(1));
      await tester.tap(find.byKey(const Key('image-use-select-all')));
      await tester.tap(find.byKey(const Key('image-use-import')));
      await tester.pumpAndSettle();
      expect(result!.selection!.importVibeReferences, isFalse);
      expect(result!.selection!.importPreciseReferences, isFalse);
    },
  );
  testWidgets(
    'attached references retain import and explain their usage badges',
    (tester) async {
      ImageDestinationResult? result;
      await _mount(
        tester,
        metadata: NaiImageMetadata(
          prompt: 'source',
          vibeReferences: const [
            VibeReference(displayName: 'vibe', vibeEncoding: 'encoded'),
          ],
          preciseReferenceImages: [base64Encode(_portrait)],
        ),
        onResult: (value) => result = value,
      );
      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(
              of: find.byKey(const Key('image-use-recorded-pr')),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, contains('可通过“参考图”导入'));
      await tester.tap(find.byKey(const Key('image-use-import')));
      await tester.pumpAndSettle();
      expect(result!.selection!.importVibeReferences, isTrue);
      expect(result!.selection!.importPreciseReferences, isTrue);
    },
  );
  testWidgets('ordinary metadata has no feature badges', (tester) async {
    await _mount(tester);
    expect(find.byKey(const Key('image-use-recorded-vibe')), findsNothing);
    expect(find.byKey(const Key('image-use-recorded-pr')), findsNothing);
    expect(find.byKey(const Key('image-use-recorded-inpaint')), findsNothing);
  });
  testWidgets('no metadata keeps image actions available and import disabled', (
    tester,
  ) async {
    ImageDestinationResult? result;
    await _mount(tester, metadata: null, onResult: (r) => result = r);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('image-use-import')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('图生图'));
    await tester.pumpAndSettle();
    expect(result!.destination, ImageDestination.img2img);
    expect(result!.selection, isNull);
  });
  testWidgets('encoded bundle preserves reuse, raw and library actions', (
    tester,
  ) async {
    ImageDestinationResult? result;
    await _mount(
      tester,
      vibe: const VibeReference(displayName: 'bundle', vibeEncoding: 'fixture'),
      bundle: true,
      onResult: (r) => result = r,
    );
    await tester.tap(find.byKey(const Key('image-use-vibe-menu')));
    await tester.pumpAndSettle();
    final items = tester
        .widgetList<PopupMenuItem<ImageDestination>>(
          find.byType(PopupMenuItem<ImageDestination>),
        )
        .toList();
    expect(
      items.map((i) => i.value),
      containsAll([
        ImageDestination.vibeTransferReuse,
        ImageDestination.vibeTransferRaw,
        ImageDestination.saveToVibeLibrary,
      ]),
    );
    await tester.tap(find.byWidget(items.last));
    await tester.pumpAndSettle();
    expect(result!.destination, ImageDestination.saveToVibeLibrary);
  });
}
