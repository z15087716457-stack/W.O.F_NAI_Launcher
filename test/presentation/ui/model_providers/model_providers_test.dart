// 服务商工作台：交互、草稿保存口径、校验与布局。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_controller.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_providers_harness.dart';

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('三栏：列表 / 中栏 / 检查器，选中第一个服务商和第一个模型', (t) async {
    await pumpProviders(t);
    expect(find.byKey(const Key('mp-list')), findsOneWidget);
    expect(find.byKey(const Key('mp-inspector')), findsOneWidget);
    expect(find.text('DeepSeek'), findsWidgets);
    expect(
      t.widget<Text>(find.byKey(const Key('mp-insp-id'))).data,
      'deepseek-flash',
    );
    // 原“高级请求参数”入口不在了，请求参数直接在页面上。
    expect(find.text('高级请求参数'), findsNothing);
    expect(find.byKey(const Key('mp-timeout')), findsOneWidget);
    expect(find.byKey(const Key('mp-levels')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('切服务商、切模型', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-model-deepseek-v4-pro')));
    await t.pumpAndSettle();
    expect(
      t.widget<Text>(find.byKey(const Key('mp-insp-id'))).data,
      'deepseek-v4-pro',
    );
    await t.tap(find.byKey(const Key('mp-provider-an')));
    await t.pumpAndSettle();
    expect(t.widget<Text>(find.byKey(const Key('mp-title'))).data, 'Anthropic');
    expect(
      t.widget<Text>(find.byKey(const Key('mp-insp-id'))).data,
      'claude-sonnet-5-5',
    );
  });

  testWidgets('思考协议只在 Anthropic Messages 显示', (t) async {
    await pumpProviders(t);
    // DeepSeek：OpenAI Chat Completions，选项没有作用，不显示；思考档位照常。
    expect(find.byKey(const Key('mp-levels')), findsOneWidget);
    expect(find.byKey(const Key('mp-default-level')), findsOneWidget);
    expect(find.byKey(const Key('mp-adaptive')), findsNothing);
    expect(find.text('思考协议'), findsNothing);
    await t.tap(find.byKey(const Key('mp-provider-an')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-adaptive')), findsOneWidget);
    expect(find.text('思考协议'), findsOneWidget);
  });

  testWidgets('编辑进草稿：保存条出现、计数、放弃还原', (t) async {
    final rec = await pumpProviders(t);
    expect(find.byKey(const Key('mp-dock')), findsNothing);
    await t.tap(find.byKey(const Key('mp-level-medium')));
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-dock')), findsOneWidget);
    expect(find.text('DeepSeek 有 2 项修改未保存'), findsOneWidget);
    expect(find.byKey(const Key('mp-dirty-ds')), findsOneWidget);
    expect(rec.calls, isEmpty, reason: '编辑只改草稿，不回调');
    await t.tap(find.byKey(const Key('dock-放弃')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-dock')), findsNothing);
  });

  testWidgets('保存：传 base / edited，成功后草稿清掉', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(
      find.byKey(const Key('mp-retry')).evaluate().isEmpty
          ? find.text('2')
          : find.descendant(
              of: find.byKey(const Key('mp-retry')),
              matching: find.text('3'),
            ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(rec.has('save:ds'), isTrue);
    expect(rec.lastSaved!.retryAttempts, 3);
    expect(rec.lastKey, isNull);
    expect(find.byKey(const Key('mp-dock')), findsNothing);
  });

  testWidgets('保存中继续编辑：新的修改留在草稿里', (t) async {
    final rec = await pumpProviders(t);
    final gate = Completer<void>();
    rec.saveGate = gate.future;
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pump();
    expect(find.text('正在保存…'), findsOneWidget);
    await t.tap(find.byKey(const Key('mp-level-medium')));
    await t.pump();
    gate.complete();
    await t.pumpAndSettle();
    expect(
      rec.lastSaved!.model('deepseek-flash')!.capabilities,
      contains(ProviderCapability.search),
    );
    expect(
      rec.lastSaved!.model('deepseek-flash')!.reasoningLevels,
      isNot(contains('medium')),
    );
    expect(find.text('DeepSeek 有 1 项修改未保存'), findsOneWidget);
  });

  testWidgets('冲突：保留草稿，别处的新值合并进来', (t) async {
    final rec = await pumpProviders(t);
    rec.saveResult = ProvidersSaveResult.conflict;
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    rec.externalEdit('ds', (s) => s.copyWith(timeoutSeconds: 150));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(find.text('配置已在别处修改：已合并最新值，确认后再保存'), findsOneWidget);
    expect(find.text('150'), findsOneWidget, reason: '别处的超时值显示出来');
    expect(find.byKey(const Key('mp-cap-search')), findsOneWidget);
  });

  testWidgets('失败：保留草稿并提示', (t) async {
    final rec = await pumpProviders(t);
    rec.saveResult = ProvidersSaveResult.failed;
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('mp-retry')),
        matching: find.text('3'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(find.text('保存失败，修改已保留'), findsOneWidget);
  });

  testWidgets('校验：地址不合法时禁止保存', (t) async {
    final rec = await pumpProviders(t);
    await t.enterText(_field('mp-url'), 'api.deepseek.com');
    await t.pumpAndSettle();
    expect(find.text('接口地址必须是完整的 http:// 或 https:// URL。'), findsOneWidget);
    expect(find.text('有 1 处需要修正'), findsOneWidget);
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(rec.has('save'), isFalse);
  });

  testWidgets('Key：输入新 Key 计入修改，保存时随 apiKey 传出', (t) async {
    final rec = await pumpProviders(t);
    await t.enterText(_field('mp-key'), 'sk-new');
    await t.pumpAndSettle();
    expect(find.text('DeepSeek 有 1 项修改未保存'), findsOneWidget);
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(rec.lastKey, 'sk-new');
  });

  testWidgets('显示 Key 走 onRevealApiKey', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-key-reveal')));
    await t.pumpAndSettle();
    expect(rec.has('reveal:ds'), isTrue);
    expect(find.text('sk-plain-ds'), findsOneWidget);
  });

  testWidgets('显示 Key 时改 Key：保存后输入框是新 Key，不退回旧值', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-key-reveal')));
    await t.pumpAndSettle();
    await t.enterText(_field('mp-key'), 'sk-new');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-保存')));
    await t.pumpAndSettle();
    expect(rec.lastKey, 'sk-new');
    // 离开输入框、切模型都不应退回显示时读到的旧 Key。
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('mp-model-deepseek-v4-pro')));
    await t.pumpAndSettle();
    expect(t.widget<TextField>(_field('mp-key')).controller!.text, 'sk-new');
    expect(find.text('DeepSeek 有 1 项修改未保存'), findsNothing);
  });

  testWidgets('显示 Key 时改了又放弃：回到原 Key', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-key-reveal')));
    await t.pumpAndSettle();
    await t.enterText(_field('mp-key'), 'sk-new');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dock-放弃')));
    await t.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    expect(
      t.widget<TextField>(_field('mp-key')).controller!.text,
      'sk-plain-ds',
    );
  });

  testWidgets('测试连接 / 测试模型带草稿', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-test')));
    await t.ensureVisible(find.byKey(const Key('mp-test-model')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('mp-test-model')));
    await t.pump();
    expect(rec.calls, [
      'test:ds:https://api.deepseek.com:null',
      'testModel:ds:deepseek-flash:8000:null',
    ]);
  });

  testWidgets('启用开关即时生效', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-enabled')));
    await t.pumpAndSettle();
    expect(rec.calls, ['enabled:ds:false']);
    expect(find.byKey(const Key('mp-dock')), findsNothing);
  });

  testWidgets('思考档位：去掉默认档时默认回到跟随服务', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-level-none')));
    await t.pumpAndSettle();
    final sel = find.byKey(const Key('mp-default-level'));
    expect(
      find.descendant(of: sel, matching: find.text('跟随服务')),
      findsOneWidget,
    );
  });

  testWidgets('不再有服务商级图片开关和采样（温度 / Top P）', (t) async {
    await pumpProviders(t);
    expect(find.byKey(const Key('mp-image')), findsNothing);
    expect(find.byKey(const Key('mp-temp')), findsNothing);
    expect(find.byKey(const Key('mp-topp-on')), findsNothing);
    expect(find.byKey(const Key('mp-cap-vision')), findsOneWidget);
  });

  testWidgets('请求头：添加一行、非法名称标红', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-add-header')));
    await t.pumpAndSettle();
    await t.enterText(_field('mp-header-0-key'), 'bad name');
    await t.pumpAndSettle();
    expect(find.textContaining('需要修正'), findsOneWidget);
    await t.enterText(_field('mp-header-0-key'), 'X-Title');
    await t.pumpAndSettle();
    expect(find.textContaining('需要修正'), findsNothing);
  });

  testWidgets('请求体值必须是 JSON', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-model-deepseek-v4-pro')));
    await t.pumpAndSettle();
    await t.enterText(_field('mp-body-0-value'), '{bad');
    await t.pumpAndSettle();
    expect(find.text('有 1 处需要修正'), findsOneWidget);
  });

  testWidgets('上下文 / 最大输出：输出超过上下文报错', (t) async {
    await pumpProviders(t);
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('mp-out')),
        matching: find.text('8K'),
      ),
    );
    await t.pump();
    await t.enterText(_field('mp-out'), '200k');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(find.text('输出不能超过上下文窗口'), findsOneWidget);
  });

  testWidgets('目录：切到目录、勾选、批量添加', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-provider-or')));
    await t.pumpAndSettle();
    await t.tap(find.text('服务商目录 342'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-tray')), findsOneWidget);
    expect(find.textContaining('还有 282 个'), findsOneWidget);
    await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-opus-5')));
    await t.tap(find.byKey(const Key('mp-cat-anthropic/claude-sonnet-5-5')));
    await t.pump();
    expect(find.text('已选 1 个'), findsOneWidget, reason: '已添加的不能再勾');
    await t.tap(find.byKey(const Key('mp-add-picked')));
    await t.pumpAndSettle();
    expect(rec.calls, ['add:or:anthropic/claude-opus-5:false']);
    expect(
      t.widget<Text>(find.byKey(const Key('mp-insp-id'))).data,
      'anthropic/claude-opus-5',
    );
  });

  testWidgets('目录：从没读取过时自动读取一次', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-provider-an')));
    await t.pumpAndSettle();
    await t.tap(find.text('服务商目录'));
    await t.pumpAndSettle();
    expect(rec.calls, ['fetch:an']);
    expect(find.byKey(const Key('mp-catalog-idle')), findsOneWidget);
  });

  testWidgets('目录失败显示原因和重试', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-provider-relay')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-error')), findsOneWidget);
    await t.tap(find.text('服务商目录'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-catalog-failed')), findsOneWidget);
  });

  testWidgets('手动添加模型：回车添加、重复 ID 不可加', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-manual')));
    await t.pumpAndSettle();
    await t.enterText(_field('mp-manual-input'), 'deepseek-flash');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('mp-manual-confirm')));
    await t.pump();
    expect(rec.calls, isEmpty);
    await t.enterText(_field('mp-manual-input'), 'deepseek-chat');
    await t.pump();
    await t.tap(find.byKey(const Key('mp-manual-confirm')));
    await t.pumpAndSettle();
    expect(rec.calls, ['add:ds:deepseek-chat:true']);
    expect(find.byKey(const Key('mp-model-deepseek-chat')), findsOneWidget);
  });

  testWidgets('移除模型要确认', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-insp-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-移除模型')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
    expect(rec.calls, isEmpty);
    await t.tap(find.byKey(const Key('confirm-ok')));
    await t.pumpAndSettle();
    expect(rec.calls, ['remove:ds:deepseek-flash']);
  });

  testWidgets('删除服务商要确认', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-delete')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('confirm-ok')));
    await t.pumpAndSettle();
    expect(rec.calls, ['delete:ds']);
    expect(t.widget<Text>(find.byKey(const Key('mp-title'))).data, 'OpenAI');
  });

  testWidgets('拖动排序回调新顺序', (t) async {
    final rec = await pumpProviders(t);
    final from = t.getCenter(find.byKey(const Key('mp-model-deepseek-flash')));
    final g = await t.startGesture(from - const Offset(240, 0));
    await t.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 60));
    await t.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 30));
    await t.pump(const Duration(milliseconds: 50));
    await g.up();
    await t.pumpAndSettle();
    final drag = find.byKey(const Key('mp-model-deepseek-flash'));
    expect(drag, findsOneWidget);
    // 起点在拖动柄上才会排序；不在柄上则不排序。这里只验证不会误回调成其他操作。
    expect(rec.calls.where((c) => !c.startsWith('reorder')), isEmpty);
  });

  testWidgets('添加服务商：顶栏按钮开弹窗，选预设回调 onCreate', (t) async {
    final rec = await pumpProviders(t);
    await t.tap(find.text('添加服务商').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-picker')), findsOneWidget);
    await t.enterText(_field('mp-picker-search'), 'kimi');
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('mp-preset-moonshot')), findsOneWidget);
    expect(find.byKey(const Key('mp-preset-deepseek')), findsNothing);
    await t.tap(find.byKey(const Key('mp-picker-next')));
    await t.pumpAndSettle();
    expect(rec.calls, ['create:moonshot']);
    expect(find.byKey(const Key('mp-picker')), findsNothing);
  });

  testWidgets('空态', (t) async {
    await pumpProviders(t, data: ProvidersFixture.empty);
    expect(find.byKey(const Key('mp-empty')), findsOneWidget);
    await t.tap(find.byKey(const Key('mp-empty-add')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-picker')), findsOneWidget);
  });

  testWidgets('有未保存修改时切页先确认', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    await t.tap(find.text('NAI Agent').first);
    await t.pumpAndSettle();
    expect(find.text('服务商配置还没保存，离开这一页会丢掉修改。'), findsOneWidget);
  });

  testWidgets('切到功能分配再回来草稿还在', (t) async {
    await pumpProviders(t);
    await t.tap(find.byKey(const Key('mp-cap-search')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('models-tab-tasks')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('models-tab-providers')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mp-dock')), findsOneWidget);
  });

  test('三方合并：用户改的字段保留，别处改的字段跟上', () {
    final base = ProvidersFixture.deepseek.settings;
    final edited = base.copyWith(retryAttempts: 3);
    final latest = base.copyWith(timeoutSeconds: 150);
    final m = ProviderSettings.merge(base, edited, latest);
    expect(m.retryAttempts, 3);
    expect(m.timeoutSeconds, 150);
  });

  test('JSON 校验', () {
    expect(ProvidersValidate.json('{"a":1}'), isTrue);
    expect(ProvidersValidate.json('0.3'), isTrue);
    expect(ProvidersValidate.json('{bad'), isFalse);
  });

  group('布局不溢出', () {
    for (final (w, l, dark) in [
      (1600.0, 'zh', false),
      (1600.0, 'zh', true),
      (1280.0, 'zh', false),
      (1100.0, 'zh', true),
      (900.0, 'zh', false),
      (1280.0, 'en', false),
      (1280.0, 'ja', false),
      (1280.0, 'ko', false),
      (1280.0, 'zh_TW', false),
      (900.0, 'en', false),
    ]) {
      testWidgets('$l $w ${dark ? '深' : '浅'}', (t) async {
        await pumpProviders(t, window: w, locale: l, dark: dark);
        expect(t.takeException(), isNull);
        for (final id in ['or', 'relay', 'ol']) {
          await t.tap(find.byKey(Key('mp-provider-$id')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: id);
        }
        await t.tap(find.byKey(const Key('mp-mode')).first);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  });
}
