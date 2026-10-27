import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/resource_window/resource_gallery_viewer.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_controller.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';

import '../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  late Directory temp;
  late List<String> paths;
  late Uint8List pixels;
  late ResourceWindowController controller;
  final calls = <Map<String, Object?>>[];
  final deleted = <String>{};
  Completer<Object?>? translation;
  setUp(() async {
    calls.clear();
    deleted.clear();
    translation = null;
    temp = await Directory.systemTemp.createTemp('resource-viewer-');
    pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 100, height: 150)),
    );
    paths = [for (var i = 0; i < 3; i++) '${temp.path}/image-$i.png'];
    for (final path in paths) {
      await File(path).writeAsBytes(pixels);
    }
    controller = ResourceWindowController(
      windowId: 'child',
      kind: FloatingResourceKind.gallery,
      invoke: (method, args) async {
        calls.add({'method': method, ...args});
        if (method == 'resources.query') {
          final offset = args['offset'] as int;
          final active = paths
              .where((path) => !deleted.contains(path))
              .toList();
          return {
            'requestId': args['requestId'],
            'revision': 1,
            'items': [
              for (final path in active.skip(offset).take(2))
                {'id': path, 'title': path},
            ],
            'total': active.length,
            'hasMore': offset + 2 < active.length,
            'layout': 'grid',
            'cellSize': 132.0,
            'layouts': ['grid'],
          };
        }
        if (method == 'resources.thumbnail') return pixels;
        if (method != 'gallery.viewer') return null;
        final operation = args['operation'];
        if (operation == 'records') {
          return {
            'confirmDangerousActions': true,
            'records': [
              for (final id in args['ids'] as List)
                {
                  'path': id,
                  'size': pixels.length,
                  'modifiedAt': DateTime(2026).millisecondsSinceEpoch,
                  'favorite': false,
                },
            ],
          };
        }
        if (operation == 'metadata') {
          return jsonEncode(
            NaiImageMetadata(
              prompt: 'blue sky ${paths.indexOf(args['id'] as String)}',
              seed: 42,
              width: 100,
              height: 150,
            ).toJson(),
          );
        }
        if (operation == 'collections') return <Object?>[];
        if (operation == 'delete') {
          deleted.add(args['id'] as String);
          return true;
        }
        if (operation == 'restore') deleted.remove(args['id']);
        if (operation == 'translate') {
          return translation?.future ?? 'translated';
        }
        return null;
      },
    );
    await controller.initialize();
  });
  tearDown(() => controller.dispose());
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }
    await tester.runAsync(() => temp.delete(recursive: true));
  }

  ImageViewerPage viewer(WidgetTester tester) =>
      tester.widget(find.byType(ImageViewerPage));
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byType(ImageViewerPage).evaluate().isEmpty) return;
      final data = viewer(tester).data;
      if (data.current?.image != null &&
          data.detail?.status == ViewerMetaStatus.ready) {
        return;
      }
    }
    fail('Resource viewer did not finish loading');
  }

  Future<void> pump(WidgetTester tester, {double width = 1040}) async {
    tester.view.physicalSize = Size(width, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListenableBuilder(
          listenable: controller,
          builder: (_, _) => controller.viewerId == null
              ? const Text('resource list')
              : ResourceGalleryViewer(
                  controller: controller,
                  initialId: controller.viewerId!,
                ),
        ),
      ),
    );
    controller.actions.onOpen(paths.first);
    await tester.pump();
    await flush(tester);
  }

  testWidgets(
    'double click uses shared viewer in child, zooms and pages without primary-window commands',
    (tester) async {
      await pump(tester);
      expect(find.byType(ImageViewerPage), findsOneWidget);
      expect(viewer(tester).data.currentKey, paths.first);
      expect(viewer(tester).data.current!.width, 100);
      expect(viewer(tester).data.current!.height, 150);
      expect(viewer(tester).data.detail!.prompt, 'blue sky 0');
      expect(viewer(tester).data.current!.image, isA<ResizeImage>());
      expect(viewer(tester).data.current!.thumb, isA<ResourceWindowImage>());
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      final scope = tester.widget<ViewerPageScope>(
        find.byType(ViewerPageScope),
      );
      expect(scope.controller.zoom.scale, 1);
      viewer(tester).actions.onStep(1);
      await flush(tester);
      expect(viewer(tester).data.currentKey, paths[1]);
      viewer(tester).actions.onStep(1);
      await flush(tester);
      expect(viewer(tester).data.currentKey, paths.last);
      expect(
        calls
            .where((call) => call['method'] == 'resources.query')
            .last['offset'],
        2,
      );
      expect(
        calls.where(
          (call) =>
              call['method'] == 'resources.open' ||
              call['method'] == 'resources.action',
        ),
        isEmpty,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('resource list'), findsOneWidget);
      expect(controller.data.items.map((item) => item.id), paths);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'explicit actions and favorite forward current IDs; deletion keeps existing confirmation and undo UI',
    (tester) async {
      await pump(tester, width: 1440);
      viewer(tester).actions.onAction(paths.first, ViewerAction.img2img);
      await tester.pump();
      expect(calls.last, containsPair('operation', 'action'));
      expect(calls.last, containsPair('action', 'img2img'));
      viewer(tester).actions.onSetFavorite(paths.first, true);
      await tester.pump();
      await tester.pump();
      expect(viewer(tester).data.current!.favorite, true);
      final scope = tester.widget<ViewerPageScope>(
        find.byType(ViewerPageScope),
      );
      scope.controller.requestDelete();
      await tester.pump();
      expect(find.byKey(const Key('viewer-delete-confirm')), findsOneWidget);
      expect(calls.where((call) => call['operation'] == 'delete'), isEmpty);
      await tester.tap(find.byKey(const Key('viewer-delete-confirm')));
      await flush(tester);
      expect(viewer(tester).data.currentKey, paths[1]);
      expect(viewer(tester).data.undo, isNotNull);
      viewer(tester).actions.onUndoDelete();
      await flush(tester);
      expect(viewer(tester).data.currentKey, paths.first);
      expect(
        calls.where((call) => call['operation'] == 'restore').single['id'],
        paths.first,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'translation completing after a page turn cannot overwrite the next image',
    (tester) async {
      await pump(tester);
      translation = Completer<Object?>();
      viewer(
        tester,
      ).actions.onToggleTranslation(paths.first, ViewerPart.prompt);
      await tester.pump();
      expect(viewer(tester).data.translations[ViewerPart.prompt]!.busy, true);
      viewer(tester).actions.onStep(1);
      await flush(tester);
      translation!.complete('old image translation');
      await tester.pump();
      await tester.pump();
      expect(viewer(tester).data.currentKey, paths[1]);
      expect(viewer(tester).data.translations, isEmpty);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'deleting in a partly loaded range can still step to the compacted last page',
    (tester) async {
      await pump(tester);
      viewer(tester).actions.onDelete(paths.first);
      await flush(tester);
      await controller.refresh(retain: 2);
      await tester.pump();
      expect(controller.data.hasMore, false);
      expect(controller.data.total, 2);
      viewer(tester).actions.onStep(1);
      await flush(tester);
      expect(viewer(tester).data.currentKey, paths.last);
      await finish(tester);
    },
  );
}
