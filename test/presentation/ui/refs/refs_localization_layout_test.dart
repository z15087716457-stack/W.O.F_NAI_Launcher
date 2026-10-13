import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'refs_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [900.0, 1600.0]) {
        for (final empty in [false, true]) {
          testWidgets(
            'precise library $locale dark=$dark width=$width empty=$empty fits',
            (tester) async {
              await pumpRefs(
                tester,
                data: RefsFixture.preciseView(empty: empty),
                locale: locale,
                dark: dark,
                window: width,
              );

              final capture = Platform.environment['FE01_CAPTURE_DIR'];
              if (capture != null && empty) {
                await _captureRegion(
                  tester,
                  'refs-sidebar',
                  '$capture/$locale-${dark ? 'dark' : 'light'}-${width.toInt()}.png',
                );
              } else if (capture != null && width == 1600) {
                await _captureRegion(
                  tester,
                  'refs-inspector',
                  '$capture/inspector-$locale-${dark ? 'dark' : 'light'}.png',
                );
              }
              final error = tester.takeException();
              if (error != null) {
                fail(error is FlutterError ? error.toStringDeep() : '$error');
              }

              final context = tester.element(
                find.byKey(const Key('refs-sidebar')),
              );
              final labels = AppLocalizations.of(context)!;
              final title = find.text(labels.refs_preciseTitle);
              final collapse = find.byTooltip(labels.refs_collapseSidebar);
              expect(title, findsOneWidget);
              expect(collapse, findsOneWidget);
              expect(
                tester.getRect(title).right,
                lessThanOrEqualTo(tester.getRect(collapse).left),
                reason:
                    'The complete localized title must leave the sidebar control usable.',
              );
              expect(
                tester.getRect(collapse).right,
                lessThanOrEqualTo(
                  tester.getRect(find.byKey(const Key('refs-sidebar'))).right,
                ),
              );
            },
          );
        }
      }
    }
  }

  testWidgets('long title stays discoverable and collapse stays clickable', (
    tester,
  ) async {
    final recorder = RecordingRefsActions();
    await pumpRefs(
      tester,
      data: RefsFixture.preciseView(empty: true),
      actions: recorder.actions,
      locale: 'en',
      window: 900,
    );
    final context = tester.element(find.byKey(const Key('refs-sidebar')));
    final labels = AppLocalizations.of(context)!;
    final title = find.text(labels.refs_preciseTitle);
    expect(
      tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
      isTrue,
    );
    await hoverOver(tester, title);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(labels.refs_preciseTitle), findsNWidgets(2));
    await tester.tap(find.byTooltip(labels.refs_collapseSidebar));
    await tester.pumpAndSettle();
    expect(recorder.calls, contains('sidebar:false'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _captureRegion(
  WidgetTester tester,
  String key,
  String path,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('refs-capture')),
  );
  final region = tester.getRect(find.byKey(Key(key)));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      region,
      Rect.fromLTWH(0, 0, region.width, region.height),
      Paint(),
    );
    final picture = recorder.endRecording();
    final sidebar = await picture.toImage(
      region.width.ceil(),
      region.height.ceil(),
    );
    final data = await sidebar.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    sidebar.dispose();
    picture.dispose();
    image.dispose();
  });
}
