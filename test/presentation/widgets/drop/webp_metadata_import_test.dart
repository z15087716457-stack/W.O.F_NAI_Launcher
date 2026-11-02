import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/drop/global_drop_handler.dart';
import 'package:nai_launcher/presentation/widgets/drop/image_destination_dialog.dart';

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Uint8List webp;
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    directory = await Directory.systemTemp.createTemp('webp-import-');
    Hive.init(directory.path);
    await ImageMetadataService().initialize();
    webp = await File(
      'test/fixtures/metadata/v4_webp_exif_stealth.webp',
    ).readAsBytes();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });

  for (final alphaOnly in [false, true]) {
    test('WebP ${alphaOnly ? 'alpha' : 'EXIF'} 元数据按图片内容读取', () async {
      final bytes = alphaOnly ? _withoutExif(webp) : webp;
      final parsed = UnifiedMetadataParser.parseFromImageBytes(bytes);
      expect(parsed.success, isTrue);
      expect(parsed.sourceFormat, contains(alphaOnly ? 'stealth' : 'EXIF'));
      final expected = await ImageMetadataService().getMetadataFromBytes(bytes);
      for (final name in ['image.webp', 'image.WEBP', 'renamed.png']) {
        final imported = await detectImportableDroppedImageMetadata(
          name,
          bytes,
        );
        expect(imported?.hasData, isTrue);
        expect(imported?.prompt, expected!.prompt);
        expect(imported?.characterPrompts, expected.characterPrompts);
        expect(imported?.characterInfos, expected.characterInfos);
      }
    });
  }

  test('无法解析的图片仍返回无元数据', () async {
    expect(
      await detectImportableDroppedImageMetadata(
        'broken.webp',
        Uint8List.fromList([1, 2, 3]),
      ),
      isNull,
    );
  });

  testWidgets('WebP 经实际导入检测后使用图片弹窗可以导入', (t) async {
    final metadata = await t.runAsync(
      () => detectImportableDroppedImageMetadata('image.webp', webp),
    );
    expect(metadata, isNotNull);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1000, 1000);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ImageDestinationDialog(
            imageBytes: webp,
            fileName: 'image.webp',
            metadata: metadata,
          ),
        ),
      ),
    );
    await t.runAsync(
      () => precacheImage(
        MemoryImage(webp),
        t.element(find.byType(ImageDestinationDialog)),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('未找到 NovelAI 元数据'), findsNothing);
    expect(
      t
          .widget<FilledButton>(find.byKey(const Key('image-use-import')))
          .onPressed,
      isNotNull,
    );
    await t.pumpWidget(const SizedBox());
  });
}

Uint8List _withoutExif(Uint8List bytes) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final size = ByteData.sublistView(
      bytes,
      offset + 4,
      offset + 8,
    ).getUint32(0, Endian.little);
    final end = offset + 8 + size + (size & 1);
    if (latin1.decode(bytes.sublist(offset, offset + 4)) == 'EXIF') {
      final result = Uint8List.fromList([
        ...bytes.sublist(0, offset),
        ...bytes.sublist(end),
      ]);
      ByteData.sublistView(
        result,
      ).setUint32(4, result.length - 8, Endian.little);
      return result;
    }
    offset = end;
  }
  throw StateError('Fixture has no EXIF chunk');
}
