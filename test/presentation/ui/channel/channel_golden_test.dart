// 画布视觉通道 v3 字符艺术基准截图（中文浅色 / 深色）：固定种子 + 假历史，锁定 5 套字符艺术主题与 3 列弹层。
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'channel_test_harness.dart';

typedef _Pump = Future<void> Function(WidgetTester t, bool dark);

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

  final all = channelSettings(pool: ChannelSettings.allThemes);
  final scenes = <(String, _Pump, bool)>[
    for (final th in ChannelTheme.values) (th.name, canvas(s: fixed(th)), true),
    ('random', canvas(s: all), true),
    ('overview', canvas(s: all, overview: true), false),
    ('transition', canvas(s: all, focusY: 4012, focusScale: .35), false),
    ('popover', canvas(s: all, popover: true), true),
    (
      'popover-fixed',
      canvas(s: fixed(ChannelTheme.aurora), popover: true),
      false,
    ),
    (
      'popover-off',
      canvas(s: channelSettings(mode: ChannelMode.off), popover: true),
      false,
    ),
  ];

  for (final (file, pump, alsoDark) in scenes) {
    for (final dark in [false, if (alsoDark) true]) {
      final name = dark ? '$file-dark' : file;
      testWidgets('golden v3/$name', skip: skip, (t) async {
        await pump(t, dark);
        await expectLater(
          find.byKey(const Key('gen-capture')),
          matchesGoldenFile('goldens/v3/$name.png'),
        );
      });
    }
  }
}
