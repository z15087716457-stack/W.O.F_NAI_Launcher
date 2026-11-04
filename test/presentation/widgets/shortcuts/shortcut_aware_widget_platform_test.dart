// macOS 按规范用 ⌘ 当主修饰键，默认快捷键 ctrl+3（本地图库）在 Mac 上是 ⌘3。
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';

class _DefaultConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

Future<void> _pumpGallerySwitch(WidgetTester tester, VoidCallback onHit) async {
  final container = ProviderContainer(
    overrides: [
      shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: ShortcutAwareWidget(
            contextType: ShortcutContext.global,
            autofocus: true,
            shortcuts: {ShortcutIds.navigateToLocalGallery: onHit},
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chord(WidgetTester tester, LogicalKeyboardKey modifier) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

/// 照本地图库：页面快捷键绑「全选并进入多选」（ctrl+a）和「收起分类栏」（ctrl+b），页面里有输入框
Future<TextEditingController> _pumpGalleryPage(
  WidgetTester tester, {
  required VoidCallback onSelectAll,
  required VoidCallback onToggleCategories,
}) async {
  final controller = TextEditingController(text: 'hello world');
  addTearDown(controller.dispose);
  final container = ProviderContainer(
    overrides: [
      shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: PageShortcuts(
            contextType: ShortcutContext.gallery,
            shortcuts: {
              ShortcutIds.enterSelectionMode: onSelectAll,
              ShortcutIds.toggleCategoryPanel: onToggleCategories,
            },
            child: Column(
              children: [
                TextField(controller: controller),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

/// 点进输入框，光标放在中间
Future<void> _focusField(
  WidgetTester tester,
  TextEditingController controller,
) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  controller.selection = const TextSelection.collapsed(offset: 5);
  await tester.pump();
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

void main() {
  testWidgets('macOS：⌘3 切到本地图库，Control+3 不触发', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      var hits = 0;
      await _pumpGallerySwitch(tester, () => hits++);
      await _chord(tester, LogicalKeyboardKey.metaLeft);
      expect(hits, 1);
      await _chord(tester, LogicalKeyboardKey.controlLeft);
      expect(hits, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Windows：照旧是 Ctrl+3', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      var hits = 0;
      await _pumpGallerySwitch(tester, () => hits++);
      await _chord(tester, LogicalKeyboardKey.controlLeft);
      expect(hits, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'a retained comma from the AppKit settings menu does not block later Command shortcuts',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        var hits = 0;
        await _pumpGallerySwitch(tester, () => hits++);
        await tester.sendKeyDownEvent(
          LogicalKeyboardKey.comma,
          platform: 'macos',
        );
        await _chord(tester, LogicalKeyboardKey.metaLeft);
        expect(hits, 1);
        // Extra modifiers must still prevent a match; only unrelated ordinary keys are ignored.
        await tester.sendKeyDownEvent(
          LogicalKeyboardKey.shiftLeft,
          platform: 'macos',
        );
        await _chord(tester, LogicalKeyboardKey.metaLeft);
        expect(hits, 1);
        await tester.sendKeyUpEvent(
          LogicalKeyboardKey.shiftLeft,
          platform: 'macos',
        );
        await tester.sendKeyUpEvent(
          LogicalKeyboardKey.comma,
          platform: 'macos',
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
  group('⌘A 在输入框里归输入框（macOS）', () {
    testWidgets('macOS：焦点在输入框里时 ⌘A 全选文字、不进多选；⌘B 照旧触发页面功能', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        var selectAll = 0;
        var toggle = 0;
        final controller = await _pumpGalleryPage(
          tester,
          onSelectAll: () => selectAll++,
          onToggleCategories: () => toggle++,
        );
        await _focusField(tester, controller);
        await _press(
          tester,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.keyA,
        );
        expect(selectAll, 0);
        expect(
          controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 11),
        );
        await _press(
          tester,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.keyB,
        );
        expect(toggle, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('macOS：焦点不在输入框里时 ⌘A 照旧全选并进入多选', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        var selectAll = 0;
        final controller = await _pumpGalleryPage(
          tester,
          onSelectAll: () => selectAll++,
          onToggleCategories: () {},
        );
        await _press(
          tester,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.keyA,
        );
        expect(selectAll, 1);
        expect(controller.selection.isCollapsed, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows：不变，输入框里 Ctrl+A 照旧进多选', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        var selectAll = 0;
        final controller = await _pumpGalleryPage(
          tester,
          onSelectAll: () => selectAll++,
          onToggleCategories: () {},
        );
        await _press(
          tester,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.keyA,
        );
        expect(selectAll, 1);
        await _focusField(tester, controller);
        await _press(
          tester,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.keyA,
        );
        expect(selectAll, 2);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
