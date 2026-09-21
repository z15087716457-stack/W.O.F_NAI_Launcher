import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/screens/generation/services/generation_save_service.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Uint8List png;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('canvas_save_test_');
    png = Uint8List.fromList(img.encodePng(img.Image(width: 16, height: 16)));
  });
  tearDown(() async => root.delete(recursive: true));

  test('repeated and concurrent saves produce one identical file', () async {
    final image = GeneratedImageDetailData(id: 'same-image', imageBytes: png);
    final paths = await Future.wait([
      GenerationSaveService.saveToDirectory(image, rootPath: root.path),
      GenerationSaveService.saveToDirectory(image, rootPath: root.path),
    ]);
    final again = await GenerationSaveService.saveToDirectory(
      image,
      rootPath: root.path,
    );
    expect(paths.toSet(), {again});
    expect(await File(again).readAsBytes(), png);
    final files = await root
        .list(recursive: true)
        .where((entry) => entry is File)
        .toList();
    expect(files, hasLength(1));
  });

  test('PNG metadata and original bytes survive saving unchanged', () async {
    final encoded = await ImageSaveUtils.buildPrebuiltMetadataBytes(
      imageBytes: png,
      metadata: {
        'Software': 'NovelAI',
        'Comment': '{"seed":123,"prompt":"original"}',
      },
    );
    final image = GeneratedImageDetailData(
      id: 'metadata-image',
      imageBytes: encoded,
      metadata: const NaiImageMetadata(seed: 999, prompt: 'stale cache'),
    );
    final path = await GenerationSaveService.saveToDirectory(
      image,
      rootPath: root.path,
    );
    expect(await File(path).readAsBytes(), encoded);
  });

  test(
    'metadata fallback preserves full raw character and reference structure',
    () {
      const metadata = NaiImageMetadata(
        rawJson:
            '{"Comment":{"prompt":"original","v4_prompt":{"caption":{"char_captions":[{"char_caption":"person","centers":[{"x":0.25,"y":0.75}]}]}},"director_reference_strength_values":[0.8]}}',
      );
      final comment = GenerationSaveService.buildCommentJsonFromMetadata(
        metadata,
      );
      expect(comment['prompt'], 'original');
      expect(comment['director_reference_strength_values'], [0.8]);
      expect(
        comment['v4_prompt']['caption']['char_captions'][0]['centers'][0]['x'],
        0.25,
      );
    },
  );

  test(
    'metadata without raw JSON retains coordinates and does not invent parameters',
    () {
      const metadata = NaiImageMetadata(
        prompt: 'original',
        qualityToggle: false,
        ucPreset: 2,
        characterUseCoords: true,
        characterInfos: [
          CharacterPromptInfo(
            prompt: 'person',
            negativePrompt: 'hat',
            centerX: .2,
            centerY: .8,
          ),
        ],
        preciseReferenceImages: ['YQ=='],
        preciseReferenceTypes: ['character'],
        preciseReferenceStrengths: [.9],
        preciseReferenceFidelities: [.75],
      );
      final comment = GenerationSaveService.buildCommentJsonFromMetadata(
        metadata,
      );
      expect(comment.containsKey('seed'), isFalse);
      expect(comment.containsKey('width'), isFalse);
      expect(comment['quality_toggle'], false);
      expect(comment['uc_preset'], 2);
      expect(comment['v4_prompt']['caption']['char_captions'][0]['centers'], [
        {'x': .2, 'y': .8},
      ]);
      expect(
        comment['v4_negative_prompt']['caption']['char_captions'][0]['char_caption'],
        'hat',
      );
      expect(comment['director_reference_secondary_strength_values'], [.25]);
    },
  );
}
