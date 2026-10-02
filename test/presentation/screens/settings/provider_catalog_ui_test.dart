import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/compact_service_connection.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

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
    (const Size(1000, 500), 1.0, 'short'),
  ]) {
    testWidgets(
      'larger catalog remains searchable, scrollable and selectable: ${spec.$3}',
      (tester) async {
        await harness.pumpManagement(tester, size: spec.$1, scale: spec.$2);
        await harness.tapVisible(tester, find.byKey(const Key('service-add')));
        final search = find.byKey(const Key('provider-search'));
        final custom = find.byKey(
          const Key('choose-provider-openaiCompatibleChat'),
        );
        expect(find.text('API Key 连接'), findsOneWidget);
        expect(custom, findsOneWidget);
        expect(tester.getSize(custom).height, lessThan(58 * spec.$2));
        final surface = find
            .ancestor(of: search, matching: find.byType(Material))
            .first;
        final height = tester.getSize(surface).height;
        expect(height, closeTo(spec.$1.height * .85, 1));
        await harness.capture(tester, 'provider-expansion-catalog-${spec.$3}');

        final searchPosition = tester.getRect(search);
        await tester.drag(
          find.byKey(const Key('provider-catalog-scroll')),
          const Offset(0, -2800),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(search), searchPosition);
        expect(find.text('本地服务'), findsOneWidget);
        final ollama = find.byKey(const Key('choose-provider-ollama'));
        expect(ollama.hitTestable(), findsOneWidget);
        await harness.capture(tester, 'provider-expansion-local-${spec.$3}');

        await tester.enterText(search, 'MiniMax');
        await tester.pumpAndSettle();
        expect(tester.getSize(surface).height, closeTo(height, 1));
        expect(find.text('本地服务'), findsNothing);
        final card = find.byKey(
          const Key('choose-provider-minimaxChinaMessages'),
        );
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(card.hitTestable(), findsOneWidget);
        await harness.capture(tester, 'provider-expansion-region-${spec.$3}');
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(search, findsNothing);
        final connection = tester.widget<CompactServiceConnection>(
          find.byType(CompactServiceConnection),
        );
        expect(connection.preset, ProviderPreset.minimaxChinaMessages);
        expect(connection.protocol, ProviderProtocol.anthropicMessages);
        expect(connection.url.text, 'https://api.minimaxi.com/anthropic/v1');
        expect(connection.apiKey.text, isEmpty);
        expect(find.text('点击“获取列表”读取此服务的模型，\n或在右侧手动添加模型 ID。'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
