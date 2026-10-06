import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/contiguous_region_selector.dart';
import 'package:nai_launcher/data/services/efficient_vit_sam_model_manager.dart';
import 'package:nai_launcher/data/services/efficient_vit_sam_service.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/tool_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final runSmokeTest = Platform.environment['EFFICIENT_VIT_SAM_SMOKE'] == '1';
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final inpaint in [false, true]) {
    test('editor inpaint=$inpaint excludes the retired SAM tool', () async {
      final tools = ToolManager(inpaint: inpaint);
      addTearDown(tools.dispose);
      await tools.settingsManager.load();
      expect(tools.tools, hasLength(inpaint ? 4 : 8));
      expect(tools.getToolById('magic_wand'), isNull);
      tools.setToolById('magic_wand');
      expect(tools.currentTool!.id, 'brush');
    });
  }

  if (runSmokeTest) {
    test(
      'manual legacy EfficientViT-SAM audit with cached ONNX models',
      () async {
        final modelDirectory = Directory(
          Platform.environment['EFFICIENT_VIT_SAM_MODEL_DIR'] ??
              '${Directory.systemTemp.path}${Platform.pathSeparator}'
                  'nai_launcher_efficientvit_sam_poc',
        );
        final manager = EfficientVitSamModelManager(
          directoryResolver: () async => modelDirectory,
          download: (_, _, _) async => throw StateError(
            'Legacy SAM audit requires cached models; downloads are disabled',
          ),
        );
        final service = EfficientVitSamService(modelManager: manager);
        final scene = _buildSyntheticScene();

        // ignore: avoid_print
        print('model_dir=${modelDirectory.path}');
        // ignore: avoid_print
        print('model_revision=${EfficientVitSamModelManager.modelRevision}');
        try {
          final circle = await _runSelection(
            service: service,
            scene: scene,
            pointX: 200,
            pointY: 192,
            name: 'circle',
            modelDirectory: modelDirectory,
          );
          final rectangle = await _runSelection(
            service: service,
            scene: scene,
            pointX: 480,
            pointY: 192,
            name: 'rectangle',
            modelDirectory: modelDirectory,
          );

          expect(circle.selectedPixelCount, greaterThan(0));
          expect(rectangle.selectedPixelCount, greaterThan(0));
          expect(circle.mask, isNot(orderedEquals(rectangle.mask)));
        } finally {
          service.dispose();
        }
      },
    );
  }
}

Future<ContiguousRegionSelection> _runSelection({
  required EfficientVitSamService service,
  required _SyntheticScene scene,
  required int pointX,
  required int pointY,
  required String name,
  required Directory modelDirectory,
}) async {
  final stopwatch = Stopwatch()..start();
  EfficientVitSamProgressStage? lastStage;
  var lastDownloadBucket = -1;
  final selection = await service.selectRgba(
    rgba: scene.rgba,
    width: scene.width,
    height: scene.height,
    startX: pointX,
    startY: pointY,
    invert: false,
    onProgress: (progress) {
      final wholePercent = ((progress.fraction ?? -1) * 100).floor();
      final downloadBucket = wholePercent ~/ 10;
      if (progress.stage != lastStage ||
          progress.stage == EfficientVitSamProgressStage.downloadingModels &&
              downloadBucket != lastDownloadBucket) {
        final suffix = progress.fraction == null
            ? ''
            : ' ${(progress.fraction! * 100).toStringAsFixed(1)}%';
        // ignore: avoid_print
        print('stage=${progress.stage.name}$suffix');
        lastStage = progress.stage;
        lastDownloadBucket = downloadBucket;
      }
    },
  );
  stopwatch.stop();

  final output = File(
    '${modelDirectory.path}${Platform.pathSeparator}smoke_mask_$name.png',
  );
  await output.writeAsBytes(img.encodePng(_renderMask(selection)), flush: true);
  final coverage =
      selection.selectedPixelCount / (scene.width * scene.height) * 100;
  // ignore: avoid_print
  print(
    'selection=$name elapsed_ms=${stopwatch.elapsedMilliseconds} '
    'pixels=${selection.selectedPixelCount} '
    'coverage=${coverage.toStringAsFixed(2)}% mask=${output.path}',
  );
  return selection;
}

_SyntheticScene _buildSyntheticScene() {
  const width = 640;
  const height = 384;
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final offset = (y * width + x) * 4;
      var red = 238;
      var green = 235;
      var blue = 222;
      final circleDistance = math.sqrt(
        math.pow(x - 200, 2) + math.pow(y - 192, 2),
      );
      if (circleDistance <= 120) {
        red = 217;
        green = 58;
        blue = 54;
      } else if (x >= 400 && x <= 560 && y >= 80 && y <= 304) {
        red = 45;
        green = 91;
        blue = 190;
      }
      rgba[offset] = red;
      rgba[offset + 1] = green;
      rgba[offset + 2] = blue;
      rgba[offset + 3] = 255;
    }
  }
  return _SyntheticScene(rgba: rgba, width: width, height: height);
}

img.Image _renderMask(ContiguousRegionSelection selection) {
  final rgba = Uint8List(selection.width * selection.height * 4);
  for (var index = 0; index < selection.mask.length; index++) {
    final value = selection.mask[index] == 1 ? 255 : 0;
    final offset = index * 4;
    rgba[offset] = value;
    rgba[offset + 1] = value;
    rgba[offset + 2] = value;
    rgba[offset + 3] = 255;
  }
  return img.Image.fromBytes(
    width: selection.width,
    height: selection.height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

class _SyntheticScene {
  const _SyntheticScene({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba;
  final int width;
  final int height;
}
