import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
      for (final kind in ['empty', 'images']) {
        final name =
            '${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}-$kind';
        testWidgets('request failure is visible at 320px: $name', (
          tester,
        ) async {
          debugDisableShadows = false;
          final l = await AppLocalizations.delegate.load(locale);
          final message = switch (kind) {
            'empty' => l.naiAgent_emptyResponse,
            _ => l.naiAgent_imageRequestTooLarge,
          };
          final fixture = AgentFixture.view(AgentScene.chat);
          final data = AgentViewData(
            now: fixture.now,
            workspace: fixture.workspace,
            chat: fixture.chat,
            workspaces: fixture.workspaces,
            chats: fixture.chats,
            composer: fixture.composer,
            thread: fixture.thread.take(1).toList(),
            shelf: fixture.shelf,
            usage: fixture.usage,
            models: fixture.models,
            thinking: fixture.thinking,
            permission: fixture.permission,
            mentions: fixture.mentions,
            skills: fixture.skills,
            error: message,
          );
          await pumpAgent(
            tester,
            data: data,
            width: 320,
            height: 680,
            dark: dark,
            locale: locale.toString(),
          );
          await tester.ensureVisible(find.byKey(const ValueKey('error')));
          await tester.pumpAndSettle();
          expect(find.text(message), findsOneWidget);
          expect(tester.takeException(), isNull);
          final output = Platform.environment['AGENT_REQUEST_ERROR_CAPTURES'];
          if (output != null) {
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
