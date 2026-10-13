import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../core/services/anlas_calculator.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/director/director_tool_type.dart';
import '../../data/services/director/pixel_snap_service.dart';
import '../providers/auth_provider.dart';
import '../providers/director_tools_notifier.dart';
import '../providers/image_generation_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/generation/services/generation_save_service.dart';
import '../services/image_workflow_launcher.dart';
import '../ui/tools/tools_contract.dart';
import '../ui/tools/tools_director.dart';
import '../utils/dropped_file_reader.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../widgets/common/selectable_image_card.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import 'generation_backend.dart';
import 'generation_history_actions.dart';
import 'generation_operations.dart';

ToolsDirectorTool toolsDirectorTool(DirectorToolType value) => switch (value) {
  DirectorToolType.removeBackground => ToolsDirectorTool.removeBackground,
  DirectorToolType.extractLineArt => ToolsDirectorTool.lineArt,
  DirectorToolType.toSketch => ToolsDirectorTool.sketch,
  DirectorToolType.colorize => ToolsDirectorTool.colorize,
  DirectorToolType.fixEmotion => ToolsDirectorTool.emotion,
  DirectorToolType.declutter => ToolsDirectorTool.declutter,
  DirectorToolType.pixelSnap => ToolsDirectorTool.pixelSnap,
};

DirectorToolType directorTool(ToolsDirectorTool value) => DirectorToolType
    .values
    .firstWhere((tool) => toolsDirectorTool(tool) == value);

ToolsDirectorData toolsDirectorView(
  DirectorToolsState state, {
  int? anlas,
  bool opus = false,
  DateTime? now,
}) => ToolsDirectorData(
  tool: toolsDirectorTool(state.selectedTool),
  costs: {
    for (final tool in ToolsDirectorTool.values)
      tool: state.source == null
          ? null
          : tool == ToolsDirectorTool.pixelSnap
          ? 0
          : AnlasCalculator.calculateAugmentCost(
              width: state.imageWidth,
              height: state.imageHeight,
              isBgRemoval: tool == ToolsDirectorTool.removeBackground,
              isOpus: opus,
            ),
  },
  anlas: anlas,
  opusFree: opus,
  inputs: [
    for (final source in state.sources)
      ToolsDirectorInput(
        id: source.id,
        thumb: MemoryImage(source.bytes),
        width: source.width,
        height: source.height,
      ),
  ],
  input: state.source?.id,
  runs: [
    for (final run in state.runs)
      ToolsDirectorRun(
        id: run.images.first.id,
        tool: toolsDirectorTool(run.tool),
        inputId: run.source.id,
        images: [for (final image in run.images) MemoryImage(image.bytes)],
        time: run.images.first.createdAt,
        width: run.images.first.width,
        height: run.images.first.height,
        cost: run.cost,
        variants: run.tool != DirectorToolType.removeBackground
            ? []
            : [
                for (var i = 0; i < run.images.length; i++)
                  switch (i) {
                    0 => currentL10n.img2img_masked,
                    1 => currentL10n.img2img_generated,
                    _ => currentL10n.img2img_blend,
                  },
              ],
      ),
  ],
  run: state.selectedRun?.images.first.id,
  variant: state.variantIndex,
  defry: state.defry,
  prompt: state.prompt,
  emotion: state.emotion,
  pixel: ToolsPixelOptions(
    palette: ToolsPixelPalette.values.byName(
      state.pixelOptions.paletteMode.name,
    ),
    colors: state.pixelOptions.colors,
    avoidOverRefining: state.pixelOptions.avoidOverRefining,
    upscale: state.pixelOptions.upscale,
  ),
  running: state.isRunning,
  error: state.error,
  now: now,
);

class ToolsDirectorPlatform {
  const ToolsDirectorPlatform();
  Future<List<Uint8List>> importImages() async {
    final files = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (files == null) return [];
    return [
      for (final file in files.files)
        if (file.bytes != null || file.path != null)
          file.bytes ?? await File(file.path!).readAsBytes(),
    ];
  }

  Future<List<Uint8List>> pasteImages() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return [];
    final reader = await clipboard.read();
    for (final item in reader.items) {
      final image = await DroppedFileReader.read(
        item,
        allowRemoteImages: false,
      );
      if (image != null) return [image.bytes];
    }
    return [];
  }
}

