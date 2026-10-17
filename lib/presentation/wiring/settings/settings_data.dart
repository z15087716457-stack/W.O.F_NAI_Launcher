import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/services/system_font_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../data/services/anlas_statistics_service.dart';
import '../../../data/services/anlas_usage_metrics.dart';
import '../../../data/services/danbooru_auth_service.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/canvas_channel_provider.dart';
import '../../providers/cost_estimate_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/online_gallery_blacklist_provider.dart';
import '../../providers/proxy_settings_provider.dart';
import '../../providers/rag_model_download_provider.dart';
import '../../providers/rag_provider.dart';
import '../../providers/update_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../ui/settings/settings_format.dart';
import 'settings_accounts.dart';
import 'settings_agent.dart';
import 'settings_backups.dart';
import 'settings_connections.dart';
import 'settings_edits.dart';
import 'settings_inventory.dart';
import 'settings_caches.dart';
import 'settings_dictionary_update.dart';
import 'settings_models.dart';
import 'settings_rag.dart';
import 'settings_rag_startup.dart';
import 'settings_shortcuts.dart';
import 'settings_storage.dart';
import 'settings_system.dart';
import 'settings_upscale.dart';
import 'settings_values.dart';

SettingsValueLabel settingsValueLabels(
  BuildContext context,
  SettingsViewData data,
) {
  final labels = <SettingKey, Map<String, String>>{
    for (final key in SettingKey.values)
      key: {
        for (final choice in SettingSpec.of(key).choices)
          choice: SettingsFormat.choice(context, key, choice),
        for (final option in data.options[key] ?? const <SettingsOption>[])
          option.value: option.label,
      },
  };
  final l = context.l10n;
  return (key, value) {
    if (value == null) return l.set_defaultTag;
    if (value is bool) return value ? l.set_on : l.set_off;
    if (value is num) {
      return switch (key) {
        SettingKey.settingsFontScale => '${(value * 100).round()}%',
        SettingKey.costThreshold => '${value.round()} Anlas',
        SettingKey.intervalSeconds => '${value.round()} ${l.set_unitSeconds}',
        SettingKey.intervalJitter => '±${value.round()}%',
        SettingKey.seedInputNoise ||
        SettingKey.seedLatentNoise => value.toStringAsFixed(2),
        _ => '${value.round()}',
      };
    }
    return labels[key]?[value] ?? value.toString();
  };
}

Map<SettingKey, List<SettingsOption>> settingsOptions(
  BuildContext context,
  WidgetRef ref,
  List<LocalUpscaleModel> upscale,
) {
  final config = ref.watch(promptAssistantConfigProvider);
  final font = ref.watch(fontNotifierProvider);
  final availableFonts = {
    ...{
      for (final item in [...bundledPresets, ...GoogleFontPresets.all, font])
        item.key: item,
    },
    for (final name in ref.watch(systemFontsProvider).valueOrNull ?? <String>[])
      'system:$name': FontConfig(
        displayName: name,
        fontFamily: name,
        source: FontSource.system,
      ),
  };
  return {
    SettingKey.fontFamily: [
      SettingsOption(
        value: 'system',
        label: FontConfig.defaultFont.displayName,
      ),
      for (final item in availableFonts.values)
        if (item != FontConfig.defaultFont)
          SettingsOption(
            value: item.key,
            label: item.displayName,
            detail: item.source.name,
          ),
    ],
    SettingKey.defaultAccount: [
      for (final account in ref.watch(accountManagerNotifierProvider).accounts)
        SettingsOption(value: account.id, label: account.displayName),
    ],
    SettingKey.agentModel: [
      for (final provider in config.providers.where((p) => p.enabled))
        for (final model
            in config
                .modelsForProvider(providerId: provider.id)
                .where((m) => !m.isPlaceholder))
          SettingsOption(
            value: jsonEncode([provider.id, model.name]),
            label: model.displayName,
            detail: provider.name,
            mark: provider.name.characters.take(2).toString(),
            color: 0xff266eff,
          ),
    ],
    SettingKey.upscaleDefault: [
      for (final model in upscale)
        SettingsOption(value: 'local:${model.id}', label: model.name),
      const SettingsOption(value: 'comfyui', label: 'ComfyUI'),
      const SettingsOption(value: 'novelai', label: 'NovelAI'),
    ],
  };
}

