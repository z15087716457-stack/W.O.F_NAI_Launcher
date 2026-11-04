// macOS 上 Control+单击当右键：改写规则的单测，加上装了这个 binding 之后几个常见控件的表现。
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/utils/control_click.dart';
import 'package:nai_launcher/presentation/widgets/common/selectable_image_card.dart';

class _ControlClickTestBinding extends AutomatedTestWidgetsFlutterBinding
    with ControlClickBinding {}

const _at = Offset(10, 10);

void main() {
  _ControlClickTestBinding();

  group('ControlClickMapper', () {
    late ControlClickMapper mapper;
    setUp(() => mapper = ControlClickMapper());

    PointerEvent map(
      PointerEvent event, {
      bool macOS = true,
      bool control = false,
      bool command = false,
    }) => mapper.map(event, macOS: macOS, control: control, command: command);

    test('macOS：按着 Control 按下主键改成次键，同一指针的移动、抬起跟着改', () {
      final down = map(
        const PointerDownEvent(pointer: 1, position: _at),
        control: true,
      );
      expect(down, isA<PointerDownEvent>());
      expect(down.buttons, kSecondaryButton);
      expect(down.position, _at);

      // 按下之后松开 Control 也跟着改，直到抬起
      final move = map(
        const PointerMoveEvent(pointer: 1, position: Offset(14, 10)),
      );
      expect(move, isA<PointerMoveEvent>());
      expect(move.buttons, kSecondaryButton);
      const up = PointerUpEvent(pointer: 1, position: Offset(14, 10));
      expect(map(up), same(up));

      // 抬起以后这个指针不再改；下一次不按 Control 的点击照旧是主键
      const next = PointerDownEvent(pointer: 2, position: _at);
      expect(map(next), same(next));
      const nextMove = PointerMoveEvent(pointer: 2, position: Offset(12, 10));
      expect(map(nextMove), same(nextMove));
    });

    test('取消也结束这一下', () {
      map(const PointerDownEvent(pointer: 1), control: true);
      const cancel = PointerCancelEvent(pointer: 1);
      expect(map(cancel), same(cancel));
      const move = PointerMoveEvent(pointer: 1);
      expect(map(move), same(move));
    });

    test('⌘ 也按着、按下之后才按 Control、按下的不是主键：都不改', () {
      const withCommand = PointerDownEvent(pointer: 1);
      expect(map(withCommand, control: true, command: true), same(withCommand));

      const plain = PointerDownEvent(pointer: 2);
      expect(map(plain), same(plain));
      const lateControl = PointerMoveEvent(pointer: 2);
      expect(map(lateControl, control: true), same(lateControl));

      for (final buttons in [kSecondaryButton, kMiddleMouseButton]) {
        final down = PointerDownEvent(pointer: 3 + buttons, buttons: buttons);
        expect(map(down, control: true), same(down));
      }
    });

    test('滚轮、触控板手势、悬停不动', () {
      map(const PointerDownEvent(pointer: 1), control: true);
      final untouched = <PointerEvent>[
        const PointerScrollEvent(position: _at, scrollDelta: Offset(0, 20)),
        const PointerPanZoomStartEvent(pointer: 1, position: _at),
        const PointerPanZoomUpdateEvent(pointer: 1, position: _at, scale: 2),
        const PointerPanZoomEndEvent(pointer: 1, position: _at),
        const PointerHoverEvent(position: _at),
      ];
      for (final event in untouched) {
        expect(map(event, control: true), same(event));
      }
    });

    test('其他平台不改', () {
      const down = PointerDownEvent(pointer: 1);
      expect(map(down, macOS: false, control: true), same(down));
      const move = PointerMoveEvent(pointer: 1);
      expect(map(move, macOS: false, control: true), same(move));
    });
  });

  group('装上 binding 之后', () {
    Future<void> controlClick(WidgetTester tester, Finder target) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final mouse = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    Future<TextEditingController> pumpField(WidgetTester tester) async {
      final controller = TextEditingController(text: 'blue eyes, solo');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: TextField(controller: controller),
              ),
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('macOS：Control+单击图片卡片出右键菜单，不走单击（多选和普通单击都在单击里）', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: SelectableImageCard(
                    imageBytes: base64Decode(_oneByOnePngBase64),
                    imageIdentity: 'image-1',
                    allowRepeatedModifierTaps: true,
                    onTap: () => taps++,
                    onFullscreen: () {},
                    enableSelection: false,
                    enableSaveAction: false,
                    enableCopyAction: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await controlClick(tester, find.byType(SelectableImageCard));
      expect(find.text('Details'), findsOneWidget);
      expect(taps, 0);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('macOS：Control+单击输入框打开文字的右键菜单', (tester) async {
      await pumpField(tester);
      await controlClick(tester, find.byType(TextField));
      expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('Windows：Ctrl+单击输入框照旧是普通单击', (tester) async {
      final controller = await pumpField(tester);
      await controlClick(tester, find.byType(TextField));
      expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
      expect(controller.selection.isCollapsed, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });
}

const _oneByOnePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6qv0YAAAAASUVORK5CYII=';
