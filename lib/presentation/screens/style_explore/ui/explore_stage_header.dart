import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/studio_icons.dart';
import '../../../widgets/navigation/window_chrome_layout.dart';
import 'explore_controls.dart';
import 'explore_style.dart';
import 'explore_text.dart';
import '../actions/explore_run_actions.dart';
import 'explore_run_switcher.dart';

/// Prototype size choices and inspector toggle with their 10px gaps.
const double _trailingWidth = 10 + 70 + 10 + 28;

/// Switcher padding, status dot, gaps, chevron and border around the name.
const double _switcherChrome = 59;

class ExploreStageHeader extends ConsumerWidget {
  const ExploreStageHeader({
    super.key,
    required this.inspectorVisible,
    this.runMenuController,
  });
  final bool inspectorVisible;
  final MenuController? runMenuController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final run = ref.watch(exploreActiveRunProvider);
    final runner = ref.watch(exploreRunRunnerProvider);
    final capture = ref.watch(exploreManualCaptureProvider);
    final generation = ref.watch(imageGenerationNotifierProvider);
    final running = run != null && runner.isRunning && runner.runId == run.id;
    final manual =
        run != null &&
        capture.armed &&
        capture.runId == run.id &&
        generation.isGenerating;
    final paused =
        run?.status == ExploreRunStatus.paused && !running && !manual;
    final busy = running || manual;
    final count = running ? runner.processedCount + 1 : generation.currentImage;
    final total = running ? runner.totalCount : generation.totalImages;
    final current = total > 0 ? count.clamp(1, total) : 0;
    final round = run?.rounds.isNotEmpty == true ? run!.rounds.last.number : 1;
    final progress = paused
        ? l10n.styleExplore_pausedRemaining(run!.pendingCandidates.length)
        : total > 0
        ? l10n.styleExplore_roundProgress(round, current, total)
        : l10n.styleExplore_roundGenerating(round);
    final stats = [
      if (run != null && run.candidates.isNotEmpty)
        l10n.styleExplore_imageCount(run.candidates.length),
      if (!busy && run != null) ...[
        if (run.candidates.any((c) => c.review.heart))
          l10n.styleExplore_favoriteCount(
            run.candidates.where((c) => c.review.heart).length,
          ),
        if (run.rounds.isNotEmpty)
          l10n.styleExplore_roundCount(run.rounds.length),
        if (run.families.isNotEmpty)
          l10n.styleExplore_lineCount(run.families.length),
      ],
    ];
    final large = ref.watch(
      layoutStateNotifierProvider.select(
        (layout) => layout.styleExploreGridLarge,
      ),
    );
    final text = theme.textTheme.bodySmall!.copyWith(
      fontSize: 12,
      height: 1.45,
      color: scheme.onSurfaceVariant,
    );
    final progressText = text.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
    );
    final nameText = theme.textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    final progressing = busy || paused;
    final hasTotal = busy && total > 0;
    final fraction = '$current / $total';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        key: const Key('explore-stage-header'),
        height: 52,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
          child: LayoutBuilder(
            builder: (context, space) {
              double measure(String value, TextStyle style) {
                final p = TextPainter(
                  text: TextSpan(text: value, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final width = p.width.ceilToDouble();
                p.dispose();
                return width;
              }

              final available =
                  space.maxWidth - _trailingWidth - (progressing ? 10 : 0);
              final desiredName = math.min(
                300.0,
                measure(
                      run?.displayName ?? l10n.styleExplore_newRun,
                      nameText,
                    ) +
                    _switcherChrome,
              );
              final chrome =
                  16.0 + (busy ? 24 : 0) + 6 + ((running || paused) ? 56 : 28);
              final options = !progressing
                  ? <double>[0]
                  : [
                      if (hasTotal)
                        measure(progress, progressText) + chrome + 100,
                      measure(progress, progressText) + chrome,
                      if (hasTotal) measure(fraction, progressText) + chrome,
                    ];
              final fits = options.indexWhere(
                (w) => w + desiredName <= available,
              );
              final level = fits < 0 ? options.length - 1 : fits;
              final progressWidth = fits >= 0 || !progressing
                  ? options[level]
                  : math.min(
                      options[level],
                      math.max(
                        chrome + 24,
                        available - math.min(desiredName, 96),
                      ),
                    );
              final nameWidth = math.max(
                _switcherChrome,
                math.min(desiredName, available - progressWidth),
              );
              var room = available - nameWidth - progressWidth - 10;
              final visibleStats = <String>[];
              for (final item in stats) {
                final need =
                    measure(item, text) + (visibleStats.isEmpty ? 0 : 19);
                if (need > room) break;
                room -= need;
                visibleStats.add(item);
              }
              return Row(
                children: [
                  SizedBox(
                    width: nameWidth,
                    child: ExploreRunSwitcher(controller: runMenuController),
                  ),
                  if (visibleStats.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: stats.join(' · '),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < visibleStats.length; i++) ...[
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: scheme.outline,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ExploreText(
                              visibleStats[i],
                              maxLines: 1,
                              style: text,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: WindowChromeScope.activeOf(context)
                        ? const WindowDragArea(
                            key: Key('explore-header-blank-drag'),
                          )
                        : const SizedBox(),
                  ),
                  if (progressing) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: progressWidth,
                      child: Tooltip(
                        message: progress,
                        child: Container(
                          key: const Key('explore-stage-progress'),
                          height: 34,
                          padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              if (busy) ...[
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: MediaQuery.disableAnimationsOf(context)
                                      ? CustomPaint(
                                          painter: _StillSpinner(
                                            scheme.primary,
                                          ),
                                        )
                                      : CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.primary,
                                          backgroundColor: scheme.primary
                                              .withValues(alpha: .25),
                                        ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: ExploreText(
                                  hasTotal && level == 2 ? fraction : progress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: progressText,
                                ),
                              ),
                              if (hasTotal && level == 0) ...[
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 90,
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: current / total,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                    color: scheme.primary,
                                    backgroundColor: scheme.primary.withValues(
                                      alpha: .18,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              if (running)
                                ExploreIconButton(
                                  'pause',
                                  key: const Key('explore-run-pause'),

                                  size: 15,
                                  color: scheme.primary,
                                  tooltip: l10n.styleExplore_pauseRun,
                                  onPressed: () => ref
                                      .read(exploreRunRunnerProvider.notifier)
                                      .pause(),
                                ),
                              if (paused)
                                ExploreIconButton(
                                  'play',
                                  key: const Key('explore-run-resume'),

                                  size: 13,
                                  filled: true,
                                  color: scheme.primary,
                                  tooltip: l10n.common_continue,
                                  onPressed: () => ExploreRunActions.start(
                                    context,
                                    ref,
                                    run!,
                                  ),
                                ),
                              ExploreIconButton(
                                'stop',
                                key: const Key('explore-run-cancel'),

                                size: 13,
                                filled: true,
                                color: scheme.primary,
                                tooltip: paused
                                    ? l10n.styleExplore_cancelRun
                                    : l10n.styleExplore_stopRun,
                                onPressed: () => ExploreRunActions.cancel(
                                  context,
                                  ref,
                                  run!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final big in [false, true])
                          Padding(
                            padding: EdgeInsets.only(left: big ? 2 : 0),
                            child: _SizeChoice(
                              key: Key(
                                big
                                    ? 'explore-size-large'
                                    : 'explore-size-small',
                              ),
                              selected: big == large,
                              large: big,
                              tooltip: big
                                  ? l10n.styleExplore_largeCandidates
                                  : l10n.styleExplore_smallCandidates,
                              onTap: () => ref
                                  .read(layoutStateNotifierProvider.notifier)
                                  .setStyleExploreGridLarge(big),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ExploreIconButton(
                    'panel',
                    key: const Key('style-explore-inspector-toggle'),

                    size: 16,
                    color: inspectorVisible
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    background: inspectorVisible
                        ? scheme.surfaceContainerHighest
                        : null,
                    tooltip: inspectorVisible
                        ? l10n.styleExplore_hideInspector
                        : l10n.styleExplore_showInspector,
                    onPressed: () => ref
                        .read(layoutStateNotifierProvider.notifier)
                        .setStyleExploreInspectorVisible(!inspectorVisible),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SizeChoice extends StatelessWidget {
  const _SizeChoice({
    super.key,
    required this.selected,
    required this.large,
    required this.tooltip,
    required this.onTap,
  });
  final bool selected, large;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? ExploreStyle.raised(t) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            width: 32,
            height: 28,
            child: Center(
              child: Icon(
                large
                    ? StudioIcons.gallerySizeLarge
                    : StudioIcons.gallerySizeSmall,
                size: 15,
                color: selected ? c.onSurface : c.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StillSpinner extends CustomPainter {
  _StillSpinner(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect.deflate(1),
      paint..color = color.withValues(alpha: .25),
    );
    canvas.drawArc(
      rect.deflate(1),
      -math.pi,
      math.pi / 2,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_StillSpinner oldDelegate) => color != oldDelegate.color;
}
