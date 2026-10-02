import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/provider_connection_health_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/provider_connection_status_dot.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

ProviderConnectionStatus _status(WidgetTester tester, String key) => tester
    .widget<ProviderConnectionStatusDot>(find.byKey(ValueKey(key)))
    .result
    .status;

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'enabled service keeps cached status at the right and delete lives beside save',
    (tester) async {
      final container = await harness.pumpManagement(
        tester,
        size: const Size(1600, 1000),
      );
      final config = container.read(promptAssistantConfigProvider);
      final provider = config.providers.first;
      final health = container.read(providerConnectionHealthProvider);
      expect(find.byTooltip('管理 DeepSeek'), findsNothing);
      expect(find.text('复制服务配置'), findsNothing);
      expect(
        _status(tester, 'provider-health-deepseek'),
        ProviderConnectionStatus.unverified,
      );
      expect(find.byKey(const ValueKey('provider-health-local')), findsNothing);
      final delete = tester.getRect(find.byKey(const Key('service-delete')));
      final save = tester.getRect(find.byKey(const Key('service-save')));
      expect(delete.left, greaterThan(save.right));
      expect((delete.center.dy - save.center.dy).abs(), lessThan(2));
      await harness.capture(tester, 'provider-health-unverified');

      health.succeeded(health.begin(provider));
      await tester.pumpAndSettle();
      expect(
        _status(tester, 'provider-health-deepseek'),
        ProviderConnectionStatus.healthy,
      );
      await harness.capture(tester, 'provider-health-green');
      health.failed(
        health.begin(provider),
        DioException(
          requestOptions: RequestOptions(path: 'https://example.test'),
          type: DioExceptionType.connectionError,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _status(tester, 'provider-health-deepseek'),
        ProviderConnectionStatus.failed,
      );
      final dotTooltip = find.descendant(
        of: find.byKey(const ValueKey('provider-health-deepseek')),
        matching: find.byType(Tooltip),
      );
      expect(tester.widget<Tooltip>(dotTooltip).message, contains('无法连接服务'));
      await harness.capture(tester, 'provider-health-red');
      await harness.tapVisible(tester, find.text('本地模型').first);
      await harness.tapVisible(tester, find.text('DeepSeek').first);
      expect(
        _status(tester, 'provider-health-deepseek'),
        ProviderConnectionStatus.failed,
      );
      health.failed(
        health.begin(provider),
        DioException(
          requestOptions: RequestOptions(path: 'https://example.test'),
          response: Response(
            requestOptions: RequestOptions(path: 'https://example.test'),
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _status(tester, 'provider-health-deepseek'),
        ProviderConnectionStatus.limited,
      );
      await harness.capture(tester, 'provider-health-limited');
      expect(
        container.read(promptAssistantConfigProvider).encode(),
        config.encode(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'delete confirms, removes only the selected service and clears its status',
    (tester) async {
      final secrets = harness.MemorySecrets()
        ..keys['deepseek'] = 'offline-test-key'
        ..keys['local'] = 'local-test-key';
      final container = await harness.pumpManagement(tester, secrets: secrets);
      final before = container.read(promptAssistantConfigProvider);
      final health = container.read(providerConnectionHealthProvider);
      health.succeeded(health.begin(before.providers.first));
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, find.byKey(const Key('service-delete')));
      expect(find.text('删除 DeepSeek？'), findsOneWidget);
      await harness.capture(tester, 'provider-health-delete-confirm');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        container.read(promptAssistantConfigProvider).encode(),
        before.encode(),
      );
      await harness.tapVisible(tester, find.byKey(const Key('service-delete')));
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      final after = container.read(promptAssistantConfigProvider);
      expect(after.providers.single.id, 'local');
      expect(
        after.models.every((model) => model.providerId != 'deepseek'),
        isTrue,
      );
      expect(
        after.interfaceFor(LauncherInterface.translate).providerId,
        isEmpty,
      );
      expect(secrets.keys['deepseek'], isNull);
      expect(secrets.keys['local'], 'local-test-key');
      expect(
        health.resultFor('deepseek').status,
        ProviderConnectionStatus.unverified,
      );
      expect(
        find.byKey(const ValueKey('provider-health-deepseek')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact selector shows enabled status and new drafts have no delete action',
    (tester) async {
      final container = await harness.pumpManagement(
        tester,
        size: const Size(600, 760),
        scale: 1.3,
      );
      final provider = container
          .read(promptAssistantConfigProvider)
          .providers
          .first;
      final health = container.read(providerConnectionHealthProvider);
      health.succeeded(health.begin(provider));
      await tester.pumpAndSettle();
      expect(
        _status(tester, 'provider-health-compact-deepseek'),
        ProviderConnectionStatus.healthy,
      );
      expect(
        find.byKey(const ValueKey('provider-health-compact-local')),
        findsNothing,
      );
      expect(find.byKey(const Key('service-delete')), findsOneWidget);
      await harness.capture(tester, 'provider-health-compact');
      await harness.tapVisible(tester, find.byKey(const Key('service-add')));
      await tester.tap(
        find.byKey(const ValueKey('choose-provider-openaiCompatibleChat')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('service-delete')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
