import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/auth/chatgpt_auth_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/chatgpt_connection_card.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Auth extends ChatGptAuthService {
  _Auth()
    : super(
        dio: Dio(),
        read: (_) async => null,
        write: (_, _) async {},
        openBrowser: (_) async => false,
      );
  ChatGptAccount? current;
  @override
  Future<ChatGptAccount?> account(String id) async => current;
  @override
  Future<void> signIn(String id, CancelToken cancellation) async {
    current = const ChatGptAccount(
      clientId: 'synthetic-client',
      email: 'test@example.invalid',
      signedIn: true,
      planEnabled: true,
    );
  }

  @override
  Future<bool> signOut(String id) async {
    current = const ChatGptAccount(
      clientId: 'synthetic-client',
      email: 'test@example.invalid',
      signedIn: false,
      planEnabled: false,
    );
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  for (final locale in const [
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
  ]) {
    testWidgets('ChatGPT sign-in/out and narrow layout: $locale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 620));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = _Auth();
      final boundary = GlobalKey();
      var connected = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatGptAuthServiceProvider.overrideWithValue(auth)],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(fontFamily: 'HarmonyOS Sans SC'),
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ChatGptConnectionCard(
                    providerId: 'chatgpt-test',
                    onConnected: () {
                      connected++;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with ChatGPT'));
      await tester.pumpAndSettle();
      expect(connected, 1);
      expect(find.textContaining('test@example.invalid'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final output = Platform.environment['CHATGPT_UI_CAPTURES'];
      if (output != null) {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await Directory(output).create(recursive: true);
          await File(
            '$output/chatgpt-$locale.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
      }
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ChatGptConnectionCard)),
      )!;
      await tester.tap(find.text(l10n.chatGpt_signOut));
      await tester.pumpAndSettle();
      expect(find.text(l10n.chatGpt_signedOut), findsOneWidget);
      expect(find.text(l10n.chatGpt_signOut), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unsaved service cannot start authorization', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChatGptConnectionCard(providerId: null, onConnected: () {}),
          ),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
  });
}
