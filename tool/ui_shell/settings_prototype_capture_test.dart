// 设置页：用原型同一批假数据实绘 17 页，导出关键元素位置（rects.json），
// 供 settings_measure.py 和原型（.devin/mockups/settings/mock.html）比。
// 运行：flutter test tool/ui_shell/settings_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/settings/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/settings/settings_test_harness.dart';

/// 原型 hash → 页面。
const views = {
  'overview': SettingsPageId.overview,
  'account': SettingsPageId.account,
  'appearance': SettingsPageId.appearance,
  'canvas': SettingsPageId.canvas,
  'keys': SettingsPageId.shortcuts,
  'gen': SettingsPageId.generation,
  'storage': SettingsPageId.storage,
  'data': SettingsPageId.dictionaries,
  'models': SettingsPageId.models,
  'agent': SettingsPageId.agent,
  'rag': SettingsPageId.rag,
  'upscale': SettingsPageId.upscale,
  'bridge': SettingsPageId.bridges,
  'network': SettingsPageId.network,
  'privacy': SettingsPageId.privacy,
  'backup': SettingsPageId.backup,
  'about': SettingsPageId.about,
};

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/settings/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, Object>>{};

  for (final MapEntry(key: name, value: page) in views.entries) {
    testWidgets('capture $name', (t) async {
      await pumpSettings(t, page: page);
      final m = <String, Object>{};
      void put(String k, Finder f) {
        if (f.evaluate().isEmpty) return;
        final r = t.getRect(f.first);
        m[k] = [r.left, r.top, r.width, r.height];
      }

      void all(String k, Finder f) {
        var i = 0;
        for (final e in f.evaluate()) {
          final r = t.getRect(find.byElementPredicate((x) => x == e));
          m['$k${i++}'] = [r.left, r.top, r.width, r.height];
        }
      }

      put('search', find.byKey(const Key('settings-search')));
      all('nav', find.byWidgetPredicate((w) => '${w.key}'.contains("'settings-nav-")));
      final title = find.byType(SettingsPageTitle);
      final texts = find.descendant(of: title, matching: find.byType(Text));
      for (final (i, k) in ['eyebrow', 'title', 'desc'].indexed) {
        if (texts.evaluate().length > i) put(k, texts.at(i));
      }
      all('sec', find.byType(SettingsSection));
      all('card', find.byType(SettingsCard));
      all('row', find.byType(SettingsRow));
      all('ac', find.byType(SettingsAsideCard));
      all('tile', find.byWidgetPredicate((w) => '${w.key}'.contains("'settings-tile-")));
      put('hero0', find.byKey(const Key('settings-account-hero')));
      put('hero1', find.byKey(const Key('settings-attention')));
      rects[name] = m;
    });
  }

  tearDownAll(() {
    File('${out.path}/rects.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(rects),
    );
  });
}
