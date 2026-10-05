import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/history_manager.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final direction in ['right', 'top_left']) {
    testWidgets(
      '$direction drag keeps source position, focus, mask and reversible geometry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final image = img.Image(width: 256, height: 256, numChannels: 4);
        img.fill(image, color: img.ColorRgba8(34, 68, 102, 255));
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ImageEditorScreen(
              initialImage: Uint8List.fromList(img.encodePng(image)),
              mode: ImageEditorMode.inpaint,
              debugDisableDropRegion: true,
            ),
          ),
        );
        for (
          var i = 0;
          i < 50 &&
              find.byKey(Key('outpaint_edge_$direction')).evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        final screen = tester.state(find.byType(ImageEditorScreen)) as dynamic;
        final EditorState state = screen.debugEditorState;
        expect(screen.debugCanvasSize, const Size(256, 256));
        expect(state.layerManager.layers.first.id, state.inpaintSourceLayerId);
        expect(state.layerManager.layers.last.inpaintMask, isTrue);
        state.setInpaintFocusRegion(const Rect.fromLTWH(64, 64, 128, 128));
        // Place a mask stroke inside the focus to verify resize translates existing content.
        state.layerManager.activeLayer!.addStroke(
          StrokeData(
            points: const [Offset(96, 96)],
            size: 24,
            color: Colors.white,
            opacity: 1,
            hardness: 1,
          ),
        );
        await tester.pump();
        final beforeScale = state.canvasController.scale;
        final beforePoint = state.canvasController.canvasToScreen(
          const Offset(96, 96),
          canvasSize: state.canvasSize,
        );
        final beforeOffset = state.canvasController.offset;
        final edge = find.byKey(Key('outpaint_edge_$direction'));
        final start = tester.getCenter(edge);
        final movement = direction == 'right'
            ? Offset(64 * beforeScale, 0)
            : Offset(-64 * beforeScale, -64 * beforeScale);
        final gesture = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(movement);
        await tester.pump(const Duration(seconds: 1));
        expect(screen.debugCanvasSize, const Size(256, 256));
        expect(screen.debugIsDrawing, isFalse);
        expect(screen.debugActiveLayerStrokeCount, 1);
        expect(
          find.text(direction == 'right' ? '320 × 256' : '320 × 320'),
          findsOneWidget,
        );
        await gesture.up();
        await tester.pump();
        final shift = direction == 'right' ? Offset.zero : const Offset(64, 64);
        expect(
          screen.debugCanvasSize,
          direction == 'right' ? const Size(320, 256) : const Size(320, 320),
        );
        expect(state.canvasController.scale, beforeScale);
        expect(
          state.canvasController.canvasToScreen(
            const Offset(96, 96) + shift,
            canvasSize: state.canvasSize,
          ),
          beforePoint,
        );
        expect(
          state.inpaintFocusRegion,
          const Rect.fromLTWH(64, 64, 128, 128).shift(shift),
        );
        expect(screen.debugActiveLayerStrokeCount, 1);
        expect(
          state.layerManager.activeLayer!.strokes.single.points.single,
          const Offset(96, 96) + shift,
        );
        state.setInpaintFocusRegion(null);
        Uint8List? maskBytes;
        await tester.runAsync(() async {
          maskBytes = await screen.debugExportMask();
        });
        final mask = img.decodePng(maskBytes!)!;
        expect((
          mask.width,
          mask.height,
        ), direction == 'right' ? (320, 256) : (320, 320));
        expect(
          mask.getPixel((96 + shift.dx).round(), (96 + shift.dy).round()).r,
          255,
        );
        expect(
          mask.getPixel((32 + shift.dx).round(), (32 + shift.dy).round()).r,
          0,
        );
        expect(
          mask
              .getPixel(
                direction == 'right' ? 300 : 10,
                direction == 'right' ? 64 : 10,
              )
              .r,
          255,
        );
        expect(screen.debugUndo(), isTrue);
        await tester.pump();
        expect(screen.debugCanvasSize, const Size(256, 256));
        expect(state.canvasController.offset, beforeOffset);
        expect(state.inpaintFocusRegion, const Rect.fromLTWH(64, 64, 128, 128));
        expect(
          state.layerManager.activeLayer!.strokes.single.points.single,
          const Offset(96, 96),
        );
        state.redo();
        await tester.pump();
        expect(
          state.layerManager.activeLayer!.strokes.single.points.single,
          const Offset(96, 96) + shift,
        );
        expect(
          state.canvasController.canvasToScreen(
            const Offset(96, 96) + shift,
            canvasSize: state.canvasSize,
          ),
          beforePoint,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
