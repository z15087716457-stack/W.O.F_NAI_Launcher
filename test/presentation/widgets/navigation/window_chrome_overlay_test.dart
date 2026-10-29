import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/app_toast.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final windowCalls = <String>[];
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    windowCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          windowCalls.add(call.method);
          return call.method == 'isMaximized' ? false : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  for (final dark in [false, true]) {
    testWidgets('root toast and branch popups paint above chrome; dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final boundary = GlobalKey();
      final branch = GlobalKey<NavigatorState>();
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => RepaintBoundary(
            key: boundary,
            child: IntegratedTitleBarShell(
              deferToRoute: true,
              captionHeight: 62,
              child: child!,
            ),
          ),
          home: Navigator(
            key: branch,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => WindowChromePage(
                child: Builder(
                  builder: (context) {
                    pageContext = context;
                    return const Scaffold(
                      body: Column(
                        children: [
                          LibraryWindowHeader(
                            child: SizedBox(height: 62, child: TextField()),
                          ),
                          Expanded(child: Center(child: Text('画廊内容'))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final minimize = find.byIcon(Icons.remove);
      await tester.enterText(find.byType(TextField), 'preserved draft');
      AppToast.info(pageContext, '检测到 48458 张图片。首次建立索引可能需要几分钟，期间仍可正常使用图库。');
      await tester.pumpAndSettle();
      expect(minimize.hitTestable(), findsNothing);
      if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final file = File(
            '.dart_tool/chrome-overlays/toast-${dark ? 'dark' : 'light'}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byIcon(Icons.close).hitTestable().first);
      await tester.pumpAndSettle();
      expect(windowCalls, isNot(contains('close')));
      expect(minimize.hitTestable(), findsOneWidget);

      for (final root in [false, true]) {
        final result = showMenu<String>(
          context: pageContext,
          useRootNavigator: root,
          position: const RelativeRect.fromLTRB(700, 0, 0, 600),
          items: const [PopupMenuItem(value: 'selected', child: Text('弹出菜单'))],
          constraints: const BoxConstraints.tightFor(width: 280),
        );
        await tester.pumpAndSettle();
        expect(minimize.hitTestable(), findsNothing);
        await tester.tap(find.text('弹出菜单'));
        await tester.pumpAndSettle();
        expect(await result, 'selected');
        expect(minimize.hitTestable(), findsOneWidget);
      }
      final dialog = showDialog<void>(
        context: pageContext,
        builder: (_) =>
            const AlertDialog(title: Text('更新日志'), content: Text('这是对话框')),
      );
      await tester.pumpAndSettle();
      expect(minimize.hitTestable(), findsNothing);
      await tester.tapAt(const Offset(977, 31));
      await tester.pumpAndSettle();
      await dialog;
      expect(windowCalls, isNot(contains('close')));
      branch.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const WindowChromePage(child: Scaffold(body: Text('详情页'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('window-caption-controls')), findsOneWidget);
      branch.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('window-caption-controls')), findsOneWidget);
      expect(find.text('preserved draft'), findsOneWidget);
      await tester.tap(minimize);
      expect(windowCalls, contains('minimize'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
