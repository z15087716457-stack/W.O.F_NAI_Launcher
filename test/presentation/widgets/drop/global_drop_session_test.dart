import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_image_drop_overlay.dart';
import 'package:nai_launcher/presentation/widgets/drop/global_drop_handler.dart';
import 'package:nai_launcher/presentation/widgets/drop/image_destination_dialog.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../helpers/drop_session_fixture.dart';
import '../../../helpers/app_logger_test_isolation.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _BrokenReader extends HeldDropReader {
  _BrokenReader() : super(bytes: Uint8List(0));
  @override
  bool canProvide(DataFormat value) => throw StateError('source failed');
}

void main() {
  prepareDropTestPlatform();
  late Directory temp;
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    temp = await Directory.systemTemp.createTemp('global-drop-session-');
    Hive.init(temp.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await ImageMetadataService().initialize();
  });
  tearDownAll(() async {
    await AppLoggerTestIsolation.tearDown();
    await Hive.close();
    assert(temp.absolute.path.startsWith(Directory.systemTemp.absolute.path));
    assert(temp.path.contains('global-drop-session-'));
    await temp.delete(recursive: true);
  });

  Future<DropRegion> pump(WidgetTester t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          imageGenerationNotifierProvider.overrideWith(_Generation.new),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GlobalDropHandler(child: SizedBox.expand()),
        ),
      ),
    );
    return t.widget<DropRegion>(find.byType(DropRegion));
  }

  Future<void> cleanUp(WidgetTester t, List<HeldDropReader> readers) async {
    await t.pumpWidget(const SizedBox());
    for (final r in readers) {
      if (!r.release.isCompleted) r.release.complete();
    }
    await t.pump();
  }

  testWidgets('hover, leave and reading use the shared drop notice', (t) async {
    final drop = await pump(t);
    final reader = HeldDropReader(bytes: Uint8List(0));
    final session = FixtureDropSession([reader]);
    expect(find.byType(UiImageDropOverlay), findsNothing);
    expect(await drop.onDropOver(session.over()), DropOperation.copy);
    await t.pump();
    expect(find.text('松开以导入图片'), findsOneWidget);
    expect(find.byType(UiSpinner), findsNothing);
    final draggingRect = t.getRect(find.byKey(const Key('image-drop-notice')));

    // The native source can leave without dropping, then return.
    drop.onDropLeave!(DropEvent(session: session));
    await t.pump();
    expect(find.byType(UiImageDropOverlay), findsNothing);
    expect(await drop.onDropOver(session.over()), DropOperation.copy);
    await t.pump();
    await drop.onPerformDrop(session.perform());
    await t.pump();
    expect(find.text('正在准备图片'), findsOneWidget);
    expect(find.text('松开以导入图片'), findsNothing);
    expect(find.byType(UiSpinner), findsOneWidget);
    expect(t.getRect(find.byKey(const Key('image-drop-notice'))), draggingRect);

    reader.release.complete();
    await t.pump();
    expect(find.byType(UiImageDropOverlay), findsNothing);
    expect(t.takeException(), isNull);
    await cleanUp(t, [reader]);
  });

  testWidgets(
    'drag and reading cover the window outside the native drop region',
    (t) async {
      var navigationTaps = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 100,
                    height: 80,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => navigationTaps++,
                      child: const Text('navigation'),
                    ),
                  ),
                  const Positioned(
                    left: 120,
                    top: 80,
                    right: 0,
                    bottom: 0,
                    child: GlobalDropHandler(child: SizedBox.expand()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final window = t.getRect(find.byType(Scaffold));
      final target = t.getRect(find.byType(GlobalDropHandler));
      expect(target, isNot(window));
      final drop = t.widget<DropRegion>(find.byType(DropRegion));
      final reader = HeldDropReader(bytes: Uint8List(0));
      final session = FixtureDropSession([reader]);
      expect(await drop.onDropOver(session.over()), DropOperation.copy);
      await t.pump();
      final backdrop = find.byKey(const Key('image-drop-backdrop'));
      final notice = find.byKey(const Key('image-drop-notice'));
      expect(t.getRect(backdrop), window);
      expect(t.getRect(notice).center, window.center);
      expect(t.getRect(find.byType(GlobalDropHandler)), target);
      await t.tapAt(const Offset(20, 20));
      expect(navigationTaps, 1);

      await drop.onPerformDrop(session.perform());
      await t.pump();
      expect(t.getRect(backdrop), window);
      expect(t.getRect(notice).center, window.center);
      await t.tapAt(const Offset(20, 20));
      expect(navigationTaps, 1);
      await cleanUp(t, [reader]);
      expect(backdrop, findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'global drop starts every native read before returning and owns a snapshot',
    (t) async {
      final drop = await pump(t);
      final readers = [
        HeldDropReader(bytes: Uint8List.fromList([1]), name: 'one.png'),
        HeldDropReader(bytes: Uint8List.fromList([2]), name: 'two.png'),
      ];
      final session = FixtureDropSession(readers);
      final done = drop.onPerformDrop(session.perform());
      expect(readers.map((r) => r.fileReads), [1, 1]);
      await done;
      for (final r in readers) {
        r.callbackReturned = true;
      }
      session.items.clear();
      await t.pump();
      expect(readers.map((r) => r.fileReads), [1, 1]);
      expect(t.takeException(), isNull);
      await cleanUp(t, readers);
    },
  );

  testWidgets('rapid second drop is refused while the first read is pending', (
    t,
  ) async {
    final drop = await pump(t);
    final first = HeldDropReader(bytes: Uint8List.fromList([1]));
    final second = HeldDropReader(bytes: Uint8List.fromList([2]));
    await drop.onPerformDrop(FixtureDropSession([first]).perform());
    final next = FixtureDropSession([second]);
    expect(await drop.onDropOver(next.over()), DropOperation.none);
    await drop.onPerformDrop(next.perform());
    expect(first.fileReads, 1);
    expect(second.fileReads, 0);
    expect(t.takeException(), isNull);
    await cleanUp(t, [first, second]);
  });

  testWidgets(
    'one broken source cannot prevent other native reads from starting',
    (t) async {
      final drop = await pump(t);
      final broken = _BrokenReader();
      final valid = HeldDropReader(bytes: Uint8List.fromList([2]));
      await drop.onPerformDrop(FixtureDropSession([broken, valid]).perform());
      expect(valid.fileReads, 1);
      await t.pump();
      expect(t.takeException(), isNull);
      await cleanUp(t, [broken, valid]);
    },
  );

  testWidgets(
    'an unreadable drop releases busy state so the next drop can enter',
    (t) async {
      final drop = await pump(t);
      final empty = HeldDropReader(bytes: Uint8List(0));
      final session = FixtureDropSession([empty]);
      await drop.onPerformDrop(session.perform());
      expect(await drop.onDropOver(session.over()), DropOperation.none);
      empty.release.complete();
      await t.pump();
      expect(await drop.onDropOver(session.over()), DropOperation.copy);
      await t.pump(const Duration(seconds: 5));
      expect(t.takeException(), isNull);
      await cleanUp(t, [empty]);
    },
  );

  testWidgets(
    'two virtual images survive drop disposal and open one destination dialog at a time',
    (t) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const GlobalDropHandler(child: Scaffold()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j3ioAAAAASUVORK5CYII=',
      );
      final readers = [
        HeldDropReader(bytes: png, name: 'first.png'),
        HeldDropReader(bytes: png, name: 'second.png'),
      ];
      final session = FixtureDropSession(readers);
      final drop = t.widget<DropRegion>(find.byType(DropRegion));
      await drop.onPerformDrop(session.perform());
      expect(readers.map((r) => r.fileReads), [1, 1]);
      for (final reader in readers) {
        reader.callbackReturned = true;
      }
      session.items.clear();
      for (final reader in readers) {
        reader.release.complete();
        for (
          var i = 0;
          i < 200 && find.byType(ImageDestinationDialog).evaluate().isEmpty;
          i++
        ) {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await t.pump();
        }
        expect(find.byType(ImageDestinationDialog), findsOneWidget);
        expect(
          t
              .widget<ImageDestinationDialog>(
                find.byType(ImageDestinationDialog),
              )
              .fileName,
          reader.fileName,
        );
        expect(await drop.onDropOver(session.over()), DropOperation.none);
        Navigator.of(t.element(find.byType(ImageDestinationDialog))).pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(await drop.onDropOver(session.over()), DropOperation.copy);
      expect(t.takeException(), isNull);
      await cleanUp(t, readers);
    },
  );
}
