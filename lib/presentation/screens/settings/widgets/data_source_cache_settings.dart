import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/autocomplete/autocomplete_providers.dart';
import '../../../../core/autocomplete/autocomplete_settings.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/app_toast.dart';
import 'settings_card.dart';
import 'settings_columns.dart';
import 'settings_tile.dart';

class DataSourceCacheSettings extends ConsumerWidget {
  const DataSourceCacheSettings({
    super.key,
    this.controlsOnly = false,
    this.cacheOnly = false,
    this.showHeading = true,
  }) : assert(!(controlsOnly && cacheOnly));
  final bool controlsOnly, cacheOnly, showHeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(autocompleteSettingsProvider);
    final relatedTags = SettingsSwitchTile(
      title: Text(context.l10n.autocomplete_relatedTagsTitle),
      subtitle: Text(context.l10n.autocomplete_relatedTagsSubtitle),
      value: settings.relatedTagsEnabled,
      onChanged: ref
          .read(autocompleteSettingsProvider.notifier)
          .setRelatedTagsEnabled,
    );
    if (controlsOnly) {
      return SettingsCard(
        title: showHeading ? context.l10n.settings_tagExpansion : null,
        bottomSpacing: showHeading ? 26 : 0,
        child: relatedTags,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          title: context.l10n.settings_tagDictionaries,
          child: Column(
            children: [
              if (!cacheOnly) relatedTags,
              _CatalogStatus(ref: ref),
              FutureBuilder<int>(
                future: _loadCooccurrenceCount(ref),
                builder: (context, snapshot) => SettingsTile(
                  hoverFeedback: false,
                  title: Text(context.l10n.autocomplete_cooccurrence),
                  subtitle: Text(
                    context.l10n.autocomplete_entryCount(snapshot.data ?? 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        SettingsCard(
          title: context.l10n.settings_cacheMaintenance,
          child: SettingsColumns(
            left: _clearCache(context, ref, ai: false),
            right: _clearCache(context, ref, ai: true),
          ),
        ),
      ],
    );
  }

  Widget _clearCache(BuildContext context, WidgetRef ref, {required bool ai}) =>
      SettingsTile(
        controlWrapWidth: 300 * MediaQuery.textScalerOf(context).scale(1),
        title: Text(
          ai
              ? context.l10n.autocomplete_clearAiCache
              : context.l10n.autocomplete_clearDanbooruCache,
        ),
        trailing: OutlinedButton.icon(
          key: Key(
            ai ? 'settings-clear-ai-cache' : 'settings-clear-danbooru-cache',
          ),
          onPressed: () async {
            final database = ref.read(autocompleteCacheDatabaseProvider);
            final count = ai
                ? await database.clearAiTranslationCache()
                : await database.clearDanbooruCache();
            if (context.mounted) {
              AppToast.success(
                context,
                context.l10n.autocomplete_cacheCleared(count),
              );
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l10n.settings_clear),
        ),
      );
}

Future<int> _loadCooccurrenceCount(WidgetRef ref) async {
  try {
    final manager = await ref.read(databaseManagerProvider.future);
    return await manager.cooccurrenceDataSource.getCount();
  } catch (_) {
    return 0;
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: ref.read(tagCatalogRepositoryProvider).metadata(),
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        return SettingsTile(
          leading: Icon(
            metadata == null ? Icons.hourglass_top : Icons.check_circle_outline,
          ),
          title: Text(context.l10n.autocomplete_baseCatalog),
          subtitle: Text(
            metadata == null
                ? context.l10n.common_loading
                : context.l10n.autocomplete_catalogStatus(
                    metadata['tag_count'] ?? '0',
                    metadata['data_version'] ?? '-',
                  ),
          ),
        );
      },
    );
  }
}
