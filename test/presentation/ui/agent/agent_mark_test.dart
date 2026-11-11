import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/ui/kit/app_visibility_scope.dart';

const _captureKey = Key('agent-pixel-capture');
final _toggle = find.byKey(const Key('agent-toggle'));
const _blue = 0xff0a6cff;
const _white = 0xffffffff;
const _expandedEye = 0xff0040b0;
final _surface = GeistTheme.light.colorScheme.surface.toARGB32();
final _accent = GeistTheme.light.colorScheme.primary.toARGB32();
final _error = GeistTheme.light.colorScheme.error.toARGB32();
const _warn = 0xffb86e00;
const _ok = 0xff2b9a66;
const _faint = 0xff8f8f8f;

/// Always rolls [value], so the idle loop always picks the same reaction.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  setUp(() => agentMarkRandom = _FixedRandom(.1));
  tearDown(() => agentMarkRandom = Random());

  test('all frames have contiguous rows and smooth pixel boundaries', () {
    for (final entry in agentMarkFrames.entries) {
      expect(entry.value, hasLength(9), reason: entry.key);
      (int, int)? previous;
      for (final row in entry.value) {
        expect(row.length, anyOf(9, 11), reason: entry.key);
        final left = row.indexOf(RegExp('[^.]'));
        if (left == -1) continue;
        final right = row.lastIndexOf(RegExp('[^.]'));
        expect(
          row.substring(left, right + 1),
          isNot(contains('.')),
          reason: '${entry.key}: $row',
        );
        final inset = (row.length - 9) ~/ 2;
        final bounds = (left - inset, right - inset);
        if (previous != null) {
          expect(
            (bounds.$1 - previous.$1).abs(),
            lessThanOrEqualTo(1),
            reason: '${entry.key}: left boundary at $row',
          );
          expect(
            (bounds.$2 - previous.$2).abs(),
            lessThanOrEqualTo(1),
            reason: '${entry.key}: right boundary at $row',
          );
        }
        previous = bounds;
      }
    }
  });

  test('base, stretch and all original expressions remain byte-for-byte', () {
    const base = [
      '....#....',
      '...+#=...',
      '..+###=..',
      '.+#####=.',
      '#+######=',
      '##wo#wo#=',
      '##oo#oo#=',
      '=#######=',
      '.=======.',
    ];
    const originalExpressions = {
      'blink': {5: '#+######=', 6: '##oo#oo#='},
      'happy': {5: '##o###o#=', 6: '#o#o#o#o='},
      'lookL': {5: '#wo#wo##=', 6: '#oo#oo##='},
      'lookR': {5: '###wo#wo=', 6: '###oo#oo='},
      'lookU': {4: '#+wo#wo#=', 5: '##oo#oo#=', 6: '########='},
      'ouch': {4: '#+o###o#=', 5: '###o#o##=', 6: '##o###o#='},
      'talkA': {7: '=###o###='},
      'talkB': {7: '=##ooo##='},
    };
    final frames = agentMarkFrames;
    expect(frames['base'], base);
    expect(frames['stretch'], const [
      '....#....',
      '....#....',
      '...+#=...',
      '..+###=..',
      '..+###=..',
      '..wo#wo..',
      '..oo#oo..',
      '..=###=..',
      '...===...',
    ]);
    for (final entry in originalExpressions.entries) {
      expect(frames[entry.key], [
        for (var y = 0; y < 9; y++) entry.value[y] ?? base[y],
      ], reason: entry.key);
    }
  });

  test('overflow spans adjacent body rows without isolated side pixels', () {
    for (final entry in agentMarkFrames.entries) {
      for (final x in [-1, 9]) {
        final spilled = <int>{};
        for (var y = 0; y < entry.value.length; y++) {
          final row = entry.value[y];
          final i = x + (row.length - 9) ~/ 2;
          if (i >= 0 && i < row.length && row[i] != '.') spilled.add(y);
        }
        for (final y in spilled) {
          expect(
            spilled.contains(y - 1) || spilled.contains(y + 1),
            isTrue,
            reason: '${entry.key}: isolated overflow at ($x, $y)',
          );
        }
      }
    }
  });

  test('squash blink lowers only the eyes within the widened body', () {
    expect(agentMarkFrames['squashBlink'], const [
      '...........',
      '...........',
      '....+#=....',
      '...+###=...',
      '..+#####=..',
      '.+#######=.',
      '+#########=',
      '###oo#oo##=',
      '.=========.',
    ]);
  });

  for (final expanded in [false, true]) {
    testWidgets('click squashes the body past the grid, expanded=$expanded', (
      tester,
    ) async {
      await _pump(tester, child: _button(expanded: expanded));
      final center = tester.getCenter(_toggle);
      await tester.tap(_toggle);
      await tester.pump();
      final pixels = await _pixels(tester, 1);
      expect(_at(pixels, center, -1, 7), expanded ? _white : _blue);
      expect(_at(pixels, center, -1, 6), expanded ? _white : 0xff6cb6ff);
      if (expanded) expect(_at(pixels, center, -2, 7), _blue);
    });
  }

  for (final dark in [false, true]) {
    for (final ratio in [1.25, 1.5]) {
      testWidgets('sprite aligns to physical pixels at $ratio, dark=$dark', (
        tester,
      ) async {
        const mark = Key('static-agent-mark');
        final theme = dark ? GeistTheme.dark : GeistTheme.light;
        await _pump(
          tester,
          theme: theme,
          ratio: ratio,
          child: Row(
            spacing: 14,
            children: [
              _button(),
              _button(expanded: true),
              const AgentMark(tileSize: 26),
              const AgentMark(key: mark),
              _button(badge: AgentToggleBadge.question),
              _button(badge: AgentToggleBadge.done),
              _button(badge: AgentToggleBadge.thinking),
            ],
          ),
        );
        final pixels = await _pixels(
          tester,
          ratio,
          'agent-${dark ? 'dark' : 'light'}-$ratio',
        );
        final cell = (2 * ratio).round();
        for (final icon in [find.byKey(mark), _toggle.first]) {
          final center = tester.getCenter(icon);
          final left = (center.dx * ratio - cell * 4.5).round();
          final top = (center.dy * ratio - cell * 4.5).round();
          for (var y = 0; y < cell; y++) {
            for (var x = 0; x < 9 * cell; x++) {
              expect(
                pixels(left + x, top + y),
                x ~/ cell == 4
                    ? (dark ? 0xff3d8bff : _blue)
                    : theme.colorScheme.surface.toARGB32(),
              );
            }
          }
        }
      });
    }
  }

  testWidgets('expanded drops the tile and rings a white sprite in blue', (
    tester,
  ) async {
    await _pump(tester, child: _button(expanded: true));
    final center = tester.getCenter(_toggle);
    final pixels = await _pixels(tester, 1, 'agent-expanded');
    expect(_at(pixels, center, 4, 0), _white);
    expect(_at(pixels, center, 3, 0), _blue);
    expect(_at(pixels, center, 5, 0), _blue);
    expect(_at(pixels, center, 4, -1), _blue);
    expect(_at(pixels, center, 3, 5), _expandedEye);
    // Former solid tile area: corners of the 28px button stay transparent.
    for (final corner in [const Offset(-12, -12), const Offset(12, 12)]) {
      final point = center + corner;
      expect(pixels(point.dx.round(), point.dy.round()), _surface);
    }
  });

  testWidgets('clicks restart the jump and hidden windows reset it', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    var clicks = 0;
    await _pump(
      tester,
      visible: visible,
      child: _button(onPressed: () => clicks++),
    );
    final center = tester.getCenter(_toggle);
    Future<int> tip([String? capture]) async =>
        _at(await _pixels(tester, 1, capture), center, 4, 0);

    expect(await tip(), _blue);
    await tester.tap(_toggle);
    await tester.pump();
    expect(await tip(), _surface, reason: 'squashed: no tip');
    await tester.pump(const Duration(milliseconds: 320));
    expect(await tip('agent-jump'), _blue, reason: 'airborne body');
    await tester.tap(_toggle);
    await tester.pump();
    expect(await tip(), _surface);
    expect(clicks, 2);

    visible.value = false;
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 10));
    visible.value = true;
    await tester.pump();
    expect(await tip(), _blue);
  });

  testWidgets('reduced motion shows a still frame and the state badge', (
    tester,
  ) async {
    final expanded = ValueNotifier(false);
    addTearDown(expanded.dispose);
    await _pump(
      tester,
      reduceMotion: true,
      child: ValueListenableBuilder(
        valueListenable: expanded,
        builder: (_, on, _) => _button(
          expanded: on,
          badge: AgentToggleBadge.thinking,
          onPressed: () => expanded.value = !on,
        ),
      ),
    );
    final rect = tester.getRect(_toggle);
    final first = await _pixels(tester, 1);
    expect(_at(first, rect.center, 4, 0), _blue);
    expect(_at(first, rect.center, 2, -2), _accent, reason: 'thinking dots');
    expect(first((rect.right - 1).round(), rect.top.round()), _accent);
    await tester.tap(_toggle);
    await tester.pump();
    expect(_at(await _pixels(tester, 1), rect.center, 4, 0), _white);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 5));
    expect(_at(await _pixels(tester, 1), rect.center, 2, -2), _accent);
  });

  for (final header in [false, true]) {
    testWidgets('states draw their symbols and outcome badges, '
        'header=$header', (tester) async {
      const badges = [
        AgentToggleBadge.thinking,
        AgentToggleBadge.question,
        AgentToggleBadge.done,
        AgentToggleBadge.error,
        AgentToggleBadge.runLimit,
        AgentToggleBadge.writing,
      ];
      await _pump(
        tester,
        width: 400,
        child: Row(
          spacing: 18,
          children: [
            for (final badge in badges)
              if (header)
                AgentStatusMark(badge: badge)
              else
                _button(badge: badge),
          ],
        ),
      );
      final marks = header ? find.byType(AgentStatusMark) : _toggle;
      Offset center(int i) => tester.getCenter(marks.at(i));
      int corner(int Function(int, int) pixels, int i) {
        final rect = tester.getRect(marks.at(i));
        return pixels((rect.right - 1).round(), rect.top.round());
      }

      var pixels = await _pixels(
        tester,
        1,
        header ? 'agent-header-status' : 'agent-toggle-status',
      );
      expect(_at(pixels, center(0), 2, -2), _surface);
      expect(corner(pixels, 0), _surface, reason: 'running shows no badge');
      expect(corner(pixels, 2), _ok);
      expect(corner(pixels, 3), _error);
      expect(corner(pixels, 4), _warn);

      await tester.pump(const Duration(milliseconds: 300));
      pixels = await _pixels(tester, 1);
      expect(_at(pixels, center(0), 2, -2), _accent, reason: 'first dot');
      expect(_at(pixels, center(1), 7, 1), _warn, reason: 'question dot');
      expect(corner(pixels, 1), _surface, reason: 'question uses its symbol');

      var talked = false;
      for (var i = 0; i < 20 && !talked; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        final mouth = _at(await _pixels(tester, 1), center(5), 4, 7);
        talked = mouth != (header ? _white : _blue);
      }
      expect(talked, isTrue, reason: 'writing opens the mouth');
    });
  }

  testWidgets('idle breathes, then blinks, and returns to open eyes', (
    tester,
  ) async {
    await _pump(tester, child: const AgentStatusMark());
    final center = tester.getCenter(find.byType(AgentStatusMark));
    Future<int> cell(int x, int y) async =>
        _at(await _pixels(tester, 1), center, x, y);

    expect(await cell(3, 5), _expandedEye);
    await tester.pump(const Duration(milliseconds: 2250));
    expect(await cell(4, -1), _surface, reason: 'breathing lowers the tip');
    expect(await cell(3, 5), _expandedEye);
    await tester.pump(const Duration(milliseconds: 1650));
    expect(await cell(4, -1), _blue, reason: 'outline above the tip');
    await tester.pump(const Duration(milliseconds: 200));
    expect(await cell(3, 5), _white, reason: 'blink');
    await tester.pump(const Duration(milliseconds: 120));
    expect(await cell(3, 5), _expandedEye);
  });

  testWidgets('idle toggle dozes off and wakes on hover', (tester) async {
    await _pump(tester, child: _button());
    final center = tester.getCenter(_toggle);
    for (var i = 0; i < 125; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    Future<bool> snoring(Duration span) async {
      for (
        var t = Duration.zero;
        t < span;
        t += const Duration(milliseconds: 100)
      ) {
        await tester.pump(const Duration(milliseconds: 100));
        if (_at(await _pixels(tester, 1), center, 6, -1) == _faint) return true;
      }
      return false;
    }

    expect(await snoring(const Duration(seconds: 3)), isTrue);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(center);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(await snoring(const Duration(seconds: 4)), isFalse);
  });

  testWidgets('a new state replays its entrance and stops cleanly', (
    tester,
  ) async {
    final badge = ValueNotifier(AgentToggleBadge.thinking);
    addTearDown(badge.dispose);
    await _pump(
      tester,
      child: ValueListenableBuilder(
        valueListenable: badge,
        builder: (_, value, _) => _button(badge: value),
      ),
    );
    final center = tester.getCenter(_toggle);
    badge.value = AgentToggleBadge.done;
    await tester.pump();
    expect(_at(await _pixels(tester, 1), center, 4, 0), _surface);
    var sparkled = false;
    for (var i = 0; i < 12 && !sparkled; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      final pixels = await _pixels(tester, 1);
      sparkled = _at(pixels, center, -2, 1) == 0xfff5a400;
    }
    expect(sparkled, isTrue, reason: 'done celebrates with stars');
    badge.value = AgentToggleBadge.error;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_at(await _pixels(tester, 1), center, 3, 5), 0xff08214f);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });
}

