import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/anlas_calculator.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../data/datasources/remote/nai_image_enhancement_api_service.dart';
import '../../data/models/director/director_tool_type.dart';
import '../../data/services/director/pixel_snap_service.dart';
import 'image_generation_provider.dart';
import 'subscription_provider.dart';

class EmotionPreset {
  const EmotionPreset(this.label, this.mood, [this.extraTags = '']);
  final String label;
  final String mood;
  final String extraTags;
}

const emotionPresets = [
  EmotionPreset('Neutral', 'neutral'),
  EmotionPreset('Happy', 'happy', 'smile'),
  EmotionPreset('Sad', 'sad', 'crying'),
  EmotionPreset('Angry', 'angry', 'furrowed brow'),
  EmotionPreset('Scared', 'scared'),
  EmotionPreset('Surprised', 'surprised', 'open mouth, wide eyes'),
  EmotionPreset('Tired', 'tired'),
  EmotionPreset('Excited', 'excited'),
  EmotionPreset('Nervous', 'nervous'),
  EmotionPreset('Thinking', 'thinking'),
  EmotionPreset('Confused', 'confused'),
  EmotionPreset('Shy', 'shy', 'blush, embarrassed, looking away'),
  EmotionPreset('Disgusted', 'disgusted'),
  EmotionPreset('Smug', 'smug', 'half-closed eyes'),
  EmotionPreset('Bored', 'bored'),
  EmotionPreset('Laugh', 'laughing', 'open mouth'),
  EmotionPreset('Irritated', 'irritated'),
  EmotionPreset('Aroused', 'aroused'),
  EmotionPreset('Embarrassed', 'embarrassed'),
  EmotionPreset('Worried', 'worried'),
  EmotionPreset('Love', 'love', 'heart'),
  EmotionPreset('Determined', 'determined'),
  EmotionPreset('Hurt', 'hurt'),
  EmotionPreset('Playful', 'playful', 'wink'),
];

class DirectorSource {
  const DirectorSource({
    required this.id,
    required this.bytes,
    required this.width,
    required this.height,
  });
  final String id;
  final Uint8List bytes;
  final int width;
  final int height;
}

class DirectorResultRun {
  const DirectorResultRun({
    required this.source,
    required this.tool,
    required this.images,
    required this.prompt,
    required this.defry,
    required this.emotion,
    required this.pixelOptions,
    this.cost,
  });
  final DirectorSource source;
  final DirectorToolType tool;
  final List<GeneratedImage> images;
  final String prompt;
  final int defry;
  final String emotion;
  final PixelSnapOptions pixelOptions;
  final int? cost;
}

class DirectorToolsState {
  const DirectorToolsState({
    this.selectedTool = DirectorToolType.removeBackground,
    this.defry = 0,
    this.prompt = '',
    this.emotion = 'neutral',
    this.isRunning = false,
    this.error,
    this.sources = const [],
    this.sourceIndex = 0,
    this.runs = const [],
    this.selectedRunIndex,
    this.variantIndex = 0,
    this.pixelOptions = const PixelSnapOptions(),
  });
  final DirectorToolType selectedTool;
  final int defry;
  final String prompt;
  final String emotion;
  final bool isRunning;
  final String? error;
  final List<DirectorSource> sources;
  final int sourceIndex;
  final List<DirectorResultRun> runs;
  final int? selectedRunIndex;
  final int variantIndex;
  final PixelSnapOptions pixelOptions;
  DirectorSource? get source => sources.isEmpty
      ? null
      : sources[sourceIndex.clamp(0, sources.length - 1)];
  Uint8List? get sourceImage => source?.bytes;
  int get imageWidth => source?.width ?? 0;
  int get imageHeight => source?.height ?? 0;
  DirectorResultRun? get selectedRun =>
      selectedRunIndex == null || selectedRunIndex! >= runs.length
      ? null
      : runs[selectedRunIndex!];
  List<GeneratedImage> get resultVariants => selectedRun?.images ?? const [];
  GeneratedImage? get selectedResult => resultVariants.isEmpty
      ? null
      : resultVariants[variantIndex.clamp(0, resultVariants.length - 1)];
  Uint8List? get result => selectedResult?.bytes;
  bool get canRun => !isRunning && source != null;

