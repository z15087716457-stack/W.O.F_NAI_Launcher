// 页面快捷键的焦点：保活页面切回来时焦点回到这一页；焦点退到页面上面的范围（用鼠标在输入框外点一下）时拿回来。
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/page_focus.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';

class _DefaultConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

/// 新页面的写法（在线图库、块库、Vibe 库……）：Focus(autofocus: true) + onKeyEvent
Widget _page(String name, VoidCallback onHit) => Focus(
  autofocus: true,
  onKeyEvent: (_, e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.keyK) {
      onHit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: Text(name),
);

/// 带输入框的页面，页面快捷键用 PageShortcuts（同本地图库）：Ctrl+B 收起分类栏
Widget _galleryPage(VoidCallback onHit, {Key? key, FocusNode? field}) =>
    PageShortcuts(
      contextType: ShortcutContext.gallery,
      shortcuts: {ShortcutIds.toggleCategoryPanel: onHit},
      child: Column(
        key: key,
        children: [
          TextField(focusNode: field),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );

Future<void> _pressCtrlB(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Widget _app(Widget home) => ProviderScope(
  overrides: [shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new)],
  child: MaterialApp(home: home),
);

void main() {
  for (final dialog in [false, true]) {
    testWidgets(
      'application switch restores the ${dialog ? 'dialog' : 'page'} editor and selection',
      (t) async {
        final field = FocusNode();
        final controller = TextEditingController(text: 'unfinished draft');
        addTearDown(field.dispose);
        addTearDown(controller.dispose);
        final editor = TextField(focusNode: field, controller: controller);
        await t.pumpWidget(
          _app(
            Scaffold(
              body: GlobalShortcuts(
                shortcuts: const {},
                child: Builder(
                  builder: (context) => dialog
                      ? TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(content: editor),
                          ),
                          child: const Text('open'),
                        )
                      : editor,
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        if (dialog) {
          await t.tap(find.text('open'));
          await t.pumpAndSettle();
        }
        await t.tap(find.byType(TextField));
        controller.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 8,
        );
        await t.pump();
        expect(field.hasPrimaryFocus, isTrue);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await t.pump();
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pump();
        expect(field.hasPrimaryFocus, isTrue);
        expect(
          controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 8),
        );
        await t.pumpWidget(const SizedBox());
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }),
    );
  }

  testWidgets('保活页面切回来时焦点回到这一页，本页按键生效；隐藏的页面收不到', (tester) async {
    var index = 0;
    final visited = <int>{0};
    late StateSetter setIndex;
    var hitsA = 0;
    var hitsB = 0;

    // 照外壳（app_router）：IndexedStack 保活 + TickerMode，分支第一次访问时才建
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setIndex = setState;
            return IndexedStack(
              index: index,
              children: [
                for (final (i, name, onHit) in [
                  (0, 'A', () => hitsA++),
                  (1, 'B', () => hitsB++),
                ])
                  TickerMode(
                    enabled: index == i,
                    child: RefocusWhenActive(
                      active: index == i,
                      child: visited.contains(i)
                          ? _page(name, onHit)
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect((hitsA, hitsB), (1, 0));

    setIndex(() {
      index = 1;
      visited.add(1);
    });
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect((hitsA, hitsB), (1, 1));

    // 切回 A：A 一直在树上（保活），焦点要回到 A
    setIndex(() => index = 0);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect((hitsA, hitsB), (2, 1));

    setIndex(() => index = 1);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect((hitsA, hitsB), (2, 2));
  });

  testWidgets('鼠标在输入框外点一下（焦点退回所在范围），页面快捷键照常', (tester) async {
    var hits = 0;
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(
      _app(Scaffold(body: _galleryPage(() => hits++, field: field))),
    );
    await tester.pumpAndSettle();
    await _pressCtrlB(tester);
    expect(hits, 1);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);

    // 桌面端用鼠标点输入框外面：输入框失去焦点，焦点退回所在的焦点范围
    await tester.tapAt(const Offset(400, 500), kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(field.hasFocus, isFalse);

    await _pressCtrlB(tester);
    expect(hits, 2);
  });

  testWidgets('焦点退到更外层的范围：可见页面拿回焦点，隐藏的保活页面不抢', (tester) async {
    var hitsA = 0;
    var hitsB = 0;
    final keyA = GlobalKey();
    await tester.pumpWidget(
      _app(
        IndexedStack(
          children: [
            for (final (i, key, onHit) in [
              (0, keyA, () => hitsA++),
              (1, GlobalKey(), () => hitsB++),
            ])
              TickerMode(
                enabled: i == 0,
                child: RefocusWhenActive(
                  active: i == 0,
                  child: Material(child: _galleryPage(onHit, key: key)),
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _pressCtrlB(tester);
    expect((hitsA, hitsB), (1, 0));

    // 页面 A 所在的焦点范围整个失去焦点，焦点落到外面两页共用的范围上
    FocusScope.of(keyA.currentContext!).unfocus();
    await tester.pump();

    await _pressCtrlB(tester);
    expect((hitsA, hitsB), (2, 0));
  });
}
