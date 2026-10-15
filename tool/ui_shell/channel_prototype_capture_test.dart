// 画布视觉通道：用原型同一批图（.devin/mockups/generation/assets）实绘各场景，
// 外加关键元素的位置（rects.json），供 channel_measure.py 和原型（.devin/mockups/canvas-channel/mock.html）比。
// 运行：flutter test tool/ui_shell/channel_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/channel/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/channel/channel_test_harness.dart';

final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String key) => _images.putIfAbsent(key, () {
  final f = File('../../mockups/generation/assets/$key.jpg');
  return f.existsSync() ? MemoryImage(f.readAsBytesSync()) : null;
});

/// 键名 → Flutter 组件 Key（和 channel_measure.py 的键名一致）。
const keys = {
  'pop': 'gen-display-popover',
  'sec': 'channel-settings',
  'mode': 'channel-mode',
  'mode-off': 'channel-mode-off',
  'mode-fixed': 'channel-mode-fixed',
  'mode-random': 'channel-mode-random',
  'cards': 'channel-cards',
  'card-circuit': 'channel-card-circuit',
  'card-wave': 'channel-card-wave',
  'note': 'channel-note',
  'reroll': 'channel-reroll',
  'level': 'channel-level',
  'ruler': 'channel-ruler',
  'motion': 'channel-motion',
  'scrub': 'channel-scrubber',
  'canvas': 'channel-fixture-canvas',
};

typedef Scene = (String, Future<void> Function(WidgetTester));

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/channel/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, Object>>{};
  final texts = <String, String>{};

  Future<void> pump(
    WidgetTester t, {
    ChannelSettings? s,
    bool dark = false,
    bool overview = false,
    bool generating = false,
    double? focusY,
    double? focusScale,
  }) => pumpChannel(
    t,
    settings: s,
    dark: dark,
    overview: overview,
    generating: generating,
    focusY: focusY,
    focusScale: focusScale,
    images: protoImage,
  );

  Future<void> pop(
    WidgetTester t, {
    ChannelSettings? s,
    bool dark = false,
  }) async {
    await pump(t, s: s, dark: dark);
    await tapKey(t, 'gen-display');
  }

  final scenes = <Scene>[
    ('random', (t) => pump(t)),
    ('random-dark', (t) => pump(t, dark: true)),
    for (final th in ChannelTheme.values) ...[
      (
        th.name,
        (t) => pump(
          t,
          s: channelSettings(mode: ChannelMode.fixed, fixed: th),
        ),
      ),
      (
        '${th.name}-dark',
        (t) => pump(
          t,
          s: channelSettings(mode: ChannelMode.fixed, fixed: th),
          dark: true,
        ),
      ),
    ],
    ('overview', (t) => pump(t, overview: true)),
    ('overview-dark', (t) => pump(t, overview: true, dark: true)),
    ('transition', (t) => pump(t, focusY: 4012, focusScale: .35)),
    ('day', (t) => pump(t, focusY: 8200, focusScale: .3)),
    ('pop', (t) => pop(t)),
    ('pop-dark', (t) => pop(t, dark: true)),
    (
      'pop-fixed',
      (t) => pop(
        t,
        s: channelSettings(mode: ChannelMode.fixed, fixed: ChannelTheme.arcade),
      ),
    ),
    ('pop-off', (t) => pop(t, s: channelSettings(mode: ChannelMode.off))),
    ('off', (t) => pump(t, s: channelSettings(mode: ChannelMode.off))),
    ('generating', (t) => pump(t, generating: true)),
    ('soft', (t) => pump(t, s: channelSettings(level: ChannelLevel.soft))),
    ('strong', (t) => pump(t, s: channelSettings(level: ChannelLevel.strong))),
  ];

  for (final (name, run) in scenes) {
    testWidgets('capture $name', (tester) async {
      await run(tester);
      final m = <String, Object>{};
      for (final e in keys.entries) {
        final f = find.byKey(Key(e.value));
        if (f.evaluate().isEmpty) continue;
        final r = tester.getRect(f.first);
        m[e.key] = [r.left, r.top, r.width, r.height];
      }
      rects[name] = m;
      final seq = find.byKey(const Key('channel-sequence'));
      if (seq.evaluate().isNotEmpty) {
        texts[name] = (tester.widget(seq) as Text).data ?? '';
      }
      final boundary =
          tester.renderObject(find.byKey(const Key('gen-capture')))
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }

  tearDownAll(() {
    for (final e in texts.entries) {
      rects[e.key]?['noteText'] = e.value;
    }
    File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  });
}
