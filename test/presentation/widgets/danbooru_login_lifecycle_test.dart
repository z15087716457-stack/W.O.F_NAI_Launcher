import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/danbooru_login_dialog.dart';

class OfflineLogin extends DanbooruAuth {
  final completed = Completer<bool>();
  int calls = 0;
  @override
  DanbooruAuthState build() => const DanbooruAuthState();
  @override
  Future<bool> login(String username, String apiKey) {
    calls++;
    return completed.future;
  }
}

void main() {
  for (final response in [false, true]) {
    for (final dismissal in ['barrier', 'escape', 'route', 'alive']) {
      testWidgets('$dismissal with verification result $response', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1100, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final auth = OfflineLogin();
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [danbooruAuthProvider.overrideWith(() => auth)],
            child: MaterialApp(
              navigatorKey: navigator,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const DanbooruLoginDialog(),
                    ),
                    child: const Text('Open fixture'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open fixture'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), 'fixture');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'dummy-not-a-real-key',
        );
        final dynamic handler = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .onPressed;
        Object? failure;
        final task = (handler() as Future<void>).then<void>(
          (_) {},
          onError: (Object error) {
            failure = error;
          },
        );
        await tester.pump();
        expect(auth.calls, 1);
        switch (dismissal) {
          case 'barrier':
            await tester.tapAt(const Offset(4, 4));
          case 'escape':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          case 'route':
            unawaited(
              navigator.currentState!.pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const Scaffold(body: Text('Replacement route')),
                ),
                (_) => false,
              ),
            );
        }
        if (dismissal != 'alive') {
          await tester.pumpAndSettle();
          expect(find.byType(DanbooruLoginDialog), findsNothing);
        }
        auth.completed.complete(response);
        await tester.pump();
        await task;
        await tester.pumpAndSettle();
        expect(failure, isNull);
        expect(tester.takeException(), isNull);
        if (dismissal == 'route') {
          expect(find.text('Replacement route'), findsOneWidget);
        }
        if (dismissal == 'alive') {
          expect(
            find.byType(DanbooruLoginDialog),
            response ? findsNothing : findsOneWidget,
          );
          if (!response) {
            expect(
              tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
              isNotNull,
            );
          }
        }
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}
