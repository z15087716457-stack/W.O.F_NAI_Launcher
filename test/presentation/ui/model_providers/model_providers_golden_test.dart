// 服务商工作台基准截图（中文浅色 / 深色 + 关键状态）：固定假数据、真实字体，锁定视觉。
// 只有界面方确认新样子后才更新：
//   flutter test --update-goldens test/presentation/ui/model_providers/model_providers_golden_test.dart
// 接线侧不准 --update-goldens。基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/approved_visual_regions.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model_providers_harness.dart';

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  final scenes = <(String, double, bool, Future<void> Function(WidgetTester)?)>[
    ('ready', 1600, false, null),
    ('ready-dark', 1600, true, null),
    (
      'pro',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-model-deepseek-v4-pro'))),
    ),
    (
      'catalog',
      1600,
      false,
      (t) async {
        await t.tap(find.byKey(const Key('mp-provider-or')));
        await t.pumpAndSettle();
        await t.tap(find.text('服务商目录 342'));
        await t.pumpAndSettle();
        await t.enterText(_field('mp-filter-catalog'), 'claude');
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-opus-5')));
        await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-haiku-5')));
      },
    ),
    (
      'catalog-dark',
      1600,
      true,
      (t) async {
        await t.tap(find.byKey(const Key('mp-provider-or')));
        await t.pumpAndSettle();
        await t.tap(find.text('服务商目录 342'));
      },
    ),
    (
      'error',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-provider-relay'))),
    ),
    (
      'headers',
      1600,
      false,
      (t) => t.tap(find.byKey(const Key('mp-provider-or'))),
    ),
    (
      'unsaved',
      1600,
      false,
      (t) async {
        await t.tap(find.byKey(const Key('mp-level-medium')));
        await t.tap(find.byKey(const Key('mp-cap-search')));
      },
    ),
    ('add', 1600, false, (t) => t.tap(find.byKey(const Key('mp-add')))),
    ('add-dark', 1600, true, (t) => t.tap(find.byKey(const Key('mp-add')))),
    ('narrow', 1100, false, null),
  ];

  for (final (name, w, dark, act) in scenes) {
    testWidgets(name, skip: skip, (t) async {
      await pumpProviders(t, window: w, height: 1100, dark: dark);
      if (act != null) {
        await act(t);
        await t.pumpAndSettle();
      }
      // 2026-10-19：设置导航的 Agent 图标换成侧栏同款标志，只排除这个
      // 18px 图标格；原 PNG 不变，其余像素逐个锁定。
      final masks = [
        for (final e
            in find.byKey(const Key('settings-nav-agent-mark')).evaluate())
          Rect.fromCenter(
            center: t.getRect(find.byWidget(e.widget)).center,
            width: 18,
            height: 18,
          ),
        // 2026-10-20：非 Anthropic 协议隐藏「思考协议」（用户确认）。只排除默认档位
        // 那一行里、默认档位选择框右边原来放思考协议的位置；仍显示时照常逐像素比对。
        if (find.byKey(const Key('mp-adaptive')).evaluate().isEmpty)
          for (final e in find.byKey(const Key('mp-thinking-row')).evaluate())
            () {
              final row = t.getRect(find.byWidget(e.widget));
              final picker = t.getRect(
                find.byKey(const Key('mp-default-level')),
              );
              return Rect.fromLTRB(
                picker.right,
                row.top,
                row.right,
                row.bottom,
              );
            }(),
        // 2026-10-21：删掉服务商级「图片输入」开关和检查器「采样」一节，思考档位改用
        // 英文原名（用户确认）。从「请求」一行往下的中栏和检查器整体上移，一起排除；
        // 卡片缩短后底边上移，排除服务商列表下方到底部的条带。标题、页签、
        // 服务商列表、接口地址 / Key / 协议和检查器上半部分照旧逐像素锁定。
        ...() {
          final capture = t.getRect(find.byKey(const Key('settings-capture')));
          final retry = find.byKey(const Key('mp-retry'));
          final url = find.byKey(const Key('mp-url'));
          final first = find.byKey(const Key('mp-provider-ds'));
          final last = find.byKey(const Key('mp-provider-relay'));
          if (retry.evaluate().isEmpty || url.evaluate().isEmpty) {
            return const <Rect>[];
          }
          final r = t.getRect(retry);
          final u = t.getRect(url);
          // 英文档位名宽度不同、换行位置变了：排除档位按钮所在的检查器区域。
          final levels = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('mp-level-'),
          );
          return [
            if (levels.evaluate().isNotEmpty)
              () {
                final box = levels
                    .evaluate()
                    .map((e) => t.getRect(find.byWidget(e.widget)))
                    .reduce((a, b) => a.expandToInclude(b));
                return Rect.fromLTRB(
                  box.left - 4,
                  box.top - 4,
                  capture.right,
                  capture.bottom,
                );
              }(),
            Rect.fromLTRB(
              u.left - 24,
              r.top - 30,
              capture.right,
              capture.bottom,
            ),
            // 卡片左边框 2px 一列（卡片变矮后边框的抗锯齿随之变化）。
            if (first.evaluate().isNotEmpty)
              Rect.fromLTRB(
                t.getRect(first).left - 14,
                t.getRect(first).top,
                t.getRect(first).left - 8,
                capture.bottom,
              ),
            if (first.evaluate().isNotEmpty && last.evaluate().isNotEmpty)
              Rect.fromLTRB(
                t.getRect(first).left - 12,
                t.getRect(last).bottom + 8,
                capture.right,
                capture.bottom,
              ),
          ];
        }(),
      ];
      await expectOutsideApprovedRegions(
        t,
        find.byKey(const Key('settings-capture')),
        'test/presentation/ui/model_providers/goldens/mp-$name.png',
        masks,
      );
    });
  }
}
