import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tips_provider.dart';
import '../../providers/warmup_provider.dart';
import '../../themes/studio_typography.dart';
import '../../utils/warmup_message_localizer.dart';
import '../../widgets/auth/entry_controls.dart';
import '../../widgets/branding/brand_entry_scene.dart';

/// 载入页：与登录页同一场景，背景随预热进度「去噪」成提示词墙，
/// Logo 下方是像素分段进度条、百分比与当前任务。
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warmupNotifierProvider);
    final l10n = context.l10n;
    final progress = state.progress.progress.clamp(0.0, 1.0);
    var task = WarmupMessageLocalizer.localizeTask(
      l10n,
      state.progress.currentTask,
    );
    // 预热完成后还在验证已保存的账号时，停在 100% 说明正在登录
    if (state.isComplete) {
      final status = ref.watch(authNotifierProvider.select((s) => s.status));
      if (status == AuthStatus.loading || status == AuthStatus.initial) {
        task = l10n.auth_loggingIn;
      }
    }
    final error = state.error ?? state.progress.error;
    final subTask =
        error == null && state.subTaskMessage != null && !state.isComplete
        ? WarmupMessageLocalizer.localizeSubTask(l10n, state.subTaskMessage!)
        : null;
    final tip = ref.watch(splashTipProvider).hint(l10n);
    return BrandEntryScene(
      loading: true,
      progress: progress,
      child: _BootPanel(
        progress: progress,
        task: task,
        detail: error != null
            ? WarmupMessageLocalizer.localizeSubTask(l10n, error)
            : subTask,
        tip: tip,
        isError: error != null,
      ),
    );
  }
}

class _BootPanel extends StatelessWidget {
  const _BootPanel({
    required this.progress,
    required this.task,
    required this.detail,
    required this.tip,
    required this.isError,
  });

  final double progress;
  final String task;
  final String? detail;

  /// 没有子任务或错误时，这一行显示一条小贴士。
  final String tip;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final percent = (progress * 100).round();
    final step = (progress * 28).round();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: BootProgressBar(
                    key: const Key('brand_warmup_progress'),
                    value: progress,
                    semanticsLabel: task,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 56,
                  child: Text.rich(
                    TextSpan(
                      text: '$percent',
                      children: [
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontFamily: StudioTypography.mono,
                            fontSize: 12,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: StudioTypography.pixelSquare,
                      fontSize: 22,
                      height: 0.8,
                      color: palette.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    task,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'STEP ${step.toString().padLeft(2, '0')}/28',
                  style: StudioTypography.data.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.66,
                    color: palette.faint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: Text(
                detail ?? tip,
                key: Key(
                  detail == null ? 'brand_warmup_tip' : 'brand_warmup_detail',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isError ? palette.error : palette.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 34 格像素进度条：已完成的格子是墨色，最前面一格是品牌蓝。
class BootProgressBar extends StatelessWidget {
  const BootProgressBar({super.key, required this.value, this.semanticsLabel});

  final double value;
  final String? semanticsLabel;

  static const int segments = 34;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final filled = (clamped * segments).round();
    return Semantics(
      label: semanticsLabel,
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        height: 9,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < segments; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: ColoredBox(
                  color: i == filled - 1 && clamped < 1
                      ? palette.blue
                      : palette.ink.withValues(alpha: i < filled ? 0.9 : 0.1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
