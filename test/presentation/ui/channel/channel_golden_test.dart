// 画布视觉通道基准截图（中文浅色 / 深色）：固定种子 + 假历史，锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/channel/channel_golden_test.dart
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

  // (文件名, 装载, 也拍深色)
  final scenes = <(String, _Pump, bool)>[
    ('random', canvas(), true),
    for (final th in ChannelTheme.values) (th.name, canvas(s: fixed(th)), true),
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
        await expectLater(
          find.byKey(const Key('gen-capture')),
          matchesGoldenFile('goldens/$name.png'),
        );
      });
    }
  }
}
