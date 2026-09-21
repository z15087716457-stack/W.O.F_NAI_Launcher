import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/warmup_provider.dart';
import '../../utils/warmup_message_localizer.dart';
import '../../widgets/branding/brand_entry_scene.dart';

/// A calm, centered brand screen driven by real warmup progress.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(warmupNotifierProvider);
    return BrandEntryScene(
      loading: true,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final progress = state.progress.progress.clamp(0.0, 1.0);
          final task = WarmupMessageLocalizer.localizeTask(
            context.l10n,
            state.progress.currentTask,
          );
          final error = state.error ?? state.progress.error;
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${(progress * 100).round().toString().padLeft(2, '0')}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  key: const Key('brand_warmup_progress'),
                  value: progress,
                  backgroundColor: scheme.outline,
                  semanticsLabel: task,
                  semanticsValue: '${(progress * 100).round()}%',
                ),
                const SizedBox(height: 14),
                if (error != null)
                  Text(
                    WarmupMessageLocalizer.localizeSubTask(context.l10n, error),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  )
                else if (state.subTaskMessage != null && !state.isComplete)
                  Text(
                    WarmupMessageLocalizer.localizeSubTask(
                      context.l10n,
                      state.subTaskMessage!,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
