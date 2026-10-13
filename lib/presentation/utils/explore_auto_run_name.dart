import '../../data/models/prompt_block/pill_document.dart';
import '../../l10n/app_localizations.dart';
import '../providers/prompt_block_library_provider.dart';

/// Uses the same enabled rolling/evolution instances as roll snapshot capture.
String exploreAutoRunName({
  required PillDocument document,
  required PromptBlockLibraryState? library,
  required AppLocalizations l10n,
  DateTime? now,
}) {
  final time = now ?? DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
  final titles = [
    for (final instance in document.instances.values)
      if (instance.enabled &&
          instance.settings.hasRoll &&
          instance.evolutionEnabled)
        library?.blockById(instance.blockId)?.title.trim() ?? '',
  ].where((title) => title.isNotEmpty).toList();
  if (titles.isEmpty) return l10n.styleExplore_manualRunName(stamp);
  final blocks =
      titles.take(2).join(' + ') +
      (titles.length > 2 ? ' +${titles.length - 2}' : '');
  return l10n.styleExplore_autoRunName(blocks, stamp);
}

/// 0 today, 1 the current Monday-based week, 2 earlier.
int exploreRunDateGroup(DateTime updatedAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  if (!updatedAt.toLocal().isBefore(today)) return 0;
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return updatedAt.toLocal().isBefore(monday) ? 2 : 1;
}
