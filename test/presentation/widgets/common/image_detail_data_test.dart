import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/file_image_detail_data.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';

void main() {
  test(
    'generated detail data can hide actions while keeping metadata',
    () async {
      const metadata = NaiImageMetadata(
        prompt: 'snapshot prompt',
        negativePrompt: 'snapshot negative',
        width: 512,
        height: 768,
      );
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );

      final detail = GeneratedImageDetailData(
        imageBytes: bytes,
        metadata: metadata,
        id: 'failed-snapshot',
        showSaveButton: false,
        showCopyButton: false,
      );

      expect(detail.identifier, equals('failed-snapshot'));
      expect(detail.metadata, same(metadata));
      expect(await detail.getMetadataAsync(), same(metadata));
      expect(detail.showSaveButton, isFalse);
      expect(detail.showCopyButton, isFalse);
      expect(detail.showFavoriteButton, isFalse);
      expect(await detail.getImageBytes(), orderedEquals(bytes));
    },
  );

  test('file detail data can hide copy without changing save visibility', () {
    final detail = FileImageDetailData(
      filePath: 'C:\\tmp\\failed_snapshot.png',
      showCopyButton: false,
    );

    expect(detail.showSaveButton, isFalse);
    expect(detail.showCopyButton, isFalse);
    expect(detail.showFavoriteButton, isTrue);
  });

  test('local detail data keeps copy and favorite visible by default', () {
    final record = LocalImageRecord(
      path: 'C:\\tmp\\local_image.png',
      metadata: null,
      size: 128,
      modifiedAt: DateTime(2026),
    );

    final detail = LocalImageDetailData(record);

    expect(detail.showSaveButton, isFalse);
    expect(detail.showCopyButton, isTrue);
    expect(detail.showFavoriteButton, isTrue);
  });

  test('local detail data caps decode size even without metadata', () {
    final record = LocalImageRecord(
      path: 'C:\\tmp\\large_plain.png',
      metadata: null,
      size: 128,
      modifiedAt: DateTime(2026),
    );

    final detail = LocalImageDetailData(record);
    final provider = detail.getImageProvider();

    expect(provider, isA<ResizeImage>());
    final resized = provider as ResizeImage;
    expect(resized.width, 4096);
    expect(resized.height, 4096);
    expect(resized.policy, ResizeImagePolicy.fit);
  });

  test(
    'local dimensions prefer metadata and fall back to timeline dimensions',
    () {
      final date = DateTime(2026, 8, 31);
      LocalImageRecord record(NaiImageMetadata? metadata) => LocalImageRecord(
        path: 'fixture',
        size: 0,
        modifiedAt: date,
        metadata: metadata,
      );
      final metadata = LocalImageDetailData(
        record(const NaiImageMetadata(width: 1216, height: 832)),
        aspectRatio: .5,
      );
      expect(metadata.aspectRatio, 1216 / 832);
      expect(metadata.groupDate, date);
      expect(
        LocalImageDetailData(record(null), aspectRatio: .5).aspectRatio,
        .5,
      );
      expect(
        LocalImageDetailData(
          record(const NaiImageMetadata(width: 0, height: 832)),
          aspectRatio: .5,
        ).aspectRatio,
        .5,
      );
      expect(LocalImageDetailData(record(null)).aspectRatio, isNull);
    },
  );
  test('file and generated adapters expose dimensions without date groups', () {
    const metadata = NaiImageMetadata(width: 1216, height: 832);
    final generated = GeneratedImageDetailData(
      imageBytes: Uint8List(0),
      metadata: metadata,
    );
    final file = FileImageDetailData(
      filePath: 'fixture',
      initialMetadata: metadata,
    );
    for (final image in [generated, file]) {
      expect(image.aspectRatio, 1216 / 832);
      expect(image.groupDate, isNull);
    }
    expect(
      GeneratedImageDetailData(imageBytes: Uint8List(0)).aspectRatio,
      isNull,
    );
    expect(
      FileImageDetailData(
        filePath: 'fixture',
        initialMetadata: const NaiImageMetadata(height: 0, width: 10),
      ).aspectRatio,
      isNull,
    );
  });
}
