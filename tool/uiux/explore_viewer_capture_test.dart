import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/viewer_stage.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_inspector_test.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_detail_dialog_test.dart';

void main() {
  final output = Directory('.dart_tool/uiux-explore-task06/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('shared production exploration viewer with real fonts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cards =
        jsonDecode(
              File(
                '.dart_tool/uiux-explore-task03/prototype-cards.json',
              ).readAsStringSync(),
            )
            as List;
    final base = inspectorFixture(),
        run = base.copyWith(
          candidates: [
            for (var i = 0; i < base.candidates.length; i++)
              base.candidates[i].copyWith(
                generation: base.candidates[i].generation.copyWith(
                  filePath:
                      'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i]['image']}',
                ),
              ),
          ],
        );
    for (final width in [1280, 1920]) {
      tester.view.physicalSize = Size(width.toDouble(), 1000);
      for (final locale in ['zh', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(const SizedBox.shrink());
          final boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: viewerFixtureApp(
                run,
                ids: run.candidates.map((c) => c.id).toList(),
                locale: locale,
                dark: dark,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('open-viewer')));
          await tester.pumpAndSettle();
          expect(find.byType(ViewerStage), findsOneWidget);
          for (var i = 0; i < 20; i++) {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            });
            await tester.pumpAndSettle();
            if (tester
                .renderObjectList<RenderImage>(find.byType(RawImage))
                .every((r) => r.image != null)) {
              break;
            }
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$width/$locale/$dark',
          );
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final bytes = await tester.runAsync(() async {
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            return data!;
          });
          File(
            '${output.path}/viewer-$width-$locale-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    }
  });
}
