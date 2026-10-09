import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/studio_icons.dart';
import '../../../widgets/generation/auto_save_toggle_chip.dart';
import '../../../widgets/navigation/window_chrome_layout.dart';
import 'explore_icon.dart';
import 'explore_run_actions.dart';
import 'explore_run_switcher.dart';

/// Size toggle, auto-save and inspector toggle with their 10px gaps.
const double _trailingWidth = 10 + 70 + 10 + 28 + 10 + 28;

/// Switcher padding, status dot, gaps, chevron and border around the name.
const double _switcherChrome = 59;

class ExploreStageHeader extends ConsumerWidget {
  const ExploreStageHeader({super.key, required this.inspectorVisible});
  final bool inspectorVisible;

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
    final runStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w700,
    );
    final statStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );
    final progressStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: scheme.primary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final hasFraction = busy && total > 0;
    final compactProgress = '$current / $total';
    return Container(
      key: const Key('explore-stage-header'),
      height: 52,
      padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double widthOf(String text, TextStyle? style) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final width = painter.width.ceilToDouble();
            painter.dispose();
            return width;
          }

          // Degrade order on narrow stages: statistics drop whole items, the
          // progress bar goes, the round prefix collapses to "9 / 12", and
          // only then the exploration name is shortened.
          final showProgress = busy || paused;
          final available =
              constraints.maxWidth - _trailingWidth - (showProgress ? 10 : 0);
          final desiredRun = math.min(
            300.0,
            widthOf(run?.displayName ?? l10n.styleExplore_newRun, runStyle) +
                _switcherChrome,
          );
          final chrome =
              16.0 + (busy ? 24 : 0) + 6 + ((running || paused) ? 56 : 28);
          final progressOptions = !showProgress
              ? const <double>[0]
              : [
                  if (hasFraction)
                    widthOf(progress, progressStyle) + chrome + 100,
                  widthOf(progress, progressStyle) + chrome,
                  if (hasFraction)
                    widthOf(compactProgress, progressStyle) + chrome,
                ];
          final progressLevel = progressOptions.indexWhere(
            (width) => width + desiredRun <= available,
          );
          final progressIndex = progressLevel < 0
              ? progressOptions.length - 1
              : progressLevel;
          final progressWidth = progressLevel >= 0 || !showProgress
              ? progressOptions[progressIndex]
              : math.min(
                  progressOptions[progressIndex],
                  math.max(chrome + 24, available - math.min(desiredRun, 96)),
                );
          final showBar = hasFraction && progressIndex == 0;
          final compact = hasFraction && progressIndex == 2;
          final runWidth = math.max(
            _switcherChrome,
            math.min(desiredRun, available - progressWidth),
          );
          var statsRoom = available - runWidth - progressWidth - 10;
          final shownStats = <String>[];
          for (final stat in stats) {
            final width =
                widthOf(stat, statStyle) + (shownStats.isEmpty ? 0 : 19);
            if (width > statsRoom) break;
            statsRoom -= width;
            shownStats.add(stat);
          }
          return Row(
            children: [
              SizedBox(width: runWidth, child: const ExploreRunSwitcher()),
              if (shownStats.isNotEmpty) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: stats.join(' · '),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < shownStats.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: scheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Text(shownStats[i], maxLines: 1, style: statStyle),
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
              if (showProgress) ...[
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
                                      painter: _StillSpinner(scheme.primary),
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
                            child: Text(
                              compact ? compactProgress : progress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: progressStyle,
                            ),
                          ),
                          if (showBar) ...[
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
                            ExploreHeaderIconButton(
                              key: const Key('explore-run-pause'),
                              tooltip: l10n.styleExplore_pauseRun,
                              color: scheme.primary,
                              icon: const ExploreIcon(
                                'pause',
                                size: 15,
                                strokeWidth: 2.4,
                              ),
                              onPressed: () => ref
                                  .read(exploreRunRunnerProvider.notifier)
                                  .pause(),
                            ),
                          if (paused)
                            ExploreHeaderIconButton(
                              key: const Key('explore-run-resume'),
                              tooltip: l10n.common_continue,
                              color: scheme.primary,
                              icon: const ExploreIcon(
                                'play',
                                size: 13,
                                filled: true,
                              ),
                              onPressed: () =>
                                  ExploreRunActions.start(context, ref, run!),
                            ),
                          ExploreHeaderIconButton(
                            key: const Key('explore-run-cancel'),
                            tooltip: paused
                                ? l10n.styleExplore_cancelRun
                                : l10n.styleExplore_stopRun,
                            color: scheme.primary,
                            icon: const ExploreIcon(
                              'stop',
                              size: 13,
                              filled: true,
                            ),
                            onPressed: () =>
                                ExploreRunActions.cancel(context, ref, run!),
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
                        child: Container(
                          width: 32,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: large == big
                                ? (theme.brightness == Brightness.dark
                                      ? scheme.surfaceContainerHigh
                                      : scheme.surfaceContainer)
                                : null,
                            boxShadow:
                                large == big &&
                                    theme.brightness == Brightness.light
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .08,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ExploreHeaderIconButton(
                            key: Key(
                              big ? 'explore-size-large' : 'explore-size-small',
                            ),
                            tooltip: big
                                ? l10n.styleExplore_largeCandidates
                                : l10n.styleExplore_smallCandidates,
                            color: large == big
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            icon: Icon(
                              big
                                  ? StudioIcons.gallerySizeLarge
                                  : StudioIcons.gallerySizeSmall,
                              size: 15,
                            ),
                            onPressed: () => ref
                                .read(layoutStateNotifierProvider.notifier)
                                .setStyleExploreGridLarge(big),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const SizedBox(
                width: 28,
                height: 28,
                child: AutoSaveToggleIcon(prototypeStyle: true),
              ),
              const SizedBox(width: 10),
              ExploreHeaderIconButton(
                key: const Key('style-explore-inspector-toggle'),
                selected: inspectorVisible,
                tooltip: inspectorVisible
                    ? l10n.styleExplore_hideInspector
                    : l10n.styleExplore_showInspector,
                icon: const Icon(StudioIcons.galleryPanelRight, size: 16),
                onPressed: () => ref
                    .read(layoutStateNotifierProvider.notifier)
                    .setStyleExploreInspectorVisible(!inspectorVisible),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ExploreHeaderIconButton extends StatelessWidget {
  const ExploreHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.selected = false,
  });
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Material(
            color: selected
                ? scheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(6),
              hoverColor: scheme.surfaceContainerHighest,
              child: IconTheme(
                data: IconThemeData(
                  color:
                      color ??
                      (selected ? scheme.onSurface : scheme.onSurfaceVariant),
                ),
                child: Center(child: icon),
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
