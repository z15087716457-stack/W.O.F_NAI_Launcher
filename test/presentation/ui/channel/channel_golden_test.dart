// 画布视觉通道基准截图（中文浅色 / 深色）：固定种子 + 假历史，锁定视觉。界面变了这里会失败。
// 原基准 PNG 保留，只排除已经确认的界面变更区域。
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_text.dart';

import '../../../helpers/approved_visual_regions.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'channel_test_harness.dart';

typedef _Pump = Future<void> Function(WidgetTester t, bool dark);

// 原导航尺位于画布右边缘内 6px，上下各留 64px。
List<Rect> _formerRulerRegions(WidgetTester t) {
  final canvas = t.getRect(find.byKey(const Key('channel-fixture-canvas')));
  final rail = Rect.fromLTRB(
    canvas.right - 30,
    canvas.top + 64,
    canvas.right - 6,
    canvas.bottom - 64,
  );
  final actions = find.byKey(const Key('gen-bar-actions'));
  return [
    rail,
    // The clipped toolbar blur samples the old ruler within 3 × sigma 10.
    if (actions.evaluate().isNotEmpty)
      t.getRect(actions).intersect(rail.inflate(30)),
  ];
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  _Pump canvas({
    ChannelSettings? s,
    bool overview = false,
    bool generating = false,
    double? focusY,
    double? focusScale,
    bool popover = false,
  }) => (t, dark) async {
    await pumpChannel(
      t,
      settings: s,
      dark: dark,
      overview: overview,
      generating: generating,
      focusY: focusY,
      focusScale: focusScale,
    );
    if (popover) await tapKey(t, 'gen-display');
  };

  ChannelSettings fixed(ChannelTheme th) =>
      channelSettings(mode: ChannelMode.fixed, fixed: th);

  // (文件名, 装载, 也拍深色)
  final scenes = <(String, _Pump, bool)>[
    ('random', canvas(), true),
    for (final th in channelLegacyThemes) (th.name, canvas(s: fixed(th)), true),
    ('overview', canvas(overview: true), true),
    ('transition', canvas(focusY: 4012, focusScale: .35), false),
    ('popover', canvas(popover: true), true),
    (
      'popover-fixed',
      canvas(s: fixed(ChannelTheme.arcade), popover: true),
      false,
    ),
    (
      'popover-off',
      canvas(s: channelSettings(mode: ChannelMode.off), popover: true),
      false,
    ),
    ('generating', canvas(generating: true), false),
    ('soft', canvas(s: channelSettings(level: ChannelLevel.soft)), false),
    ('strong', canvas(s: channelSettings(level: ChannelLevel.strong)), false),
  ];

  for (final (file, pump, alsoDark) in scenes) {
    for (final dark in [false, if (alsoDark) true]) {
      final name = dark ? '$file-dark' : file;
      testWidgets('golden $name', skip: skip, (t) async {
        await pump(t, dark);
        final masks = _formerRulerRegions(t);
        // 同生图页基准：既有变体价签占位已获准调整，保留原图并排除该工具条。
        final toolbar = find.byKey(const Key('gen-bar-top'));
        if (toolbar.evaluate().isNotEmpty) {
          masks.add(t.getRect(toolbar).inflate(22));
        }
        // 主题卡从 3 列 6 张改为 4 列 11 张，整个弹层的新样子由 v2 基准锁定。
        final popover = find.byKey(const Key('gen-display-popover'));
        if (popover.evaluate().isNotEmpty) masks.add(t.getRect(popover));
        final settings = find.byKey(const Key('channel-settings'));
        if (settings.evaluate().isNotEmpty) {
          final l = AppLocalizations.of(t.element(settings))!;
          expect(find.text('NEW'), findsNothing);
          final title = t.getRect(find.text(l.channel_title));
          final text = TextPainter(
            text: TextSpan(
              text: 'NEW',
              style: UiText.mono(10, weight: FontWeight.w500, height: 1.3),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          // 保留原 PNG，仅排除用户要求移除的 NEW 标签。
          masks.add(
            Rect.fromLTWH(
              title.right + 6,
              title.center.dy - 7.5,
              text.width + 10,
              15,
            ),
          );
          text.dispose();
        }
        masks.addAll(promptEditorSlotRegions(t));
        await expectOutsideApprovedRegions(
          t,
          find.byKey(const Key('gen-capture')),
          'test/presentation/ui/channel/goldens/$name.png',
          masks,
        );
      });
    }
  }

  // v2：后加的主题和 11 张卡的弹层。
  final all = channelSettings(pool: ChannelSettings.allThemes);
  final v2 = <(String, _Pump, bool)>[
    for (final th in ChannelTheme.values)
      if (!channelLegacyThemes.contains(th))
        (th.name, canvas(s: fixed(th)), true),
    ('random-all', canvas(s: all), true),
    ('overview-all', canvas(s: all, overview: true), false),
    ('popover', canvas(s: all, popover: true), true),
    (
      'popover-fixed',
      canvas(s: fixed(ChannelTheme.metro), popover: true),
      false,
    ),
  ];
  for (final (file, pump, alsoDark) in v2) {
    for (final dark in [false, if (alsoDark) true]) {
      final name = dark ? '$file-dark' : file;
      testWidgets('golden v2/$name', skip: skip, (t) async {
        await pump(t, dark);
        final masks = _formerRulerRegions(t);
        final ruler = find.byKey(const Key('channel-ruler'));
        if (ruler.evaluate().isNotEmpty) {
          final l = AppLocalizations.of(t.element(ruler))!;
          final row = t.getRect(ruler);
          final sub = t.getRect(find.text(l.channel_rulerSub));
          masks.add(
            Rect.fromLTRB(row.left, sub.top, row.right - 40, sub.bottom),
          );
        }
        await expectOutsideApprovedRegions(
          t,
          find.byKey(const Key('gen-capture')),
          'test/presentation/ui/channel/goldens/v2/$name.png',
          masks,
        );
      });
    }
  }
}
