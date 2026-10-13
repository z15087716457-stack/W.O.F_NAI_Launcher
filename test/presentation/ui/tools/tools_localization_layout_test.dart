import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import '../gen/gen_test_harness.dart';
import 'tools_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [390.0, 720.0, 1440.0]) {
        for (final mode in ToolsEditorMode.values) {
          testWidgets('editor $locale dark=$dark width=$width ${mode.name}', (
            t,
          ) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width, 900);
            addTearDown(t.view.reset);
            final r = ToolsRecorder();
            await t.pumpWidget(
              genApp(
                ToolsEditorPage(
                  data: ToolsFixture.editor(
                    mode: mode,
                  ).copyWith(dirty: false, canUndo: true, canRedo: true),
                  actions: r.editor,
                  slots: const ToolsEditorSlots(
                    canvas: ToolsFixtureStage.builder,
                  ),
                ),
                locale: locale,
                dark: dark,
              ),
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            final top = t.getRect(find.byKey(const Key('tools-editor-top')));
            for (final key in [
              'tools-editor-back',
              'tools-editor-undo',
              'tools-editor-redo',
              'tools-editor-download',
              'tools-editor-cancel',
              mode == ToolsEditorMode.inpaint
                  ? 'tools-editor-apply-main'
                  : 'tools-editor-apply',
            ]) {
              final rect = t.getRect(find.byKey(Key(key)));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              expect(rect.bottom, lessThanOrEqualTo(top.bottom));
            }
            await captureUiuxRegion(
              t,
              find.byKey(const Key('gen-capture')),
              'tools-$locale-$dark-$width-${mode.name}',
              top,
            );
            for (final key in [
              'tools-editor-undo',
              'tools-editor-redo',
              'tools-editor-download',
              mode == ToolsEditorMode.inpaint
                  ? 'tools-editor-apply-main'
                  : 'tools-editor-apply',
              'tools-editor-cancel',
            ]) {
              await tapKey(t, key);
            }
            expect(r.calls, [
              'onUndo',
              'onRedo',
              'onDownload',
              'onApply',
              'onBack',
            ]);
            await t.pumpWidget(const SizedBox());
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  }
}
