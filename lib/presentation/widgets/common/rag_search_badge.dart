import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/rag_provider.dart';

class RagSearchBadge extends ConsumerWidget {
  const RagSearchBadge({super.key, required this.source});
  final RagSource source;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(ragSettingsProvider).enabledFor(source)) {
      return const SizedBox.shrink();
    }
    final status = ref.watch(ragControllerProvider).forSource(source);
    return Tooltip(
      message: status.available
          ? (status.partial
                ? context.l10n.rag_partial
                : context.l10n.rag_badgeHint)
          : context.l10n.rag_unavailable,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.searching > 0 || status.phase == 'loading')
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.2),
                ),
              ),
            Text(
              'RAG',
              key: Key('rag-badge-${source.name}'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: status.available
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
