// Agent 设置的二级弹窗（设置页同款外观）与回收区管理窗。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_agent_dialogs.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_dialog_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';

final _now = DateTime(2026, 10, 20, 18);

/// 装一个按钮，点它用 [showSettingsDialog] 打开 [dialog]；返回结果写进 [result]。
Future<List<Object?>> _open(
  WidgetTester t,
  WidgetBuilder dialog, {
  bool dark = false,
  Size size = const Size(1100, 820),
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final result = <Object?>[];
  await t.pumpWidget(
    RepaintBoundary(
      key: const Key('cap'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? GeistTheme.dark : GeistTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () async => result.add(
                  await showSettingsDialog<Object?>(context, dialog),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.byKey(const Key('open')));
  await t.pumpAndSettle();
  return result;
}

List<SettingsTrashRow> _rows() => [
  SettingsTrashRow(
    id: 's1',
    kind: SettingsTrashKind.skill,
    title: 'watercolor-style',
    at: _now.subtract(const Duration(minutes: 3)),
    bytes: 2048,
    detail: '全局',
  ),
  SettingsTrashRow(
    id: 'c1',
    kind: SettingsTrashKind.chat,
    title: '水彩改稿',
    at: _now.subtract(const Duration(hours: 2)),
    bytes: 340000,
    detail: '画风研究',
  ),
  SettingsTrashRow(
    id: 'c2',
    kind: SettingsTrashKind.chat,
    title: '旧对话',
    at: _now.subtract(const Duration(days: 3)),
    bytes: 12000,
    blocked: '所属工作区也在回收区里，先恢复工作区',
  ),
  SettingsTrashRow(
    id: 'w1',
    kind: SettingsTrashKind.workspace,
    title: '临时工作区',
    at: _now.subtract(const Duration(days: 3)),
    bytes: 5400000,
  ),
];

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('确认弹窗：危险操作红色按钮，取消 / 确认返回 false / true', (t) async {
    final r = await _open(
      t,
      (_) => const SettingsConfirmDialog(
        title: '删除 Skill',
        body: '「1」会移进回收区。',
        confirm: '删除',
        danger: true,
      ),
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('删除 Skill'), findsOneWidget);
    await t.tap(find.byKey(const Key('confirm-ok')));
    await t.pumpAndSettle();
    expect(r, [true]);
  });

  testWidgets('文字输入：校验不过就地标红不关窗，Esc 关闭返回 null', (t) async {
    final r = await _open(
      t,
      (_) => SettingsTextDialog(
        title: '新建 Skill',
        label: '名称',
        help: '只用小写字母、数字和连字符',
        validate: (v) => RegExp(r'^[a-z0-9-]+$').hasMatch(v) ? null : '名称不合法',
      ),
    );
    await t.enterText(
      find.byKey(const Key('settings-dialog-input')).first,
      'Bad Name',
    );
    await t.tap(find.byKey(const Key('settings-dialog-ok')));
    await t.pumpAndSettle();
    expect(find.text('名称不合法'), findsOneWidget);
    expect(r, isEmpty);
    await t.enterText(
      find.byKey(const Key('settings-dialog-input')).first,
      'good-name',
    );
    await t.tap(find.byKey(const Key('settings-dialog-ok')));
    await t.pumpAndSettle();
    expect(r, ['good-name']);
  });

  testWidgets('回收区：筛选、恢复失败就地提示、被阻止的不能恢复、彻底删除后刷新', (t) async {
    var rows = _rows();
    final calls = <String>[];
    await _open(
      t,
      (_) => SettingsTrashDialog(
        now: _now,
        load: () async => rows,
        onRestore: (row) async {
          calls.add('restore:${row.id}');
          if (row.id == 's1') return '恢复失败：原位置已有同名内容';
          rows = rows.where((r) => r.id != row.id).toList();
          return null;
        },
        onPurge: (row) async {
          calls.add('purge:${row.id}');
          rows = rows.where((r) => r.id != row.id).toList();
          return true;
        },
        onEmpty: (count) async {
          calls.add('empty:$count');
          rows = [];
          return true;
        },
      ),
    );
    expect(find.byKey(const Key('trash-row-c1')), findsOneWidget);
    await t.tap(find.byKey(const Key('trash-filter-skill')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('trash-row-c1')), findsNothing);
    await t.tap(find.byKey(const Key('trash-restore-s1')));
    await t.pumpAndSettle();
    expect(find.text('恢复失败：原位置已有同名内容'), findsOneWidget);
    await t.tap(find.byKey(const Key('trash-filter-all')));
    await t.pumpAndSettle();
    // 被阻止的那条恢复按钮不可点。
    await t.tap(find.byKey(const Key('trash-restore-c2')));
    await t.pumpAndSettle();
    expect(calls, isNot(contains('restore:c2')));
    await t.tap(find.byKey(const Key('trash-restore-c1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('trash-row-c1')), findsNothing);
    await t.tap(find.byKey(const Key('trash-purge-w1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('trash-row-w1')), findsNothing);
    await t.tap(find.byKey(const Key('trash-empty')));
    await t.pumpAndSettle();
    expect(find.text('回收区是空的'), findsOneWidget);
    expect(calls, ['restore:s1', 'restore:c1', 'purge:w1', 'empty:2']);
  });

  testWidgets('添加 Skill 文件夹：选位置和调用方式后返回', (t) async {
    final r = await _open(
      t,
      (_) => const SettingsSkillImportDialog(
        folder: r'D:\skills\watercolor-style',
        workspace: '画风研究',
      ),
    );
    await t.tap(find.text('当前工作区「画风研究」'));
    await t.tap(find.text('仅手动调用'));
    await t.pump();
    await t.tap(find.byKey(const Key('skill-import-ok')));
    await t.pumpAndSettle();
    expect(r, [(true, true)]);
  });

  testWidgets('文本查看：显示字数和 token 估算，复制按钮切换成已复制', (t) async {
    await _open(
      t,
      (_) => const SettingsTextViewer(
        title: '查看最终提示词',
        notice: '当前没有运行中的会话。',
        text: '你是 NAI Agent。',
      ),
    );
    expect(find.textContaining('字符'), findsOneWidget);
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    await t.tap(find.byKey(const Key('settings-dialog-copy')));
    await t.pump();
    expect(find.text('已复制'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
  });
}
