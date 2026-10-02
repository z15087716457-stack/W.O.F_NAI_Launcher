import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/ai_service_editor.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/compact_service_connection.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_dialog.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

CompactServiceConnection _connection(WidgetTester tester) =>
    tester.widget(find.byType(CompactServiceConnection));

Future<void> _type(
  WidgetTester tester,
  TextEditingController controller,
  String value,
) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is TextField && identical(widget.controller, controller),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, ProviderPreset preset) async {
  await harness.tapVisible(tester, find.byKey(const Key('service-add')));
  expect(find.text('选择服务商'), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('choose-provider-${preset.name}')));
  await tester.pumpAndSettle();
}

Future<void> _editName(WidgetTester tester) async {
  await harness.tapVisible(
    tester,
    find.byKey(const Key('service-edit-connection')),
  );
  await _type(tester, _connection(tester).name, '修改中的服务');
}

class _FailingSecrets extends harness.MemorySecrets {
  bool fail = true;

  @override
  Future<void> savePromptAssistantApiKey(String providerId, String key) async {
    if (fail) throw StateError('模拟保存失败');
    await super.savePromptAssistantApiKey(providerId, key);
  }
}

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
    (const Size(1600, 1000), 1.0, 'wide'),
    (const Size(600, 760), 1.3, 'compact'),
  ]) {
    testWidgets(
      '${spec.$3} add opens picker first and creates only the chosen service',
      (tester) async {
        final container = await harness.pumpManagement(
          tester,
          size: spec.$1,
          scale: spec.$2,
        );
        final before = container.read(promptAssistantConfigProvider).encode();
        final editor = tester.state(find.byType(AiServiceEditor));
        await harness.capture(tester, 'provider-add-${spec.$3}-button');
        final add = tester.widget<IconButton>(
          find.byKey(const Key('service-add')),
        );
        await harness.tapVisible(tester, find.byKey(const Key('service-add')));
        add.onPressed!();
        await tester.pumpAndSettle();
        expect(find.text('选择服务商'), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
        expect(tester.state(find.byType(AiServiceEditor)), same(editor));
        expect(container.read(promptAssistantConfigProvider).encode(), before);
        expect(
          find.descendant(
            of: find.byType(SettingsDialogFrame),
            matching: find.byIcon(Icons.check),
          ),
          findsNothing,
        );
        await harness.capture(tester, 'provider-add-${spec.$3}-picker');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(AiServiceEditor)), same(editor));
        expect(container.read(promptAssistantConfigProvider).encode(), before);

        await harness.tapVisible(tester, find.byKey(const Key('service-add')));
        await tester.enterText(
          find.byKey(const Key('provider-search')),
          'Anthropic',
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('choose-provider-anthropic')),
        );
        await tester.pumpAndSettle();
        expect(find.text('选择服务商'), findsNothing);
        final connection = _connection(tester);
        expect(connection.preset, ProviderPreset.anthropic);
        expect(connection.protocol, ProviderProtocol.anthropicMessages);
        expect(connection.name.text, 'Anthropic');
        expect(connection.url.text, 'https://api.anthropic.com');
        expect(container.read(promptAssistantConfigProvider).encode(), before);
        await harness.capture(tester, 'provider-add-${spec.$3}-draft');
        await _type(tester, connection.apiKey, 'offline-test-key');
        await harness.tapVisible(tester, find.byKey(const Key('service-save')));
        final saved = container.read(promptAssistantConfigProvider);
        expect(saved.providers, hasLength(3));
        expect(saved.providers.last.preset, ProviderPreset.anthropic);
        expect(saved.providers.last.name, 'Anthropic');
        expect(
          saved.providers.first.toJson(),
          harness.sampleConfig.providers.first.toJson(),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'canceling add preserves an unsaved draft until a vendor is chosen',
    (tester) async {
      final container = await harness.pumpManagement(tester);
      final before = container.read(promptAssistantConfigProvider).encode();
      await _editName(tester);
      final editor = tester.state(find.byType(AiServiceEditor));
      await harness.tapVisible(tester, find.byKey(const Key('service-add')));
      expect(find.text('选择服务商'), findsOneWidget);
      expect(find.text('保留当前编辑？'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(AiServiceEditor)), same(editor));
      expect(_connection(tester).name.text, '修改中的服务');
      expect(container.read(promptAssistantConfigProvider).encode(), before);

      await _choose(tester, ProviderPreset.anthropic);
      expect(find.text('保留当前编辑？'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(AiServiceEditor)), same(editor));
      expect(_connection(tester).name.text, '修改中的服务');
      await _choose(tester, ProviderPreset.anthropic);
      await tester.tap(find.text('放弃'));
      await tester.pumpAndSettle();
      expect(_connection(tester).preset, ProviderPreset.anthropic);
      expect(_connection(tester).name.text, 'Anthropic');
      expect(container.read(promptAssistantConfigProvider).encode(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save before add retains the draft on failure and switches after retry',
    (tester) async {
      final secrets = _FailingSecrets()..keys['deepseek'] = 'existing-test-key';
      final container = await harness.pumpManagement(tester, secrets: secrets);
      await _editName(tester);
      await _type(tester, _connection(tester).apiKey, 'new-offline-test-key');
      await _choose(tester, ProviderPreset.anthropic);
      await tester.tap(find.text('保存并切换'));
      await tester.pumpAndSettle();
      expect(find.textContaining('模拟保存失败'), findsOneWidget);
      expect(_connection(tester).preset, ProviderPreset.deepseek);
      expect(_connection(tester).name.text, '修改中的服务');
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        'DeepSeek',
      );
      expect(
        container.read(promptAssistantConfigProvider).providers,
        hasLength(2),
      );
      secrets.fail = false;
      await _choose(tester, ProviderPreset.anthropic);
      await tester.tap(find.text('保存并切换'));
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).providers.first.name,
        '修改中的服务',
      );
      expect(
        container.read(promptAssistantConfigProvider).providers,
        hasLength(2),
      );
      expect(_connection(tester).preset, ProviderPreset.anthropic);
      expect(_connection(tester).name.text, 'Anthropic');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty state add opens picker and explicit custom shortcut keeps its preset',
    (tester) async {
      final container = await harness.pumpManagement(
        tester,
        config: harness.sampleConfig.copyWith(providers: [], models: []),
      );
      expect(find.byType(AiServiceEditor), findsNothing);
      await harness.tapVisible(tester, find.byKey(const Key('service-add')));
      expect(find.text('选择服务商'), findsOneWidget);
      expect(find.byType(AiServiceEditor), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('添加你的第一个模型服务'), findsOneWidget);
      await harness.tapVisible(
        tester,
        find.widgetWithText(FilledButton, '自定义服务'),
      );
      expect(find.text('选择服务商'), findsNothing);
      expect(_connection(tester).preset, ProviderPreset.openaiCompatibleChat);
      expect(container.read(promptAssistantConfigProvider).providers, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
