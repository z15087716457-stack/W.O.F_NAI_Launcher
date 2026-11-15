import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import 'inline_prompt_readings_test.dart' as fixture;
import 'paired_prompt_readings_test.dart' as paired;

const examples = [
  (
    name: 'train',
    source:
        'An empty glowing train with warm interior lights is pulling into '
        'the station, doors about to open, rain streaking past.',
    parts: [
      (
        'An empty glowing train with warm interior lights is pulling into the station',
        '一列空荡发光的列车，车厢内亮着温暖的灯光，映照出无人乘坐的座椅，正缓缓驶入车站。',
      ),
      ('doors about to open', '车门即将打开'),
      ('rain streaking past.', '雨水划过车窗。'),
    ],
  ),
  (
    name: 'hud',
    source:
        'Persistent HUD in the corners: a small circular radar minimap in '
        'the top left with a white arrow at its center, beside it a thin green '
        'HP gauge and a thin blue EN gauge labeled "ノエ". All on-screen text '
        'is clean, legible Japanese., wide shot, side view, rainy night.',
    parts: [
      (
        'Persistent HUD in the corners: a small circular radar minimap in the top left with a white arrow at its center,',
        '左上角有一个小型圆形雷达小地图，中心有白色箭头，常驻界面保持在屏幕角落。',
      ),
      ('beside it', '在它旁边'),
      ('a thin green HP gauge', '一条纤细的绿色生命值槽'),
      ('and a thin blue EN gauge labeled "ノエ".', '以及标注“ノエ”的蓝色能量槽。'),
      ('All on-screen text is clean,', '所有屏幕文字都清楚地显示，'),
      ('legible Japanese.', '使用清晰易读的日语。'),
      ('wide shot', '远景'),
      ('side view', '侧视图'),
      ('rainy night.', '雨夜。'),
    ],
  ),
];

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'copy and native edits across a prose-to-short boundary use source only',
    (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final sample = examples.first;
      final c = TextEditingController(text: sample.source);
      final readings = [
        for (final (source, translation) in sample.parts)
          PromptReading(
            start: sample.source.indexOf(source),
            end: sample.source.indexOf(source) + source.length,
            source: source,
            translation: translation,
            perSegment: true,
          ),
      ];
      await fixture.pumpReadingEditor(t, c, readings);
      await t.showKeyboard(find.byType(TextField));
      final state = t.state<EditableTextState>(find.byType(EditableText));
      final from = sample.source.indexOf('station');
      final to = sample.source.indexOf('open') + 4;
      c.selection = TextSelection(baseOffset: from, extentOffset: to);
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyC);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(copied, sample.source.substring(from, to));
      final view = paired.editor(t), before = paired.editor(t).value;
      const replacement = 'station gates';
      t.testTextInput.updateEditingValue(
        before.copyWith(
          text: before.text.replaceRange(
            before.selection.start,
            before.selection.end,
            replacement,
          ),
          selection: TextSelection.collapsed(
            offset: before.selection.start + replacement.length,
          ),
        ),
      );
      await t.pump();
      expect(c.text, sample.source.replaceRange(from, to, replacement));
      expect(view.source.text, c.text);
      expect(find.text('待更新'), findsOneWidget);
      expect(find.text('雨水划过车窗。'), findsOneWidget);
      expect(
        t.state<EditableTextState>(find.byType(EditableText)),
        same(state),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.binding.setSurfaceSize(null);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  for (final sample in examples) {
    for (final width in [320.0, 440.0, 736.0]) {
      for (final scale in [1.0, 1.5]) {
        for (final dark in [true, false]) {
          testWidgets(
            '${sample.name} prose-to-short transitions width=$width scale=$scale dark=$dark',
            (t) async {
              final c = TextEditingController(text: sample.source);
              final readings = [
                for (final (source, translation) in sample.parts)
                  PromptReading(
                    start: sample.source.indexOf(source),
                    end: sample.source.indexOf(source) + source.length,
                    source: source,
                    translation: translation,
                    perSegment: true,
                  ),
              ];
              await fixture.pumpReadingEditor(
                t,
                c,
                readings,
                width: width,
                scale: scale,
                brightness: dark ? Brightness.dark : Brightness.light,
              );
              final boxes = [
                for (final item in paired.labels().evaluate())
                  t.getRect(find.byWidget(item.widget)),
              ];
              expect(boxes.length, readings.length);
              final capture = Platform.environment['READING_BOUNDARY_CAPTURE'];
              if (capture != null) {
                await t.runAsync(() async {
                  await Directory(capture).create(recursive: true);
                  final boundary = t.renderObject<RenderRepaintBoundary>(
                    find.byType(RepaintBoundary).first,
                  );
                  final image = await boundary.toImage();
                  final data = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '$capture/${sample.name}-$width-$scale-$dark.png',
                  ).writeAsBytes(data!.buffer.asUint8List());
                  image.dispose();
                });
              }
              final next = paired.glyphRect(
                t,
                readings[1].start,
                readings[1].start + 1,
              );
              expect(
                next.top,
                greaterThanOrEqualTo(boxes[0].bottom),
                reason:
                    'A short phrase following prose must start below its full translation',
              );
              for (var i = 0; i < boxes.length; i++) {
                expect(boxes[i].left, greaterThanOrEqualTo(-.1));
                expect(boxes[i].right, lessThanOrEqualTo(width + .1));
                final last = paired.glyphRect(
                  t,
                  readings[i].end - 1,
                  readings[i].end,
                );
                expect(boxes[i].top, greaterThanOrEqualTo(last.bottom));
                for (var j = i + 1; j < boxes.length; j++) {
                  final overlap = boxes[i].intersect(boxes[j]);
                  expect(
                    overlap.width > .1 && overlap.height > .1,
                    isFalse,
                    reason: 'Translations $i and $j must not overlap',
                  );
                }
              }
              // Neighboring short phrases still share a row when they fit.
              final a = paired.glyphRect(
                t,
                readings[1].start,
                readings[1].start + 1,
              );
              final b = paired.glyphRect(
                t,
                readings[2].start,
                readings[2].start + 1,
              );
              if (sample.name == 'hud' && width == 736 && scale == 1) {
                expect(b.top, closeTo(a.top, .1));
              }
              expect(c.text, sample.source);
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox());
              c.dispose();
              await t.binding.setSurfaceSize(null);
            },
          );
        }
      }
    }
  }
}
