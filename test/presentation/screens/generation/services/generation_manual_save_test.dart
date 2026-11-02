import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/services/generation_save_service.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';

import '../../../../helpers/app_logger_test_isolation.dart';
import '../../../../helpers/fake_local_gallery_service.dart';

class ProbeGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void publish(ImageGenerationState value) => state = value;
}

void main() {
  late Directory root;
  late Uint8List first;
  late Uint8List second;
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  setUp(() async {
    root = await Directory.systemTemp.createTemp('manual-save-probe-');
    SharedPreferences.setMockInitialValues({});
    Hive.init('${root.path}/hive');
    await Hive.openBox(StorageKeys.settingsBox);
    await LocalStorageService().setImageSavePath('${root.path}/gallery');
    final base = Uint8List.fromList(
      img.encodePng(img.Image(width: 16, height: 16)),
    );
    Future<Uint8List> encoded(int seed) =>
        ImageSaveUtils.buildPrebuiltMetadataBytes(
          imageBytes: base,
          metadata: {
            'Software': 'NovelAI',
            'Comment': jsonEncode({'prompt': 'synthetic', 'seed': seed}),
          },
        );
    first = await encoded(1);
    second = await encoded(2);
  });
  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  testWidgets('手动保存只更新指定文件，重复保存不刷新图库或替换图片列表', (tester) async {
    final gallery = FakeLocalGalleryService([]);
    final container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(gallery),
        ),
        imageGenerationNotifierProvider.overrideWith(ProbeGeneration.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
    });
    final records = [
      GeneratedImage(id: 'first', bytes: first, width: 16, height: 16),
      GeneratedImage(id: 'second', bytes: second, width: 16, height: 16),
      GeneratedImage(
        id: 'same-bytes-no-path',
        bytes: first,
        width: 16,
        height: 16,
      ),
    ];
    (container.read(imageGenerationNotifierProvider.notifier)
            as ProbeGeneration)
        .publish(ImageGenerationState(history: records));
    await container.read(localGalleryNotifierProvider.notifier).initialize();
    late WidgetRef widgetRef;
    late BuildContext saveContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                saveContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    Future<void> save(String id) async {
      final record = records.singleWhere((image) => image.id == id);
      await tester.runAsync(
        () => GenerationSaveService.saveImageFromDetail(
          saveContext,
          widgetRef,
          GeneratedImageDetailData(id: id, imageBytes: record.bytes),
        ),
      );
      await tester.pump();
    }

    await save('first');
    expect(gallery.refreshCount, 0);
    expect(gallery.addedImages, isEmpty);
    final firstPath = container
        .read(imageGenerationNotifierProvider)
        .findImageById('first')!
        .filePath;
    expect(firstPath, isNotNull);
    expect(await tester.runAsync(() => File(firstPath!).readAsBytes()), first);

    final beforeRepeat = container.read(imageGenerationNotifierProvider);
    await save('first');
    expect(gallery.refreshCount, 0);
    final afterRepeat = container.read(imageGenerationNotifierProvider);
    expect(afterRepeat.findImageById('first')!.filePath, firstPath);
    expect(afterRepeat, same(beforeRepeat));
    expect(gallery.fileChanges, hasLength(1));

    await save('second');
    expect(gallery.refreshCount, 0);

    await save('same-bytes-no-path');
    expect(gallery.refreshCount, 0);
    expect(
      container
          .read(imageGenerationNotifierProvider)
          .findImageById('same-bytes-no-path')!
          .filePath,
      firstPath,
    );
    expect(gallery.addedImages, isEmpty);
    expect(gallery.fileChanges, hasLength(3));
    expect(gallery.fileChanges.first.files, {firstPath});
    expect(
      gallery.timelineRequests,
      4,
    ); // initialization plus three path updates
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
