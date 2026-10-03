import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _EmptyLibrary extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

void main() {
  final calls = <String>[];
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'isMaximized' || call.method == 'isFullScreen') {
        return false;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.nailauncher/titlebar'),
      (_) async => null,
    );
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.nailauncher/titlebar'),
      null,
    );
  });

  Widget host({
    Locale locale = const Locale('zh'),
    bool dark = false,
    GlobalKey? capture,
    double accessoryWidth = 0,
  }) => ProviderScope(
    overrides: [
      promptBlockLibraryNotifierProvider.overrideWith(_EmptyLibrary.new),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: dark ? GeistTheme.dark : GeistTheme.light,
      builder: (context, child) => RepaintBoundary(key: capture, child: child!),
      home: IntegratedTitleBarShell(
        captionHeight: 62,
        accessoryWidth: accessoryWidth,
        accessory: accessoryWidth == 0
            ? null
            : const ColoredBox(color: Colors.blue),
        child: const PromptBlockLibraryScreen(),
      ),
    ),
  );

  final search = find.byKey(const Key('prompt-block-library-search'));
  final captions = find.byKey(const Key('window-caption-controls'));
  final divider = find.byKey(const Key('window-header-caption-divider'));
  final create = find.byKey(const Key('prompt-block-new-block'));

  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [1400.0, 1100.0, 700.0]) {
        testWidgets(
          'toolbar ${locale.toLanguageTag()} dark=$dark width=$width',
          (tester) async {
            await tester.binding.setSurfaceSize(Size(width, 700));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final capture = GlobalKey();
            await tester.pumpWidget(
              host(locale: locale, dark: dark, capture: capture),
            );
            await tester.pumpAndSettle();
            final captionRect = tester.getRect(captions);
            expect(tester.getRect(search).overlaps(captionRect), isFalse);
            expect(tester.getRect(create).overlaps(captionRect), isFalse);
            expect(
              tester.getRect(divider).right,
              closeTo(captionRect.left - 8, .01),
            );
            expect(
              tester.getRect(divider).center.dy,
              closeTo(captionRect.center.dy, .01),
            );
            if (width == 1400) {
              expect(
                tester.getRect(create).right,
                closeTo(captionRect.left - 17, .01),
              );
            } else {
              expect(tester.getSize(search).width, greaterThan(320));
            }
            expect(tester.takeException(), isNull);
            if (Platform.environment['CAPTURE_BLOCK_TOOLBAR'] == '1' &&
                locale == const Locale('zh') &&
                width == 1400) {
              await tester.runAsync(() async {
                final image =
                    await (capture.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory('.dart_tool/block-toolbar-captures')
                  ..createSync(recursive: true);
                File(
                  '${folder.path}/${dark ? 'dark' : 'light'}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          },
        );
      }
    }
  }

  testWidgets(
    'resizing grows only search; actions stay at captions and keep the query',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.enterText(search, 'keep query');
      await tester.pumpAndSettle();
      final searchWidth = tester.getSize(search).width;
      final buttonWidth = tester.getSize(create).width;
      await tester.binding.setSurfaceSize(const Size(1700, 700));
      await tester.pumpAndSettle();
      expect(tester.getSize(search).width, closeTo(searchWidth + 300, .01));
      expect(tester.getSize(create).width, buttonWidth);
      expect(
        tester.getRect(create).right,
        closeTo(tester.getRect(captions).left - 17, .01),
      );
      expect(find.text('keep query'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(calls, contains('minimize'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('update accessory reservation stays outside toolbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(accessoryWidth: 88));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(create).right,
      closeTo(tester.getRect(captions).left - 88 - 17, .01),
    );
    expect(
      tester.getRect(divider).right,
      closeTo(tester.getRect(captions).left - 88 - 8, .01),
    );
    expect(tester.takeException(), isNull);
  });
}
