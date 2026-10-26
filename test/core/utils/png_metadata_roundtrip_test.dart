import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

typedef PngChunk = ({String type, Uint8List data});
List<PngChunk> chunks(Uint8List bytes) {
  final result = <PngChunk>[];
  for (var offset = 8; offset + 12 <= bytes.length;) {
    final size = ByteData.sublistView(bytes, offset).getUint32(0);
    result.add((
      type: ascii.decode(bytes.sublist(offset + 4, offset + 8)),
      data: Uint8List.sublistView(bytes, offset + 8, offset + 8 + size),
    ));
    offset += size + 12;
  }
  return result;
}

Uint8List chunk(String type, List<int> data) {
  final body = [...ascii.encode(type), ...data];
  return Uint8List.fromList([
    ...(ByteData(4)..setUint32(0, data.length)).buffer.asUint8List(),
    ...body,
    ...(ByteData(4)..setUint32(0, getCrc32(body))).buffer.asUint8List(),
  ]);
}

bool textChunk(PngChunk item) => ['tEXt', 'iTXt', 'zTXt'].contains(item.type);
String keyword(PngChunk item) =>
    latin1.decode(item.data.sublist(0, item.data.indexOf(0)));
String text(PngChunk item) {
  var offset = item.data.indexOf(0) + 1;
  if (item.type == 'tEXt') return latin1.decode(item.data.sublist(offset));
  if (item.type == 'zTXt') {
    return latin1.decode(zlib.decode(item.data.sublist(offset + 1)));
  }
  final compressed = item.data[offset] == 1;
  offset += 2;
  for (var i = 0; i < 2; i++) {
    offset = item.data.indexOf(0, offset) + 1;
  }
  final bytes = item.data.sublist(offset);
  return utf8.decode(compressed ? zlib.decode(bytes) : bytes);
}

