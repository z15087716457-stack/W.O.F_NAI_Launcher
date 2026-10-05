import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/inpaint_mask_utils.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/tools/brush_tool.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/inpaint_controls.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'mask mode registers only official mask tools and ignores painting presets',
    () async {
      final mask = EditorState(inpaint: true);
      final edit = EditorState();
      expect(mask.tools.map((t) => t.id), [
        'brush',
        'eraser',
        'fill',
        'inpaint_focus',
      ]);
      expect(
        edit.tools.map((t) => t.id),
        containsAll([
          'magic_wand',
          'ellipse_selection',
          'lasso_selection',
          'color_picker',
        ]),
      );
      mask.setBrushOpacity(0.1);
      mask.setBrushHardness(0.2);
      mask.setToolById('magic_wand');
      expect(mask.currentTool!.id, 'brush');
      expect((mask.currentTool as BrushTool).settings.opacity, 1);
      expect((mask.currentTool as BrushTool).settings.hardness, 1);
      mask.setSquareBrush(true);
      mask.setToolById('eraser');
      expect(mask.squareBrush, isTrue);
      mask.setToolById('brush');
      expect(mask.squareBrush, isTrue);
      mask.dispose();
      edit.dispose();
    },
  );

  testWidgets(
    'square draw, erase and empty-mask fill export binary coverage and undo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(const Locale('zh'), Brightness.light));
      await _ready(tester);
      final screen = tester.state(find.byType(ImageEditorScreen)) as dynamic;
      final EditorState state = screen.debugEditorState;
      state.setBrushSize(32);
      await tester.tap(find.byKey(const Key('inpaint_square_brush')));
      await tester.pump();
      final origin = tester.getTopLeft(find.byType(EditorCanvas));
      Offset point(Offset p) =>
          origin +
          state.canvasController.canvasToScreen(
            p,
            canvasSize: state.canvasSize,
          );
      await tester.tapAt(point(const Offset(128, 128)));
      await tester.pump();
      var bytes = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      var mask = InpaintMaskUtils.decodeBinaryMask(bytes!)!;
      expect(mask.mask[112 * 256 + 112], 1, reason: 'square corner is covered');
      expect(mask.mask[111 * 256 + 111], 0);
      state.setMaskAppearance(
        opacity: 0,
        color: Colors.red,
        border: false,
        pattern: MaskDisplayPattern.hearts,
      );
      final same = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      expect(same, bytes, reason: 'appearance never changes exported coverage');
      state.setToolById('eraser');
      state.setBrushSize(16);
      await tester.pump();
      await tester.tapAt(point(const Offset(128, 128)));
      await tester.pump();
      bytes = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      mask = InpaintMaskUtils.decodeBinaryMask(bytes!)!;
      expect(mask.mask[128 * 256 + 128], 0);
      state.undo();
      await tester.pump();
      bytes = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      expect(
        InpaintMaskUtils.decodeBinaryMask(bytes!)!.mask[128 * 256 + 128],
        1,
      );
      state.layerManager.activeLayer!.clearStrokes();
      state.setToolById('fill');
      await tester.pump();
      await tester.tapAt(point(const Offset(32, 32)));
      await _wait(tester, () => state.layerManager.activeLayer!.hasBaseImage);
      bytes = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      expect(
        InpaintMaskUtils.decodeBinaryMask(bytes!)!.mask.every((v) => v == 1),
        isTrue,
      );
      final filledId = state.layerManager.activeLayerId!;
      state.historyManager.execute(
        DeleteInpaintLayerAction(layerId: filledId),
        state,
      );
      state.undo();
      await tester.pump();
      final restored = await tester.runAsync<Uint8List>(
        () async => await screen.debugExportMask() as Uint8List,
      );
      expect(
        InpaintMaskUtils.decodeBinaryMask(restored!)!.mask.every((v) => v == 1),
        isTrue,
      );
      state.undo();
      await tester.pump();
      expect(state.layerManager.activeLayer!.hasBaseImage, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets('focused region exports its interior and preserves context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('zh'), Brightness.light));
    await _ready(tester);
    final screen = tester.state(find.byType(ImageEditorScreen)) as dynamic;
    final EditorState state = screen.debugEditorState;
    state.setInpaintFocusRegion(const Rect.fromLTWH(0, 0, 256, 256));
    state.setInpaintContextSize(32);
    final bytes = await tester.runAsync<Uint8List>(
      () async => await screen.debugExportMask() as Uint8List,
    );
    final mask = InpaintMaskUtils.decodeBinaryMask(bytes!)!;
    expect(mask.mask[128 * 256 + 128], 1);
    expect(mask.mask[31 * 256 + 31], 0);
    expect(mask.mask[224 * 256 + 224], 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final size in [
        const Size(1440, 900),
        const Size(720, 600),
        const Size(390, 780),
      ]) {
        testWidgets('official mask layout $locale $brightness $size', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          await tester.pumpWidget(_app(locale, brightness, boundary: boundary));
          await _ready(tester);
          expect(find.byType(InpaintToolSettings), findsOneWidget);
          expect(find.byType(InpaintToolbar), findsOneWidget);
          expect(find.byIcon(Icons.more_horiz), findsNothing);
          expect(find.byIcon(Icons.more_vert), findsNothing);
          expect(find.byIcon(Icons.compress), findsNothing);
          expect(find.byKey(const Key('outpaint_edge_right')), findsNothing);
          expect(tester.getSize(find.byType(EditorCanvas)), size);
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_INPAINT_UI'] == '1') {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '.dart_tool/inpaint-cleanup-20261005/captures/${locale.toLanguageTag()}-${brightness.name}-${size.width.round()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          final screen =
              tester.state(find.byType(ImageEditorScreen)) as dynamic;
          final EditorState state = screen.debugEditorState;
          state.setToolById('inpaint_focus');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.byType(TextFormField), findsOneWidget);
          await tester.tap(find.byKey(const Key('inpaint_palette')));
          await tester.pump();
          expect(find.byType(InpaintMaskAppearance), findsOneWidget);
          state.setMaskAppearance(pattern: MaskDisplayPattern.hearts);
          await tester.pump();
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_INPAINT_UI'] == '1') {
            await _capture(
              tester,
              boundary,
              '${locale.toLanguageTag()}-${brightness.name}-${size.width.round()}-appearance',
            );
          }
          await tester.tap(find.byKey(const Key('inpaint_layers')));
          await tester.pump();
          expect(find.byKey(const Key('inpaint_add_3d')), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_INPAINT_UI'] == '1') {
            await _capture(
              tester,
              boundary,
              '${locale.toLanguageTag()}-${brightness.name}-${size.width.round()}-layers',
            );
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        });
      }
    }
  }
}

Widget _app(Locale locale, Brightness brightness, {GlobalKey? boundary}) =>
    MaterialApp(
      theme: AppTheme.getTheme(AppStyle.geist, brightness),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepaintBoundary(
        key: boundary,
        child: ImageEditorScreen(
          initialImage: _png(),
          mode: ImageEditorMode.inpaint,
          debugDisableDropRegion: true,
        ),
      ),
    );
Uint8List _png() {
  final input = img.Image(width: 256, height: 256);
  img.fill(input, color: img.ColorRgb8(90, 140, 160));
  return Uint8List.fromList(img.encodePng(input));
}

Future<void> _ready(WidgetTester tester) async {
  await _wait(tester, () => find.byType(InpaintToolbar).evaluate().isNotEmpty);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _wait(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 80; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 30));
    if (ready()) return;
  }
  fail('Editor did not finish asynchronous work');
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/inpaint-cleanup-20261005/captures/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
