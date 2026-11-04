import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

const _chrome = MethodChannel('com.wof.naiStudio/window_chrome');

void main() {
  testWidgets(
    'native title bar follows the current Flutter surface, including same-brightness changes',
    (t) async {
      final requests = <MethodCall>[];
      final messenger = t.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_chrome, (call) async {
        requests.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(_chrome, null));
      for (final (brightness, color) in [
        (Brightness.dark, const Color(0xff111111)),
        (Brightness.dark, const Color(0xff192336)),
        (Brightness.light, const Color(0xfff9faf5)),
      ]) {
        await t.pumpWidget(
          MaterialApp(
            themeAnimationDuration: Duration.zero,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: brightness,
              ).copyWith(surface: color),
            ),
            home: const IntegratedTitleBarShell(
              deferToRoute: true,
              child: SizedBox(),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(requests, isNotEmpty);
        expect(requests.last.method, 'configure');
        expect(requests.last.arguments['surface'], color.toARGB32());
        expect(requests.last.arguments['dark'], brightness == Brightness.dark);
        expect(requests.last.arguments['agent'], isNull);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
