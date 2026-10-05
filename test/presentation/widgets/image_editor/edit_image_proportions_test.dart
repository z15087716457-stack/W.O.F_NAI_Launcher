import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_image_controls.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/layer_thumbnail_tray.dart';
import '../../../helpers/studio_capture_fonts.dart';

Widget app(Widget child) => MaterialApp(
  theme: AppTheme.getTheme(AppStyle.geist, Brightness.light),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'Compact Draw matches bottom toolbar height and size remains editable',
    (tester) async {
      final state = EditorState()..initNewCanvas(const Size(832, 1216));
      await tester.pumpWidget(
        app(EditToolSettings(state: state, maxWidth: 780)),
      );
      expect(
        tester.getSize(find.byType(EditToolSettings)),
        const Size(459, 50),
      );
      final label = tester.getRect(find.byKey(const Key('edit_tool_label')));
      expect(label.size, const Size(52, 48));
      final icon = find.descendant(
        of: find.byKey(const Key('edit_tool_label')),
        matching: find.byType(EditGlyph),
      );
      expect(tester.getSize(icon), const Size(16, 16));
      final swatch = tester.getRect(find.byKey(const Key('edit_color_swatch')));
      final size = tester.getRect(find.byType(EditNumberSlider));
      final tips = tester.getRect(find.byKey(const Key('edit_tips')));
      final pressure = tester.getRect(find.byKey(const Key('edit_pressure')));
      expect(swatch.left - label.right, 9);
      expect(size.left - swatch.right, 8);
      expect(tips.left - size.right, 8);
      expect(tips.size, const Size(118, 38));
      expect(pressure.left - tips.right, 6);
      expect(pressure.size, const Size(38, 38));
      final slider = tester.getRect(find.byType(Slider));
      await tester.tapAt(Offset(slider.right - 1, slider.center.dy));
      await tester.pumpAndSettle();
      expect(state.brushSize, 100);
      await tester.enterText(find.byType(TextFormField), '240');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(state.brushSize, 240);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  for (final canvas in [const Size(832, 1216), const Size(1216, 832)]) {
    testWidgets(
      'fractional thumbnail $canvas clips checkerboard inside its frame',
      (tester) async {
        final state = EditorState()..initNewCanvas(canvas);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          app(
            RepaintBoundary(
              key: boundary,
              child: EditorLayerTray(state: state),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        final thumb = tester.getRect(
          find.byKey(
            Key('inpaint_layer_thumb_${state.layerManager.activeLayer!.id}'),
          ),
        );
        final box =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final origin = box.localToGlobal(Offset.zero);
        final local = thumb.shift(-origin);
        final scheme = Theme.of(
          tester.element(find.byType(EditorLayerTray)),
        ).colorScheme;
        await tester.runAsync(() async {
          final image = await box.toImage(pixelRatio: 1);
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          Color pixel(int x, int y) {
            final i = (y * image.width + x) * 4;
            return Color.fromARGB(
              data[i + 3],
              data[i],
              data[i + 1],
              data[i + 2],
            );
          }

          // Cover each checkerboard row, both the selected frame and panel just outside it.
          for (
            var y = local.top.ceil() + 25;
            y < local.bottom.floor() - 4;
            y++
          ) {
            expect(
              pixel(local.right.floor() - 2, y),
              scheme.onSurface,
              reason: 'right frame at $y',
            );
            expect(
              pixel(local.right.ceil() + 1, y),
              scheme.surfaceContainer,
              reason: 'outside frame at $y',
            );
          }
          for (
            var x = local.left.ceil() + 4;
            x < local.right.floor() - 4;
            x++
          ) {
            expect(
              pixel(x, local.bottom.floor() - 2),
              scheme.onSurface,
              reason: 'bottom frame at $x',
            );
          }
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      },
    );
  }
}
