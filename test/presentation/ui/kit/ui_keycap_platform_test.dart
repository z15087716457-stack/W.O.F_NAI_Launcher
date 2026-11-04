// 键帽和菜单右侧的快捷键字按平台写：macOS 用 Mac 符号（⌘ ⇧ ⌥ ⌃ ⏎），Windows 原样。
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_keycap.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_menu.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_parts.dart';

import '../../../helpers/font_glyph_coverage.dart';
import '../../../helpers/studio_capture_fonts.dart';

Future<void> _pump(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(1600, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(
    MaterialApp(
      theme: GeistTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await t.pumpAndSettle();
}

List<String> _texts(WidgetTester t, Finder of) => [
  for (final w in t.widgetList<Text>(
    find.descendant(of: of, matching: find.byType(Text)),
  ))
    w.data!,
];

Widget _menu(List<String> trailing) => UiMenu(
  onClose: () {},
  items: [
    for (final (i, x) in trailing.indexed)
      UiMenuItem(label: 'item $i', trailing: x, onTap: () {}),
  ],
);

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('macOS：Ctrl 写成 ⌘，修饰键按 Mac 的顺序排，菜单快捷键连写', (t) async {
    await _pump(
      t,
      Column(
        children: [
          const UiKeycaps(['Ctrl', 'Shift', 'T'], key: Key('ui')),
          const SettingsKeys(['ctrl', 'enter'], key: Key('settings')),
          const UiKeycaps(['Ctrl', '↵'], key: Key('enter')),
          const ViewerKeycaps(['Esc'], key: Key('viewer')),
          SizedBox(
            key: const Key('menu'),
            child: _menu(['Ctrl D', 'Ctrl+V', 'E', 'Enter']),
          ),
        ],
      ),
    );
    expect(_texts(t, find.byKey(const Key('ui'))), ['⇧', '⌘', 'T']);
    expect(_texts(t, find.byKey(const Key('settings'))), ['⌘', '⏎']);
    expect(_texts(t, find.byKey(const Key('enter'))), ['⌘', '⏎']);
    expect(_texts(t, find.byKey(const Key('viewer'))), ['⎋']);
    expect(
      _texts(t, find.byKey(const Key('menu'))),
      containsAll(['⌘D', '⌘V', 'E', '⏎']),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Windows：键名原样', (t) async {
    await _pump(
      t,
      Column(
        children: [
          const UiKeycaps(['Ctrl', 'Shift', 'T'], key: Key('ui')),
          const SettingsKeys(['ctrl', 'enter'], key: Key('settings')),
          const ViewerKeycaps(['Esc'], key: Key('viewer')),
          SizedBox(key: const Key('menu'), child: _menu(['Ctrl D'])),
        ],
      ),
    );
    expect(_texts(t, find.byKey(const Key('ui'))), ['Ctrl', 'Shift', 'T']);
    expect(_texts(t, find.byKey(const Key('settings'))), ['ctrl', 'enter']);
    expect(_texts(t, find.byKey(const Key('viewer'))), ['Esc']);
    expect(find.text('Ctrl D'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('macOS：键帽上可能出现的 Mac 符号，自带字体里都有字形，没有方框', (t) async {
    final coverage = await t.runAsync(FontGlyphCoverage.load);
    // 修饰键 + 快捷键能用的每个键（Mac 写法）
    final labels = [
      '⌃',
      '⌥',
      '⇧',
      '⌘',
      '↵',
      for (final key in ShortcutKey.values) key.macLabel,
    ];
    await _pump(
      t,
      Column(
        children: [
          Wrap(
            key: const Key('ui'),
            children: [for (final k in labels) UiKeycap(k)],
          ),
          Wrap(
            key: const Key('settings'),
            children: [for (final k in labels) SettingsKey(k)],
          ),
          Wrap(
            key: const Key('viewer'),
            children: [for (final k in labels) ViewerKeycap(k)],
          ),
          SizedBox(key: const Key('menu'), child: _menu(labels)),
        ],
      ),
    );
    for (final group in ['ui', 'settings', 'viewer', 'menu']) {
      final paragraphs = t.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byKey(Key(group)),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraphs, isNotEmpty);
      for (final p in paragraphs) {
        final text = p.text.toPlainText();
        final style = p.text.style!;
        expect(
          coverage!.missing(text, style),
          isEmpty,
          reason: '$group「$text」${style.fontFamily}',
        );
      }
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
