import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/ui/kit/app_visibility_scope.dart';

const _captureKey = Key('agent-pixel-capture');
final _toggle = find.byKey(const Key('agent-toggle'));

void main() {
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
              _button(badge: AgentToggleBadge.waiting),
              _button(badge: AgentToggleBadge.done),
              _button(badge: AgentToggleBadge.running),
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
                    ? (dark ? 0xff3d8bff : 0xff0a6cff)
                    : theme.colorScheme.surface.toARGB32(),
              );
            }
          }
        }
      });
    }
  }

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
    final tip = tester.getCenter(_toggle) + const Offset(0, -8);
    final background = GeistTheme.light.colorScheme.surface.toARGB32();
    Future<int> tipColor([String? capture]) async =>
        (await _pixels(tester, 1, capture))(tip.dx.round(), tip.dy.round());

    expect(await tipColor(), 0xff0a6cff);
    await tester.tap(_toggle);
    await tester.pump();
    expect(await tipColor(), background);
    await tester.pump(const Duration(milliseconds: 320));
    expect(await tipColor('agent-jump'), 0xff0a6cff);
    await tester.tap(_toggle);
    await tester.pump();
    expect(await tipColor(), background);
    expect(clicks, 2);

    visible.value = false;
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 10));
    visible.value = true;
    await tester.pump();
    expect(await tipColor(), 0xff0a6cff);
  });

  testWidgets('reduced motion keeps static states and the running badge', (
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
          badge: AgentToggleBadge.running,
          onPressed: () => expanded.value = !on,
        ),
      ),
    );
    final rect = tester.getRect(_toggle);
    final x = rect.center.dx.round();
    final y = (rect.center.dy - 8).round();
    final first = await _pixels(tester, 1);
    expect(first(x, y), 0xff0a6cff);
    expect(
      first((rect.right - 1).round(), rect.top.round()),
      GeistTheme.light.colorScheme.primary.toARGB32(),
    );
    await tester.tap(_toggle);
    await tester.pump();
    expect((await _pixels(tester, 1))(x, y), 0xffffffff);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final header in [false, true]) {
    testWidgets(
      'running hops, waiting blinks and done stays visible, header=$header',
      (tester) async {
        await _pump(
          tester,
          child: Row(
            spacing: 14,
            children: [
              for (final badge in [
                AgentToggleBadge.running,
                AgentToggleBadge.waiting,
                AgentToggleBadge.done,
              ])
                if (header)
                  AgentStatusMark(badge: badge)
                else
                  _button(badge: badge),
            ],
          ),
        );
        final marks = header ? find.byType(AgentStatusMark) : _toggle;
        final tip = tester.getCenter(marks.first) + const Offset(0, -8);
        final waiting = tester.getRect(marks.at(1));
        final done = tester.getRect(marks.at(2));
        final initial = await _pixels(
          tester,
          1,
          header ? 'agent-header-status' : null,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          (await _pixels(tester, 1))(tip.dx.round(), tip.dy.round()),
          header ? 0xff0a6cff : GeistTheme.light.colorScheme.surface.toARGB32(),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final after = await _pixels(tester, 1);
        final waitingX = (waiting.right - 1).round();
        final waitingY = waiting.top.round();
        final doneX = (done.right - 1).round();
        final doneY = done.top.round();
        expect(after(waitingX, waitingY), isNot(initial(waitingX, waitingY)));
        expect(after(doneX, doneY), initial(doneX, doneY));
      },
    );
  }

  testWidgets('idle sidebar blinks and returns to the open eye frame', (
    tester,
  ) async {
    await _pump(tester, child: const AgentStatusMark());
    final eye =
        tester.getCenter(find.byType(AgentStatusMark)) + const Offset(-2, 2);
    Future<int> eyeColor() async =>
        (await _pixels(tester, 1))(eye.dx.round(), eye.dy.round());

    expect(await eyeColor(), 0xff0040b0);
    await tester.pump(const Duration(seconds: 3));
    var blinked = false;
    for (var sample = 0; sample <= 20; sample++) {
      if (await eyeColor() == 0xffffffff) {
        blinked = true;
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(blinked, isTrue);
    await tester.pump(const Duration(milliseconds: 120));
    expect(await eyeColor(), 0xff0040b0);
  });
}

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
  ValueNotifier<bool>? visible,
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = Size(324 * ratio, 64 * ratio);
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
