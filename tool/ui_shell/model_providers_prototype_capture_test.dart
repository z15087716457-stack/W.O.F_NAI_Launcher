// 服务商工作台：用原型同一批假数据实绘，导出 PNG 和关键元素位置（rects.json），
// 供 model_providers_measure.py 和原型（.devin/mockups/model-providers/mock.html#b）比。
// 运行：flutter test tool/ui_shell/model_providers_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/model-providers/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/model_providers/model_providers_harness.dart';

/// 原型 hash → (窗口高, 深色, 交互)。
final views = <String, (double, bool, Future<void> Function(WidgetTester)?)>{
  'b': (1100, false, null),
  'b-dark': (1100, true, null),
  'b-catalog-p_openrouter': (
    1100,
    false,
    (t) async {
      await t.tap(find.byKey(const Key('mp-provider-or')));
      await t.pumpAndSettle();
      await t.tap(find.text('服务商目录 342'));
      await t.pumpAndSettle();
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('mp-filter-catalog')),
          matching: find.byType(TextField),
        ),
        'claude',
      );
      await t.pump(const Duration(milliseconds: 400));
      for (final id in [
        'anthropic/claude-opus-5',
        'anthropic/claude-haiku-5',
      ]) {
        await t.tap(find.byKey(Key('mp-cat-$id')));
        await t.pump();
      }
      await t.pumpAndSettle();
    },
  ),
  'b-p_relay': (
    1100,
    false,
    (t) async {
      await t.tap(find.byKey(const Key('mp-provider-relay')));
      await t.pumpAndSettle();
    },
  ),
  'b-add': (
    1100,
    false,
    (t) async {
      await t.tap(find.byKey(const Key('mp-add')));
      await t.pumpAndSettle();
    },
  ),
  'b-unsaved': (
    1100,
    false,
    (t) async {
      await t.tap(find.byKey(const Key('mp-level-medium')));
      await t.tap(find.byKey(const Key('mp-cap-search')));
      await t.pumpAndSettle();
    },
  ),
};

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/model-providers/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, Object>>{};

  for (final MapEntry(key: name, value: (h, dark, act)) in views.entries) {
    testWidgets('capture $name', (t) async {
      await pumpProviders(t, height: h, dark: dark);
      if (act != null) await act(t);
      final m = <String, Object>{};
      void put(String k, Finder f) {
        if (f.evaluate().isEmpty) return;
        final r = t.getRect(f.first);
        m[k] = [r.left, r.top, r.width, r.height];
      }

      put('list', find.byKey(const Key('mp-list')));
      put('middle', find.byKey(const Key('mp-middle')));
      put('inspector', find.byKey(const Key('mp-inspector')));
      put('title', find.byKey(const Key('mp-title')));
      put('status', find.byKey(const Key('mp-status')));
      put('test', find.byKey(const Key('mp-test')));
      put('url', find.byKey(const Key('mp-url')));
      put('key', find.byKey(const Key('mp-key')));
      put('protocol', find.byKey(const Key('mp-protocol')));
      put('timeout', find.byKey(const Key('mp-timeout')));
      put('concurrency', find.byKey(const Key('mp-concurrency')));
      put('retry', find.byKey(const Key('mp-retry')));
      put('mode', find.byKey(const Key('mp-mode')));
      put('models', find.byKey(const Key('mp-models')));
      put('catalog', find.byKey(const Key('mp-catalog')));
      put('alias', find.byKey(const Key('mp-alias')));
      put('levels', find.byKey(const Key('mp-levels')));
      put('testModel', find.byKey(const Key('mp-test-model')));
      var i = 0;
      for (final e
          in find
              .byWidgetPredicate(
                (w) => '${w.key}'.startsWith("[<'mp-provider-"),
              )
              .evaluate()) {
        final r = t.getRect(find.byElementPredicate((x) => x == e));
        m['prov${i++}'] = [r.left, r.top, r.width, r.height];
      }
      rects[name] = m;
      final box = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('settings-capture')),
      );
      await t.runAsync(() async {
        final img = await box.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
    });
  }

  tearDownAll(() {
    File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  });
}
