import 'dart:io';

import 'light_theme_contrast.dart' show InMemoryLocalStorageService;
import 'package:nai_launcher/core/utils/image_share_sanitizer.dart';
import 'package:nai_launcher/core/utils/nai_resolution_adapter.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';

class HistoryCaptureStorage extends InMemoryLocalStorageService {
  @override
  String getHistoryClickBehavior() =>
      HistoryClickBehavior.selectPreview.storageValue;
}

File generationFixtureFile(String prototypeName, {bool usePrototype = false}) =>
    File(
      usePrototype
          ? '../../mockups/generation/assets/$prototypeName.jpg'
          : 'test/fixtures/edit_image_sample.png',
    );

List<GeneratedImage> historyCaptureImages({
  bool mixed = false,
  bool usePrototype = false,
}) {
  final now = DateTime.now();
  final kind = usePrototype ? 'prototype' : 'fixture';
  final names = mixed
      ? ['canvas', 'g19', 'g07', 'g18']
      : ['canvas', 'h1', 'h2', 'g18'];
  final counts = mixed ? [1, 2, 2, 1] : [1, 2, 4, 2];
  final minutes = [42, 38, 31, 20];
  return [
    for (var batch = 0; batch < names.length; batch++)
      for (var index = 0; index < counts[batch]; index++)
        () {
          final file = generationFixtureFile(
            names[batch],
            usePrototype: usePrototype,
          );
          final bytes = file.readAsBytesSync();
          final dimensions = NaiResolutionAdapter.readImageSize(bytes)!;
          return GeneratedImage(
            id: 'capture-$kind-${mixed ? 'mixed' : 'plain'}-$batch-$index',
            bytes: bytes,
            width: dimensions.$1,
            height: dimensions.$2,
            createdAt: DateTime(
              now.year,
              now.month,
              now.day,
              16,
              minutes[batch],
            ),
            generationRunId: batch + 1,
            batchIndex: index,
            operation: batch == 0 ? ImageOperation.upscale : null,
            kind: mixed && batch == 3
                ? GeneratedImageKind.failedStreamSnapshot
                : GeneratedImageKind.completed,
          );
        }(),
  ];
}

Future<void> prepareHistoryCaptureImages(
  List<GeneratedImage> images, {
  bool usePrototype = false,
}) async {
  final service = ShareImagePreparationService.instance;
  for (final image in images.where((image) => image.canDrag)) {
    final batch = image.generationRunId! - 1;
    final mixed = image.id.contains('mixed');
    final names = mixed
        ? ['canvas', 'g19', 'g07', 'g18']
        : ['canvas', 'h1', 'h2', 'g18'];
    final file = generationFixtureFile(
      names[batch],
      usePrototype: usePrototype,
    );
    service.enqueue(
      imageId: image.id,
      imageBytes: image.bytes,
      fileName: '${image.id}.${usePrototype ? 'jpg' : 'png'}',
      stripMetadata: false,
      sourceFilePath: file.absolute.path,
    );
    await service
        .waitUntilReady(image.id, stripMetadata: false)
        .timeout(const Duration(seconds: 5));
  }
}
