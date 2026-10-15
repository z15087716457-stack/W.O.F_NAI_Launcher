import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/rag_provider.dart';
import '../ui/blocks/blocks_contract.dart';

BlocksRagStatus blocksRagStatus(WidgetRef ref, BuildContext context) {
  if (!ref.watch(ragSettingsProvider).enabledFor(RagSource.blocks)) {
    return const BlocksRagStatus();
  }
  final status = ref.watch(
    ragControllerProvider.select((state) {
      final s = state.forSource(RagSource.blocks);
      return (s.available, s.partial, s.searching, s.phase);
    }),
  );
  return BlocksRagStatus(
    enabled: true,
    available: status.$1,
    searching: status.$3 > 0 || status.$4 == 'loading',
    tooltip: status.$1
        ? (status.$2 ? context.l10n.rag_partial : context.l10n.rag_badgeHint)
        : context.l10n.rag_unavailable,
  );
}