  int estimatedAnlasCost({bool isOpus = false}) {
    if (selectedTool == DirectorToolType.pixelSnap || source == null) return 0;
    return AnlasCalculator.calculateAugmentCost(
      width: imageWidth,
      height: imageHeight,
      isBgRemoval: selectedTool == DirectorToolType.removeBackground,
      isOpus: isOpus,
    );
  }

  DirectorToolsState copyWith({
    DirectorToolType? selectedTool,
    int? defry,
    String? prompt,
    String? emotion,
    bool? isRunning,
    String? error,
    List<DirectorSource>? sources,
    int? sourceIndex,
    List<DirectorResultRun>? runs,
    int? selectedRunIndex,
    int? variantIndex,
    PixelSnapOptions? pixelOptions,
    bool clearResult = false,
    bool clearError = false,
  }) => DirectorToolsState(
    selectedTool: selectedTool ?? this.selectedTool,
    defry: defry ?? this.defry,
    prompt: prompt ?? this.prompt,
    emotion: emotion ?? this.emotion,
    isRunning: isRunning ?? this.isRunning,
    error: clearError ? null : error ?? this.error,
    sources: sources ?? this.sources,
    sourceIndex: sourceIndex ?? this.sourceIndex,
    runs: runs ?? this.runs,
    selectedRunIndex: clearResult
        ? null
        : selectedRunIndex ?? this.selectedRunIndex,
    variantIndex: variantIndex ?? this.variantIndex,
    pixelOptions: pixelOptions ?? this.pixelOptions,
  );
}

final directorToolsNotifierProvider =
    NotifierProvider<DirectorToolsNotifier, DirectorToolsState>(
      DirectorToolsNotifier.new,
    );

