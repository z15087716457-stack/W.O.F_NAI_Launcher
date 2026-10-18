import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../wiring/nai_agent/agent_wiring_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init();
  });
  tearDown(() async {
    await h.dispose();
  });
  Future<void> artifact(String path, {String tool = 'image_tool'}) async {
    h.c.selected!.messages = [
      {
        'role': 'assistant',
        'content': [
          {'type': 'toolCall', 'id': 'out', 'name': tool, 'arguments': {}},
        ],
      },
      {
        'role': 'toolResult',
        'toolCallId': 'out',
        'details': {
          'artifacts': [
            {'type': 'image', 'path': path, 'width': 240, 'height': 160},
          ],
          'image_ids': ['history-image'],
          'estimated_anlas': 1,
        },
      },
    ];
  }

  Future<void> image(String name) async {
    File(
      '${h.c.selected!.workspace.directory.path}/$name',
    ).writeAsBytesSync(img.encodePng(img.Image(width: 240, height: 160)));
  }

  testWidgets(
    'restored artifact visible outside collapsed tool detail and opens new zoom',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await image('image.png');
      await artifact('image.png');
      await h.pump(tester, files: true);
      final block = h
          .panel(tester)
          .data
          .thread
          .single
          .reply!
          .blocks
          .whereType<AgentImagesBlock>()
          .single;
      expect(block.images.single.historyId, 'history-image');
      final tile = find.byKey(Key('agent-image-${block.images.single.id}'));
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pump();
      expect(find.byKey(const Key('agent-zoom')), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agent-zoom-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('agent-zoom')), findsNothing);
      await tester.tap(find.byKey(const Key('agent-tab-shelf')));
      await tester.pump();
      expect(h.panel(tester).data.shelf.imageCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'missing/corrupt image is omitted safely including zoom payload validation',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final name in ['missing.png', 'corrupt.png']) {
        if (name == 'corrupt.png') {
          await image('valid.png');
          final bytes = File(
            '${h.c.selected!.workspace.directory.path}/valid.png',
          ).readAsBytesSync();
          File(
            '${h.c.selected!.workspace.directory.path}/$name',
          ).writeAsBytesSync(bytes.sublist(0, 33));
        }
        await artifact(name);
        await h.pump(tester, files: true);
        expect(h.panel(tester).data.shelf.imageCount, 0);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'actual junction/symlink escape cannot load an external artifact',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final outside = Directory.systemTemp.createTempSync('agent-external-');
      final link = '${h.c.selected!.workspace.directory.path}/linked'
          .replaceAll('/', Platform.pathSeparator);
      try {
        File(
          '${outside.path}/image.png',
        ).writeAsBytesSync(img.encodePng(img.Image(width: 4, height: 3)));
        if (Platform.isWindows) {
          final result = await tester.runAsync(
            () => Process.run('cmd.exe', [
              '/c',
              'mklink',
              '/J',
              link,
              outside.path,
            ]),
          );
          expect(
            result!.exitCode,
            0,
            reason: '${result.stdout}${result.stderr}',
          );
        } else {
          Link(link).createSync(outside.path);
        }
        await artifact('linked/image.png');
        await h.pump(tester, files: true);
        expect(h.panel(tester).data.shelf.imageCount, 0);
        expect(find.byType(Image), findsNothing);
        await tester.pumpWidget(const SizedBox());
      } finally {
        outside.deleteSync(recursive: true);
      }
    },
  );
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in Brightness.values) {
      testWidgets('real-font restored CodeMode artifacts $locale $brightness', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await image('seedvr2-7b-sharp-int8-original-image-upscaled.png');
        await artifact(
          'seedvr2-7b-sharp-int8-original-image-upscaled.png',
          tool: 'codemode',
        );
        for (final width in [320.0, 440.0]) {
          await h.pump(
            tester,
            width: width,
            locale: Locale(locale),
            brightness: brightness,
            files: true,
          );
          expect(h.panel(tester).data.shelf.imageCount, 1);
          expect(find.byType(Image), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
