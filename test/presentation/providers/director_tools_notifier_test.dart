import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/history_batch.dart';

class _Api extends Mock implements NAIImageEnhancementApiService {}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(prompt: 'unrelated draft');
}

Uint8List _png(int width) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: 16)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(Uint8List(0)));
  late ProviderContainer container;
  late _Api api;
  setUp(() {
    api = _Api();
    container = ProviderContainer(
      overrides: [
        naiImageEnhancementApiServiceProvider.overrideWithValue(api),
        imageGenerationNotifierProvider.overrideWith(_Generation.new),
        generationParamsNotifierProvider.overrideWith(_Params.new),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'all 24 website emotions retain their request values and extra prompt',
    () async {
      // Current official menu order and enum values, verified in browser and
      // public component 266 on 2026-10-05; see the Director UI audit.
      const moods = [
        'neutral',
        'happy',
        'sad',
        'angry',
        'scared',
        'surprised',
        'tired',
        'excited',
        'nervous',
        'thinking',
        'confused',
        'shy',
        'disgusted',
        'smug',
        'bored',
        'laughing',
        'irritated',
        'aroused',
        'embarrassed',
        'worried',
        'love',
        'determined',
        'hurt',
        'playful',
      ];
      expect(emotionPresets.map((p) => p.mood).toList(), moods);
      final source = _png(24);
      final controller = container.read(directorToolsNotifierProvider.notifier);
      controller.addSource(source);
      controller.selectTool(DirectorToolType.fixEmotion);
      controller.updateDefry(5);
      controller.updatePrompt('extra guidance');
      for (final mood in moods) {
        when(
          () => api.augmentImages(
            source,
            reqType: 'emotion',
            prompt: '$mood;;extra guidance',
            defry: 5,
          ),
        ).thenAnswer((_) async => [_png(16)]);
        controller.updateEmotion(mood);
        await controller.runTool();
        verify(
          () => api.augmentImages(
            source,
            reqType: 'emotion',
            prompt: '$mood;;extra guidance',
            defry: 5,
          ),
        ).called(1);
        expect(container.read(directorToolsNotifierProvider).error, isNull);
      }
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'unrelated draft',
      );
    },
  );

  test(
    'queue deduplicates, removes and reuses results; requests lock source and settings',
    () async {
      final source = _png(24);
      final other = _png(32);
      final outputs = [_png(8), _png(12), _png(16)];
      final pending = Completer<List<Uint8List>>();
      when(
        () => api.augmentImages(
          source,
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).thenAnswer((_) => pending.future);
      final controller = container.read(directorToolsNotifierProvider.notifier);
      controller.addSource(source);
      controller.addSource(Uint8List.fromList(source));
      expect(
        container.read(directorToolsNotifierProvider).sources,
        hasLength(1),
      );
      final task = controller.runTool();
      controller.addSource(other);
      controller.selectTool(DirectorToolType.colorize);
      controller.updatePrompt('late edit');
      await controller.runTool();
      expect(
        container.read(directorToolsNotifierProvider).sourceImage,
        same(source),
      );
      pending.complete(outputs);
      await task;
      final state = container.read(directorToolsNotifierProvider);
      expect(state.isRunning, isFalse);
      expect(state.error, isNull);
      expect(state.resultVariants, hasLength(3));
      expect(
        state.resultVariants.map((i) => i.operation),
        everyElement(ImageOperation.removeBackground),
      );
      expect(
        state.resultVariants.map((i) => i.originalBytes),
        everyElement(same(source)),
      );
      final history = buildHistoryBatches(
        container.read(imageGenerationNotifierProvider),
      );
      expect(history, hasLength(1));
      expect(history.single.count, 3);
      expect(history.single.cover!.bytes, outputs.first);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'unrelated draft',
      );
      controller.selectVariant(2);
      controller.applyResultAsSource();
      expect(
        container.read(directorToolsNotifierProvider).sourceImage,
        outputs[2],
      );
      expect(container.read(directorToolsNotifierProvider).result, isNull);
      controller.selectRun(0);
      expect(
        container.read(directorToolsNotifierProvider).sourceImage,
        same(source),
      );
      verify(
        () => api.augmentImages(
          source,
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).called(1);
    },
  );

  test(
    'tool options are independent and failures leave the source available',
    () async {
      final controller = container.read(directorToolsNotifierProvider.notifier);
      controller.addSource(_png(32));
      controller.selectTool(DirectorToolType.colorize);
      controller.updatePrompt('red hair');
      controller.updateDefry(4);
      controller.selectTool(DirectorToolType.fixEmotion);
      controller.updatePrompt('blue eyes');
      controller.updateDefry(2);
      controller.selectTool(DirectorToolType.colorize);
      expect(container.read(directorToolsNotifierProvider).prompt, 'red hair');
      expect(container.read(directorToolsNotifierProvider).defry, 4);
      when(
        () => api.augmentImages(
          any(),
          reqType: 'colorize',
          prompt: 'red hair',
          defry: 4,
        ),
      ).thenThrow(StateError('offline fixture error'));
      await controller.runTool();
      final state = container.read(directorToolsNotifierProvider);
      expect(state.error, contains('offline fixture error'));
      expect(state.canRun, isTrue);
      expect(state.runs, isEmpty);
    },
  );

  test(
    'Pixel Snap runs locally without accessing the billing service',
    () async {
      final controller = container.read(directorToolsNotifierProvider.notifier);
      final image = img.Image(width: 128, height: 96);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final a = x ~/ 8,
              b = y ~/ 8,
              cell = (a * 13 + b * 7 + a * b * 3) % 11;
          image.setPixelRgb(
            x,
            y,
            (cell * 53 + 15) % 256,
            (cell * 83 + 71) % 256,
            (cell * 37 + 129) % 256,
          );
        }
      }
      controller.addSource(Uint8List.fromList(img.encodePng(image)));
      controller.selectTool(DirectorToolType.pixelSnap);
      expect(
        container.read(directorToolsNotifierProvider).estimatedAnlasCost(),
        0,
      );
      await controller.runTool();
      expect(container.read(directorToolsNotifierProvider).error, isNull);
      expect(
        container.read(directorToolsNotifierProvider).selectedResult?.operation,
        ImageOperation.pixelSnap,
      );
      verifyZeroInteractions(api);
    },
  );
}
