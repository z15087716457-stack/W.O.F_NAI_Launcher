import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/app_toast.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  late BuildContext anchor;
  final capture = GlobalKey();
  Future<void> pump(
    WidgetTester tester, {
    double width = 800,
    bool reduced = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(Size(width, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppStyle.geist, brightness),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => RepaintBoundary(
          key: capture,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              anchor = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'long messages and progress share a measured stack; stale controllers cannot dismiss a replacement',
    (tester) async {
      await pump(tester, width: 360);
      final old = AppToast.showProgress(anchor, '旧任务');
      final current = AppToast.showProgress(
        anchor,
        '正在建立索引',
        progress: .25,
        subtitle: '期间仍可使用应用',
      );
      old.dismiss();
      old.fail(message: '不应出现');
      AppToast.info(
        anchor,
        '检测到 48463 张图片。首次建立索引可能需要几分钟，期间仍可正常使用应用。请稍候，索引会在后台继续。',
      );
      AppToast.success(anchor, '设置已保存');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump();
      expect(find.text('旧任务'), findsNothing);
      expect(find.text('不应出现'), findsNothing);
      expect(find.text('正在建立索引'), findsOneWidget);
      final cards = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      final rects = tester
          .widgetList(cards)
          .map((widget) => tester.getRect(find.byWidget(widget)))
          .toList();
      expect(rects.length, 3);
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].right, lessThanOrEqualTo(360));
        if (i > 0) expect(rects[i].top, greaterThan(rects[i - 1].bottom));
      }
      current.updateProgress(.8, subtitle: '已处理 38,770 张图片');
      await tester.pump();
      expect(find.text('80%'), findsOneWidget);
      current.complete(message: '索引完成');
      await tester.pump();
      expect(find.text('索引完成'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byKey(const Key('toast-dismiss')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completion before first paint and reduced motion are safe across overlay disposal',
    (tester) async {
      await pump(tester, reduced: true);
      final controller = AppToast.showProgress(anchor, '排队中');
      controller.complete(message: '已经完成');
      await tester.pump();
      expect(find.text('已经完成'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('已经完成'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('toast-dismiss')));
      await tester.pump();
      await tester.pump();
      expect(find.text('已经完成'), findsNothing);
      final orphan = AppToast.showProgress(anchor, '待处理');
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      orphan.updateProgress(.5);
      orphan.complete();
      orphan.dismiss();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Studio notifications render in both themes', (tester) async {
    if (Platform.environment['CAPTURE_SETTINGS_REDESIGN'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final brightness in Brightness.values) {
      await pump(tester, brightness: brightness);
      AppToast.info(anchor, '检测到 48463 张图片。首次建立索引可能需要几分钟，期间仍可正常使用应用。');
      AppToast.success(anchor, '模型设置已保存');
      AppToast.warning(anchor, '当前文件已存在，请确认保存位置。');
      AppToast.showProgress(
        anchor,
        '正在整理图库',
        progress: .68,
        subtitle: '已处理 32,954 张图片',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '.dart_tool/settings-redesign-captures/notifications-${brightness.name}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
