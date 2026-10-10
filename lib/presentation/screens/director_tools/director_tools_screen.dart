import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
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
  final _promptFocus = FocusNode();
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
    _promptFocus.dispose();
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
    borderRadius: BorderRadius.circular(3),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directorToolsNotifierProvider);
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
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
            if (!state.isRunning && !_promptFocus.hasFocus) _paste();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!state.isRunning) Navigator.maybePop(context);
          },
        },
        child: Scaffold(
          backgroundColor: _scheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _header(state),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 1000;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (wide)
                            SizedBox(width: 120, child: _sourceQueue(state)),
                          Expanded(
                            child: Column(
                              children: [
                                if (!wide)
                                  SizedBox(
                                    height: 76,
                                    child: _sourceQueue(
                                      state,
                                      horizontal: true,
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      wide ? 12 : 10,
                                      wide ? 20 : 8,
                                      wide ? 20 : 10,
                                      16,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, frames) {
                                        final panes = [
                                          Expanded(
                                            child: _imageFrame(
                                              state,
                                              output: false,
                                            ),
                                          ),
                                          SizedBox(
                                            width: frames.maxWidth >= 560
                                                ? 20
                                                : 0,
                                            height: frames.maxWidth >= 560
                                                ? 0
                                                : 10,
                                          ),
                                          Expanded(
                                            child: _imageFrame(
                                              state,
                                              output: true,
                                            ),
                                          ),
                                        ];
                                        return frames.maxWidth >= 560
                                            ? Row(children: panes)
                                            : Column(children: panes);
                                      },
                                    ),
                                  ),
                                ),
                                _toolDock(
                                  state,
                                  c.maxHeight,
                                  compact: c.maxWidth < 680,
                                ),
                              ],
                            ),
                          ),
                          if (wide && _showHistory)
                            SizedBox(width: 140, child: _history(state)),
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
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: _outline)),
    ),
    child: Row(
      children: [
        _icon(
          'director_small_arrow',
          context.l10n.editor_back,
          state.isRunning ? null : () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 4),
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
        _icon(
          'director_chevron',
          context.l10n.generation_history,
          () {
            if (MediaQuery.sizeOf(context).width >= 1000) {
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
          },
          quarterTurns: _showHistory ? 3 : 1,
        ),
      ],
    ),
  );

  Widget _sourceQueue(DirectorToolsState state, {bool horizontal = false}) {
    final upload = SizedBox(
      width: horizontal ? 40 : double.infinity,
      height: 38,
      child: _icon(
        'nai-icon-import',
        context.l10n.common_import,
        state.isRunning ? null : _import,
        surface: true,
      ),
    );
    final list = ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      itemCount: state.sources.length,
      separatorBuilder: (_, _) =>
          SizedBox(width: horizontal ? 6 : 0, height: horizontal ? 0 : 6),
      itemBuilder: (_, index) => SizedBox(
        width: horizontal ? 60 : null,
        height: horizontal ? null : 96,
        child: Stack(
          children: [
            Positioned.fill(
              child: _thumbnail(
                state.sources[index].bytes,
                selected: state.sourceIndex == index,
                onTap: state.isRunning
                    ? null
                    : () => _controller.selectSource(index),
              ),
            ),
            Positioned(
              top: 1,
              right: 1,
              child: _icon(
                'inpaint_close',
                context.l10n.common_delete,
                state.isRunning
                    ? null
                    : () => _controller.removeSource(state.sources[index].id),
                size: 10,
                buttonSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: horizontal
          ? const EdgeInsets.fromLTRB(10, 8, 10, 4)
          : const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: horizontal
          ? Row(
              children: [
                upload,
                const SizedBox(width: 6),
                Expanded(child: list),
              ],
            )
          : Column(
              children: [
                upload,
                const SizedBox(height: 6),
                Expanded(child: list),
              ],
            ),
    );
  }

  Widget _imageFrame(DirectorToolsState state, {required bool output}) {
    final result = state.selectedResult;
    final bytes = output ? result?.bytes : state.sourceImage;
    final width = output ? result?.width ?? state.imageWidth : state.imageWidth;
    final height = output
        ? result?.height ?? state.imageHeight
        : state.imageHeight;
    final name = output ? 'result' : 'source';
    // Both sides reserve exactly the same space, including multi-result tabs.
    // Footer actions and labels must never change either image's fitted size.
    final variants = state.resultVariants.length > 1;
    return Container(
      key: ValueKey('director-$name-frame'),
      decoration: BoxDecoration(
        color: _insetSurface,
        border: Border.all(color: _outline),
        borderRadius: BorderRadius.circular(3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (variants)
            SizedBox(
              height: 36,
              child: output
                  ? Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var i = 0;
                              i < state.resultVariants.length;
                              i++
                            )
                              _segment(
                                _variantLabel(state, i),
                                state.variantIndex == i,
                                state.isRunning
                                    ? null
                                    : () => _controller.selectVariant(i),
                              ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Stack(
                key: ValueKey('director-$name-preview'),
                fit: StackFit.expand,
                children: [
                  if (bytes != null)
                    InteractiveViewer(
                      key: ValueKey(
                        'director-$name-view-${output ? result?.id : state.source?.id}',
                      ),
                      minScale: .5,
                      maxScale: 8,
                      child: Center(
                        child: AspectRatio(
                          key: ValueKey('director-$name-image'),
                          aspectRatio: width / height,
                          child: CanvasImageBackground(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              filterQuality:
                                  output &&
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
                  if (output && state.isRunning)
                    ColoredBox(
                      color: _insetSurface.withValues(alpha: .8),
                      child: LayoutBuilder(
                        builder: (context, loading) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: loading.maxHeight.clamp(1, 24),
                                height: loading.maxHeight.clamp(1, 24),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              if (loading.maxHeight >= 72) ...[
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.img2img_directorRunning,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            key: ValueKey('director-$name-footer'),
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  if (output && result != null) _dimsBadge(width, height),
                  if (!output) ...[
                    _icon(
                      'nai-icon-copy',
                      context.l10n.image_copy,
                      bytes == null ? null : () => _copy(bytes),
                    ),
                    _icon(
                      'nai-icon-upscale',
                      context.l10n.image_upscale,
                      bytes == null || state.isRunning
                          ? null
                          : () {
                              ImageWorkflowLauncher.openUpscale(ref, bytes);
                              Navigator.pop(context);
                            },
                    ),
                  ],
                  const Spacer(),
                  if (output && result != null) ...[
                    _icon(
                      'director_small_arrow',
                      context.l10n.img2img_directorAddToQueue,
                      state.isRunning ? null : _controller.applyResultAsSource,
                    ),
                    _icon(
                      'nai-icon-copy',
                      context.l10n.image_copy,
                      () => _copy(result.bytes),
                    ),
                    _icon(
                      'nai-icon-save',
                      context.l10n.image_save,
                      () => _save(result),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: _glyph('director_more', 16),
                        tooltip: context.l10n.img2img_moreActions,
                        enabled: !state.isRunning,
                        onSelected: (_) => Navigator.pop(context, result.bytes),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'use',
                            child: Text(
                              context.l10n.img2img_directorApplyAsSource,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!output && bytes != null) _dimsBadge(width, height),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimsBadge(int width, int height) => Container(
    height: 32,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: _panelSurface,
      border: Border.all(color: _outline),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text('$width × $height', style: const TextStyle(fontSize: 12)),
  );

  Widget _toolDock(
    DirectorToolsState state,
    double availableHeight, {
    required bool compact,
  }) {
    final hasOptions =
        state.selectedTool.needsPrompt ||
        state.selectedTool == DirectorToolType.pixelSnap ||
        state.error != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 15),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: availableHeight * (compact ? .34 : .48),
        ),
        child: DecoratedBox(
          key: const ValueKey('director-dock'),
          decoration: _panelDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasOptions)
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.selectedTool == DirectorToolType.pixelSnap)
                            _pixelOptions(state),
                          if (state.selectedTool.needsPrompt)
                            _promptOptions(state),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                state.error!,
                                style: TextStyle(
                                  color: _scheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (hasOptions) Divider(height: 1, thickness: 1, color: _outline),
              SizedBox(
                height: 50,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cost = state.estimatedAnlasCost(
                        isOpus: ref.watch(isOpusSubscriptionProvider),
                      );
                      final run = FilledButton(
                        key: const ValueKey('director-transform'),
                        onPressed: state.canRun ? _run : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(132, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.isRunning
                                  ? context.l10n.img2img_directorRunning
                                  : context.l10n.img2img_transform,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$cost', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            _glyph(
                              'nai-icon-anlas',
                              14,
                              color: _scheme.onPrimary,
                            ),
                          ],
                        ),
                      );
                      // Keep the action fixed; overflow tools move to the official
                      // More menu rather than making a second uneven row.
                      final shown = <DirectorToolType>[];
                      var room = c.maxWidth - 160;
                      for (final item in DirectorToolType.values) {
                        final painter = TextPainter(
                          text: TextSpan(
                            text: item.labelKey(context.l10n),
                            style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          textDirection: Directionality.of(context),
                        )..layout();
                        final needed = painter.width + 35;
                        if (room - needed <
                            (item == DirectorToolType.values.last ? 0 : 32)) {
                          break;
                        }
                        shown.add(item);
                        room -= needed;
                      }
                      final overflow = DirectorToolType.values
                          .where((t) => !shown.contains(t))
                          .toList();
                      return Row(
                        children: [
                          for (final item in shown)
                            _segment(
                              item.labelKey(context.l10n),
                              state.selectedTool == item,
                              state.isRunning
                                  ? null
                                  : () => _controller.selectTool(item),
                              asset: item.iconAsset,
                            ),
                          if (overflow.isNotEmpty)
                            SizedBox(
                              width: 32,
                              height: 40,
                              child: PopupMenuButton<DirectorToolType>(
                                key: const ValueKey('director-more-tools'),
                                tooltip: context.l10n.img2img_moreActions,
                                enabled: !state.isRunning,
                                padding: EdgeInsets.zero,
                                icon: _glyph(
                                  overflow.contains(state.selectedTool)
                                      ? state.selectedTool.iconAsset
                                      : 'director_more',
                                  14,
                                ),
                                onSelected: _controller.selectTool,
                                itemBuilder: (_) => [
                                  for (final item in overflow)
                                    PopupMenuItem(
                                      value: item,
                                      child: Row(
                                        children: [
                                          _glyph(item.iconAsset, 14),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.labelKey(context.l10n),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          run,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promptOptions(DirectorToolsState state) => LayoutBuilder(
    builder: (context, c) {
      final emotion = state.selectedTool == DirectorToolType.fixEmotion;
      final settings = SizedBox(
        width: emotion ? 250 : 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  emotion
                      ? context.l10n.img2img_directorEmotion
                      : context.l10n.img2img_directorDefry,
                  style: _labelStyle,
                ),
                if (emotion) ...[
                  const Spacer(),
                  Text(
                    _strength(state.defry),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (emotion)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('director-emotion-${state.emotion}'),
                        initialValue: state.emotion,
                        isExpanded: true,
                        icon: _glyph('director_chevron', 14),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: _scheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final p in emotionPresets)
                            DropdownMenuItem(
                              value: p.mood,
                              child: Text(_emotionLabel(p.mood)),
                            ),
                        ],
                        onChanged: state.isRunning
                            ? null
                            : (v) {
                                if (v != null) _controller.updateEmotion(v);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _icon(
                    'director_plus',
                    context.l10n.img2img_directorWeaken,
                    state.isRunning || state.defry == 5
                        ? null
                        : () => _controller.updateDefry(state.defry + 1),
                    surface: true,
                  ),
                  _icon(
                    'director_minus',
                    context.l10n.img2img_directorStrengthen,
                    state.isRunning || state.defry == 0
                        ? null
                        : () => _controller.updateDefry(state.defry - 1),
                    surface: true,
                  ),
                ],
              )
            else
              SizedBox(
                height: 34,
                child: Row(
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
              ),
          ],
        ),
      );
      final prompt = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.img2img_directorPrompt, style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _prompt,
            focusNode: _promptFocus,
            enabled: !state.isRunning,
            onChanged: _controller.updatePrompt,
            minLines: 1,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (emotion)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                context.l10n.img2img_directorEmotionHint,
                style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant),
              ),
            ),
          if (c.maxWidth >= 520)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                settings,
                const SizedBox(width: 15),
                Expanded(child: prompt),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [settings, const SizedBox(height: 12), prompt],
            ),
        ],
      );
    },
  );

  TextStyle get _labelStyle =>
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  String _strength(int level) => [
    context.l10n.img2img_emotionStrengthNormal,
    context.l10n.img2img_emotionStrengthSlightlyWeak,
    context.l10n.img2img_emotionStrengthWeak,
    context.l10n.img2img_emotionStrengthWeaker,
    context.l10n.img2img_emotionStrengthVeryWeak,
    context.l10n.img2img_emotionStrengthWeakest,
  ][level.clamp(0, 5)];

  Widget _pixelOptions(DirectorToolsState state) => LayoutBuilder(
    builder: (context, c) {
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
      final palette = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.img2img_palette, style: _labelStyle),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Row(
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
                      state.isRunning ? null : () => update(paletteMode: mode),
                    ),
                  ),
              ],
            ),
          ),
          if (p.paletteMode == PixelSnapPaletteMode.custom)
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Text('${p.colors}', style: const TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: p.colors.toDouble(),
                      min: 16,
                      max: 256,
                      divisions: 15,
                      onChanged: state.isRunning
                          ? null
                          : (v) => update(colors: v.round()),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
      final controls = [
        palette,
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
      ];
      if (c.maxWidth >= 720) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < controls.length; i++) ...[
              if (i > 0) const SizedBox(width: 20),
              Expanded(child: controls[i]),
            ],
          ],
        );
      }
      return Wrap(
        spacing: 20,
        runSpacing: 14,
        children: [
          for (final control in controls)
            SizedBox(
              width: c.maxWidth >= 490 ? (c.maxWidth - 20) / 2 : c.maxWidth,
              child: control,
            ),
        ],
      );
    },
  );

  Widget _optionCard(
    String title,
    String hint,
    bool value,
    ValueChanged<bool>? changed,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: _labelStyle)),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: changed,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        hint,
        style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant),
      ),
    ],
  );

  Widget _history(DirectorToolsState state) {
    final batches = buildHistoryBatches(
      ref.watch(imageGenerationNotifierProvider),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: _outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.generation_history,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                  height: 112,
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
                              color: _scheme.surface,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
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
    );
  }

  Widget _thumbnail(
    Uint8List bytes, {
    required bool selected,
    required VoidCallback? onTap,
  }) => Material(
    color: _insetSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(3),
      side: BorderSide(color: selected ? _scheme.primary : _outline, width: 1),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Image.memory(bytes, fit: BoxFit.contain, cacheWidth: 240),
      ),
    ),
  );

  Widget _glyph(String asset, double size, {Color? color}) => RotatedBox(
    quarterTurns: asset == 'director_small_arrow' ? 1 : 0,
    child: SvgPicture.asset(
      'assets/icons/$asset.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? _scheme.onSurface,
        BlendMode.srcIn,
      ),
    ),
  );
  Widget _icon(
    String asset,
    String label,
    VoidCallback? onPressed, {
    double size = 16,
    double buttonSize = 32,
    bool surface = false,
    int quarterTurns = 0,
  }) => SizedBox(
    width: surface ? null : buttonSize,
    height: buttonSize,
    child: IconButton(
      icon: RotatedBox(
        quarterTurns: quarterTurns,
        child: _glyph(
          asset,
          size,
          color: onPressed == null
              ? _scheme.onSurface.withValues(alpha: .3)
              : _scheme.onSurface,
        ),
      ),
      tooltip: label,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: buttonSize, minHeight: buttonSize),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: surface ? _panelSurface : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: surface ? BorderSide(color: _outline) : BorderSide.none,
        ),
      ),
    ),
  );
  Widget _segment(
    String text,
    bool selected,
    VoidCallback? onPressed, {
    String? asset,
  }) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: selected ? _scheme.onSurface : _scheme.onSurfaceVariant,
      backgroundColor: selected
          ? _scheme.onSurface.withValues(alpha: .08)
          : Colors.transparent,
      minimumSize: const Size(28, 28),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (asset != null) ...[
          _glyph(
            asset,
            14,
            color: selected ? _scheme.onSurface : _scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
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
    'scared' => context.l10n.img2img_emotionScared,
    'nervous' => context.l10n.img2img_emotionNervous,
    'thinking' => context.l10n.img2img_emotionThinking,
    'confused' => context.l10n.img2img_emotionConfused,
    'bored' => context.l10n.img2img_emotionBored,
    'irritated' => context.l10n.img2img_emotionIrritated,
    'aroused' => context.l10n.img2img_emotionAroused,
    'embarrassed' => context.l10n.img2img_emotionEmbarrassed,
    'determined' => context.l10n.img2img_emotionDetermined,
    'hurt' => context.l10n.img2img_emotionHurt,
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
