import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import '../image_generation_provider_test.dart'
    show MockNAIImageGenerationApiService, TestSubscriptionNotifier;

class _NoSave extends ImageSaveSettingsNotifier {
  @override
  ImageSaveSettings build() => const ImageSaveSettings(autoSave: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    registerFallbackValue(const ImageParams());
    directory = await Directory.systemTemp.createTemp('old-request-snapshot-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'inflight inpaint retains its source and mask even if input buffers change',
    () async {
      final api = MockNAIImageGenerationApiService();
      final arrived = Completer<ImageParams>();
      final stream = StreamController<ImageStreamChunk>();
      when(() => api.cancelGeneration()).thenReturn(null);
      when(() => api.generateImageStream(any())).thenAnswer((call) {
        arrived.complete(call.positionalArguments.single as ImageParams);
        return stream.stream;
      });
      final container = ProviderContainer(
        overrides: [
          naiImageGenerationApiServiceProvider.overrideWithValue(api),
          subscriptionNotifierProvider.overrideWith(
            TestSubscriptionNotifier.new,
          ),
          imageSaveSettingsNotifierProvider.overrideWith(_NoSave.new),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(notificationSettingsNotifierProvider.notifier)
          .setSoundEnabled(false);
      final source = Uint8List.fromList(
        img.encodePng(img.Image(width: 64, height: 96)),
      );
      final mask = Uint8List.fromList(
        img.encodePng(
          img.Image(width: 64, height: 96)..clear(img.ColorRgb8(255, 255, 255)),
        ),
      );
      final expectedSource = Uint8List.fromList(source);
      final expectedMask = Uint8List.fromList(mask);
      final work = container
          .read(imageGenerationNotifierProvider.notifier)
          .generateSourceImage(
            ImageParams(
              prompt: 'comparison test',
              action: ImageGenerationAction.infill,
              sourceImage: source,
              maskImage: mask,
              width: 64,
              height: 96,
            ),
            operation: ImageOperation.inpaint,
          );
      final sent = await arrived.future.timeout(const Duration(seconds: 5));
      source[0] = 99;
      mask[0] = 99;
      stream.add(ImageStreamChunk.complete(expectedSource));
      await stream.close();
      await work;
      final result = container
          .read(imageGenerationNotifierProvider)
          .currentImages
          .single;
      expect(sent.sourceImage, orderedEquals(expectedSource));
      expect(sent.maskImage, orderedEquals(expectedMask));
      expect(result.originalBytes, orderedEquals(expectedSource));
      expect(result.inpaintMaskBytes, orderedEquals(expectedMask));
      expect(result.canCompareOriginal, isTrue);
    },
  );
}