SettingsViewData settingsViewData(
  BuildContext context,
  WidgetRef ref,
  SettingsPageId page,
) {
  final now = DateTime.now();
  final accounts = settingsAccountsData(
    settingsAccountFacts(ref),
    todayUsed:
        ref.watch(anlasStatisticsServiceProvider).valueOrNull?.todayCost ?? 0,
  );
  final values = ref.watch(settingsValuesProvider);
  final edits = ref.watch(settingsEditsProvider);
  final config = ref.watch(promptAssistantConfigProvider);
  final upscaleModels = page == SettingsPageId.upscale
      ? ref.watch(localUpscaleModelsProvider).valueOrNull ??
            const <LocalUpscaleModel>[]
      : [...localUpscaleCatalog, ...advancedUpscaleCatalog];
  final workflow = ref.watch(imageWorkflowControllerProvider).upscale;
  final ragSettings = ref.watch(ragSettingsProvider);
  final ragStatus = ref.watch(ragControllerProvider);
  final runtime = page == SettingsPageId.rag
      ? ref.watch(ragRuntimeInfoProvider)
      : const AsyncLoading<Never>();
  final rag = settingsRagData(
    ragSettings,
    ragStatus,
    runtime,
    ref.watch(ragModelDownloadProvider),
    ref.watch(settingsRagSessionProvider),
    page == SettingsPageId.rag
        ? ref.watch(settingsRagWeightsProvider).valueOrNull
        : null,
    indexBytes: page == SettingsPageId.rag
        ? ref.watch(settingsIndexBytesProvider).valueOrNull ?? 0
        : 0,
    preparing: ref.watch(settingsRagStartupProvider).preparing,
  );
  final storage =
      page == SettingsPageId.storage || page == SettingsPageId.overview
      ? ref.watch(settingsStorageDataProvider)
      : const AsyncLoading<SettingsStorageData>();
  final generation = ref.watch(generationRequestParamsProvider);
  final metrics = ref.watch(anlasUsageMetricsProvider).valueOrNull?.at(now);
  final translation = config.interfaceFor(LauncherInterface.translate);
  final tagTranslation = config.interfaceFor(LauncherInterface.tagTranslate);
  final blacklist = ref.watch(onlineGalleryBlacklistNotifierProvider);
  final danbooru = ref.watch(danbooruAuthProvider);
  final network = ref.watch(settingsNetworkProvider);
  final update = ref.watch(updateStateProvider);
  final models = settingsModelsData(context, ref);
  final attention = <SettingsAttention>[
    if (update.hasNewVersion)
      SettingsAttention(
        kind: SettingsAttentionKind.update,
        tone: SettingsTone.warn,
        subject: update.versionInfo?.version ?? '',
        bytes: update.versionInfo?.primaryAsset?.size ?? 0,
      ),
    for (final source in rag.sources.where(
      (s) => s.state == SettingsRagState.paused,
    ))
      SettingsAttention(
        kind: SettingsAttentionKind.ragPaused,
        tone: SettingsTone.warn,
        subject: source.kind.name,
        done: source.done,
        total: source.total,
      ),
    for (final account in accounts.accounts.where((a) => a.expired))
      SettingsAttention(
        kind: SettingsAttentionKind.credentialExpired,
        tone: SettingsTone.error,
        subject: account.name,
      ),
    for (final provider in models.providers.where(
      (p) => p.status == SettingsTone.error,
    ))
      SettingsAttention(
        kind: SettingsAttentionKind.providerDown,
        tone: SettingsTone.error,
        subject: provider.name,
      ),
  ];
  final lastScan = ref.watch(settingsLastScanProvider);
  final measured = storage.valueOrNull;
  final dictionary = page == SettingsPageId.dictionaries
      ? ref.watch(settingsDictionaryDataProvider).valueOrNull
      : null;
  final cacheFootprint = page == SettingsPageId.dictionaries
      ? ref.watch(settingsCacheFootprintProvider).valueOrNull
      : null;
  final cacheStats = page == SettingsPageId.dictionaries
      ? ref.watch(settingsCacheStatsProvider).valueOrNull
      : null;
  final locations =
      page == SettingsPageId.storage || page == SettingsPageId.overview
      ? ref.watch(settingsStorageLocationsProvider).valueOrNull
      : null;
  return SettingsViewData(
    page: page,
    values: values,
    now: now,
    version: AppVersion.versionName,
    options: settingsOptions(context, ref, upscaleModels),
    modified: {
      for (final key in SettingKey.values)
        if (values[key] !=
            (key == SettingKey.upscaleDefault
                ? 'local:anime'
                : SettingSpec.of(key).defaultValue))
          key,
    },
    lastChange: edits.last,
    recent: edits.entries.map((e) => e.change).take(5).toList(),
    restartPending: edits.restartPending,
    attention: attention,
    account: accounts,
    canvas: SettingsCanvasData(
      channel: ref.watch(canvasChannelNotifierProvider),
    ),
    shortcuts: settingsShortcutsData(context, ref),
    generation: SettingsGenerationData(
      estimate: SettingsCostEstimate(
        model: generation.model,
        width: generation.width,
        height: generation.height,
        steps: generation.steps,
        images: ref.watch(imagesPerRequestProvider),
        cost: ref.watch(estimatedCostProvider),
      ),
      hourlyUsage: metrics?.hourly ?? const [],
      warningsToday: metrics?.warnings ?? 0,
      maxSingleToday: metrics?.maxDeduction ?? 0,
      translationModel: translation.isConfigured ? translation.model : null,
      ragTagsReady:
          ragSettings.enabledFor(RagSource.tags) && ragStatus.available,
    ),
    storage: SettingsStorageData(
      slices: measured?.slices ?? const [],
      diskLabel: measured?.diskLabel ?? locations?.diskLabel ?? '',
      diskFree: measured?.diskFree,
      computing: storage.isLoading,
      roots:
          locations?.roots.map((root) {
            final previous = measured?.roots.where((r) => r.id == root.id);
            final old = previous?.firstOrNull;
            return old == null
                ? root
                : SettingsGalleryRoot(
                    id: root.id,
                    path: root.path,
                    images: old.images,
                    primary: root.primary,
                  );
          }).toList() ??
          measured?.roots ??
          const [],
      imageCount: measured?.imageCount ?? 0,
      lastScanAt: lastScan,
      scanning: ref.watch(settingsStorageBusyProvider),
      thumbnailBytes: measured?.thumbnailBytes ?? 0,
      thumbnailLimit:
          locations?.thumbnailLimit ?? measured?.thumbnailLimit ?? 0,
      folderNames: locations?.folderNames ?? measured?.folderNames ?? const {},
    ),
    dictionaries: page == SettingsPageId.dictionaries
        ? SettingsDictionaryData(
            tagCount: dictionary?.tagCount ?? 0,
            dataVersion: dictionary?.dataVersion ?? '',
            wikiCount: dictionary?.wikiCount,
            update: ref.watch(settingsDictionaryUpdateProvider),
            cooccurrence: dictionary?.cooccurrence ?? 0,
            translationModel: tagTranslation.isConfigured
                ? tagTranslation.model
                : null,
            caches: {
              if (cacheFootprint != null)
                for (final entry in cacheFootprint.entries)
                  entry.key: (entry.value.entries, entry.value.bytes),
            },
            l1: cacheStats == null
                ? null
                : SettingsCacheStat(
                    hitRate: cacheStats.l1HitRate,
                    entries: cacheStats.l1MemorySize,
                  ),
            l2: cacheStats == null
                ? null
                : SettingsCacheStat(
                    hitRate: cacheStats.l2HitRate,
                    entries: cacheStats.l2HiveSize,
                  ),
            l3: cacheStats == null
                ? null
                : SettingsCacheStat(
                    hitRate: null,
                    entries: cacheStats.l3DatabaseImageCount,
                    images: true,
                  ),
            statsUpdatedAt: cacheStats?.lastUpdated,
          )
        : const SettingsDictionaryData(),
    models: models,
    agent: settingsAgentData(ref, inspect: page == SettingsPageId.agent),
    rag: rag,
    upscale: settingsUpscaleData(
      upscaleModels,
      ref.watch(settingsUpscaleOperationProvider),
      ref.watch(advancedUpscaleInstallProvider),
      workflow,
      gpu: page == SettingsPageId.upscale
          ? ref.watch(settingsGpuProvider).valueOrNull
          : null,
    ),
    bridges: settingsBridgesData(context, ref),
    network: SettingsNetworkData(
      systemProxy: ref.watch(detectedSystemProxyProvider),
      endpoints: network.endpoints,
      checking: network.checking,
      checkedAt: network.checkedAt,
    ),
    privacy: SettingsPrivacyData(
      blacklist: blacklist.effectiveTags.toList()..sort(),
      danbooruUser: danbooru.isLoggedIn ? danbooru.user?.name : null,
      lastSyncAt: blacklist.lastSyncAt,
      syncing: blacklist.isSyncing,
    ),
    backup: page == SettingsPageId.backup
        ? ref.watch(settingsBackupDataProvider).valueOrNull ??
              const SettingsBackupData()
        : const SettingsBackupData(),
    about: settingsAboutData(
      update,
      page == SettingsPageId.about
          ? ref.watch(settingsUpdateCheckedAtProvider).valueOrNull
          : null,
    ),
  );
}
