import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

const _config = PromptAssistantConfigState(
  providers: [
    ProviderConfig(
      id: 'gateway',
      name: 'Devin / CPA',
      preset: ProviderPreset.openaiCompatibleChat,
      baseUrl: 'http://127.0.0.1:8317/v1',
    ),
  ],
  models: [
    ModelConfig(
      providerId: 'gateway',
      name: 'devin/claude-opus-5-5',
      displayName: 'Claude Opus 5.5',
      contextWindow: 312000,
      maxOutputTokens: 128000,
    ),
    ModelConfig(
      providerId: 'gateway',
      name: 'hidden-model',
      displayName: 'Hidden',
    ),
    ModelConfig(
      providerId: 'gateway',
      name: 'devin/claude-sonnet-5-5',
      displayName: 'Claude Sonnet 5.5',
    ),
  ],
  interfaces: {},
  providerHasApiKey: {},
  presets: [],
);

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
    'imported configurations immediately receive the same catalog defaults',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      final imported = _config.copyWith(
        models: const [
          ModelConfig(
            providerId: 'gateway',
            name: 'models/gemini-3-flash-preview',
            displayName: 'models/gemini-3-flash-preview',
          ),
        ],
      );
      await container
          .read(promptAssistantConfigProvider.notifier)
          .importConfiguration(imported.encode());
      await tester.pumpAndSettle();
      final model = container.read(promptAssistantConfigProvider).models.single;
      expect(model.catalogEntry, isNotNull);
      expect(model.reasoningEfforts, ['minimal', 'low', 'medium', 'high']);
      expect(model.supportsVision, isTrue);
    },
  );
  testWidgets(
    'compact panels separate official capacities from editable user values',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      expect(find.text('312K · 128K'), findsOneWidget);
      expect(find.text('1M · 128K'), findsWidgets);
      expect(find.text('Claude Opus 5.5'), findsOneWidget);
      expect(find.text('清空'), findsNothing);
      expect(find.text('模型目录'), findsNothing);
      expect(find.byTooltip('添加模型目录无法拉取到的模型'), findsOneWidget);
      final leftSearch = tester.getRect(
        find.byKey(const Key('service-catalog-search')),
      );
      final rightSearch = tester.getRect(
        find.byKey(const Key('service-selected-search')),
      );
      expect(leftSearch.width, lessThan(190));
      expect((leftSearch.top - rightSearch.top).abs(), lessThan(8));
      await harness.capture(tester, 'foundation-panels');
      await tester.tap(find.byKey(const Key('service-edit-connection')));
      await tester.pumpAndSettle();
      await harness.capture(tester, 'foundation-connection');
      await tester.tap(find.byKey(const Key('service-edit-connection')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('service-model-parameters-devin/claude-opus-5-5')),
      );
      await tester.pumpAndSettle();
      expect(find.text('采样与能力'), findsNothing);
      expect(find.text('Temperature'), findsNothing);
      expect(find.text('图片'), findsOneWidget);
      expect(find.text('原生网络搜索'), findsOneWidget);
      await harness.capture(tester, 'foundation-advanced');
      await tester.enterText(
        find.byKey(const Key('context-devin/claude-opus-5-5')),
        '256000',
      );
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      final saved = container.read(promptAssistantConfigProvider).models.first;
      expect(saved.contextWindow, 256000);
      expect(saved.name, 'devin/claude-opus-5-5');
      expect(saved.catalogEntry!.contextLimit, 1000000);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dragging saves ordering and filtered reorder leaves hidden models in place',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      final first = tester.getCenter(
        find.byKey(const Key('model-drag-devin/claude-opus-5-5')),
      );
      final last = tester.getCenter(
        find.byKey(const Key('model-drag-devin/claude-sonnet-5-5')),
      );
      final drag = await tester.startGesture(last);
      await tester.pump(const Duration(milliseconds: 100));
      await drag.moveBy(const Offset(0, -8));
      await tester.pump(const Duration(milliseconds: 100));
      for (var step = 1; step <= 12; step++) {
        await drag.moveTo(
          Offset.lerp(last, first - const Offset(0, 12), step / 12)!,
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 350));
      await drag.up();
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      var saved = container.read(promptAssistantConfigProvider);
      expect(
        saved.modelsForProvider(providerId: 'gateway').map((m) => m.name),
        ['devin/claude-sonnet-5-5', 'devin/claude-opus-5-5', 'hidden-model'],
      );
      expect(
        PromptAssistantConfigState.decode(
          saved.encode(),
        ).models.map((m) => m.name),
        saved.models.map((m) => m.name),
      );
      await tester.enterText(
        find.byKey(const Key('service-selected-search')),
        'claude',
      );
      await tester.pumpAndSettle();
      final list = tester.widget<ReorderableListView>(
        find.byKey(const Key('service-selected-list')),
      );
      list.onReorderItem!(0, 1);
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      saved = container.read(promptAssistantConfigProvider);
      expect(saved.models.map((m) => m.name), [
        'devin/claude-opus-5-5',
        'devin/claude-sonnet-5-5',
        'hidden-model',
      ]);
      await tester.tap(
        find.byKey(const Key('service-remove-model-devin/claude-sonnet-5-5')),
      );
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      expect(
        container.read(promptAssistantConfigProvider).models.map((m) => m.name),
        ['devin/claude-opus-5-5', 'hidden-model'],
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'new known models auto-fill and a short enlarged editor stays scrollable',
    (tester) async {
      final container = await harness.pumpManagement(
        tester,
        config: _config,
        size: const Size(820, 620),
        scale: 1.5,
      );
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-edit-connection')),
      );
      expect(find.byKey(const Key('service-connection-save')), findsNothing);
      await harness.capture(tester, 'foundation-connection-compact');
      await tester.ensureVisible(
        find.byKey(const Key('ai-service-manual-model-id')),
      );
      await tester.enterText(
        find.byKey(const Key('ai-service-manual-model-id')),
        'models/gemini-3-flash-preview',
      );
      await harness.tapVisible(
        tester,
        find.byKey(const Key('service-add-custom-model')),
      );
      await harness.tapVisible(tester, find.byKey(const Key('service-save')));
      final gemini = container.read(promptAssistantConfigProvider).models.last;
      expect(gemini.reasoningEfforts, ['minimal', 'low', 'medium', 'high']);
      expect(gemini.supportsVision, isTrue);
      expect(gemini.supportsNativeSearch, isTrue);
      await tester.ensureVisible(
        find.byKey(
          const Key('service-model-parameters-models/gemini-3-flash-preview'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('service-model-parameters-models/gemini-3-flash-preview'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(
          const Key(
            'model-parameters-models/gemini-3-flash-preview-openaiChatCompletions',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await harness.capture(tester, 'foundation-advanced-compact');
      expect(tester.takeException(), isNull);
    },
  );
}
