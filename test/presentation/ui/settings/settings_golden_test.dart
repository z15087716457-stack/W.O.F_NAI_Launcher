// 保留原设置页基准；归一居中，仅排除获准修改的蓝点标题行、图标和已移除的新功能标签。
// 说明文字、控件、卡片与外围仍逐像素匹配，标题另做几何和实绘检查。
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_text.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/approved_visual_regions.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  final scenes = <(String, Future<void> Function(WidgetTester))>[
    for (final p in SettingsPageId.values)
      (p.name, (t) => pumpSettings(t, page: p)),
    for (final p in [
      SettingsPageId.overview,
      SettingsPageId.appearance,
      SettingsPageId.shortcuts,
      SettingsPageId.models,
      SettingsPageId.upscale,
    ])
      ('${p.name}-dark', (t) => pumpSettings(t, page: p, dark: true)),
    ('search', (t) => pumpSettings(t, initialQuery: 'anlas')),
    (
      'toast',
      (t) => pumpSettings(
        t,
        page: SettingsPageId.generation,
        scene: SettingsScene.toast,
      ),
    ),
    (
      'restart',
      (t) => pumpSettings(
        t,
        page: SettingsPageId.network,
        scene: SettingsScene.restart,
      ),
    ),
    ('fresh', (t) => pumpSettings(t, scene: SettingsScene.fresh)),
    ('narrow', (t) => pumpSettings(t, window: 1100)),
  ];

  for (final (name, pump) in scenes) {
    testWidgets(name, skip: skip, (t) async {
      await pump(t);
      await _expectCenteredGolden(t, name);
      await t.pump(const Duration(seconds: 5));
    });
  }
}

// 只将已授权改变的横向锚点临时还原再实绘，避免平移旧 PNG 时
// Skia 圆角边缘的栅格差异。仅排除获准修改的蓝点标题行与图标，其余像素锁定。
// 居中和蓝点的几何、窗口缩放及实绘由对应专项验证。
Future<void> _expectCenteredGolden(WidgetTester t, String name) async {
  final scroll = t.widget<SingleChildScrollView>(
    find.byKey(const Key('settings-scroll')),
  );
  final align = t.renderObject<RenderPositionedBox>(
    find.byWidget(scroll.child! as Align),
  );
  final current = align.alignment;
  expect(current, Alignment.topCenter);
  try {
    align.alignment = Alignment.topLeft;
    await t.pump();
    final masks = <Rect>[];
    // F25：只豁免新增的“命中率”小字，原进度条、百分比及数量仍逐像素锁定。
    for (final label
        in find.byKey(const Key('cache-hit-rate-label')).evaluate()) {
      masks.add(t.getRect(find.byWidget(label.widget)));
    }
    final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
    expect(find.text(l.set_isNew), findsNothing);
    // 只豁免旧“新”标签本身的矩形，标题、卡片及其下方的控件继续逐像素锁定。
    final badgeText = TextPainter(
      text: TextSpan(
        text: l.set_isNew,
        style: UiText.sans(10.5, weight: FontWeight.w600, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeWidth = badgeText.width + 12;
    badgeText.dispose();
    for (final (type, label, gap) in <(Type, String, double)>[
      (SettingsOptionCard, l.set_apSystem, 8),
      (SettingsSection, l.set_scKeyboard, 6),
      (SettingsSection, l.set_stUsage, 6),
      (SettingsSection, l.set_nwCheck, 6),
      (SettingsAsideCard, l.set_bkAuto, 6),
      (SettingsAsideCard, l.set_upDefault, 6),
      (SettingsRow, l.set_abCopyDiag, 7),
    ]) {
      final title = find.descendant(
        of: find.byType(type),
        matching: find.text(label),
      );
      if (title.evaluate().isEmpty) continue;
      final rect = t.getRect(title);
      masks.add(
        Rect.fromLTWH(rect.right + gap, rect.center.dy - 9, badgeWidth, 18),
      );
    }
    for (final element in find.byType(SettingsRow).evaluate()) {
      final row = element.widget as SettingsRow;
      if (!row.modified || row.sub) continue;
      final title = t.getRect(
        find.descendant(
          of: find.byWidget(row),
          matching: find.byKey(const Key('settings-row-title')),
        ),
      );
      masks.add(
        Rect.fromLTRB(title.left - 13, title.top, title.right, title.bottom),
      );
    }
    for (final element in find.byType(SettingsModMark).evaluate()) {
      final mark = element.widget as SettingsModMark;
      if (!mark.on) continue;
      final shortcutLabel = find.ancestor(
        of: find.byWidget(mark),
        matching: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('shortcut-label-'),
        ),
      );
      final label = t.getRect(
        shortcutLabel.evaluate().isEmpty ? find.byWidget(mark) : shortcutLabel,
      );
      masks.add(
        Rect.fromLTRB(label.left - 13, label.top, label.right, label.bottom),
      );
    }
    for (final key in [
      'settings-upscale-seed-logo',
      'settings-upscale-rtx-logo',
    ]) {
      final logo = find.byKey(Key(key));
      if (logo.evaluate().isNotEmpty) masks.add(t.getRect(logo));
    }
    final brand = find.byKey(const Key('about-brand-slot'));
    if (brand.evaluate().isNotEmpty) {
      masks.add(
        t
            .getRect(brand)
            .expandToInclude(
              t.getRect(find.byKey(const Key('about-brand-name'))),
            ),
      );
    }
    await expectOutsideApprovedRegions(
      t,
      find.byKey(const Key('settings-capture')),
      'test/presentation/ui/settings/goldens/settings-$name.png',
      masks,
    );
  } finally {
    align.alignment = current;
    await t.pump();
  }
}