final toolsDirectorPlatformProvider = Provider<ToolsDirectorPlatform>(
  (ref) => const ToolsDirectorPlatform(),
);
final toolsDirectorConfirmationProvider =
    Provider<Future<bool> Function(GenerationOperations, int)>(
      (ref) =>
          (operations, cost) => operations.confirm(cost),
    );

class ToolsDirectorWiring extends ConsumerStatefulWidget {
  const ToolsDirectorWiring({
    super.key,
    required this.sourceImage,
    this.writeDraft,
  });
  final Uint8List sourceImage;
  final Future<void> Function(void Function())? writeDraft;
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List sourceImage,
    Future<void> Function(void Function())? writeDraft,
  }) => Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ToolsDirectorWiring(sourceImage: sourceImage, writeDraft: writeDraft),
    ),
  );
  @override
  ConsumerState<ToolsDirectorWiring> createState() =>
      _ToolsDirectorWiringState();
}

class _ToolsDirectorWiringState extends ConsumerState<ToolsDirectorWiring> {
  bool confirming = false;
  int accountRevision = 0;
  int importTicket = 0;
  late Future<void> Function(void Function()) entryWrite;
  DirectorToolsNotifier get controller =>
      ref.read(directorToolsNotifierProvider.notifier);
  GenerationOperations get operations => GenerationOperations(
    ref,
    context,
    () => mounted && ModalRoute.of(context)?.isCurrent != false,
  );

