// Vibe / 精准参考库壳子的交互：每个按钮、快捷键和弹窗都走契约回调，界面不自己改数据。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_slider.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'refs_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late RecordingRefsActions rec;
  setUp(() => rec = RecordingRefsActions());

  Future<void> pump(
    WidgetTester t, {
    RefsViewData? data,
    double window = 1600,
  }) => pumpRefs(
    t,
    data: data ?? RefsFixture.vibe(),
    actions: rec.actions,
    window: window,
  );

  Finder key(String k) => find.byKey(Key(k));

  Future<void> pick(WidgetTester t, List<String> keys) async {
    await tapKey(t, 'refs-multi');
    for (final k in keys) {
      await tapKey(t, 'refs-card-$k');
    }
  }

  group('左栏和工具栏', () {
    testWidgets('视图、分类、来源都改筛选', (t) async {
      await pump(t);
      await tapKey(t, 'refs-view-favorites');
      expect(rec.filters.last.view, RefsView.favorites);
      await tapKey(t, 'refs-cat-light');
      expect(rec.filters.last.categoryId, 'light');
      expect(rec.filters.last.view, RefsView.all);
      await tapKey(t, 'refs-src-bundle');
      expect(rec.filters.last.source, RefsVibeSource.bundle);
      expect(rec.filters.last.categoryId, isNull);
    });

    testWidgets('快速筛选和卡片大小', (t) async {
      await pump(t);
      await tapKey(t, 'refs-quick-needsEncoding');
      expect(rec.filters.last.quick, RefsQuick.needsEncoding);
      await t.tap(
        find.descendant(of: key('refs-card-size'), matching: find.text('大')),
      );
      await t.pumpAndSettle();
      expect(rec.calls, contains('size:large'));
    });

    testWidgets('搜索停 300ms 才回调', (t) async {
      await pump(t);
      await t.tap(key('refs-search'));
      await t.pump();
      await t.enterText(
        find.descendant(
          of: key('refs-search'),
          matching: find.byType(EditableText),
        ),
        '夜',
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(rec.filters, isEmpty);
      await t.pump(const Duration(milliseconds: 300));
      expect(rec.filters.last.query, '夜');
    });

    testWidgets('排序菜单', (t) async {
      await pump(t);
      await tapKey(t, 'refs-sort');
      await t.tap(find.text('使用次数').last);
      await t.pumpAndSettle();
      expect(rec.filters.last.sort, RefsSort.usedCount);
    });

    testWidgets('导入按钮和箭头菜单', (t) async {
      await pump(t);
      await tapKey(t, 'refs-import');
      expect(rec.calls, contains('import:files'));
      await tapKey(t, 'refs-import-menu');
      await t.tap(find.text('从剪贴板粘贴'));
      await t.pumpAndSettle();
      expect(rec.calls, contains('import:clipboard'));
    });

    testWidgets('收起左栏 / 检查器', (t) async {
      await pump(t);
      await tapKey(t, 'refs-inspector-toggle');
      expect(rec.calls, contains('inspector:false'));
    });
  });

  group('卡片', () {
    testWidgets('单击选中，双击加入生图页', (t) async {
      await pump(t);
      await tapKey(t, 'refs-card-c15');
      expect(rec.calls, contains('select:c15'));
      await t.tap(key('refs-card-c12'));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(key('refs-card-c12'));
      await t.pumpAndSettle();
      expect(rec.adds.single.$1, ['c12']);
      expect(rec.adds.single.$2, isFalse);
    });

    testWidgets('悬停条“加入生图”', (t) async {
      await pump(t);
      await hoverOver(t, key('refs-card-c13'));
      await tapKey(t, 'refs-card-add');
      expect(rec.adds.single.$1, ['c13']);
    });

    testWidgets('右键菜单：替换生图页的 Vibe', (t) async {
      await pump(t);
      await t.tap(key('refs-card-c12'), buttons: kSecondaryButton);
      await t.pumpAndSettle();
      await t.tap(find.text('替换生图页的 Vibe'));
      await t.pumpAndSettle();
      expect(rec.adds.single.$1, ['c12']);
      expect(rec.adds.single.$2, isTrue);
    });

    testWidgets('没有结果时可以清除筛选', (t) async {
      final base = RefsFixture.vibe();
      await pump(
        t,
        data: RefsViewData(
          kind: base.kind,
          now: base.now,
          model: base.model,
          counts: base.counts,
          categories: base.categories,
          filter: const RefsFilter(query: '海边', quick: RefsQuick.favorites),
          tray: base.tray,
        ),
      );
      expect(key('refs-no-results'), findsOneWidget);
      await t.tap(
        find.descendant(
          of: key('refs-no-results'),
          matching: find.text('清除筛选'),
        ),
      );
      await t.pumpAndSettle();
      expect(rec.filters.last, const RefsFilter());
    });
  });

  group('多选', () {
    testWidgets('勾选后批量加入、收藏、导出', (t) async {
      await pump(t);
      await pick(t, ['c03', 'c11']);
      expect(key('refs-selection-bar'), findsOneWidget);
      expect(find.text('已选 2'), findsOneWidget);
      await tapKey(t, 'refs-sel-add');
      expect(rec.adds.single.$1, ['c03', 'c11']);
      await tapKey(t, 'refs-sel-favorite');
      expect(rec.favorites.single.$1, ['c03', 'c11']);
      expect(rec.favorites.single.$2, isTrue);
      await tapKey(t, 'refs-sel-export');
      expect(key('refs-export'), findsOneWidget);
      await tapKey(t, 'refs-export-bundle');
      await tapKey(t, 'refs-export-confirm');
      expect(rec.exports.single.format, RefsExportFormat.bundle);
      expect(rec.exports.single.keys, ['c03', 'c11']);
    });

    testWidgets('批量删除要确认', (t) async {
      await pump(t);
      await pick(t, ['c03', 'c15']);
      await tapKey(t, 'refs-sel-delete');
      expect(key('refs-delete'), findsOneWidget);
      await tapKey(t, 'refs-delete-confirm');
      expect(rec.deletes.single, ['c03', 'c15']);
      expect(key('refs-selection-bar'), findsNothing);
    });

    testWidgets('检查器统一设置强度', (t) async {
      await pump(t);
      await pick(t, ['c03', 'c15', 'c12']);
      expect(key('refs-multi-summary'), findsOneWidget);
      await t.drag(key('refs-multi-strength'), const Offset(-40, 0));
      await t.pumpAndSettle();
      expect(
        rec.calls.where((c) => c.startsWith('strengthMany:3:')),
        hasLength(1),
      );
    });

    testWidgets('Ctrl+A 全选、Esc 退出', (t) async {
      await pump(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(
        find.text('已选 ${RefsFixture.vibe().entries.length}'),
        findsOneWidget,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(key('refs-selection-bar'), findsNothing);
    });
  });

  group('快捷键', () {
    testWidgets('Enter 加入、Shift+Enter 替换、F 收藏、Delete 删除', (t) async {
      await pump(t);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(
        [for (final x in rec.adds) '${x.$1}:${x.$2}'],
        ['[c03]:false', '[c03]:true'],
      );
      await t.sendKeyEvent(LogicalKeyboardKey.keyF);
      expect(rec.favorites.single.$1, ['c03']);
      expect(rec.favorites.single.$2, isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.delete);
      await t.pumpAndSettle();
      expect(key('refs-delete'), findsOneWidget);
    });

    testWidgets('方向键换选中', (t) async {
      await pump(t);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(rec.calls, contains('select:c15'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(rec.calls.last, startsWith('select:'));
    });

    testWidgets('Ctrl+F 聚焦搜索', (t) async {
      await pump(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyF);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus?.context;
      expect(
        focus?.findAncestorWidgetOfExactType<EditableText>() ??
            (focus?.widget is EditableText ? focus!.widget : null),
        isNotNull,
      );
    });
  });

  group('检查器', () {
    testWidgets('改强度只用于这次发送，可以存为默认', (t) async {
      await pump(t);
      await t.tap(
        find.descendant(
          of: key('refs-strength'),
          matching: find.byType(UiNumBox),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(
        find.descendant(
          of: key('refs-strength'),
          matching: find.byType(EditableText),
        ),
        '0.72',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(key('refs-changed'), findsOneWidget);
      await tapKey(t, 'refs-insp-add');
      expect(rec.adds.single.$3['c03']?.strength, .72);
      await tapKey(t, 'refs-save-default');
      expect(rec.patches.single.$1, 'c03');
      expect(rec.patches.single.$2.strength, .72);
      expect(rec.patches.single.$2.infoExtracted, isNull);
    });

    testWidgets('改名', (t) async {
      await pump(t);
      await tapKey(t, 'refs-rename-start');
      await t.enterText(key('refs-rename'), '星海夜光 2');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.calls, contains('rename:c03:星海夜光 2'));
    });

    testWidgets('需要重新编码时可以现在编码', (t) async {
      await pump(t, data: RefsFixture.vibe(selectedKey: 'c11'));
      expect(find.text('需重新编码'), findsWidgets);
      await tapKey(t, 'refs-encode-now');
      expect(rec.calls, contains('encode:c11'));
    });

    testWidgets('移到分类', (t) async {
      await pump(t);
      await tapKey(t, 'refs-insp-category');
      await t.tap(find.text('光影').last);
      await t.pumpAndSettle();
      expect(rec.moves.single.$1, ['c03']);
      expect(rec.moves.single.$2, 'light');
    });

    testWidgets('V5：横幅能切模型，加入按钮不可用', (t) async {
      await pump(t, data: RefsFixture.vibe(model: RefsFixture.v5));
      expect(key('refs-banner'), findsOneWidget);
      await tapKey(t, 'refs-insp-add');
      expect(rec.adds, isEmpty);
      await tapKey(t, 'refs-switch-model');
      expect(rec.calls, contains('switchModel'));
    });

    testWidgets('删除单条也要确认', (t) async {
      await pump(t);
      await tapKey(t, 'refs-insp-delete');
      await tapKey(t, 'refs-delete-confirm');
      expect(rec.deletes.single, ['c03']);
    });
  });

  group('精准参考库', () {
    testWidgets('改类型、发送、图生图、存为 Vibe', (t) async {
      await pump(t, data: RefsFixture.preciseView());
      await tapKey(t, 'refs-type-seg-style');
      expect(rec.patches.single.$2.type, RefsPreciseType.style);
      await tapKey(t, 'refs-insp-add');
      expect(rec.adds.single.$1, ['c20']);
      await tapKey(t, 'refs-insp-img2img');
      await tapKey(t, 'refs-insp-save-vibe');
      expect(rec.calls, containsAll(['img2img:c20', 'saveAsVibe:c20']));
    });

    testWidgets('托盘：和 Vibe 冲突时可以暂停 Vibe', (t) async {
      await pump(t, data: RefsFixture.preciseView());
      expect(key('refs-conflict'), findsOneWidget);
      await tapKey(t, 'refs-pause-vibes');
      expect(rec.calls, contains('pause:true'));
    });

    testWidgets('左栏类型筛选', (t) async {
      await pump(t, data: RefsFixture.preciseView());
      await tapKey(t, 'refs-type-character');
      expect(rec.filters.last.type, RefsPreciseType.character);
    });
  });

  group('托盘', () {
    testWidgets('清空、去生图页、移掉一个', (t) async {
      await pump(t);
      await tapKey(t, 'refs-tray-clear');
      await tapKey(t, 'refs-go-generation');
      final item = key('refs-tray-gen-c03');
      await hoverOver(t, item);
      await t.tap(find.descendant(of: item, matching: key('refs-tray-remove')));
      await t.pumpAndSettle();
      expect(
        rec.calls,
        containsAll(['trayClear', 'goGeneration', 'trayRemove:gen-c03']),
      );
    });
  });

  group('弹窗', () {
    testWidgets('大图详情：上一个 / 下一个', (t) async {
      await pump(t, data: RefsFixture.vibe(selectedKey: 'c11'));
      await tapKey(t, 'refs-insp-preview');
      expect(key('refs-detail'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      expect(rec.calls, contains('select:c10'));
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(key('refs-detail'), findsNothing);
    });

    testWidgets('组合包：只发勾选的', (t) async {
      await pump(t, data: RefsFixture.vibe(selectedKey: 'c14'));
      await tapKey(t, 'refs-insp-open-bundle');
      expect(key('refs-bundle'), findsOneWidget);
      for (final i in [0, 2]) {
        await t.tapAt(
          t.getTopLeft(key('refs-bundle-child-$i')) + const Offset(40, 40),
        );
        await t.pumpAndSettle();
      }
      await t.tap(
        find.descendant(
          of: key('refs-bundle-scope'),
          matching: find.text('只用勾选的 2 个'),
        ),
      );
      await t.pumpAndSettle();
      await tapKey(t, 'refs-bundle-add');
      expect(rec.bundles.single.$1, 'c14');
      expect(rec.bundles.single.$2, [0, 2]);
    });

    testWidgets('导入：现在编码、拆开组合包', (t) async {
      await pump(
        t,
        data: RefsFixture.vibe(importDraft: RefsFixture.importDraft()),
      );
      expect(key('refs-import-dialog'), findsOneWidget);
      await t.tap(find.text('现在编码 · 2 Anlas/张'));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: key('refs-import-bundle-r3'),
          matching: find.text('拆成 8 个'),
        ),
      );
      await t.pumpAndSettle();
      await tapKey(t, 'refs-import-confirm');
      final plan = rec.imports.single;
      expect(plan.rows, hasLength(6));
      expect(plan.categoryId, 'style');
      expect(
        plan.rows.firstWhere((r) => r.id == 'r3').bundle,
        RefsBundleImport.split,
      );
      expect(plan.encodeNow, isTrue);
    });

    testWidgets('导入：Esc 取消', (t) async {
      await pump(
        t,
        data: RefsFixture.vibe(importDraft: RefsFixture.importDraft()),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(rec.calls, contains('importCancel'));
    });

    testWidgets('导出：换保存位置', (t) async {
      await pump(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyE);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      await tapKey(t, 'refs-export-pick');
      await tapKey(t, 'refs-export-confirm');
      expect(rec.exports.single.folder, r'D:\out');
      expect(rec.exports.single.keys, ['c03']);
    });
  });

  group('空库 / 拖入 / 窄窗口', () {
    testWidgets('空库按钮导入', (t) async {
      await pump(t, data: RefsFixture.vibe(empty: true));
      expect(key('refs-empty'), findsOneWidget);
      expect(key('refs-inspector'), findsNothing);
      await tapKey(t, 'refs-empty-pick');
      await tapKey(t, 'refs-empty-paste');
      expect(rec.calls, containsAll(['import:files', 'import:clipboard']));
    });

    testWidgets('拖入提示', (t) async {
      await pump(t, data: RefsFixture.vibe(drop: RefsFixture.drop));
      expect(key('refs-drop'), findsOneWidget);
      expect(find.text('松开导入 6 个文件'), findsOneWidget);
    });

    testWidgets('窗口变窄先收检查器，再收左栏', (t) async {
      await pump(t, window: 1300);
      expect(key('refs-inspector'), findsOneWidget);
      await pump(t, window: 1100);
      expect(key('refs-inspector'), findsNothing);
      expect(key('refs-sidebar'), findsOneWidget);
      await pump(t, window: 820);
      expect(key('refs-sidebar'), findsNothing);
      expect(key('refs-expand-sidebar'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('生图页选择器', () {
    Future<List<(List<String>, bool)>> run(
      WidgetTester t,
      RefsPickerData data,
      Future<void> Function() act,
    ) async {
      final out = <(List<String>, bool)>[];
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(900, 900);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        refsApp(
          Center(
            child: RefsPicker(
              data: data,
              actions: RefsPickerActions(
                onConfirm: (keys, {required replace}) =>
                    out.add((keys, replace)),
                onClose: () {},
                onOpenLibrary: () {},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await act();
      return out;
    }

    testWidgets('勾两个追加', (t) async {
      final data = RefsFixture.vibePicker();
      final out = await run(t, data, () async {
        await tapKey(t, 'refs-picker-card-c11');
        await tapKey(t, 'refs-picker-card-u1');
        await tapKey(t, 'refs-picker-append');
      });
      expect(out.single.$1, ['c11', 'u1']);
      expect(out.single.$2, isFalse);
    });

    testWidgets('没勾时追加不可点；替换现有', (t) async {
      final data = RefsFixture.precisePicker();
      final out = await run(t, data, () async {
        await tapKey(t, 'refs-picker-append');
        await tapKey(t, 'refs-picker-card-c02');
        await tapKey(t, 'refs-picker-replace');
      });
      expect(out.single.$1, ['c02']);
      expect(out.single.$2, isTrue);
    });
  });
}
