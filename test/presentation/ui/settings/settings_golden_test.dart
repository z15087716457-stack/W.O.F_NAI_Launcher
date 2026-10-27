// 保留原设置页基准；归一居中，仅排除获准修改的标题行、图标、新标签、Agent 文案、主题卡顺序与字号示例位置。
// 获准区域以外仍逐像素匹配，变更区域另做几何和实绘检查。
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';
import 'dart:ui' as ui;

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
      final output = Platform.environment['FONT_SAMPLE_CAPTURE_DIR'];
      if (output != null && name.startsWith('appearance')) {
        final box = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('settings-capture')),
        );
        await t.runAsync(() async {
          final bitmap = await box.toImage(pixelRatio: 1);
          final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
          Directory(output).createSync(recursive: true);
          File(
            '$output/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          bitmap.dispose();
        });
      }
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
    // F36：字号示例在原占位内下移 8px，外侧行高及其余文字设置保持。
    // 只排除示例内框的原／新位置，居中与上下留白直接按几何核验。
    final sample = find.byKey(const Key('font-sample'));
    if (sample.evaluate().isNotEmpty) {
      final content = t.getRect(sample);
      final block = t.getRect(
        find.ancestor(of: sample, matching: find.byType(SettingsBlock)).first,
      );
      expect(content.center.dx, closeTo(block.center.dx, .01));
      expect(content.center.dy, closeTo(block.center.dy, .01));
      expect(content.top, greaterThan(block.top));
      expect(content.bottom, lessThan(block.bottom));
      masks.add(
        Rect.fromLTRB(content.left, block.top, content.right, block.bottom),
      );
    }
    // F29: the base row now shows Tag/Wiki counts instead of a version hash.
    // Supplement controls are capability-driven and covered by their own tests.
    final dictionaryBase = find.byKey(const Key('dictionary-base-row'));
    if (dictionaryBase.evaluate().isNotEmpty) {
      masks.add(t.getRect(dictionaryBase));
    }
    // F28：仅排除重排的三张主题卡及其 3px 选中光圈（含抗锯齿边缘）。
    // 比较工具另加 2px 容差，卡片外围和其余外观设置继续保持基准。
    for (final mode in ['system', 'light', 'dark']) {
      final card = find.byKey(Key('theme-$mode'));
      if (card.evaluate().isNotEmpty) masks.add(t.getRect(card).inflate(2));
    }
    // 2026-10-27 B05/B06（用户确认）：新增「创作区文字字号」「提示词自动补全」两行，
    // 从新行顶边往下的主栏一起排除（下方各行整体下移）；新行上方与侧栏照旧逐像素锁定。
    for (final key in ['workspaceFontScale', 'promptAutocomplete']) {
      final row = find.byKey(Key('setting-$key'));
      if (row.evaluate().isEmpty) continue;
      final capture = t.getRect(find.byKey(const Key('settings-capture')));
      final r = t.getRect(row);
      masks.add(Rect.fromLTRB(r.left, r.top, r.right, capture.bottom));
    }
    // F25：只豁免新增的“命中率”小字，原进度条、百分比及数量仍逐像素锁定。
    for (final label
        in find.byKey(const Key('cache-hit-rate-label')).evaluate()) {
      masks.add(t.getRect(find.byWidget(label.widget)));
    }
    final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
    // 2026-10-27 E04（用户确认）：「新」改为只在首次见到的那次启动显示，
    // 只允许出现在本批两行新设置里（这两行已整体排除），别处仍不准有常驻角标。
    final newRows = [
      for (final k in ['workspaceFontScale', 'promptAutocomplete'])
        find.byKey(Key('setting-$k')),
    ];
    for (final e in find.text('新').evaluate()) {
      expect(
        newRows.any(
          (row) => find
              .descendant(of: row, matching: find.byWidget(e.widget))
              .evaluate()
              .isNotEmpty,
        ),
        isTrue,
      );
    }
    // 只豁免旧“新”标签本身的矩形，标题、卡片及其下方的控件继续逐像素锁定。
    final badgeText = TextPainter(
      text: TextSpan(
        text: '新',
        style: UiText.sans(10.5, weight: FontWeight.w600, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeWidth = badgeText.width + 12;
    badgeText.dispose();
    // F26：仅排除改名影响的顺序标签、前置内容标题／提示及查看按钮行。
    for (final key in ['agent-instruction-order', 'agent-prompt-actions']) {
      final region = find.byKey(Key(key));
      if (region.evaluate().isNotEmpty) masks.add(t.getRect(region));
    }
    // D27：Skill 改造只排除 Agent 页说明行、侧栏（工具卡提示变长，新增两张侧卡使其下方
    // 卡片下移），以及主栏从新 Skill 分区开始往下（扩展、MCP 随之下移）。
    // 标题、模型区与整个指令区继续逐像素锁定；新区域另有实绘与行为检查。
    final skillSection = find.ancestor(
      of: find.byKey(const Key('skill-add')),
      matching: find.byType(SettingsSection),
    );
    if (skillSection.evaluate().isNotEmpty) {
      for (final e in find.text(l.set_agDesc).evaluate()) {
        masks.add(t.getRect(find.byWidget(e.widget)));
      }
      final capture = t.getRect(find.byKey(const Key('settings-capture')));
      // 2026-10-20：快捷信息一节插在 Skill 分区前（用户确认），从它开始往下一起排除；
      // 原 Skill 分区的顶边就是它现在的顶边，上方区域照旧逐像素锁定。
      final quick = find.ancestor(
        of: find.byKey(const Key('quick-add')),
        matching: find.byType(SettingsSection),
      );
      final section = t.getRect(
        quick.evaluate().isNotEmpty ? quick.first : skillSection.first,
      );
      masks.add(
        Rect.fromLTRB(section.left, section.top, section.right, capture.bottom),
      );
      final aside = find
          .byType(SettingsAsideCard)
          .evaluate()
          .map((e) => t.getRect(find.byWidget(e.widget)));
      final first = aside.reduce((a, b) => a.expandToInclude(b));
      masks.add(
        Rect.fromLTRB(first.left, first.top, first.right, capture.bottom),
      );
    }
    // 2026-10-21：Agent 页拆成 常规/指令/Skill/工具与扩展 分页（用户确认）：
    // 标题和说明照旧逐像素锁定；从分页条开始往下的主栏、整列侧卡一起排除，
    // 各分页的内容另有行为和截图检查。
    final agentTabs = find.byKey(const Key('agent-tabs'));
    if (agentTabs.evaluate().isNotEmpty) {
      final capture = t.getRect(find.byKey(const Key('settings-capture')));
      final tabs = t.getRect(agentTabs);
      // D27 已批准的说明行（原先只在 Skill 分区可见时排除）。
      for (final e in find.text(l.set_agDesc).evaluate()) {
        masks.add(t.getRect(find.byWidget(e.widget)));
      }
      masks.add(Rect.fromLTRB(tabs.left, tabs.top, tabs.right, capture.bottom));
      final aside = find
          .byType(SettingsAsideCard)
          .evaluate()
          .map((e) => t.getRect(find.byWidget(e.widget)));
      if (aside.isNotEmpty) {
        final first = aside.reduce((a, b) => a.expandToInclude(b));
        masks.add(
          Rect.fromLTRB(first.left, capture.top, capture.right, capture.bottom),
        );
      }
    }
    // 2026-10-20：“Agent 使用的模型”改名“默认模型”、下拉按钮左边改用厂商图标（用户确认）：
    // 只排除这一行的标题和下拉按钮里的图标格。
    // 旧标题更长，排除整条标题行（到下拉按钮左边为止），副标题和按钮外框照旧锁定。
    final modelSelect = find.byKey(const Key('select-agentModel'));
    for (final title in find.text(l.set_agModel).evaluate()) {
      final rect = t.getRect(find.byWidget(title.widget));
      final right = modelSelect.evaluate().isEmpty
          ? rect.right
          : t.getRect(modelSelect).left - 8;
      masks.add(Rect.fromLTRB(rect.left, rect.top, right, rect.bottom));
    }
    if (modelSelect.evaluate().isNotEmpty) {
      final logo = find.descendant(
        of: modelSelect,
        matching: find.byType(SettingsLogo),
      );
      if (logo.evaluate().isNotEmpty) masks.add(t.getRect(logo));
    }
    for (final title in find.text(l.set_agPrefix).evaluate()) {
      masks.add(t.getRect(find.byWidget(title.widget)));
    }
    final prefixField = find.descendant(
      of: find.byKey(const Key('agent-prefix')),
      matching: find.byType(TextField),
    );
    if (prefixField.evaluate().isNotEmpty) masks.add(t.getRect(prefixField));
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
    // 2026-10-19：导航里 Agent 图标换成侧栏同款标志，只排除这个 18px 图标格。
    for (final e
        in find.byKey(const Key('settings-nav-agent-mark')).evaluate()) {
      final mark = t.getRect(find.byWidget(e.widget));
      masks.add(Rect.fromCenter(center: mark.center, width: 18, height: 18));
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
