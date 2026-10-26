import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/metadata/cache_manager.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

import '../../../helpers/app_logger_test_isolation.dart';

Map<String, dynamic> node(String type, Map<String, dynamic> inputs) => {
  'class_type': type,
  'inputs': inputs,
};
Map<String, dynamic> graph() => {
  '1': node('CLIPTextEncode', {'text': 'excluded fixture'}),
  '2': node('CLIPTextEncode', {'text': 'desired fixture'}),
  '3': node('KSampler', {
    'positive': ['2', 0],
    'negative': ['1', 0],
    'sampler_name': 'euler',
    'steps': 20,
    'cfg': 6.5,
    'seed': 42,
  }),
};
NaiImageMetadata? parse(Map<String, dynamic> nodes) {
  final png = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 8, height: 8, textData: {'prompt': jsonEncode(nodes)}),
    ),
  );
  return UnifiedMetadataParser.parseFromImageBytes(png).metadata;
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  test(
    'generic literal prompt and structured prompt fields remain readable',
    () {
      for (final value in ['plain fixture', '{"prompt":"plain fixture"}']) {
        expect(
          UnifiedMetadataParser.parseFromTextData({
            'prompt': value,
          }).metadata!.prompt,
          'plain fixture',
        );
      }
    },
  );
  for (final reversed in [false, true]) {
    test('positive and negative follow connections, reversed=$reversed', () {
      final nodes = graph();
      final result = parse(
        reversed ? Map.fromEntries(nodes.entries.toList().reversed) : nodes,
      )!;
      expect(result.prompt, 'desired fixture');
      expect(result.negativePrompt, 'excluded fixture');
      expect(result.seed, 42);
      expect(result.steps, 20);
      expect(result.sampler, 'euler');
      expect(result.scale, 6.5);
      expect(jsonDecode(result.rawJson!), nodes);
    });
  }
  test('unconnected encoders and samplers cannot override saved output', () {
    final nodes = graph()
      ..['4'] = node('CLIPTextEncode', {'text': 'unrelated fixture'})
      ..['5'] = node('KSampler', {
        'positive': ['4', 0],
        'negative': ['1', 0],
        'seed': 999,
      })
      ..['6'] = node('VAEDecode', {
        'samples': ['3', 0],
      })
      ..['7'] = node('SaveImage', {
        'images': ['6', 0],
      });
    final result = parse(nodes)!;
    expect(result.prompt, 'desired fixture');
    expect(result.negativePrompt, 'excluded fixture');
    expect(result.seed, 42);
  });
  test('saved refinement uses nearest sampler and keeps its parameter set', () {
    final nodes = graph()
      ..['4'] = node('CLIPTextEncode', {'text': 'refined fixture'})
      ..['5'] = node('KSamplerAdvanced', {
        'positive': ['4', 0],
        'negative': ['1', 0],
        'latent_image': ['3', 0],
        'noise_seed': 123,
        'steps': 12,
        'cfg': 4.0,
        'sampler_name': 'dpmpp_2m',
      })
      ..['6'] = node('VAEDecode', {
        'samples': ['5', 0],
      })
      ..['7'] = node('SaveImage', {
        'images': ['6', 0],
      })
      ..['8'] = node('VAEDecode', {
        'samples': ['3', 0],
      })
      ..['9'] = node('PreviewImage', {
        'images': ['8', 0],
      });
    final result = parse(nodes)!;
    expect(result.prompt, 'refined fixture');
    expect(result.seed, 123);
    expect(result.steps, 12);
    expect(result.scale, 4.0);
    expect(result.sampler, 'dpmpp_2m');
  });
  test('combined conditioning includes only connected branches', () {
    final nodes = graph()
      ..['4'] = node('CLIPTextEncode', {'text': 'style fixture'})
      ..['5'] = node('ConditioningCombine', {
        'conditioning_2': ['4', 0],
        'conditioning_1': ['2', 0],
      })
      ..['6'] = node('ConditioningSetArea', {
        'conditioning': ['5', 0],
        'width': 512,
        'height': 512,
      });
    nodes['3']['inputs']['positive'] = ['6', 0];
    final result = parse(nodes)!;
    expect(result.prompt, 'desired fixture, style fixture');
    expect(result.negativePrompt, 'excluded fixture');
  });
  test('multi-output conditioning keeps the requested output polarity', () {
    final nodes = graph()
      ..['4'] = node('ControlNetApplyAdvanced', {
        'positive': ['2', 0],
        'negative': ['1', 0],
      });
    nodes['3']['inputs']['positive'] = ['4', 0];
    nodes['3']['inputs']['negative'] = ['4', 1];
    expect(parse(nodes)!.prompt, 'desired fixture');
    expect(parse(nodes)!.negativePrompt, 'excluded fixture');
  });
  test(
    'SDXL text channels are connected and equal channels are not duplicated',
    () {
      final nodes = graph();
      nodes['2'] = node('CLIPTextEncodeSDXL', {
        'text_l': 'local fixture',
        'text_g': 'global fixture',
      });
      nodes['1'] = node('CLIPTextEncodeSDXL', {
        'text_l': 'excluded fixture',
        'text_g': 'excluded fixture',
      });
      expect(parse(nodes)!.prompt, 'global fixture, local fixture');
      expect(parse(nodes)!.negativePrompt, 'excluded fixture');
    },
  );
  test('zeroed conditioning contributes no stale text', () {
    final nodes = graph()
      ..['4'] = node('ConditioningZeroOut', {
        'conditioning': ['1', 0],
      });
    nodes['3']['inputs']['negative'] = ['4', 0];
    expect(parse(nodes)!.negativePrompt, isEmpty);
  });
  test('empty positive remains a valid connected prompt', () {
    final nodes = graph();
    nodes['2']['inputs']['text'] = '';
    expect(parse(nodes)!.prompt, isEmpty);
    expect(parse(nodes)!.negativePrompt, 'excluded fixture');
  });
  test('multiple save nodes sharing one sampler are unambiguous', () {
    final nodes = graph()
      ..['4'] = node('VAEDecode', {
        'samples': ['3', 0],
      })
      ..['5'] = node('SaveImage', {
        'images': ['4', 0],
      })
      ..['6'] = node('SaveImage', {
        'images': ['4', 0],
      });
    expect(parse(nodes)!.prompt, 'desired fixture');
  });
  for (final withOutputs in [false, true]) {
    test(
      'distinct sampler branches are explicitly ambiguous, outputs=$withOutputs',
      () {
        final nodes = graph()
          ..['4'] = node('KSampler', {
            'positive': ['1', 0],
            'negative': ['2', 0],
          });
        if (withOutputs) {
          nodes['5'] = node('VAEDecode', {
            'samples': ['3', 0],
          });
          nodes['6'] = node('VAEDecode', {
            'samples': ['4', 0],
          });
          nodes['7'] = node('SaveImage', {
            'images': ['5', 0],
          });
          nodes['8'] = node('SaveImage', {
            'images': ['6', 0],
          });
        }
        expect(parse(nodes), isNull);
      },
    );
  }
  for (final type in ['missing', 'cycle', 'unsupported']) {
    test('$type conditioning cannot fall back to unrelated encoder order', () {
      final nodes = graph();
      nodes['3']['inputs']['positive'] = ['4', 0];
      if (type != 'missing') {
        nodes['4'] = node(
          type == 'cycle' ? 'ConditioningCombine' : 'UnknownConditioner',
          {
            'conditioning_1': [type == 'cycle' ? '4' : '2', 0],
            'conditioning_2': ['2', 0],
          },
        );
      }
      expect(parse(nodes), isNull);
    });
  }
  test(
    'version 6 parsed snapshots are invalidated before corrected graph parsing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'comfy_cache_version_',
      );
      final cache = MetadataCacheManager();
      try {
        Hive.init(directory.path);
        final box = await Hive.openBox<String>(
          StorageKeys.localMetadataCacheBox,
        );
        await box.put('_cacheVersion', '6');
        await box.put(
          'old-comfy-hash',
          jsonEncode(
            const NaiImageMetadata(prompt: 'wrong old positive').toJson(),
          ),
        );
        await cache.initialize();
        expect(cache.getFromPersistent('old-comfy-hash'), isNull);
        expect(int.parse(box.get('_cacheVersion')!), greaterThan(6));
        await cache.save('new-comfy-hash', parse(graph())!);
        expect(
          cache.getFromPersistent('new-comfy-hash')!.prompt,
          'desired fixture',
        );
      } finally {
        await cache.clear();
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