Map<String, String> textData(Uint8List bytes) => {
  for (final item in chunks(bytes).where(textChunk)) keyword(item): text(item),
};
Uint8List comment(String kind, String value) {
  final key = [...ascii.encode('Comment'), 0];
  return switch (kind) {
    'tEXt' => chunk('tEXt', [...key, ...latin1.encode(value)]),
    'zTXt' => chunk('zTXt', [...key, 0, ...zlib.encode(latin1.encode(value))]),
    _ => chunk('iTXt', [
      ...key,
      kind == 'compressed iTXt' ? 1 : 0,
      0,
      0,
      0,
      ...(kind == 'compressed iTXt'
          ? zlib.encode(utf8.encode(value))
          : utf8.encode(value)),
    ]),
  };
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final plain = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 16, height: 16, textData: {'Author': 'preserved'}),
    ),
  );
  const updated = ImageParams(
    prompt: 'new fixture',
    negativePrompt: 'new negative',
    seed: 99,
    width: 16,
    height: 16,
  );
  List<List<int>> idat(Uint8List bytes) => [
    for (final item in chunks(bytes))
      if (item.type == 'IDAT') item.data,
  ];

  test(
    'Unicode prompts, negatives and character captions round trip without changing pixels',
    () async {
      const prompt = 'blue sky, 中文提示，ひらがな 🌙';
      const negative = '不要模糊，ぼやけ 🚫';
      final output = await ImageSaveUtils.rebuildImageBytesWithMetadata(
        imageBytes: plain,
        params: const ImageParams(
          model: ImageModels.animeDiffusionV45Full,
          prompt: prompt,
          negativePrompt: negative,
          width: 16,
          height: 16,
          seed: 42,
        ),
        charCaptions: const [
          {
            'char_caption': '角色甲 🙂',
            'centers': [
              {'x': 0.2, 'y': 0.8},
            ],
          },
        ],
        charNegCaptions: const [
          {'char_caption': '角色负面 🐾', 'centers': []},
        ],
      );
      final parsed = UnifiedMetadataParser.parseFromImageBytes(output);
      expect(parsed.success, isTrue);
      expect(parsed.metadata!.prompt, prompt);
      expect(parsed.metadata!.negativePrompt, negative);
      expect(parsed.metadata!.seed, 42);
      final raw = jsonDecode(parsed.metadata!.rawJson!) as Map;
      expect(
        raw['v4_prompt']['caption']['char_captions'][0]['char_caption'],
        '角色甲 🙂',
      );
      expect(
        raw['v4_negative_prompt']['caption']['char_captions'][0]['char_caption'],
        '角色负面 🐾',
      );
      expect(idat(output), idat(plain));
      expect(
        img.decodePng(output)!.getBytes(),
        img.decodePng(plain)!.getBytes(),
      );
      expect(
        await ImageSaveUtils.rebuildImageBytesWithMetadata(
          imageBytes: output,
          params: updated,
          preserveExistingNovelAiMetadata: true,
        ),
        same(output),
      );
    },
  );
  test(
    'Unicode headers and a distinct description survive source inheritance',
    () async {
      final source = await ImageSaveUtils.buildPrebuiltMetadataBytes(
        imageBytes: plain,
        metadata: {
          'Description': '单独描述 🌙',
          'Software': 'NovelAI 软件',
          'Source': 'NovelAI 来源',
          'Comment': {'prompt': 'original prompt', 'seed': 42},
        },
      );
      expect(textData(source)['Description'], '单独描述 🌙');
      expect(textData(source)['Software'], 'NovelAI 软件');
      final output = await ImageSaveUtils.inheritSourceMetadata(
        imageBytes: plain,
        sourceBytes: source,
        width: 16,
        height: 16,
      );
      expect(textData(output)['Description'], '单独描述 🌙');
      final parsed = UnifiedMetadataParser.parseFromImageBytes(
        output,
      ).metadata!;
      expect(parsed.software, 'NovelAI 软件');
      expect(parsed.source, 'NovelAI 来源');
    },
  );
  test('Latin1 values retain classic tEXt compatibility', () {
    final output = UnifiedMetadataParser.embedTextChunkOnly(
      plain,
      'Comment',
      jsonEncode({'prompt': 'café déjà vu', 'seed': 42}),
    );
    expect(
      chunks(
        output,
      ).where((c) => textChunk(c) && keyword(c) == 'Comment').single.type,
      'tEXt',
    );
    expect(
      UnifiedMetadataParser.parseFromImageBytes(output).metadata!.prompt,
      'café déjà vu',
    );
  });

  for (final kind in ['tEXt', 'iTXt', 'compressed iTXt', 'zTXt']) {
    for (final beforeIdat in [false, true]) {
      test(
        'replaces $kind Comment beforeIDAT=$beforeIdat with exactly one current value',
        () async {
          final builder = BytesBuilder()..add(plain.sublist(0, 8));
          for (final item in chunks(plain)) {
            if (item.type == (beforeIdat ? 'IDAT' : 'IEND')) {
              builder.add(
                comment(
                  kind,
                  jsonEncode({
                    'prompt': 'old fixture',
                    'seed': 1,
                    'keep': [1, 2],
                  }),
                ),
              );
            }
            if (item.type == 'IEND') builder.add(chunk('npTc', [1, 2, 3]));
            builder.add(chunk(item.type, item.data));
          }
          final source = builder.toBytes();
          expect(img.decodePng(source), isNotNull);
          final output = await ImageSaveUtils.rebuildImageBytesWithMetadata(
            imageBytes: source,
            params: updated,
            actualSeed: 99,
          );
          final parsed = UnifiedMetadataParser.parseFromImageBytes(
            output,
          ).metadata!;
          expect(parsed.prompt, 'new fixture');
          expect(parsed.seed, 99);
          expect(
            chunks(
              output,
            ).where((c) => textChunk(c) && keyword(c) == 'Comment'),
            hasLength(1),
          );
          expect(jsonDecode(parsed.rawJson!)['keep'], [1, 2]);
          expect(textData(output)['Author'], 'preserved');
          expect(chunks(output).singleWhere((c) => c.type == 'npTc').data, [
            1,
            2,
            3,
          ]);
          expect(idat(output), idat(source));
        },
      );
    }
  }
  test('mixed duplicate Comment chunks are all removed', () {
    final builder = BytesBuilder()..add(plain.sublist(0, 8));
    for (final item in chunks(plain)) {
      if (item.type == 'IDAT' || item.type == 'IEND') {
        for (final kind in ['tEXt', 'iTXt', 'zTXt']) {
          builder.add(comment(kind, '{"prompt":"obsolete"}'));
        }
      }
      builder.add(chunk(item.type, item.data));
    }
    final output = UnifiedMetadataParser.embedTextChunkOnly(
      builder.toBytes(),
      'Comment',
      '{"prompt":"current","seed":99}',
    );
    expect(
      chunks(output).where((c) => textChunk(c) && keyword(c) == 'Comment'),
      hasLength(1),
    );
    expect(
      UnifiedMetadataParser.parseFromImageBytes(output).metadata!.prompt,
      'current',
    );
  });
  for (final compressed in [false, true]) {
    test('Unicode iTXt input parses with compression=$compressed', () {
      final value = jsonEncode({'prompt': '中文，ひらがな 🌙', 'seed': 42});
      final embedded = Uint8List.fromList([
        ...plain.take(33),
        ...comment(compressed ? 'compressed iTXt' : 'iTXt', value),
        ...plain.skip(33),
      ]);
      expect(
        UnifiedMetadataParser.parseFromImageBytes(embedded).metadata!.prompt,
        '中文，ひらがな 🌙',
      );
    });
  }
  test('mixed text formats follow file order and support a partial prefix', () {
    final prefix = Uint8List.fromList([
      ...plain.take(33),
      ...comment('iTXt', '{"prompt":"first"}'),
      ...comment('tEXt', '{"prompt":"second"}'),
      ...comment('zTXt', '{"prompt":"last"}'),
    ]);
    expect(
      UnifiedMetadataParser.extractPngTextData(prefix)['Comment'],
      '{"prompt":"last"}',
    );
    final complete = Uint8List.fromList([...prefix, ...plain.skip(33)]);
    expect(
      UnifiedMetadataParser.parseFromImageBytes(complete).metadata!.prompt,
      'last',
    );
  });
  test('stealth mode shares the Unicode text writer', () async {
    final image = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 64)),
    );
    final output = await UnifiedMetadataParser.embedMetadata(
      image,
      '{"prompt":"中文 🌙","seed":42}',
      useStealth: true,
    );
    expect(textData(output)['Comment'], '{"prompt":"中文 🌙","seed":42}');
    expect(
      UnifiedMetadataParser.parseFromImageBytes(output).metadata!.prompt,
      '中文 🌙',
    );
  });
  test(
    'invalid or incomplete PNG cannot report a successful metadata write',
    () {
      for (final broken in [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.sublistView(plain, 0, 33),
      ]) {
        expect(
          () => UnifiedMetadataParser.embedTextChunkOnly(
            broken,
            'Comment',
            '{"prompt":"fixture"}',
          ),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'failed metadata embedding does not replace an existing output file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'png_metadata_write_',
      );
      final file = File(p.join(directory.path, 'output.png'));
      try {
        await file.writeAsString('existing fixture');
        await expectLater(
          ImageSaveUtils.saveImageWithMetadata(
            imageBytes: Uint8List.fromList([1, 2, 3]),
            filePath: file.path,
            params: updated,
            actualSeed: 99,
          ),
          throwsFormatException,
        );
        expect(await file.readAsString(), 'existing fixture');
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
