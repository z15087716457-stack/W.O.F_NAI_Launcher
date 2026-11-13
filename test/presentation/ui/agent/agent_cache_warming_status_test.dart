import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final dark in [false, true]) {
      for (final reason in const [
        'cache refresh deadline missed',
        'conversation context changed',
        '30-minute idle safety limit reached',
        'request cannot be replayed safely',
        'expected savings below threshold',
      ]) {
        final name = '${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}';
        testWidgets('cache warming explains $reason: $name', (tester) async {
          debugDisableShadows = false;
          final l = await AppLocalizations.delegate.load(locale);
          final expected = switch (reason) {
            'cache refresh deadline missed' => l.ag_cacheWarmExpired,
            'conversation context changed' => l.ag_cacheWarmContextChanged,
            '30-minute idle safety limit reached' => l.ag_cacheWarmSafetyLimit,
            'request cannot be replayed safely' => l.ag_cacheWarmUnavailable,
            _ => l.ag_cacheWarmEconomics,
          };
          final base = AgentFixture.view(AgentScene.chat);
          final data = AgentViewData(
            now: base.now,
            workspace: base.workspace,
            chat: base.chat,
            workspaces: base.workspaces,
            chats: base.chats,
            composer: base.composer,
            thread: const [],
            shelf: base.shelf,
            models: base.models,
            thinking: base.thinking,
            permission: base.permission,
            mentions: base.mentions,
            skills: base.skills,
            usage: AgentUsageData(
              tokens: 92000,
              window: 312000,
              cacheWarming: AgentCacheWarmingData(
                mode: 'idle',
                state: 'inactive',
                reason: reason,
                ttlSeconds: 300,
              ),
            ),
          );
          await pumpAgent(
            tester,
            data: data,
            width: 400,
            height: 720,
            dark: dark,
            locale: locale.toString(),
          );
          await tester.tap(find.byKey(const Key('agent-usage')));
          await tester.pumpAndSettle();
          expect(find.text(expected), findsOneWidget);
          expect(find.text(l.ag_cacheWarmIdle), findsNothing);
          expect(tester.takeException(), isNull);
          final output = Platform.environment['AGENT_CACHE_WARMING_CAPTURES'];
          if (output != null && reason == 'cache refresh deadline missed') {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('agent-capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final file = File('$output/$name.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes.buffer.asUint8List());
              image.dispose();
            });
          }
          debugDisableShadows = true;
        });
      }
    }
  }
}
