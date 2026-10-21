import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/utils/comfyui_prompt_parser.dart';
import 'package:nai_launcher/core/utils/file_picker_utils.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

void main() {
  test(
    'new gallery saves share one folder across days without changing bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('gallery_default_');
      addTearDown(() => root.delete(recursive: true));
      final old = File('${root.path}/2026-10-01/old.png');
      await old.create(recursive: true);
      await old.writeAsString('historical image');
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final paths = await Future.wait([
        for (final day in [21, 22, 22])
          ImageSaveUtils.saveBytesToGalleryPath(
            rootPath: root.path,
            bytes: bytes,
            seed: 123,
            now: DateTime(2026, 10, day, 10, 20, 30),
          ),
      ]);
      expect(paths.toSet(), hasLength(3));
      for (final path in paths) {
        expect(File(path).parent.path, galleryUncategorizedPath(root.path));
        expect(await File(path).readAsBytes(), bytes);
      }
      expect(await old.readAsString(), 'historical image');
      expect(await Directory('${root.path}/2026-10-22').exists(), isFalse);
      expect(
        await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: root.path,
          bytes: bytes,
          seed: 123,
          now: DateTime(2026, 11, 1),
        ),
        isIn(paths),
      );
    },
  );

  group('ComfyuiPromptParser pipe syntax', () {
    test('should parse single-line whitespace pipe character prompts', () {
      const prompt =
          "1girl, 2boys, indoor, luxurious living room, sunlight, heavy contrast, tense atmosphere, ntr, femdom, humiliation, neglect play, foot worship | 1girl, large breasts, petite, rabbit girl, rabbit ears, 1.2::white hair::, very long hair, gradient hair, purple hair, ahoge, one side up, hair between eyes, 1.2::white ear fluff::, purple inner ears, 1.2::aqua eyes::, 1.1::heart-shaped pupils::, 1.2::purple pupils::, 1.3::purple eyelashes::, purple hair bow, black choker, blonde neck bell, white frilled dress, detached sleeves, white pantyhose, high heels, sitting, crossing legs, smug, arrogant, looking down, contempt, target#licking foot | 1boy, tall, muscular, handsome, stylish suit, standing, hand in pocket, holding girl's waist, smiling, confident | 1boy, short, pathetic, kneeling, on all fours, slave, human furniture, crying, despair, looking up, source#licking foot";

      expect(ComfyuiPromptParser.isComfyuiMultiCharacter(prompt), isTrue);

      final result = ComfyuiPromptParser.tryParse(prompt);

      expect(result, isNotNull);
      expect(result!.globalPrompt, startsWith('1girl, 2boys, indoor'));
      expect(result.characters, hasLength(3));
      expect(result.characters[0].prompt, contains('target#licking foot'));
      expect(result.characters[1].prompt, contains("holding girl's waist"));
      expect(result.characters[2].prompt, contains('source#licking foot'));
      expect(result.characters[0].inferredGender, CharacterGender.female);
      expect(result.characters[1].inferredGender, CharacterGender.male);
      expect(result.characters[2].inferredGender, CharacterGender.male);
    });

    test('should not treat NovelAI dynamic tags as pipe character syntax', () {
      const prompt = '1girl, {red|blue} hair, looking at viewer';

      expect(ComfyuiPromptParser.isComfyuiMultiCharacter(prompt), isFalse);
      expect(ComfyuiPromptParser.tryParse(prompt), isNull);
    });
  });

  group('ImageSaveUtils metadata semantics', () {
    test(
      'derived outputs inherit only source metadata and actual dimensions',
      () async {
        final plain = Uint8List.fromList(
          img.encodePng(img.Image(width: 4, height: 6)),
        );
        final source = UnifiedMetadataParser.embedTextChunkOnly(
          plain,
          'Comment',
          '{"prompt":"original prompt","seed":123,"width":2,"height":3}',
        );
        final output = await ImageSaveUtils.inheritSourceMetadata(
          imageBytes: plain,
          sourceBytes: source,
          width: 4,
          height: 6,
        );
        final metadata = UnifiedMetadataParser.parseFromImageBytes(
          output,
        ).metadata!;
        expect(metadata.prompt, 'original prompt');
        expect(metadata.seed, 123);
        expect(metadata.width, 4);
        expect(metadata.height, 6);
        expect(
          await ImageSaveUtils.inheritSourceMetadata(
            imageBytes: plain,
            sourceBytes: plain,
            width: 4,
            height: 6,
          ),
          same(plain),
        );
        expect(
          await ImageSaveUtils.inheritSourceMetadata(
            imageBytes: output,
            sourceBytes: plain,
            width: 4,
            height: 6,
          ),
          same(output),
        );
      },
    );
    test(
      'should build metadata from request prompt and explicit preset flags',
      () {
        final params = ImageParams(
          prompt: '1girl, sunset',
          negativePrompt: 'bad hands',
          model: ImageModels.animeDiffusionV45Full,
          qualityToggle: true,
          ucPreset: UcPresets.toApiValue(UcPresetType.heavy),
        );

        final commentJson = ImageSaveUtils.buildCommentJson(
          params: params,
          actualSeed: 123,
          charCaptions: const [
            {
              'char_caption': 'blue dress',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ],
          charNegCaptions: const [
            {
              'char_caption': 'extra fingers',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ],
        );

        expect(commentJson['prompt'], equals('1girl, sunset'));
        expect(commentJson['uc'], equals('bad hands'));
        expect(commentJson['quality_toggle'], isTrue);
        expect(commentJson['uc_preset'], equals(0));
        expect(commentJson['model'], equals(ImageModels.animeDiffusionV45Full));
        expect(
          commentJson['v4_prompt']['caption']['base_caption'],
          equals('1girl, sunset'),
        );
        expect(
          commentJson['v4_prompt']['caption']['char_captions'],
          equals([
            {
              'char_caption': 'blue dress',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ]),
        );
        expect(
          commentJson['v4_negative_prompt']['caption']['base_caption'],
          equals('bad hands'),
        );
        expect(
          commentJson['v4_negative_prompt']['caption']['char_captions'],
          equals([
            {
              'char_caption': 'extra fingers',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ]),
        );

        final metadata = ImageSaveUtils.buildMetadata(
          commentJson: commentJson,
          params: params,
        );
        expect(metadata['Description'], equals('1girl, sunset'));
      },
    );

    test('should record V5 Light tag hint alongside legacy toggle', () {
      const params = ImageParams(
        prompt: '1girl',
        model: ImageModels.animeDiffusionV5Full,
        qualityToggle: true,
        qualityTagPreset: QualityTagPreset.light,
      );

      final commentJson = ImageSaveUtils.buildCommentJson(
        params: params,
        actualSeed: 123,
      );

      expect(commentJson['quality_toggle'], isTrue);
      expect(commentJson['tag_hint_qt'], 3);
    });

    test(
      'should preserve embedded raw png metadata when saving generated bytes',
      () async {
        final png = img.Image(width: 2, height: 2);
        img.fill(png, color: img.ColorRgb8(255, 0, 0));
        var bytes = Uint8List.fromList(img.encodePng(png));

        const rawPrompt = 'artist:a,artist:b';
        const rawNegative = 'nsfw, lowres, bad hands';
        const rawSource = 'NovelAI Diffusion V4.5 4BDE2A90';
        final rawComment = <String, dynamic>{
          'prompt': rawPrompt,
          'uc': rawNegative,
          'seed': 123,
          'width': 2,
          'height': 2,
        };
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Comment',
          '{"prompt":"$rawPrompt","uc":"$rawNegative","seed":123,"width":2,"height":2}',
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Description',
          rawPrompt,
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Software',
          'NovelAI',
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Source',
          rawSource,
        );

        final tempDir = await Directory.systemTemp.createTemp(
          'image_save_utils_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final savedFile = await ImageSaveUtils.saveImageWithMetadata(
          imageBytes: bytes,
          filePath: '${tempDir.path}/saved.png',
          params: const ImageParams(
            prompt: 'different prompt',
            negativePrompt: 'different negative',
            model: ImageModels.animeDiffusionV45Full,
          ),
          actualSeed: 456,
        );

        final savedBytes = await savedFile.readAsBytes();
        expect(savedBytes, orderedEquals(bytes));
        final result = UnifiedMetadataParser.parseFromPng(savedBytes);

        expect(result.success, isTrue);
        expect(result.metadata, isNotNull);
        expect(result.metadata!.prompt, equals(rawPrompt));
        expect(result.metadata!.negativePrompt, equals(rawNegative));
        expect(result.metadata!.source, equals(rawSource));
        expect(result.metadata!.seed, equals(rawComment['seed']));
      },
    );

    test(
      'should not add app character captions to embedded png metadata',
      () async {
        final png = img.Image(width: 2, height: 2);
        img.fill(png, color: img.ColorRgb8(0, 255, 0));
        var bytes = Uint8List.fromList(img.encodePng(png));

        const rawPrompt = '1girl, living room';
        const rawNegative = 'bad hands';
        const rawSource = 'NovelAI Diffusion V4.5 4BDE2A90';
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Comment',
          '{"prompt":"$rawPrompt","uc":"$rawNegative","seed":123,"width":2,"height":2}',
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Description',
          rawPrompt,
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Software',
          'NovelAI',
        );
        bytes = UnifiedMetadataParser.embedTextChunkOnly(
          bytes,
          'Source',
          rawSource,
        );

        final tempDir = await Directory.systemTemp.createTemp(
          'image_save_utils_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final savedFile = await ImageSaveUtils.saveImageWithMetadata(
          imageBytes: bytes,
          filePath: '${tempDir.path}/saved_with_characters.png',
          params: const ImageParams(
            prompt: 'different prompt',
            negativePrompt: 'different negative',
            model: ImageModels.animeDiffusionV45Full,
          ),
          actualSeed: 456,
          charCaptions: const [
            {
              'char_caption': '1girl, rabbit girl, smug',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
            {
              'char_caption': '1boy, kneeling, despair',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ],
          charNegCaptions: const [
            {
              'char_caption': 'lowres',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
            {
              'char_caption': 'bad anatomy',
              'centers': [
                {'x': 0.5, 'y': 0.5},
              ],
            },
          ],
        );

        final result = UnifiedMetadataParser.parseFromPng(
          await savedFile.readAsBytes(),
        );

        expect(result.success, isTrue);
        expect(result.metadata, isNotNull);
        expect(result.metadata!.prompt, equals(rawPrompt));
        expect(result.metadata!.negativePrompt, equals(rawNegative));
        expect(result.metadata!.source, equals(rawSource));
        expect(result.metadata!.seed, equals(123));
        expect(result.metadata!.characterPrompts, isEmpty);
        expect(result.metadata!.characterNegativePrompts, isEmpty);
      },
    );
  });

  group('FilePickerUtils', () {
    test(
      'pickDirectoryModal locks the parent window for Windows dialogs',
      () async {
        String? capturedTitle;
        String? capturedInitialDirectory;
        bool? capturedLockParentWindow;

        final result = await FilePickerUtils.pickDirectoryModal(
          dialogTitle: '选择下载目录',
          initialDirectory: r'G:\Downloads',
          picker:
              ({
                String? dialogTitle,
                bool lockParentWindow = false,
                String? initialDirectory,
              }) async {
                capturedTitle = dialogTitle;
                capturedInitialDirectory = initialDirectory;
                capturedLockParentWindow = lockParentWindow;
                return r'G:\Downloads';
              },
        );

        expect(result, r'G:\Downloads');
        expect(capturedTitle, '选择下载目录');
        expect(capturedInitialDirectory, r'G:\Downloads');
        expect(capturedLockParentWindow, isTrue);
      },
    );
  });

  group('ImageSaveUtils.findIdenticalGalleryFile', () {
    final day = DateTime(2026, 8, 19);
    final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 251));

    Future<Directory> createDatedDir(Directory root) async {
      final dir = Directory('${root.path}/2026-08-19');
      await dir.create(recursive: true);
      return dir;
    }

    test('命中：同日目录存在同 seed 且字节一致的文件', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'find_identical_test_',
      );
      try {
        final dir = await createDatedDir(tempDir);
        await File('${dir.path}/22-59-55-12345.png').writeAsBytes(bytes);

        final found = await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: tempDir.path,
          bytes: bytes,
          seed: 12345,
          now: day,
        );
        expect(found, endsWith('22-59-55-12345.png'));
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });

    test('命中：冲突序号变体（-2）也能识别', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'find_identical_test_',
      );
      try {
        final dir = await createDatedDir(tempDir);
        await File('${dir.path}/22-59-55-12345-2.png').writeAsBytes(bytes);

        final found = await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: tempDir.path,
          bytes: bytes,
          seed: 12345,
          now: day,
        );
        expect(found, endsWith('22-59-55-12345-2.png'));
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });

    test('未命中：同 seed 但字节不同', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'find_identical_test_',
      );
      try {
        final dir = await createDatedDir(tempDir);
        final other = Uint8List.fromList(List.generate(1024, (i) => i % 250));
        await File('${dir.path}/22-59-55-12345.png').writeAsBytes(other);

        final found = await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: tempDir.path,
          bytes: bytes,
          seed: 12345,
          now: day,
        );
        expect(found, isNull);
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });

    test('未命中：seed 为 null 时不做猜测', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'find_identical_test_',
      );
      try {
        final dir = await createDatedDir(tempDir);
        await File('${dir.path}/22-59-55-12345.png').writeAsBytes(bytes);

        final found = await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: tempDir.path,
          bytes: bytes,
          seed: null,
          now: day,
        );
        expect(found, isNull);
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });

    test('未命中：不误匹配前缀部分重叠的 seed', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'find_identical_test_',
      );
      try {
        final dir = await createDatedDir(tempDir);
        // seed=12345 不应命中 "...-912345.png"
        await File('${dir.path}/22-59-55-912345.png').writeAsBytes(bytes);

        final found = await ImageSaveUtils.findIdenticalGalleryFile(
          rootPath: tempDir.path,
          bytes: bytes,
          seed: 12345,
          now: day,
        );
        expect(found, isNull);
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });
  });
}
