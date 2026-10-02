import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_compact_dropdown.dart';
import 'model_management_section_test.dart' as harness;
import '../../../helpers/studio_capture_fonts.dart';

const _id = 'deepseek-flash';
PromptAssistantConfigState get _config => harness.sampleConfig.copyWith(
  models: [
    const ModelConfig(
      providerId: 'deepseek',
      name: _id,
      displayName: _id,
      customFields: {},
    ),
  ],
  interfaces: {
    ...harness.sampleConfig.interfaces,
    LauncherInterface.translate: const InterfaceSlotConfig(
      providerId: 'deepseek',
      model: _id,
    ),
    LauncherInterface.tagTranslate: const InterfaceSlotConfig(
      providerId: 'deepseek',
      model: _id,
    ),
  },
);

class _FailingSecrets extends harness.MemorySecrets {
  bool fail = true;
  @override
  Future<void> savePromptAssistantHeaders(
    String providerId,
    String value,
  ) async {
    if (fail && providerId.startsWith('model/')) throw StateError('模拟保存失败');
    await super.savePromptAssistantHeaders(providerId, value);
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  for (var i = 0; i < 2; i++) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String value) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key(key)), value);
  await tester.pumpAndSettle();
}

Future<void> _headers(WidgetTester tester) async {
  await _tap(tester, 'service-model-parameters-$_id');
  await _tap(tester, 'model-custom-headers');
  await _tap(tester, 'model-add-header');
  await _type(tester, 'header-key-0', 'X-Client');
  await _type(tester, 'header-value-0', 'WOF-Studio');
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
      await loadStudioCaptureFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  testWidgets(
    'catalog fills numeric controls, unknown uses a dash, and row height gains click space',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      final model = container.read(promptAssistantConfigProvider).models.first;
      expect(model.contextWindow, model.catalogEntry!.contextLimit);
      expect(model.maxOutputTokens, model.catalogEntry!.outputLimit);
      expect(find.text('默认 · 默认'), findsNothing);
      final advanced = find.byKey(const Key('service-model-parameters-$_id'));
      expect(tester.getSize(advanced).height, greaterThanOrEqualTo(23));
      await _tap(tester, 'service-model-parameters-$_id');
      final context = tester.widget<TextField>(
        find.byKey(const Key('context-$_id')),
      );
      expect(context.controller!.text, model.contextWindow.toString());
      final output = tester.widget<TextField>(
        find.byKey(const Key('parameter-max-tokens')),
      );
      expect(output.controller!.text, model.maxOutputTokens.toString());
      await _tap(tester, 'service-model-parameters-$_id');
      await _type(tester, 'ai-service-manual-model-id', 'studio-local');
      await _tap(tester, 'service-add-custom-model');
      expect(find.text('— · —'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'request editors preserve invalid drafts through collapse, validate JSON, save and reload typed values',
    (tester) async {
      final secure = harness.MemorySecrets();
      final container = await harness.pumpManagement(
        tester,
        config: _config,
        secrets: secure,
      );
      await _headers(tester);
      await harness.capture(tester, 'details-headers');
      await _tap(tester, 'model-custom-body');
      expect(find.byKey(const Key('model-headers-editor')), findsNothing);
      await _tap(tester, 'model-add-body-field');
      await _type(tester, 'body-key-0', 'metadata');
      await _type(tester, 'body-value-0', '{invalid');
      expect(find.text('请输入有效的 JSON 值'), findsOneWidget);
      await _tap(tester, 'service-model-parameters-$_id');
      await _tap(tester, 'service-model-parameters-$_id');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('body-value-0')))
            .controller!
            .text,
        '{invalid',
      );
      await _tap(tester, 'service-save');
      expect(secure.headers, isEmpty);
      expect(find.textContaining('请输入有效的 JSON 值'), findsWidgets);
      await _type(
        tester,
        'body-value-0',
        '{"source":"studio","enabled":true,"count":3}',
      );
      await harness.capture(tester, 'details-body');
      await _tap(tester, 'service-save');
      final saved = container.read(promptAssistantConfigProvider);
      expect(saved.models.first.hasRequestOverrides, isTrue);
      expect(saved.encode(), isNot(contains('WOF-Studio')));
      expect(saved.encode(), isNot(contains('metadata')));
      final raw = jsonDecode(secure.headers.values.single) as Map;
      expect((raw['body'] as Map)['metadata'], {
        'source': 'studio',
        'enabled': true,
        'count': 3,
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.pumpManagement(
        tester,
        config: PromptAssistantConfigState.decode(saved.encode()),
        secrets: secure,
      );
      await _tap(tester, 'service-model-parameters-$_id');
      await _tap(tester, 'model-custom-body');
      expect(find.byKey(const Key('body-key-0')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('body-key-0')))
            .controller!
            .text,
        'metadata',
      );
      expect(
        jsonDecode(
          tester
              .widget<TextField>(find.byKey(const Key('body-value-0')))
              .controller!
              .text,
        ),
        {'source': 'studio', 'enabled': true, 'count': 3},
      );
      await _tap(tester, 'body-remove-0');
      await _tap(tester, 'model-custom-headers');
      await _tap(tester, 'header-remove-0');
      await _tap(tester, 'service-save');
      expect(secure.headers, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save-and-switch keeps the draft on failure and switches only after a successful retry',
    (tester) async {
      final secure = _FailingSecrets();
      final container = await harness.pumpManagement(
        tester,
        config: _config,
        secrets: secure,
      );
      await _headers(tester);
      await harness.tapVisible(tester, find.text('功能接口').first);
      expect(find.text('放弃'), findsOneWidget);
      expect(find.text('保存并切换'), findsOneWidget);
      await tester.tap(find.text('保存并切换'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('service-save')), findsOneWidget);
      expect(find.textContaining('模拟保存失败'), findsOneWidget);
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .first
            .hasRequestOverrides,
        isFalse,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('header-value-0')))
            .controller!
            .text,
        'WOF-Studio',
      );
      secure.fail = false;
      await harness.tapVisible(tester, find.text('功能接口').first);
      await tester.tap(find.text('保存并切换'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('task-save')), findsOneWidget);
      expect(
        container
            .read(promptAssistantConfigProvider)
            .models
            .first
            .hasRequestOverrides,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('discard switches without saving current model edits', (
    tester,
  ) async {
    final container = await harness.pumpManagement(tester, config: _config);
    final before = container
        .read(promptAssistantConfigProvider)
        .models
        .first
        .contextWindow;
    await _tap(tester, 'service-model-parameters-$_id');
    await _type(tester, 'context-$_id', '256000');
    await harness.tapVisible(tester, find.text('功能接口').first);
    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-save')), findsOneWidget);
    expect(
      container.read(promptAssistantConfigProvider).models.first.contextWindow,
      before,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'thinking dropdowns open below the field in one frame and close without animation',
    (tester) async {
      await harness.pumpManagement(
        tester,
        size: const Size(1600, 1000),
        config: _config,
      );
      await _tap(tester, 'service-model-parameters-$_id');
      final field = find.byWidgetPredicate(
        (w) => w is ModelCompactDropdown<String>,
      );
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      final bottom = tester.getRect(field).bottom;
      if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
        debugDisableShadows = false;
      }
      await tester.tap(field);
      await tester.pump();
      final menuItem = find.byType(PopupMenuItem<String>).first;
      expect(menuItem, findsOneWidget);
      expect(tester.getRect(menuItem).top, greaterThanOrEqualTo(bottom));
      await harness.capture(tester, 'details-thinking-menu');
      await tester.tap(find.text('low').last);
      await tester.pump();
      expect(find.byType(PopupMenuItem<String>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('task and preset editors also save before navigation', (
    tester,
  ) async {
    final config = _config.copyWith(
      presets: const [
        TaskPresetConfig(
          id: 'custom',
          name: '我的预设',
          task: LauncherInterface.translate,
          prompt: 'Test',
        ),
      ],
    );
    final container = await harness.pumpManagement(tester, config: config);
    await harness.tapVisible(tester, find.text('功能接口').first);
    await _tap(tester, 'task-language');
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await harness.tapVisible(tester, find.text('预设与提示词').first);
    await tester.tap(find.text('保存并切换'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(promptAssistantConfigProvider)
          .interfaceFor(LauncherInterface.translate)
          .targetLanguage,
      'en',
    );
    await harness.tapVisible(tester, find.text('我的预设').first);
    await _type(tester, 'preset-name', '修改后的预设');
    await harness.tapVisible(tester, find.text('服务商').first);
    await tester.tap(find.text('保存并切换'));
    await tester.pumpAndSettle();
    expect(
      container.read(promptAssistantConfigProvider).presets.single.name,
      '修改后的预设',
    );
    expect(find.byKey(const Key('service-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final spec in [
    (const Size(1600, 1000), 1.0, 'wide'),
    (const Size(820, 680), 1.5, 'compact'),
  ]) {
    testWidgets(
      'confirmed form remains usable with ${spec.$3} layout and custom JSON',
      (tester) async {
        await harness.pumpManagement(
          tester,
          config: _config,
          size: spec.$1,
          scale: spec.$2,
        );
        await _headers(tester);
        await harness.capture(tester, 'details-${spec.$3}-headers');
        await _tap(tester, 'model-custom-body');
        await _tap(tester, 'model-add-body-field');
        await _type(tester, 'body-key-0', 'metadata');
        await _type(tester, 'body-value-0', '{"source":"studio"}');
        await harness.capture(tester, 'details-${spec.$3}-body');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
