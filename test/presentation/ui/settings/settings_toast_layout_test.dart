import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final window in [900.0, 1600.0]) {
      testWidgets('保存提示条两端留白与居中 $locale $window', (t) async {
        final fixture = SettingsFixture.view(page: SettingsPageId.canvas);
        late SettingsHostState host;
        final rec = await pumpSettings(
          t,
          window: window,
          locale: locale,
          dark: window == 900,
          data: fixture.copyWith(
            lastChange: SettingsChange(
              id: 'long-change',
              title: '生成结果显示在',
              from: '简洁查看器',
              to: '无限画布',
              at: fixture.now,
            ),
          ),
          onHost: (value) => host = value,
        );
        final toast = find.byKey(const Key('settings-toast'));
        final icon = find.descendant(of: toast, matching: find.byType(UiGlyph));
        final shortcut = find.descendant(
          of: toast,
          matching: find.text('Ctrl+Z'),
        );
        final bounds = t.getRect(toast);
        final left = t.getRect(icon).left - bounds.left;
        final right = bounds.right - t.getRect(shortcut).right;
        expect(right, closeTo(left, .01));
        final stack = t.getRect(
          find.ancestor(of: toast, matching: find.byType(Stack)).first,
        );
        expect(bounds.center.dx, closeTo(stack.center.dx, .01));
        expect(bounds.left - stack.left, greaterThanOrEqualTo(16));
        expect(stack.right - bounds.right, greaterThanOrEqualTo(16));
        expect(t.getRect(shortcut).center.dy, closeTo(bounds.center.dy, .01));
        expect(t.takeException(), isNull);

        if (locale == 'zh') {
          final boundary = find.byKey(const Key('settings-capture'));
          await captureUiuxRegion(
            t,
            boundary,
            'saved-toast-${window.toInt()}',
            bounds.inflate(20).shift(-t.getTopLeft(boundary)),
          );
        }

        host.updateData(
          fixture.copyWith(
            lastChange: SettingsChange(
              id: 'short-change',
              title: 'CFG',
              from: '5',
              to: '6',
              at: fixture.now,
            ),
          ),
        );
        await t.pump();
        expect(t.getSize(toast).width, lessThan(bounds.width));
        host.updateData(
          fixture.copyWith(
            lastChange: SettingsChange(
              id: 'longest-change',
              title: List.filled(12, '生成结果显示在').join(),
              from: '简洁查看器',
              to: '无限画布',
              at: fixture.now,
            ),
          ),
        );
        await t.pump();
        final constrained = t.getRect(toast);
        expect(constrained.width, lessThanOrEqualTo(stack.width - 32));
        expect(
          constrained.right - t.getRect(shortcut).right,
          closeTo(left, .01),
        );
        final message = find
            .descendant(of: toast, matching: find.byType(Text))
            .first;
        expect(
          t.renderObject<RenderParagraph>(message).didExceedMaxLines,
          isTrue,
        );
        final button = find.descendant(
          of: toast,
          matching: find.byType(SettingsDockButton),
        );
        await t.tap(button);
        await t.pump();
        expect(rec.calls, contains('undo:longest-change'));
        expect(toast, findsNothing);
      });
    }
  }
}
