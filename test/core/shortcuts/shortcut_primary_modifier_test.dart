// macOS 按规范用 ⌘ 当主修饰键（配置里的 ctrl 在 Mac 上是 ⌘，Mac 的 Control 键记成 meta）。
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_manager.dart';

ParsedShortcut _pressed(Set<ShortcutModifier> modifiers, ShortcutKey key) =>
    ParsedShortcut(modifiers: modifiers, key: key, raw: '');

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('macOS：配置里的 ctrl 解析成 ⌘，存回去还是 ctrl', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final parsed = ShortcutParser.parse('ctrl+shift+enter')!;
    expect(parsed.modifiers, {ShortcutModifier.meta, ShortcutModifier.shift});
    expect(ShortcutParser.serialize(parsed), 'ctrl+shift+enter');
    expect(AppShortcutManager.normalize('meta+k'), 'meta+k');
  });

  test('macOS：手写的 cmd / command 就是 ⌘，和 ctrl 同义；Windows 上照旧是 meta', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    for (final raw in ['cmd+k', 'command+k']) {
      final parsed = ShortcutParser.parse(raw)!;
      expect(parsed.modifiers, {ShortcutModifier.meta}, reason: raw);
      expect(ShortcutParser.serialize(parsed), 'ctrl+k', reason: raw);
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(ShortcutParser.parse('cmd+k')!.modifiers, {ShortcutModifier.meta});
  });

  test('macOS：录制时按 ⌘ 存成 ctrl，按 Control 存成 meta', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(
      ShortcutParser.serialize(
        _pressed({ShortcutModifier.meta}, ShortcutKey.keyK),
      ),
      'ctrl+k',
    );
    expect(
      ShortcutParser.serialize(
        _pressed({ShortcutModifier.control}, ShortcutKey.keyK),
      ),
      'meta+k',
    );
  });

  test('macOS：按 ⌘ 触发，显示成 ⌘1 这样的符号', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final activator =
        AppShortcutManager.parseActivator('ctrl+1')! as SingleActivator;
    expect(activator.trigger, LogicalKeyboardKey.digit1);
    expect(activator.meta, isTrue);
    expect(activator.control, isFalse);
    expect(AppShortcutManager.getDisplayLabel('ctrl+1'), '⌘1');
    expect(AppShortcutManager.getDisplayLabel('ctrl+shift+t'), '⇧⌘T');
    expect(AppShortcutManager.getDisplayLabel('ctrl+enter'), '⌘⏎');
    expect(AppShortcutManager.getDisplayLabel('escape'), '⎋');
  });

  test('macOS：键帽按 Mac 菜单的写法和顺序拆开', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    List<String> keys(String shortcut) =>
        ShortcutParser.parse(shortcut)!.keyLabels;
    expect(keys('ctrl+1'), ['⌘', '1']);
    expect(keys('ctrl+shift+t'), ['⇧', '⌘', 'T']);
    expect(keys('ctrl+meta+f'), ['⌃', '⌘', 'F']);
    expect(keys('alt+arrowup'), ['⌥', '↑']);
    expect(keys('ctrl+comma'), ['⌘', ',']);
    expect(keys('escape'), ['⎋']);
    // ⇱ ⇲ 自带字体里没有，照旧写字
    expect(keys('home'), ['Home']);
    expect(AppShortcutManager.getDisplayLabel('ctrl+end'), '⌘End');
  });

  test('录快捷键：按键转回 ShortcutKey，用不了的键返回 null', () {
    expect(
      AppShortcutManager.shortcutKeyOf(LogicalKeyboardKey.comma),
      ShortcutKey.comma,
    );
    expect(
      AppShortcutManager.shortcutKeyOf(LogicalKeyboardKey.arrowUp),
      ShortcutKey.arrowup,
    );
    expect(
      AppShortcutManager.shortcutKeyOf(LogicalKeyboardKey.keyK),
      ShortcutKey.keyK,
    );
    expect(AppShortcutManager.shortcutKeyOf(LogicalKeyboardKey.capsLock), null);
  });

  test('Windows：照旧是 Ctrl', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final parsed = ShortcutParser.parse('ctrl+1')!;
    expect(parsed.modifiers, {ShortcutModifier.control});
    expect(ShortcutParser.serialize(parsed), 'ctrl+1');
    final activator =
        AppShortcutManager.parseActivator('ctrl+1')! as LogicalKeySet;
    expect(activator.keys, contains(LogicalKeyboardKey.control));
    expect(AppShortcutManager.getDisplayLabel('ctrl+1'), 'Ctrl+1');
    expect(ShortcutParser.parse('ctrl+shift+t')!.keyLabels, [
      'Ctrl',
      'Shift',
      'T',
    ]);
  });
}
