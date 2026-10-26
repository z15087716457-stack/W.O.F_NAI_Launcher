import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';

import '../../../helpers/app_logger_test_isolation.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;

class _Gallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState();
}

class _GateFile implements File {
  _GateFile(this.file, this.owner);
  final File file;
  final _Files owner;

  @override
  String get path => file.path;
  @override
  Directory get parent => file.parent;
  @override
  Future<FileStat> stat() => file.stat();
  @override
  Future<bool> exists() {
    owner.reads.add(path);
    if (!owner.entered.isCompleted) {
      owner.entered.complete();
      return owner.release.future;
    }
    return file.exists();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Files extends IOOverrides {
  _Files(this.originals);
  final Map<String, File> originals;
  final entered = Completer<void>();
  final release = Completer<bool>();
  final reads = <String>[];

  @override
  File createFile(String path) => originals.containsKey(path)
      ? _GateFile(originals[path]!, this)
      : super.createFile(path);
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  Future<void> settleUntil(WidgetTester t, bool Function() done) async {
    for (var i = 0; i < 40 && !done(); i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  for (final scenario in [
    'same path',
    'multiple changes',
    'different path',
    'old file missing',
    'unchanged',
    'resize',
    'dispose',
  ]) {
    testWidgets('in-flight thumbnail completion handles $scenario', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1200, 1000);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final dir = Directory.systemTemp.createTempSync('card_load_revision_');
      final originals = <String, File>{};
      final thumbs = Directory(
        '${dir.path}/${ThumbnailCacheService.thumbsDirName}',
      )..createSync();
      final bytes = img.encodeJpg(img.Image(width: 180, height: 180));
      for (final name in ['first.png', 'latest.png']) {
        final original = File('${dir.path}/$name')
          ..writeAsStringSync('original is not decoded');
        originals[original.path] = original;
        for (final size in ThumbnailSize.values) {
          File(
              '${thumbs.path}/${ThumbnailCacheService.buildThumbnailFileNameForTest(original.path, size: size)}',
            )
            ..writeAsBytesSync(bytes)
            ..setLastModifiedSync(
              DateTime.now().add(const Duration(seconds: 5)),
            );
        }
      }
      final first = LocalImageRecord(
        path: originals.keys.first,
        size: 10,
        modifiedAt: DateTime(2026),
      );
      final io = _Files(originals);
      Widget app(LocalImageRecord record, {double width = 180}) =>
          ProviderScope(
            overrides: [
              localGalleryNotifierProvider.overrideWith(_Gallery.new),
            ],
            child: refsApp(
              Center(
                child: LocalImageCard(
                  key: const Key('card'),
                  record: record,
                  width: width,
                  height: 180,
                ),
              ),
            ),
          );
      bool decoded() => t
          .widgetList<RawImage>(find.byType(RawImage))
          .any((image) => image.image != null);

      try {
        await IOOverrides.runWithIOOverrides(() async {
          try {
            await t.pumpWidget(app(first));
            await settleUntil(t, () => io.entered.isCompleted);
            expect(io.entered.isCompleted, isTrue);
            var latest = first;
            switch (scenario) {
              case 'same path':
              case 'multiple changes':
                latest = first.copyWith(
                  size: 11,
                  modifiedAt: DateTime(2026, 2),
                );
                await t.pumpWidget(app(latest));
                if (scenario == 'multiple changes') {
                  latest = latest.copyWith(
                    size: 12,
                    modifiedAt: DateTime(2026, 3),
                  );
                  await t.pumpWidget(app(latest));
                }
              case 'different path':
              case 'old file missing':
                latest = first.copyWith(path: originals.keys.last);
                await t.pumpWidget(app(latest));
              case 'resize':
                await t.pumpWidget(app(first, width: 700));
              case 'dispose':
                await t.pumpWidget(const SizedBox());
              case 'unchanged':
                break;
            }
            io.release.complete(scenario != 'old file missing');
            if (scenario == 'dispose') {
              await settleUntil(t, () => false);
              expect(io.reads, [first.path]);
              expect(find.byType(Image), findsNothing);
            } else {
              await settleUntil(t, decoded);
              if (scenario == 'resize') {
                await t.pump(const Duration(seconds: 1));
                await settleUntil(t, () => io.reads.length == 2 && decoded());
              }
              expect(decoded(), isTrue);
              expect(io.reads.length, scenario == 'unchanged' ? 1 : 2);
              if (scenario == 'different path' ||
                  scenario == 'old file missing') {
                expect(io.reads, [first.path, latest.path]);
                var provider = t.widget<Image>(find.byType(Image)).image;
                if (provider is ResizeImage) provider = provider.imageProvider;
                expect((provider as FileImage).file.path, contains('latest'));
              }
            }
            expect(t.takeException(), isNull);
          } finally {
            if (!io.release.isCompleted) io.release.complete(true);
            await t.pumpWidget(const SizedBox());
            await settleUntil(t, () => false);
          }
        }, io);
      } finally {
        ThumbnailService.instance.cancelAll();
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        dir.deleteSync(recursive: true);
      }
    });
  }
}
