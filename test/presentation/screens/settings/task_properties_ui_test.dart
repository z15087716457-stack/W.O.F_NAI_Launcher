import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_compact_dropdown.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

const _preset = TaskPresetConfig(
  id: 'user:layout-test',
  name: '我的阅读预设',
  task: LauncherInterface.translate,
  prompt: '离线预设文字',
);
final _config = harness.sampleConfig.copyWith(
  models: const [
    ModelConfig(
      providerId: 'deepseek',
      name: 'design-model',
      displayName: 'DeepSeek V4.1 Flash',
      reasoningEfforts: ['none', 'low', 'high'],
      reasoningEffort: 'high',
    ),
    ModelConfig(
      providerId: 'deepseek',
      name: 'lite',
      displayName: 'Lite',
      reasoningEfforts: [],
    ),
    ModelConfig(providerId: 'local', name: 'local-model', displayName: '隐藏模型'),
  ],
  interfaces: {
    LauncherInterface.translate: const InterfaceSlotConfig(
      providerId: 'deepseek',
      model: 'design-model',
    ),
  },
  presets: [_preset],
);

Finder get _route => find.byWidgetPredicate(
  (widget) =>
      widget is ModelCompactDropdown<String> &&
      widget.key.toString().contains('task-route-'),
);
String _reasoning(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('task-reasoning-value'))).data!;

