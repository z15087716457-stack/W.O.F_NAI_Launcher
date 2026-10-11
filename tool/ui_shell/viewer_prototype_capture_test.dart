// 大图查看器：和 HTML 原型（.devin/mockups/viewer/mock.html）同场景、同尺寸（1600 × 1000，含 48 主导航）的实绘，
// 用原型同一批图；外加每个场景关键元素的位置（rects.json，原点在主导航右边），供 viewer_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/viewer_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/viewer/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/viewer/viewer_test_harness.dart';

const _assets = '../../mockups/viewer/assets';
final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String key, bool thumb) =>
    _images.putIfAbsent('$key$thumb', () {
      for (final n in [if (!thumb) 's$key', 't$key']) {
        final f = File('$_assets/$n.jpg');
        if (f.existsSync()) return MemoryImage(f.readAsBytesSync());
      }
      return null;
    });

const _keys = {
  'topbar': 'viewer-topbar',
  'back': 'viewer-back',
  'zoom': 'viewer-zoom',
  'actual': 'viewer-actual',
  'fullscreen': 'viewer-fullscreen',
  'info-toggle': 'viewer-info-toggle',
  'arrow-next': 'viewer-next',
  'arrow-prev': 'viewer-prev',
  'filmstrip': 'viewer-filmstrip',
  'film-current': 'viewer-film-current',
  'image': 'viewer-image',
  'info': 'viewer-info',
  'info-header': 'viewer-info-header',
  'footer': 'viewer-footer',
  'primary': 'viewer-primary',
  'param-0': 'viewer-param-0',
  'prompt-box': 'viewer-prompt-box',
  'toast': 'viewer-undo',
  'empty': 'viewer-info-nometa',
  'tile-0': 'viewer-tile-img2img',
  'tile-5': 'viewer-tile-upscale',
};

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/viewer/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};

  final scenes =
      <(String, ViewerViewData, double, Future<void> Function(WidgetTester)?)>[
        ('a', ViewerFixture.gallery(images: protoImage), viewerRail, null),
        (
          'zoom',
          ViewerFixture.gallery(images: protoImage),
          viewerRail,
          (t) async {
            await tapKey(t, 'viewer-zoom-menu');
            await tapKey(t, 'viewer-zoom-200');
          },
        ),
        (
          'meta',
          ViewerFixture.gallery(
            current: '29',
            position: 1289,
            favorite: false,
            images: protoImage,
          ),
          viewerRail,
          null,
        ),
        ('nometa', ViewerFixture.nometa(images: protoImage), viewerRail, null),
        (
          'hist',
          ViewerFixture.generation(images: protoImage),
          viewerRail,
          null,
        ),
        ('del', ViewerFixture.deleted(images: protoImage), viewerRail, null),
        (
          'more',
          ViewerFixture.gallery(images: protoImage),
          viewerRail,
          (t) async {
            await tapKey(t, 'viewer-info-more');
            await tapKey(t, 'viewer-more-collections');
          },
        ),
        (
          'help',
          ViewerFixture.gallery(images: protoImage),
          viewerRail,
          (t) async {
            await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
            await t.sendKeyEvent(LogicalKeyboardKey.slash);
            await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          },
        ),
        (
          'full',
          ViewerFixture.gallery(images: protoImage, fullscreen: true),
          0,
          null,
        ),
        (
          'load',
          ViewerFixture.gallery(
            current: '16',
            loading: true,
            status: ViewerMetaStatus.loading,
            images: protoImage,
          ),
          viewerRail,
          null,
        ),
        (
          'err',
          ViewerFixture.gallery(
            current: '16',
            missing: true,
            images: protoImage,
          ),
          viewerRail,
          null,
        ),
      ];

  for (final (name, data, rail, interact) in scenes) {
    testWidgets(name, (t) async {
      debugDisableShadows = false;
      await pumpViewer(t, data: data, rail: rail);
      if (interact != null) {
        await interact(t);
        await t.pumpAndSettle();
      }
      final m = <String, List<double>>{};
      for (final MapEntry(key: k, value: id) in _keys.entries) {
        final f = find.byKey(Key(id));
        if (f.evaluate().length == 1) {
          final r = t.getRect(f);
          m[k] = [r.left, r.top, r.width, r.height];
        }
      }
      rects[name] = m;
      await t.runAsync(() async {
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('viewer-capture')),
        );
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      await t.pumpWidget(const SizedBox());
      debugDisableShadows = true;
    });
  }

  tearDownAll(() {
    File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  });
}