  @override
  void initState() {
    super.initState();
    entryWrite =
        widget.writeDraft ??
        ref.read(generationBackendProvider).captureDraft(alive: () => mounted);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) operations.run(() => controller.init(widget.sourceImage));
    });
  }

  Future<void> runTool() async {
    if (confirming ||
        !mounted ||
        !ref.read(directorToolsNotifierProvider).canRun ||
        ref.read(generationBackendProvider).busy) {
      return;
    }
    final request = ref.read(directorToolsNotifierProvider);
    final account = ref.read(authNotifierProvider);
    final epoch = accountRevision;
    final opus =
        ref.read(subscriptionNotifierProvider).subscription?.isOpus == true;
    final cost = request.estimatedAnlasCost(isOpus: opus);
    bool valid() =>
        mounted &&
        epoch == accountRevision &&
        account.accountId == ref.read(authNotifierProvider).accountId &&
        account.status == ref.read(authNotifierProvider).status;
    confirming = true;
    try {
      if (request.selectedTool != DirectorToolType.pixelSnap &&
          !await ref.read(toolsDirectorConfirmationProvider)(
            operations,
            cost,
          )) {
        return;
      }
      if (!valid() ||
          !identical(request, ref.read(directorToolsNotifierProvider)) ||
          ref.read(generationBackendProvider).busy ||
          cost !=
              request.estimatedAnlasCost(
                isOpus:
                    ref
                        .read(subscriptionNotifierProvider)
                        .subscription
                        ?.isOpus ==
                    true,
              )) {
        return;
      }
      await controller.runTool(canApply: valid, quotedCost: cost);
    } finally {
      confirming = false;
    }
  }

  Future<void> import(Future<List<Uint8List>> Function() load) async {
    final request = ref.read(directorToolsNotifierProvider);
    if (request.isRunning) return;
    final ticket = ++importTicket;
    final epoch = accountRevision;
    final images = await load();
    if (!mounted ||
        ticket != importTicket ||
        epoch != accountRevision ||
        !identical(request, ref.read(directorToolsNotifierProvider))) {
      return;
    }
    for (final image in images) {
      controller.addSource(image);
    }
  }

  Future<List<Uint8List>> history() async {
    final images = ref
        .read(generationHistoryActionsProvider)
        .images
        .where((image) => image.canUseAsGenerationInput)
        .toList();
    if (images.isEmpty) return [];
    final selected = await showDialog<GeneratedImage>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.generation_history),
        content: SizedBox(
          width: 600,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) => InkWell(
              onTap: () => Navigator.pop(context, images[index]),
              child: Image.memory(images[index].bytes, fit: BoxFit.contain),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
        ],
      ),
    );
    return selected == null ? [] : [selected.bytes];
  }

  Future<void> resultAction(String kind) async {
    final state = ref.read(directorToolsNotifierProvider);
    final image = state.selectedResult;
    if (image == null || state.isRunning) return;
    bool selected() =>
        mounted &&
        identical(
          ref.read(directorToolsNotifierProvider).selectedResult,
          image,
        );
    if (kind == 'copy') {
      await ref.read(imageClipboardWriterProvider)(image.bytes);
    } else if (kind == 'save') {
      await GenerationSaveService.saveImageFromDetail(
        context,
        ref,
        GeneratedImageDetailData(
          imageBytes: image.bytes,
          metadata: image.metadata,
          id: image.id,
        ),
      );
    } else if (kind == 'upscale') {
      await operations.upscale(
        image.id,
        onStarted: () {
          if (mounted) Navigator.pop(context);
        },
      );
    } else if (kind == 'init') {
      if (!selected()) return;
      await entryWrite(() {
        if (!selected()) throw StateError(context.l10n.bridge_conflict);
        ImageWorkflowLauncher.openImageToImage(ref, image.bytes);
      });
      if (mounted) Navigator.pop(context);
    }
  }

  Widget drop(BuildContext context, Widget child) => DropRegion(
    formats: Formats.standardFormats,
    onDropOver: (event) =>
        !ref.read(directorToolsNotifierProvider).isRunning &&
            event.session.allowedOperations.contains(DropOperation.copy)
        ? DropOperation.copy
        : DropOperation.none,
    onPerformDrop: (event) async => operations.run(
      () => import(() async {
        final images = <Uint8List>[];
        for (final item in event.session.items) {
          final reader = item.dataReader;
          if (reader == null) continue;
          final file = await DroppedFileReader.read(
            reader,
            allowRemoteImages: false,
          );
          if (file != null) images.add(file.bytes);
        }
        return images;
      }),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authNotifierProvider.select((state) => (state.accountId, state.status)),
      (_, _) => accountRevision++,
    );
    final state = ref.watch(directorToolsNotifierProvider);
    final subscription = ref.watch(subscriptionNotifierProvider).subscription;
    void job(Future<void> Function() action) => operations.run(action);
    int runIndex(String id) => ref
        .read(directorToolsNotifierProvider)
        .runs
        .indexWhere((run) => run.images.first.id == id);
    return PopScope(
      canPop: !state.isRunning,
      child: WindowChromePage(
        child: ToolsDirectorPage(
          data: toolsDirectorView(
            state,
            anlas: subscription?.anlasBalance,
            opus: subscription?.isOpus == true,
          ),
          slots: ToolsDirectorSlots(drop: drop),
          actions: ToolsDirectorActions(
            onBack: () {
              if (!state.isRunning) Navigator.pop(context);
            },
            onTool: (value) => controller.selectTool(directorTool(value)),
            onSelectInput: (id) => controller.selectSource(
              ref
                  .read(directorToolsNotifierProvider)
                  .sources
                  .indexWhere((source) => source.id == id),
            ),
            onRemoveInput: controller.removeSource,
            onImportFiles: () => job(
              () =>
                  import(ref.read(toolsDirectorPlatformProvider).importImages),
            ),
            onPickHistory: () => job(() => import(history)),
            onPaste: () => job(
              () => import(ref.read(toolsDirectorPlatformProvider).pasteImages),
            ),
            onRun: () => job(runTool),
            onSelectRun: (id) => controller.selectRun(runIndex(id)),
            onReuseSettings: (id) =>
                controller.selectRun(runIndex(id), copySettings: true),
            onVariant: controller.selectVariant,
            onContinue: controller.applyResultAsSource,
            onCopy: () => job(() => resultAction('copy')),
            onSave: () => job(() => resultAction('save')),
            onUpscale: () => job(() => resultAction('upscale')),
            onUseAsInit: () => job(() => resultAction('init')),
            onDefry: controller.updateDefry,
            onPrompt: controller.updatePrompt,
            onEmotion: (mood) {
              final preset = emotionPresets
                  .where((preset) => preset.mood == mood)
                  .firstOrNull;
              if (preset != null) controller.applyEmotionPreset(preset);
            },
            onPixel: (value) => controller.updatePixelOptions(
              PixelSnapOptions(
                paletteMode: PixelSnapPaletteMode.values.byName(
                  value.palette.name,
                ),
                colors: value.colors.clamp(16, 256),
                avoidOverRefining: value.avoidOverRefining,
                upscale: value.upscale,
              ),
            ),
            onDismissError: controller.clearError,
          ),
        ),
      ),
    );
  }
}
