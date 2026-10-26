import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/wiring/clipboard_history_paste.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> paste(WidgetTester tester) async {
    await tester.runAsync(() async {
      final done = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            ClipboardHistoryPaste.channel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('paste'),
            ),
            (_) => done.complete(),
          );
      await done.future;
    });
    await tester.pumpAndSettle();
  }

  testWidgets('native paste reaches the focused TextField only', (
    tester,
  ) async {
    final wiring = ClipboardHistoryPaste()..register();
    final text = TextEditingController();
    final focus = FocusNode();
    addTearDown(() {
      wiring.dispose();
      text.dispose();
      focus.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: text, focusNode: focus),
        ),
      ),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') return {'text': 'history'};
          if (call.method == 'Clipboard.hasStrings') return {'value': true};
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await paste(tester);
    await tester.pump();
    expect(text.text, isEmpty);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasPrimaryFocus, isTrue);
    expect(Actions.maybeFind<PasteTextIntent>(focus.context!), isNotNull);
    await paste(tester);
    await tester.pump();
    expect(text.text, 'history');
    focus.unfocus();
    await tester.pump();
    await paste(tester);
    await tester.pump();
    expect(text.text, 'history');
  });

  testWidgets('native paste uses custom PasteTextIntent overrides', (
    tester,
  ) async {
    final wiring = ClipboardHistoryPaste()..register();
    addTearDown(wiring.dispose);
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Actions(
            actions: {
              PasteTextIntent: CallbackAction<PasteTextIntent>(
                onInvoke: (_) {
                  count++;
                  return null;
                },
              ),
            },
            child: const TextField(autofocus: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await paste(tester);
    await tester.pump();
    expect(count, 1);
  });
}
