import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/inpaint_outpaint_utils.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  for (final (side, edges) in [
    ('right', const OutpaintEdges(right: 64)),
    ('left', const OutpaintEdges(left: 64)),
    ('top', const OutpaintEdges(top: 64)),
    ('bottom', const OutpaintEdges(bottom: 64)),
  ]) {
    testWidgets(
      'transparent and colored layers preserve compressed $side outpaint geometry',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(1600, 1000);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final source = img.Image(width: 2048, height: 1024, numChannels: 4);
        img.fill(source, color: img.ColorRgba8(220, 40, 30, 255));
        final bytes = Uint8List.fromList(img.encodePng(source));
        final observations = <Map<String, Object?>>[];
        for (final extraLayer in [0, 1, if (side == 'right') 2]) {
          ImageEditorResult? result;
          await t.pumpWidget(
            refsApp(
              Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context)
                        .push<ImageEditorResult>(
                          MaterialPageRoute(
                            builder: (_) => ImageEditorScreen(
                              initialImage: bytes,
                              mode: ImageEditorMode.inpaint,
                              debugDisableDropRegion: true,
                            ),
                          ),
                        );
                  },
                  child: const Text('open-outpaint-audit'),
                ),
              ),
            ),
          );
          await t.tap(find.text('open-outpaint-audit'));
          for (
            var i = 0;
            i < 30 && find.byType(EditorCanvas).evaluate().isEmpty;
            i++
          ) {
            await t.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
            });
            await t.pump(const Duration(milliseconds: 50));
          }
          expect(find.byType(EditorCanvas), findsOneWidget);
          final dynamic session = t.state(find.byType(ImageEditorScreen));
          await session.debugApplyOutpaintEdges(edges);
          await t.pump();
          expect(session.debugHasOutpaintChanges, isTrue);
          expect(session.debugCompressionTargetCount, greaterThan(1));
          session.debugSetCompressionTargetIndex(0);
          final Size work = session.debugCanvasSize;
          final Size target = session.debugCompressionTargetSize;
          expect(target.height, lessThan(work.height));
          if (extraLayer > 0) {
            // A transparent bitmap stands in for the non-mask pixels already
            // captured from a 3D layer. No 3D editor, model or API is invoked.
            final transparent = img.Image(
              width: work.width.round(),
              height: work.height.round(),
              numChannels: 4,
            );
            if (extraLayer == 2) {
              for (
                var y = transparent.height * 2 ~/ 5;
                y < transparent.height * 3 ~/ 5;
                y++
              ) {
                for (
                  var x = transparent.width * 2 ~/ 5;
                  x < transparent.width * 3 ~/ 5;
                  x++
                ) {
                  transparent.setPixelRgba(x, y, 30, 60, 220, 255);
                }
              }
            }
            await t.runAsync(() async {
              await session.debugEditorState.layerManager.addLayerFromImage(
                Uint8List.fromList(img.encodePng(transparent)),
                name: 'transparent-source-layer',
              );
            });
            await t.pump();
          }
          await t.runAsync(() async {
            await session.debugExportAndClose();
          });
          await t.pump();
          await t.pump(const Duration(milliseconds: 500));
          await t.pump(const Duration(milliseconds: 500));
          expect(result, isNotNull);
          final exported = img.decodePng(result!.outpaintSourceImage!)!;
          if (extraLayer == 2) {
            final center = exported.getPixel(
              exported.width ~/ 2,
              exported.height ~/ 2,
            );
            expect(
              [
                center.r.toInt(),
                center.g.toInt(),
                center.b.toInt(),
                center.a.toInt(),
              ],
              [30, 60, 220, 255],
            );
          }
          final pixel = exported.getPixel(
            exported.width ~/ 2,
            exported.height * 3 ~/ 4,
          );
          observations.add({
            'extraTransparentLayer': extraLayer,
            'work': [work.width, work.height],
            'output': [exported.width, exported.height],
            'bottomPixel': [
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              pixel.a.toInt(),
            ],
          });
          await t.pumpWidget(const SizedBox.shrink());
        }
        expect(observations[0]['bottomPixel'], [220, 40, 30, 255]);
        expect(observations[1]['bottomPixel'], observations[0]['bottomPixel']);
        expect(observations[1]['output'], observations[0]['output']);
      },
    );
  }
}
