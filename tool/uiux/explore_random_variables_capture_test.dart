import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_random_variables_module_test.dart';

void main() {
  final output = Directory('.dart_tool/uiux-explore-task02/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets(
    'production random module, real fonts, four languages and three widths',
    (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final count in [0, 1, 2, 3]) {
        for (final width in [352, 384, 560]) {
          for (final locale in ['zh', 'en', 'ja', 'ko']) {
            for (final dark in [false, true]) {
              await tester.pumpWidget(const SizedBox.shrink());
              final boundary = GlobalKey();
              await tester.pumpWidget(
                variableFixtureApp(
                  count: count,
                  width: width.toDouble(),
                  locale: locale,
                  dark: dark,
                  captureKey: boundary,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$count/$width/$locale/$dark',
              );
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final bytes = await tester.runAsync(() async {
                final image = await render.toImage(pixelRatio: 1);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                return data;
              });
              File(
                '${output.path}/variables-$count-$width-$locale-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