/// Every request snapshots its input and settings. Returned images never acquire
/// the unrelated prompt currently typed in the generation sidebar.
class DirectorToolsNotifier extends Notifier<DirectorToolsState> {
  bool _disposed = false;
  final _toolSettings =
      <DirectorToolType, ({int defry, String prompt, String emotion})>{};
  @override
  DirectorToolsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const DirectorToolsState();
  }

  Future<void> init(Uint8List sourceImage, {String? initialPrompt}) async {
    if (state.isRunning) return;
    addSource(sourceImage);
    if (initialPrompt != null) updatePrompt(initialPrompt);
  }

  void addSource(Uint8List bytes) {
    if (state.isRunning) return;
    final existing = state.sources.indexWhere(
      (s) => identical(s.bytes, bytes) || listEquals(s.bytes, bytes),
    );
    if (existing >= 0) {
      selectSource(existing);
      return;
    }
    final size = NaiResolutionAdapter.readImageSize(bytes);
    if (size == null) throw const FormatException('Unsupported image');
    final source = DirectorSource(
      id: const Uuid().v4(),
      bytes: bytes,
      width: size.$1,
      height: size.$2,
    );
    state = state.copyWith(
      sources: [source, ...state.sources].take(64).toList(),
      sourceIndex: 0,
      clearResult: true,
      clearError: true,
      variantIndex: 0,
    );
  }

  void selectSource(int index) {
    if (state.isRunning || index < 0 || index >= state.sources.length) return;
    state = state.copyWith(
      sourceIndex: index,
      clearResult: true,
      clearError: true,
      variantIndex: 0,
    );
  }

  void removeSource(String id) {
    if (state.isRunning) return;
    final activeId = state.source?.id;
    final remaining = state.sources.where((s) => s.id != id).toList();
    final index = remaining.indexWhere((s) => s.id == activeId);
    state = state.copyWith(
      sources: remaining,
      sourceIndex: index < 0 ? 0 : index,
      clearResult: activeId == id,
      clearError: true,
    );
  }

  void selectTool(DirectorToolType tool) {
    if (state.isRunning || state.selectedTool == tool) return;
    _toolSettings[state.selectedTool] = (
      defry: state.defry,
      prompt: state.prompt,
      emotion: state.emotion,
    );
    final saved = _toolSettings[tool];
    state = state.copyWith(
      selectedTool: tool,
      defry: saved?.defry ?? 0,
      prompt: saved?.prompt ?? '',
      emotion: saved?.emotion ?? 'neutral',
      clearError: true,
    );
  }

  void updateDefry(int value) {
    if (!state.isRunning) state = state.copyWith(defry: value.clamp(0, 5));
  }

  void updatePrompt(String value) {
    if (!state.isRunning) state = state.copyWith(prompt: value);
  }

  void updateEmotion(String value) {
    if (!state.isRunning) state = state.copyWith(emotion: value);
  }

  void applyEmotionPreset(EmotionPreset preset) {
    if (!state.isRunning) {
      state = state.copyWith(emotion: preset.mood, prompt: preset.extraTags);
    }
  }

  EmotionPreset? get activePreset {
    for (final preset in emotionPresets) {
      if (preset.mood == state.emotion) return preset;
    }
    return null;
  }

  void updatePixelOptions(PixelSnapOptions options) {
    if (!state.isRunning) state = state.copyWith(pixelOptions: options);
  }

  void selectVariant(int index) {
    if (index >= 0 && index < state.resultVariants.length) {
      state = state.copyWith(variantIndex: index);
    }
  }

  void selectRun(int index, {bool copySettings = false}) {
    if (state.isRunning || index < 0 || index >= state.runs.length) return;
    final run = state.runs[index];
    var sources = state.sources;
    var sourceIndex = sources.indexWhere((s) => s.id == run.source.id);
    if (sourceIndex < 0) {
      sources = [run.source, ...sources].take(64).toList();
      sourceIndex = 0;
    }
    state = state.copyWith(
      sources: sources,
      sourceIndex: sourceIndex,
      selectedRunIndex: index,
      variantIndex: 0,
      selectedTool: copySettings ? run.tool : null,
      prompt: copySettings ? run.prompt : null,
      defry: copySettings ? run.defry : null,
      emotion: copySettings ? run.emotion : null,
      pixelOptions: copySettings ? run.pixelOptions : null,
      clearError: true,
    );
  }

  Future<void> runTool({bool Function()? canApply, int? quotedCost}) async {
    if (!state.canRun) return;
    final request = state;
    final source = request.source!;
    final tool = request.selectedTool;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final List<Uint8List> bytes;
      if (tool == DirectorToolType.pixelSnap) {
        bytes = [
          await PixelSnapService.snap(
            source.bytes,
            options: request.pixelOptions,
          ),
        ];
      } else {
        final prompt = tool == DirectorToolType.fixEmotion
            ? '${request.emotion};;${request.prompt.trim()}'
            : request.prompt.trim();
        bytes = await ref
            .read(naiImageEnhancementApiServiceProvider)
            .augmentImages(
              source.bytes,
              reqType: tool.requestType!,
              prompt: tool.needsPrompt && prompt.isNotEmpty ? prompt : null,
              defry: request.defry,
            );
      }
      if (_disposed || canApply?.call() == false) return;
      final images = ref
          .read(imageGenerationNotifierProvider.notifier)
          .registerToolResults(
            bytes,
            operation: tool.operation,
            originalBytes: source.bytes,
          );
      if (images.isEmpty) {
        throw const FormatException('No valid images returned');
      }
      final run = DirectorResultRun(
        source: source,
        tool: tool,
        images: images,
        prompt: request.prompt,
        defry: request.defry,
        emotion: request.emotion,
        pixelOptions: request.pixelOptions,
        cost: quotedCost,
      );
      state = state.copyWith(
        runs: [run, ...state.runs].take(50).toList(),
        selectedRunIndex: 0,
        variantIndex: 0,
        isRunning: false,
      );
    } catch (error) {
      if (!_disposed && canApply?.call() != false) {
        state = state.copyWith(error: error.toString(), isRunning: false);
      }
    } finally {
      if (!_disposed && state.isRunning) {
        state = state.copyWith(isRunning: false);
      }
      if (!_disposed &&
          canApply?.call() != false &&
          tool != DirectorToolType.pixelSnap &&
          ref.exists(subscriptionNotifierProvider)) {
        ref
            .read(subscriptionNotifierProvider.notifier)
            .schedulePostBillingRefresh();
      }
    }
  }

  void applyResultAsSource() {
    final bytes = state.result;
    if (bytes != null && !state.isRunning) addSource(bytes);
  }

  void clearResult() {
    if (!state.isRunning) {
      state = state.copyWith(clearResult: true, clearError: true);
    }
  }

  void clearError() {
    if (!state.isRunning) state = state.copyWith(clearError: true);
  }
}