int _at(int Function(int, int) pixels, Offset center, int x, int y) => pixels(
  (center.dx - 9).round() + x * 2 + 1,
  (center.dy - 9).round() + y * 2 + 1,
);

AgentToggleButton _button({
  bool expanded = false,
  VoidCallback? onPressed,
  AgentToggleBadge badge = AgentToggleBadge.none,
}) => AgentToggleButton(
  expanded: expanded,
  tooltip: 'NAI Agent',
  badge: badge,
  onPressed: onPressed ?? () {},
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  ThemeData? theme,
  double ratio = 1,
  double width = 324,
  ValueNotifier<bool>? visible,
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = Size(width * ratio, 64 * ratio);
  addTearDown(tester.view.reset);
  theme ??= GeistTheme.light;
  final body = RepaintBoundary(
    key: _captureKey,
    child: ColoredBox(
      color: theme.colorScheme.surface,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.3, top: 17.4),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: visible == null
              ? body
              : AppVisibilityScope(visibility: visible, child: body),
        ),
      ),
    ),
  );
}

Future<int Function(int, int)> _pixels(
  WidgetTester tester,
  double ratio, [
  String? capture,
]) async {
  final box = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final (ByteData data, int width) = (await tester.runAsync(() async {
    final image = await box.toImage(pixelRatio: ratio);
    final data = (await image.toByteData())!;
    final directory = Platform.environment['AGENT_MARK_CAPTURE_DIR'];
    if (directory != null && capture != null) {
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('$directory/$capture.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List());
    }
    final width = image.width;
    image.dispose();
    return (data, width);
  }))!;
  return (x, y) {
    final rgba = data.getUint32((y * width + x) * 4);
    return (rgba >> 8) | ((rgba & 0xff) << 24);
  };
}
