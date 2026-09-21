import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/models/director/director_tool_type.dart';
import '../../../data/services/director/pixel_snap_service.dart';
import '../../providers/director_tools_notifier.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/image_workflow_launcher.dart';
import '../../utils/dropped_file_reader.dart';
import '../../widgets/anlas/anlas_balance_chip.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/image_detail/image_detail_data.dart';
import '../../widgets/common/selectable_image_card.dart';
import '../generation/services/generation_save_service.dart';
import '../generation/widgets/canvas/canvas_image_background.dart';
import '../generation/widgets/history_batch.dart';
import '../generation/widgets/image_operation_badge.dart';

class DirectorToolsScreen extends ConsumerStatefulWidget {
  const DirectorToolsScreen({super.key, required this.sourceImage});
  final Uint8List sourceImage;

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List sourceImage,
  }) => Navigator.push<Uint8List?>(
    context,
    MaterialPageRoute(
      builder: (_) => DirectorToolsScreen(sourceImage: sourceImage),
    ),
  );

  @override
  ConsumerState<DirectorToolsScreen> createState() =>
      _DirectorToolsScreenState();
}

class _DirectorToolsScreenState extends ConsumerState<DirectorToolsScreen> {
  final _prompt = TextEditingController();
  bool _showHistory = true;
  DirectorToolsNotifier get _controller =>
      ref.read(directorToolsNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.init(widget.sourceImage);
    });
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  ColorScheme get _scheme => Theme.of(context).colorScheme;

  Color get _outline => _scheme.onSurface.withValues(alpha: .10);

  Color get _panelSurface => Color.alphaBlend(
    _scheme.onSurface.withValues(alpha: .05),
    _scheme.surface,
  );

  Color get _insetSurface => Color.alphaBlend(
    (_scheme.brightness == Brightness.dark ? Colors.black : Colors.white)
        .withValues(alpha: .28),
    _scheme.surface,
  );

  BoxDecoration get _panelDecoration => BoxDecoration(
    color: _panelSurface,
    border: Border.all(color: _outline),
    borderRadius: BorderRadius.circular(6),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directorToolsNotifierProvider);
    final theme = Theme.of(context);
    ref.listen(directorToolsNotifierProvider.select((s) => s.prompt), (
      _,
      value,
    ) {
      if (_prompt.text != value) _prompt.text = value;
    });
    return PopScope(
      canPop: !state.isRunning,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
            if (state.canRun) _run();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!state.isRunning) Navigator.maybePop(context);
          },
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _header(state),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 940;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (wide)
                            SizedBox(width: 94, child: _sourceQueue(state)),
                          Expanded(
                            child: Column(
                              children: [
                                if (!wide)
                                  SizedBox(
                                    height: 86,
                                    child: _sourceQueue(
                                      state,
                                      horizontal: true,
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      8,
                                    ),
                                    child: c.maxWidth >= 640
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: _imageFrame(
                                                  state,
                                                  output: false,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _imageFrame(
                                                  state,
                                                  output: true,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              Expanded(
                                                child: _imageFrame(
                                                  state,
                                                  output: false,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: _imageFrame(
                                                  state,
                                                  output: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                _toolDock(state, c.maxHeight),
                              ],
                            ),
                          ),
                          if (wide && _showHistory)
                            SizedBox(width: 144, child: _history(state)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(DirectorToolsState state) => Container(
    height: 48,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: _outline)),
    ),
    child: Row(
      children: [
        _icon(
          Icons.arrow_back,
          context.l10n.editor_back,
          state.isRunning ? null : () => Navigator.maybePop(context),
        ),
        Text(
          context.l10n.img2img_directorTools,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        AnlasBalanceChip(
          compact: true,
          inline: true,
          estimatedCostOverride: state.estimatedAnlasCost(
            isOpus: ref.watch(isOpusSubscriptionProvider),
          ),
        ),
        const Spacer(),
        _icon(Icons.history, context.l10n.generation_history, () {
          if (MediaQuery.sizeOf(context).width >= 940) {
            setState(() => _showHistory = !_showHistory);
          } else {
            showModalBottomSheet(
              context: context,
              builder: (_) => Consumer(
                builder: (context, ref, _) => SizedBox(
                  height: 420,
                  child: _history(ref.watch(directorToolsNotifierProvider)),
                ),
              ),
            );
          }
        }),
        const SizedBox(width: 8),
      ],
    ),
  );

  Widget _sourceQueue(DirectorToolsState state, {bool horizontal = false}) {
    final actions = Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _icon(
          Icons.file_upload_outlined,
          context.l10n.common_import,
          state.isRunning ? null : _import,
          surface: true,
        ),
        _icon(
          Icons.content_paste,
          context.l10n.common_paste,
          state.isRunning ? null : _paste,
          surface: true,
        ),
      ],
    );
    final list = ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.all(6),
      itemCount: state.sources.length,
      separatorBuilder: (_, _) =>
          SizedBox(width: horizontal ? 6 : 0, height: horizontal ? 0 : 6),
      itemBuilder: (_, index) {
        final source = state.sources[index];
        return SizedBox(
          width: horizontal ? 64 : null,
          height: horizontal ? null : 98,
          child: Stack(
            children: [
              Positioned.fill(
                child: _thumbnail(
                  source.bytes,
                  selected: state.sourceIndex == index,
                  onTap: state.isRunning
                      ? null
                      : () => _controller.selectSource(index),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: _icon(
                    Icons.close,
                    context.l10n.common_delete,
                    state.isRunning
                        ? null
                        : () => _controller.removeSource(source.id),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    final queue = DecoratedBox(
      decoration: BoxDecoration(
        color: _insetSurface,
        border: Border.all(color: _outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: list,
    );
    return Padding(
      padding: horizontal
          ? const EdgeInsets.fromLTRB(12, 4, 12, 4)
          : const EdgeInsets.fromLTRB(8, 8, 4, 8),
      child: DecoratedBox(
        decoration: _panelDecoration,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: horizontal
              ? Row(
                  children: [
                    SizedBox(width: 84, child: Center(child: actions)),
                    const SizedBox(width: 6),
                    Expanded(child: queue),
                  ],
                )
              : Column(
                  children: [
                    actions,
                    const SizedBox(height: 6),
                    Expanded(child: queue),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _imageFrame(DirectorToolsState state, {required bool output}) {
    final result = state.selectedResult;
    final bytes = output
        ? state.result ?? state.sourceImage
        : state.sourceImage;
    final width = output ? result?.width ?? state.imageWidth : state.imageWidth;
    final height = output
        ? result?.height ?? state.imageHeight
        : state.imageHeight;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _insetSurface,
        border: Border.all(color: _outline),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (output && state.resultVariants.length > 1)
            Container(
              decoration: BoxDecoration(
                color: _panelSurface,
                border: Border(bottom: BorderSide(color: _outline)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < state.resultVariants.length;
                      index++
                    )
                      _segment(
                        _variantLabel(state, index),
                        state.variantIndex == index,
                        () => _controller.selectVariant(index),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InteractiveViewer(
                      key: ValueKey(
                        '${output ? 'result' : 'source'}-${output ? result?.id : state.source?.id}',
                      ),
                      minScale: .5,
                      maxScale: 8,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: width / height,
                          child: CanvasImageBackground(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              filterQuality:
                                  state.selectedRun?.tool ==
                                      DirectorToolType.pixelSnap
                                  ? FilterQuality.none
                                  : FilterQuality.medium,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      context.l10n.img2img_directorSourceImage,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (output && state.isRunning)
                  ColoredBox(
                    color: theme.colorScheme.surface.withValues(alpha: .65),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 12),
                          Text(context.l10n.img2img_directorRunning),
                        ],
                      ),
                    ),
                  ),
                if (output &&
                    result == null &&
                    !state.isRunning &&
                    bytes != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      context.l10n.img2img_original,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _panelSurface,
              border: Border(top: BorderSide(color: _outline)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (output) _dimsBadge(theme, width, height),
                if (output)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _icon(
                        Icons.arrow_back,
                        context.l10n.img2img_directorAddToQueue,
                        result == null || state.isRunning
                            ? null
                            : _controller.applyResultAsSource,
                      ),
                      _icon(
                        Icons.content_copy,
                        context.l10n.image_copy,
                        result == null ? null : () => _copy(result.bytes),
                      ),
                      _icon(
                        Icons.save_outlined,
                        context.l10n.image_save,
                        result == null ? null : () => _save(result),
                      ),
                      PopupMenuButton<String>(
                        tooltip: context.l10n.img2img_moreActions,
                        enabled: result != null && !state.isRunning,
                        onSelected: (_) =>
                            Navigator.pop(context, result!.bytes),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'use',
                            child: Text(
                              context.l10n.img2img_directorApplyAsSource,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _icon(
                        Icons.content_copy,
                        context.l10n.image_copy,
                        bytes == null ? null : () => _copy(bytes),
                      ),
                      _icon(
                        Icons.photo_size_select_large,
                        context.l10n.image_upscale,
                        bytes == null || state.isRunning
                            ? null
                            : () {
                                ImageWorkflowLauncher.openUpscale(ref, bytes);
                                Navigator.pop(context);
                              },
                      ),
                    ],
                  ),
                if (!output) _dimsBadge(theme, width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimsBadge(ThemeData theme, int width, int height) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Color.alphaBlend(
        theme.colorScheme.onSurface.withValues(alpha: .06),
        _panelSurface,
      ),
      border: Border.all(
        color: theme.colorScheme.onSurface.withValues(alpha: .14),
      ),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('$width × $height', style: theme.textTheme.labelSmall),
  );

  Widget _toolDock(DirectorToolsState state, double availableHeight) {
    final theme = Theme.of(context);
    final tool = state.selectedTool;
    final cost = state.estimatedAnlasCost(
      isOpus: ref.watch(isOpusSubscriptionProvider),
    );
    final hasHeader =
        tool == DirectorToolType.pixelSnap ||
        tool.needsPrompt ||
        state.error != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1040,
          maxHeight: availableHeight * .48,
        ),
        child: Material(
          color: _panelSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: _outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tool == DirectorToolType.pixelSnap)
                          _pixelOptions(state),
                        if (tool.needsPrompt) _promptOptions(state),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (hasHeader)
                  Divider(height: 1, thickness: 1, color: _outline),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final run = FilledButton(
                        onPressed: state.canRun ? _run : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.isRunning
                                  ? context.l10n.img2img_directorRunning
                                  : context.l10n.img2img_transform,
                            ),
                            const SizedBox(width: 12),
                            Text('$cost'),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              'assets/icons/nai-icon-anlas.svg',
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.onPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      );
                      final tools = Wrap(
                        spacing: 2,
                        runSpacing: 4,
                        children: [
                          for (final item in DirectorToolType.values)
                            _segment(
                              item.labelKey(context.l10n),
                              tool == item,
                              state.isRunning
                                  ? null
                                  : () => _controller.selectTool(item),
                              icon: item.icon,
                            ),
                        ],
                      );
                      return c.maxWidth > 820
                          ? Row(
                              children: [
                                Expanded(child: tools),
                                const SizedBox(width: 12),
                                run,
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                tools,
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: run,
                                ),
                              ],
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _promptOptions(DirectorToolsState state) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        if (state.selectedTool == DirectorToolType.fixEmotion)
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: state.emotion,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.img2img_directorEmotion,
                isDense: true,
              ),
              items: [
                for (final emotion in emotionPresets)
                  DropdownMenuItem(
                    value: emotion.mood,
                    child: Text(_emotionLabel(emotion.mood)),
                  ),
              ],
              onChanged: state.isRunning
                  ? null
                  : (value) {
                      if (value != null) _controller.updateEmotion(value);
                    },
            ),
          ),
        SizedBox(
          width: 214,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.selectedTool == DirectorToolType.fixEmotion
                    ? context.l10n.img2img_directorEmotionLevel
                    : context.l10n.img2img_directorDefry,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i <= 5; i++)
                    Expanded(
                      child: _segment(
                        '$i',
                        state.defry == i,
                        state.isRunning
                            ? null
                            : () => _controller.updateDefry(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 280,
          child: TextField(
            controller: _prompt,
            enabled: !state.isRunning,
            minLines: 1,
            maxLines: 3,
            onChanged: _controller.updatePrompt,
            decoration: InputDecoration(
              labelText: context.l10n.img2img_directorPrompt,
              hintText: context.l10n.img2img_directorPromptHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pixelOptions(DirectorToolsState state) {
    final p = state.pixelOptions;
    void update({
      PixelSnapPaletteMode? paletteMode,
      int? colors,
      bool? avoid,
      bool? upscale,
    }) => _controller.updatePixelOptions(
      PixelSnapOptions(
        paletteMode: paletteMode ?? p.paletteMode,
        colors: colors ?? p.colors,
        avoidOverRefining: avoid ?? p.avoidOverRefining,
        upscale: upscale ?? p.upscale,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 218,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.img2img_palette,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final mode in PixelSnapPaletteMode.values)
                      Expanded(
                        child: _segment(
                          switch (mode) {
                            PixelSnapPaletteMode.off =>
                              context.l10n.img2img_paletteOff,
                            PixelSnapPaletteMode.auto =>
                              context.l10n.img2img_paletteAuto,
                            PixelSnapPaletteMode.custom =>
                              context.l10n.img2img_paletteCustom,
                          },
                          p.paletteMode == mode,
                          state.isRunning
                              ? null
                              : () => update(paletteMode: mode),
                        ),
                      ),
                  ],
                ),
                if (p.paletteMode == PixelSnapPaletteMode.custom)
                  Row(
                    children: [
                      Text('${p.colors}'),
                      Expanded(
                        child: Slider(
                          value: p.colors.toDouble(),
                          min: 16,
                          max: 256,
                          divisions: 15,
                          onChanged: state.isRunning
                              ? null
                              : (value) => update(colors: value.round()),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _optionCard(
            context.l10n.img2img_avoidOverRefining,
            p.avoidOverRefining
                ? context.l10n.img2img_keepGridHint
                : context.l10n.img2img_refineGridHint,
            p.avoidOverRefining,
            state.isRunning ? null : (v) => update(avoid: v),
          ),
          _optionCard(
            context.l10n.image_upscale,
            p.upscale
                ? context.l10n.img2img_pixelUpscaleHint
                : context.l10n.img2img_pixelNativeHint,
            p.upscale,
            state.isRunning ? null : (v) => update(upscale: v),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(
    String title,
    String hint,
    bool value,
    ValueChanged<bool>? changed,
  ) => SizedBox(
    width: 236,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch(
                value: value,
                onChanged: changed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _history(DirectorToolsState state) {
    final batches = buildHistoryBatches(
      ref.watch(imageGenerationNotifierProvider),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: DecoratedBox(
        decoration: _panelDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              child: Text(
                context.l10n.generation_history,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: _outline),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: batches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final batch = batches[index];
                  final cover = batch.cover;
                  if (cover == null) return const SizedBox.shrink();
                  final runIndex = state.runs.indexWhere(
                    (r) => r.images.any((i) => i.id == cover.id),
                  );
                  return SizedBox(
                    height: 140,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _thumbnail(
                            cover.bytes,
                            selected:
                                state.selectedRun?.images.any(
                                  (i) => batch.contains(i.id),
                                ) ==
                                true,
                            onTap: state.isRunning
                                ? null
                                : () {
                                    if (runIndex >= 0) {
                                      _controller.selectRun(
                                        runIndex,
                                        copySettings:
                                            HardwareKeyboard
                                                .instance
                                                .isControlPressed ||
                                            HardwareKeyboard
                                                .instance
                                                .isMetaPressed,
                                      );
                                    } else {
                                      _controller.addSource(cover.bytes);
                                    }
                                  },
                          ),
                        ),
                        if (cover.operation != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: ImageOperationBadge(
                              operation: cover.operation!,
                            ),
                          ),
                        if (batch.count > 1)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '×${batch.count}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(
    Uint8List bytes, {
    required bool selected,
    required VoidCallback? onTap,
  }) => Material(
    color: selected
        ? _scheme.primary.withValues(alpha: .16)
        : Color.alphaBlend(
            _scheme.onSurface.withValues(alpha: .04),
            _scheme.surface,
          ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
      side: BorderSide(
        color: selected ? _scheme.primary : _outline,
        width: selected ? 1.5 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.memory(bytes, fit: BoxFit.contain, cacheWidth: 240),
      ),
    ),
  );

  Widget _icon(
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    double size = 18,
    bool surface = false,
  }) => IconButton(
    icon: StudioIcon(icon, size: size),
    tooltip: label,
    onPressed: onPressed,
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    visualDensity: VisualDensity.compact,
    style: surface
        ? IconButton.styleFrom(
            fixedSize: const Size(32, 32),
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Color.alphaBlend(
              _scheme.onSurface.withValues(alpha: .06),
              _scheme.surface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: _outline),
            ),
          )
        : null,
  );

  Widget _segment(
    String text,
    bool selected,
    VoidCallback? onPressed, {
    IconData? icon,
  }) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: selected
          ? Theme.of(context).colorScheme.onSurface
          : Theme.of(context).colorScheme.onSurfaceVariant,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)
          : Colors.transparent,
      minimumSize: const Size(30, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          StudioIcon(icon, size: 15),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          softWrap: false,
        ),
      ],
    ),
  );

  String _variantLabel(DirectorToolsState state, int index) {
    if (state.selectedRun?.tool == DirectorToolType.removeBackground &&
        state.resultVariants.length == 3) {
      return [
        context.l10n.img2img_masked,
        context.l10n.img2img_generated,
        context.l10n.img2img_blend,
      ][index];
    }
    return '${context.l10n.img2img_directorResult} ${index + 1}';
  }

  String _emotionLabel(String mood) => switch (mood) {
    'happy' => context.l10n.img2img_emotionHappy,
    'laughing' => context.l10n.img2img_emotionLaugh,
    'sad' => context.l10n.img2img_emotionSad,
    'angry' => context.l10n.img2img_emotionAngry,
    'surprised' => context.l10n.img2img_emotionSurprised,
    'shy' => context.l10n.img2img_emotionShy,
    'excited' => context.l10n.img2img_emotionExcited,
    'disgusted' => context.l10n.img2img_emotionDisgusted,
    'smug' => context.l10n.img2img_emotionSmug,
    'worried' => context.l10n.img2img_emotionWorried,
    'love' => context.l10n.img2img_emotionLove,
    'playful' => context.l10n.img2img_emotionPlayful,
    'tired' => context.l10n.img2img_emotionTired,
    _ => context.l10n.img2img_emotionNeutral,
  };

  Future<void> _run() async {
    await _controller.runTool();
  }

  Future<void> _copy(Uint8List bytes) =>
      SelectableImageCard.copyImageBytesToClipboard(context, ref, bytes);
  Future<void> _save(GeneratedImage image) =>
      GenerationSaveService.saveImageFromDetail(
        context,
        ref,
        GeneratedImageDetailData(
          imageBytes: image.bytes,
          metadata: image.metadata,
          id: image.id,
        ),
      );
  Future<void> _import() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (picked == null || !mounted) return;
      for (final file in picked.files) {
        final bytes =
            file.bytes ??
            (file.path == null ? null : await File(file.path!).readAsBytes());
        if (!mounted) return;
        if (bytes != null) _controller.addSource(bytes);
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_selectFailed('$error'));
      }
    }
  }

  Future<void> _paste() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) return;
      final reader = await clipboard.read();
      for (final item in reader.items) {
        final file = await DroppedFileReader.read(
          item,
          allowRemoteImages: false,
        );
        if (!mounted) return;
        if (file != null) {
          _controller.addSource(file.bytes);
          return;
        }
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_selectFailed('$error'));
      }
    }
  }
}