Future<void> _open(WidgetTester tester) =>
    harness.tapVisible(tester, find.text('功能接口').first);

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final spec in [
    (const Size(1440, 820), 1.0, 'wide'),
    (const Size(600, 760), 1.3, 'compact'),
  ]) {
    testWidgets(
      'task typography and contextual footer remain clear: ${spec.$3}',
      (tester) async {
        await harness.pumpManagement(
          tester,
          config: _config,
          size: spec.$1,
          scale: spec.$2,
        );
        await _open(tester);
        for (final label in ['服务商与模型', '思考', '使用预设', '目标语言']) {
          expect(
            tester.widget<Text>(find.text(label)).style!.fontWeight,
            FontWeight.w600,
          );
        }
        expect(
          tester
              .widget<ModelCompactDropdown<String>>(_route)
              .textStyle!
              .fontWeight,
          FontWeight.w400,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const Key('task-reasoning-value')))
              .style!
              .fontWeight,
          FontWeight.w400,
        );
        expect(find.byKey(const Key('task-format-hint')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('task-format-hint'))).data,
          '无需翻译时，也可将提示词拆分为模块，通过积木功能自由拼装。',
        );
        for (final task in [
          LauncherInterface.tagTranslate,
          LauncherInterface.wikiTranslate,
          LauncherInterface.promptReverse,
        ]) {
          if (spec.$3 == 'compact') {
            await harness.tapVisible(
              tester,
              find.byType(DropdownButtonFormField<LauncherInterface>),
            );
            await tester.tap(find.text(task.title).last);
            await tester.pumpAndSettle();
          } else {
            await harness.tapVisible(
              tester,
              find.widgetWithText(ManagementListItem, task.title),
            );
          }
          final hint = find.byKey(const Key('task-format-hint'));
          if (task == LauncherInterface.promptReverse) {
            expect(hint, findsOneWidget);
            expect(
              tester.widget<Text>(hint).data,
              '无需翻译时，也可将提示词拆分为模块，通过积木功能自由拼装。',
            );
          } else {
            expect(hint, findsOneWidget);
            await tester.ensureVisible(hint);
            await tester.pumpAndSettle();
            expect(tester.widget<Text>(hint).data, '无需翻译时，也可整理排版并为相关标签添加链接。');
            final bounds = tester.getRect(hint);
            expect(bounds.right, lessThanOrEqualTo(spec.$1.width));
            if (spec.$3 == 'compact') {
              expect(
                bounds.top,
                greaterThan(
                  tester
                      .getRect(find.byKey(const Key('task-effective-summary')))
                      .bottom,
                ),
              );
            }
            await harness.capture(
              tester,
              'service-finish-${task.name}-${spec.$3}',
            );
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C properties align without outlines and preserve draft save', (
    tester,
  ) async {
    final container = await harness.pumpManagement(tester, config: _config);
    await _open(tester);
    final before = container.read(promptAssistantConfigProvider).encode();
    final model = tester.getRect(_route);
    final thinking = tester.getRect(find.byKey(const Key('task-reasoning')));
    final preset = tester.getRect(
      find.byKey(Key('task-preset-${LauncherInterface.translate.builtinId}')),
    );
    final language = tester.getRect(find.byKey(const Key('task-language')));
    expect(thinking.left, greaterThan(model.right));
    expect(thinking.top, closeTo(model.top, .01));
    expect(language.left, greaterThan(preset.right));
    expect(language.top, closeTo(preset.top, .01));
    for (final picker in [_route, find.byKey(const Key('task-language'))]) {
      final decoration = tester
          .widget<ModelCompactDropdown<String>>(picker)
          .decoration!;
      expect(decoration.enabledBorder, isA<UnderlineInputBorder>());
      expect(decoration.filled, isFalse);
    }
    expect(_reasoning(tester), '跟随模型（高）');
    await harness.capture(tester, 'task-properties-wide');
    await harness.tapVisible(tester, find.byKey(const Key('task-language')));
    await tester.tap(find.text('日本語').last);
    await tester.pumpAndSettle();
    await harness.tapVisible(
      tester,
      find.byKey(Key('task-preset-${LauncherInterface.translate.builtinId}')),
    );
    await tester.tap(find.text(_preset.name).last);
    await tester.pumpAndSettle();
    await harness.tapVisible(tester, find.byKey(const Key('task-reasoning')));
    await tester.tap(find.byKey(const Key('task-reasoning-low')));
    await tester.pumpAndSettle();
    expect(container.read(promptAssistantConfigProvider).encode(), before);
    expect(find.text('有未保存的修改'), findsOneWidget);
    await harness.capture(tester, 'task-properties-edited');
    await harness.tapVisible(tester, find.byKey(const Key('task-save')));
    final saved = container
        .read(promptAssistantConfigProvider)
        .interfaceFor(LauncherInterface.translate);
    expect(saved.targetLanguage, 'ja');
    expect(saved.presetId, _preset.id);
    expect(saved.reasoningEffort, 'low');
    expect(
      container
          .read(promptAssistantConfigProvider)
          .models
          .first
          .reasoningEffort,
      'high',
    );
    await harness.tapVisible(tester, _route);
    expect(find.textContaining('隐藏模型'), findsNothing);
    await tester.tap(find.text('DeepSeek · Lite').last);
    await tester.pumpAndSettle();
    expect(_reasoning(tester), '不支持');
    expect(
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(const Key('task-reasoning')),
          )
          .enabled,
      isFalse,
    );
    await harness.tapVisible(tester, find.byKey(const Key('task-save')));
    final next = container
        .read(promptAssistantConfigProvider)
        .interfaceFor(LauncherInterface.translate);
    expect(next.model, 'lite');
    expect(next.reasoningEffort, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom preset retains restore and rule navigation', (
    tester,
  ) async {
    await harness.pumpManagement(
      tester,
      config: _config.copyWith(
        interfaces: {
          LauncherInterface.translate: const InterfaceSlotConfig(
            providerId: 'deepseek',
            model: 'design-model',
            presetId: 'user:layout-test',
          ),
        },
      ),
    );
    await _open(tester);
    expect(find.text('恢复内置预设'), findsOneWidget);
    await harness.capture(tester, 'task-properties-custom-preset');
    await harness.tapVisible(tester, find.text('恢复内置预设'));
    expect(find.text('查看内置规则'), findsOneWidget);
    await harness.tapVisible(
      tester,
      find.byKey(const Key('task-preset-details')),
    );
    expect(find.text('保留当前编辑？'), findsOneWidget);
    await harness.tapVisible(tester, find.text('保存并切换'));
    expect(find.text('内置 · 只读'), findsOneWidget);
    expect(
      find.text(LauncherInterface.translate.builtinPrompt),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final spec in [
    (const Size(740, 820), 1.3, 'compact'),
    (const Size(400, 760), 1.3, 'narrow'),
  ]) {
    testWidgets('${spec.$3} C properties stack with enlarged text', (
      tester,
    ) async {
      await harness.pumpManagement(
        tester,
        config: _config,
        size: spec.$1,
        scale: spec.$2,
      );
      await _open(tester);
      final model = tester.getRect(_route);
      final thinking = tester.getRect(find.byKey(const Key('task-reasoning')));
      expect(thinking.top, greaterThan(model.bottom));
      for (final finder in [
        _route,
        find.byKey(const Key('task-language')),
        find.byKey(const Key('task-reasoning')),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(spec.$1.width));
      }
      await tester.ensureVisible(
        find.byKey(const Key('task-effective-summary')),
      );
      await tester.pumpAndSettle();
      await harness.capture(tester, 'task-properties-${spec.$3}');
      await harness.tapVisible(tester, find.byKey(const Key('task-language')));
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'reverse and empty routes retain output contract and disabled test',
    (tester) async {
      await harness.pumpManagement(
        tester,
        config: _config.copyWith(models: []),
      );
      await _open(tester);
      expect(find.text('尚未选择可用模型'), findsOneWidget);
      final modelButton = find.descendant(
        of: _route,
        matching: find.byType(TextButton),
      );
      expect(tester.widget<TextButton>(modelButton).onPressed, isNull);
      await tester.tap(modelButton);
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(
        tester.widget<TextButton>(find.byKey(const Key('task-test'))).onPressed,
        isNull,
      );
      await harness.capture(tester, 'task-properties-empty');
      await harness.tapVisible(
        tester,
        find.widgetWithText(
          ManagementListItem,
          LauncherInterface.promptReverse.title,
        ),
      );
      expect(find.byKey(const Key('task-language')), findsNothing);
      expect(find.text('英文生成提示词'), findsWidgets);
      await harness.capture(tester, 'task-properties-reverse');
      await harness.tapVisible(tester, find.text('提示词与输出'));
      expect(find.text('应用输出约定'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
