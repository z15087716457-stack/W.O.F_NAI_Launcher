import '../../../widgets/common/translation_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/autocomplete/autocomplete_providers.dart';
import '../../../../core/autocomplete/autocomplete_settings.dart';
import '../../../../core/autocomplete/zh_dictionary_service.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/app_toast.dart';
import 'settings_card.dart';
import 'settings_tile.dart';
import 'settings_ui_theme.dart';

class DataSourceCacheSettings extends ConsumerWidget {
  const DataSourceCacheSettings({
    super.key,
    this.controlsOnly = false,
    this.cacheOnly = false,
  }) : assert(!(controlsOnly && cacheOnly));
  final bool controlsOnly, cacheOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(autocompleteSettingsProvider);
    final zh = controlsOnly
        ? null
        : ref.watch(zhDictionaryServiceProvider).state;
    final notifier = ref.read(autocompleteSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            title: controlsOnly
                ? settingsText(context, '标签扩展', 'Tag expansion', 'タグ検索')
                : context.l10n.autocomplete_dataSourcesTitle,
            icon: Icons.auto_awesome,
            child: Column(
              children: [
                if (!cacheOnly) ...[
                  SettingsSwitchTile(
                    title: Text(context.l10n.autocomplete_relatedTagsTitle),
                    subtitle: Text(
                      context.l10n.autocomplete_relatedTagsSubtitle,
                    ),
                    value: settings.relatedTagsEnabled,
                    onChanged: notifier.setRelatedTagsEnabled,
                  ),
                ],
                if (!controlsOnly) ...[
                  _CatalogStatus(ref: ref),
                  _ZhDictionaryStatus(state: zh!),
                  FutureBuilder<int>(
                    future: _loadCooccurrenceCount(ref),
                    builder: (context, snapshot) => SettingsTile(
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(context.l10n.autocomplete_cooccurrence),
                      subtitle: Text(
                        context.l10n.autocomplete_entryCount(
                          snapshot.data ?? 0,
                        ),
                      ),
                    ),
                  ),
                  SettingsTile(
                    title: Text(context.l10n.autocomplete_clearDanbooruCache),
                    trailing: OutlinedButton.icon(
                      onPressed: () async {
                        final count = await ref
                            .read(autocompleteCacheDatabaseProvider)
                            .clearDanbooruCache();
                        if (context.mounted) {
                          AppToast.success(
                            context,
                            context.l10n.autocomplete_cacheCleared(count),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(settingsText(context, '清理', 'Clear', '消去')),
                    ),
                  ),
                  SettingsTile(
                    title: Text(context.l10n.autocomplete_clearAiCache),
                    trailing: OutlinedButton.icon(
                      onPressed: () async {
                        final count = await ref
                            .read(autocompleteCacheDatabaseProvider)
                            .clearAiTranslationCache();
                        if (context.mounted) {
                          AppToast.success(
                            context,
                            context.l10n.autocomplete_cacheCleared(count),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(settingsText(context, '清理', 'Clear', '消去')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<int> _loadCooccurrenceCount(WidgetRef ref) async {
  try {
    final manager = await ref.read(databaseManagerProvider.future);
    return manager.cooccurrenceDataSource.getCount();
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

class _ZhDictionaryStatus extends ConsumerWidget {
  const _ZhDictionaryStatus({required this.state});

  final ZhDictionaryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(zhDictionaryServiceProvider);
    return SettingsTile(
      leading: state.isBusy
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: state.progress > 0 ? state.progress : null,
              ),
            )
          : state.isInstalled
          ? const TranslationIcon()
          : const Icon(Icons.download_outlined),
      title: Text(context.l10n.autocomplete_zhDictionary),
      subtitle: Text(
        state.error ??
            (state.isInstalled
                ? context.l10n.autocomplete_zhInstalled(
                    state.tagCount,
                    state.version?.substring(0, 8) ?? '-',
                  )
                : context.l10n.autocomplete_zhNotInstalled),
      ),
      trailing: Wrap(
        spacing: 6,
        children: [
          if (state.isBusy)
            IconButton(
              tooltip: context.l10n.common_cancel,
              onPressed: service.cancelInstall,
              icon: const Icon(Icons.close),
            )
          else ...[
            if (state.isInstalled)
              IconButton(
                tooltip: context.l10n.autocomplete_checkUpdate,
                onPressed: () => service.checkForUpdate(force: true),
                icon: const Icon(Icons.refresh),
              ),
            FilledButton.tonal(
              onPressed: () async {
                if (!state.isInstalled) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.autocomplete_zhDictionary),
                      content: Text(context.l10n.autocomplete_zhInstallPrompt),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.common_cancel),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.l10n.autocomplete_install),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                try {
                  await service.installOrUpdate();
                } catch (error) {
                  if (context.mounted) {
                    AppToast.error(context, error.toString());
                  }
                }
              },
              child: Text(
                state.isInstalled
                    ? state.updateAvailable
                          ? context.l10n.autocomplete_update
                          : context.l10n.autocomplete_repair
                    : context.l10n.autocomplete_install,
              ),
            ),
            if (state.isInstalled)
              IconButton(
                tooltip: context.l10n.autocomplete_remove,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.autocomplete_remove),
                      content: Text(context.l10n.autocomplete_removeConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.common_cancel),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.l10n.common_confirm),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await service.remove();
                },
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ],
      ),
    );
  }
}
