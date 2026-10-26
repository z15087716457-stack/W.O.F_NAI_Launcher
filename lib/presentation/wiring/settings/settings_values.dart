import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/autocomplete/autocomplete_settings.dart' as autocomplete;
import '../../../core/rag/rag_settings.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/update_check_service.dart';
import '../../../core/utils/app_language.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/hive_storage_helper.dart';
import '../../../data/models/settings/proxy_settings.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_mode_provider.dart';
import '../../providers/canvas_settings_provider.dart';
import '../../providers/comfyui/comfyui_provider.dart';
import '../../providers/font_provider.dart';
import '../../providers/generation/generation_settings_notifiers.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../providers/history_click_behavior_provider.dart';
import '../../providers/image_save_settings_provider.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/online_gallery_blacklist_provider.dart';
import '../../providers/proxy_settings_provider.dart';
import '../../providers/settings_font_scale_provider.dart';
import '../../providers/share_image_settings_provider.dart';
import '../../providers/shortcuts_provider.dart';
import '../../providers/simple_output_viewer_provider.dart';
import '../../providers/simple_viewer_group_batches_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/update_provider.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_agent.dart';
import '../../../core/cache/thumbnail_cache_service.dart';

final settingsRefreshProvider = StateProvider<int>((ref) => 0);

String settingsSeedModel(UpscaleWorkflowSettings settings) =>
    settings.localModel.startsWith('seedvr2-')
    ? settings.localModel
    : settings.localSeedvr2Model;

final settingsValuesProvider = Provider<SettingsValues>((ref) {
  ref.watch(settingsRefreshProvider);
  final store = ref.watch(localStorageServiceProvider);
  ref.watch(themeNotifierProvider);
  final font = ref.watch(fontNotifierProvider);
  final locale = ref.watch(localeNotifierProvider);
  final sound = ref.watch(notificationSettingsNotifierProvider);
  final save = ref.watch(imageSaveSettingsNotifierProvider);
  final privacy = ref.watch(shareImageSettingsProvider);
  final rag = ref.watch(ragSettingsProvider);
  final proxy = ref.watch(proxySettingsNotifierProvider);
  final shortcuts = ref.watch(shortcutConfigNotifierProvider).valueOrNull;
  final agent = ref.watch(naiAgentUiPreferencesProvider).settings;
  final upscale = ref.watch(imageWorkflowControllerProvider).upscale;
  final seedId = settingsSeedModel(upscale);
  final seed = upscale.localSeedvr2Options[seedId] ?? const Seedvr2Options();
  final comfy = ref.watch(comfyUISettingsProvider);
  String? path(String? value) => value == null || value.isEmpty ? null : value;
  return SettingsValues({
    SettingKey.themeMode: store.getStudioThemeMode(),
    SettingKey.fontFamily: font == FontConfig.defaultFont ? 'system' : font.key,
    SettingKey.settingsFontScale: ref.watch(settingsFontScaleProvider),
    SettingKey.language: AppLanguage.fromLocale(locale).storageCode,
    SettingKey.reduceMotion: ref.watch(canvasReducedMotionNotifierProvider),
    SettingKey.completionSound: sound.soundEnabled,
    SettingKey.completionSoundFile: path(sound.customSoundPath),
    SettingKey.historyClick:
        ref.watch(historyClickBehaviorNotifierProvider) ==
            HistoryClickBehavior.selectPreview
        ? 'linkedPreview'
        : 'openDetail',
    SettingKey.outputViewer: ref.watch(simpleOutputViewerNotifierProvider)
        ? 'simple'
        : 'canvas',
    SettingKey.simpleViewerGroupBatches: ref.watch(
      simpleViewerGroupBatchesProvider,
    ),
    SettingKey.canvasLockCamera: ref.watch(canvasLockCameraNotifierProvider),
    SettingKey.canvasZoomToFill: ref.watch(canvasZoomToFillNotifierProvider),
    SettingKey.shortcutsEnabled: shortcuts?.enableShortcuts ?? true,
    SettingKey.shortcutsInTooltips: shortcuts?.showShortcutInTooltip ?? true,
    SettingKey.shortcutsInMenus: shortcuts?.showInMenus ?? false,
    SettingKey.navNumberBadges: shortcuts?.showShortcutBadges ?? true,
    SettingKey.costWarning: privacy.warnHighAnlasCost,
    SettingKey.costThreshold: privacy.highAnlasCostThreshold.toDouble(),
    SettingKey.intervalLimit: privacy.limitGenerationInterval,
    SettingKey.intervalSeconds: privacy.generationIntervalSeconds.toDouble(),
    SettingKey.intervalJitter: privacy.generationIntervalJitterPercent
        .toDouble(),
    SettingKey.wheelWeight: ref.watch(promptWeightScrollSettingsProvider),
    SettingKey.wheelModifier: ref.watch(
      promptWeightScrollModifierSettingsProvider,
    ),
    SettingKey.relatedTags: ref
        .watch(autocomplete.autocompleteSettingsProvider)
        .relatedTagsEnabled,
    SettingKey.imageSavePath: path(save.customPath),
    SettingKey.autoSave: save.autoSave,
    SettingKey.vibePath: path(
      store.getSetting<String>(StorageKeys.vibeLibrarySavePath),
    ),
    SettingKey.galleryQuality:
        ref.watch(
              localGalleryNotifierProvider.select((s) => s.thumbnailQuality),
            ) ==
            GalleryThumbnailQuality.sd
        ? 'standard'
        : 'high',
    SettingKey.appDataPath: path(HiveStorageHelper.instance.getCustomPath()),
    SettingKey.cacheStatsAutoRefresh:
        store.getSetting<bool>('settings_cache_stats_auto_refresh') ?? true,
    SettingKey.agentModel: agent.modelId.isEmpty
        ? null
        : jsonEncode([agent.providerId, agent.modelId]),
    SettingKey.agentEnterToSend: agent.enterToSend,
    SettingKey.agentMaxRequests: agent.maxRequestsPerRun.toDouble(),
    SettingKey.ragEnabled: rag.enabled,
    SettingKey.ragContext: rag.mode == RagContextMode.before
        ? 'beforeCursor'
        : 'around',
    SettingKey.ragDevice: rag.device.name,
    SettingKey.ragEmbedPath: path(rag.embedding),
    SettingKey.ragRerankPath: path(rag.reranker),
    SettingKey.ragPythonPath: path(rag.python),
    SettingKey.upscaleDefault: upscale.backend == UpscaleBackend.local
        ? 'local:${upscale.localModel}'
        : upscale.backend.name,
    SettingKey.seedVramMode: seed.blocksToSwap > 0 ? 'low' : 'recommended',
    SettingKey.seedCpuOffload: seed.blocksToSwap.toDouble(),
    SettingKey.seedVaeTiling: seed.vaeTiled,
    SettingKey.seedVaeTile: seed.vaeTileSize.toString(),
    SettingKey.seedInputNoise: seed.inputNoise,
    SettingKey.seedLatentNoise: seed.latentNoise,
    SettingKey.kritaBridge: ref.watch(kritaBridgeNotifierProvider).enabled,
    SettingKey.comfyEnabled: comfy.enabled,
    SettingKey.comfyUrl: comfy.serverUrl,
    SettingKey.proxyEnabled: proxy.enabled,
    SettingKey.proxyMode: proxy.mode == ProxyMode.auto ? 'system' : 'manual',
    SettingKey.proxyHost: proxy.manualHost,
    SettingKey.proxyPort: proxy.manualPort?.toString(),
    SettingKey.stripMetadata: privacy.stripMetadataForCopyAndDrag,
    SettingKey.confirmExternalSend: privacy.warnExternalImageSend,
    SettingKey.confirmDangerous: privacy.confirmDangerousActions,
    SettingKey.noOverwrite: privacy.preventOverwrite,
    SettingKey.blacklistAutoSync: ref
        .watch(onlineGalleryBlacklistNotifierProvider)
        .autoSyncOnStartup,
    SettingKey.includePrerelease: store.getIncludePrereleaseUpdates(),
    SettingKey.logToFile: store.getFileLoggingEnabled(),
    SettingKey.defaultAccount: ref
        .watch(accountManagerNotifierProvider)
        .accounts
        .where((a) => a.isDefault)
        .firstOrNull
        ?.id,
    SettingKey.autoLogin: ref.watch(authModeNotifierProvider).autoLogin,
  });
});

/// One adapter per existing authority. No opening the page writes preferences.
class SettingsValueStore {
  SettingsValueStore(this.ref);
  final Ref ref;
  LocalStorageService get storage => ref.read(localStorageServiceProvider);
  SettingsValues get values => ref.read(settingsValuesProvider);

  Future<void> write(SettingKey key, Object? value, {String? seedModel}) async {
    final spec = SettingSpec.of(key);
    if (spec.kind == SettingKind.toggle && value is! bool ||
        spec.kind == SettingKind.number && (value is! num || !value.isFinite) ||
        (spec.kind == SettingKind.path ||
                spec.kind == SettingKind.text ||
                spec.kind == SettingKind.choice) &&
            value != null &&
            value is! String) {
      throw ArgumentError.value(value, key.name);
    }
    final tile = key == SettingKey.seedVaeTile && value is String
        ? int.tryParse(value)
        : null;
    final customTile =
        tile != null && tile >= 128 && tile <= 4096 && tile % 64 == 0;
    if (spec.choices.isNotEmpty &&
        !spec.choices.contains(value) &&
        !customTile) {
      throw ArgumentError.value(value, key.name);
    }
    final n = value is num ? value.toDouble() : 0.0;
    if (spec.kind == SettingKind.number && (n < spec.min || n > spec.max)) {
      throw RangeError('Invalid value for ${key.name}: $n');
    }
    final b = value == true;
    final text = value is String ? value : null;
    switch (key) {
      case SettingKey.themeMode:
        await ref.read(themeNotifierProvider.notifier).setMode(text!);
      case SettingKey.fontFamily:
        await ref
            .read(fontNotifierProvider.notifier)
            .setFont(
              text == 'system'
                  ? FontConfig.defaultFont
                  : FontConfig.fromKey(text!),
            );
      case SettingKey.settingsFontScale:
        await ref.read(settingsFontScaleProvider.notifier).setFontScale(n);
      case SettingKey.language:
        await ref.read(localeNotifierProvider.notifier).setLocale(text!);
      case SettingKey.reduceMotion:
        await ref
            .read(canvasReducedMotionNotifierProvider.notifier)
            .setReduced(b);
      case SettingKey.completionSound:
        await ref
            .read(notificationSettingsNotifierProvider.notifier)
            .setSoundEnabled(b);
      case SettingKey.completionSoundFile:
        await ref
            .read(notificationSettingsNotifierProvider.notifier)
            .setCustomSoundPath(text);
      case SettingKey.historyClick:
        await ref
            .read(historyClickBehaviorNotifierProvider.notifier)
            .setBehavior(
              text == 'linkedPreview'
                  ? HistoryClickBehavior.selectPreview
                  : HistoryClickBehavior.openDetail,
            );
      case SettingKey.outputViewer:
        await ref
            .read(simpleOutputViewerNotifierProvider.notifier)
            .setSimple(text == 'simple');
      case SettingKey.simpleViewerGroupBatches:
        await ref.read(simpleViewerGroupBatchesProvider.notifier).setGrouped(b);
      case SettingKey.canvasLockCamera:
        await ref.read(canvasLockCameraNotifierProvider.notifier).setLocked(b);
      case SettingKey.canvasZoomToFill:
        await storage.setSetting(StorageKeys.canvasZoomToFill, b);
        ref.invalidate(canvasZoomToFillNotifierProvider);
      case SettingKey.shortcutsEnabled:
        await ref
            .read(shortcutConfigNotifierProvider.notifier)
            .updateSettings(enableShortcuts: b);
      case SettingKey.shortcutsInTooltips:
        await ref
            .read(shortcutConfigNotifierProvider.notifier)
            .updateSettings(showShortcutInTooltip: b);
      case SettingKey.shortcutsInMenus:
        await ref
            .read(shortcutConfigNotifierProvider.notifier)
            .updateSettings(showInMenus: b);
      case SettingKey.navNumberBadges:
        await ref
            .read(shortcutConfigNotifierProvider.notifier)
            .updateSettings(showShortcutBadges: b);
      case SettingKey.costWarning:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setWarnHighAnlasCost(b);
      case SettingKey.costThreshold:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setHighAnlasCostThreshold(n.toInt());
      case SettingKey.intervalLimit:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setLimitGenerationInterval(b);
      case SettingKey.intervalSeconds:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setGenerationIntervalSeconds(n.toInt());
      case SettingKey.intervalJitter:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setGenerationIntervalJitterPercent(n.toInt());
      case SettingKey.wheelWeight:
        await ref.read(promptWeightScrollSettingsProvider.notifier).set(b);
      case SettingKey.wheelModifier:
        await storage.setPromptWeightScrollModifier(text!);
        ref.invalidate(promptWeightScrollModifierSettingsProvider);
      case SettingKey.relatedTags:
        await ref
            .read(autocomplete.autocompleteSettingsProvider.notifier)
            .setRelatedTagsEnabled(b);
        ref.invalidate(cooccurrenceSettingsProvider);
      case SettingKey.imageSavePath:
        await ref
            .read(imageSaveSettingsNotifierProvider.notifier)
            .setCustomPath(text);
      case SettingKey.autoSave:
        await ref
            .read(imageSaveSettingsNotifierProvider.notifier)
            .setAutoSave(b);
      case SettingKey.vibePath:
        if (text == null) {
          await storage.deleteSetting(StorageKeys.vibeLibrarySavePath);
        } else {
          await storage.setSetting(StorageKeys.vibeLibrarySavePath, text);
        }
      case SettingKey.galleryQuality:
        await ref
            .read(localGalleryNotifierProvider.notifier)
            .setThumbnailQuality(
              text == 'standard'
                  ? GalleryThumbnailQuality.sd
                  : GalleryThumbnailQuality.hd,
            );
      case SettingKey.appDataPath:
        await HiveStorageHelper.instance.setCustomPath(text);
      case SettingKey.cacheStatsAutoRefresh:
        await storage.setSetting('settings_cache_stats_auto_refresh', b);
      case SettingKey.agentModel:
        final selection = text == null
            ? ['', '']
            : (jsonDecode(text) as List).cast<String>();
        if (selection.length != 2) {
          throw const FormatException('Invalid model selection');
        }
        await ref.read(settingsAgentBackendProvider).update({
          'providerId': selection[0],
          'modelId': selection[1],
        });
      case SettingKey.agentEnterToSend:
        await ref.read(settingsAgentBackendProvider).update({'enterToSend': b});
      case SettingKey.agentMaxRequests:
        await ref.read(settingsAgentBackendProvider).update({
          'maxRequestsPerRun': n.toInt(),
        });
      case SettingKey.ragEnabled:
      case SettingKey.ragContext:
      case SettingKey.ragDevice:
      case SettingKey.ragEmbedPath:
      case SettingKey.ragRerankPath:
      case SettingKey.ragPythonPath:
        final current = ref.read(ragSettingsProvider);
        await ref.read(ragSettingsProvider.notifier).update(switch (key) {
          SettingKey.ragEnabled => current.copyWith(enabled: b),
          SettingKey.ragContext => current.copyWith(
            mode: text == 'beforeCursor'
                ? RagContextMode.before
                : RagContextMode.around,
          ),
          SettingKey.ragDevice => current.copyWith(
            device: RagDevice.values.byName(text!),
          ),
          SettingKey.ragEmbedPath => current.copyWith(embedding: text ?? ''),
          SettingKey.ragRerankPath => current.copyWith(reranker: text ?? ''),
          _ => current.copyWith(python: text ?? ''),
        });
      case SettingKey.upscaleDefault:
        final controller = ref.read(imageWorkflowControllerProvider.notifier);
        if (ref.read(imageWorkflowControllerProvider).isToolRunning) {
          throw StateError('busy');
        }
        final selected = text ?? 'local:anime';
        if (selected.startsWith('local:')) {
          final model = selected.substring(6);
          if (![
                ...localUpscaleCatalog,
                ...advancedUpscaleCatalog,
              ].any((item) => item.id == model) &&
              !(await ref.read(localUpscaleModelManagerProvider).models()).any(
                (item) => item.id == model && item.installed,
              )) {
            throw ArgumentError.value(model, 'model');
          }
          await controller.setDefaultUpscale(
            UpscaleBackend.local,
            model: model,
          );
        } else {
          await controller.setDefaultUpscale(
            UpscaleBackend.values.byName(selected),
          );
        }
      case SettingKey.seedVramMode:
      case SettingKey.seedCpuOffload:
      case SettingKey.seedVaeTiling:
      case SettingKey.seedVaeTile:
      case SettingKey.seedInputNoise:
      case SettingKey.seedLatentNoise:
        final current = ref.read(imageWorkflowControllerProvider);
        if (current.isToolRunning) throw StateError('busy');
        final id = seedModel ?? settingsSeedModel(current.upscale);
        final seed =
            current.upscale.localSeedvr2Options[id] ?? const Seedvr2Options();
        if (key == SettingKey.seedCpuOffload &&
            n > Seedvr2Options.maxBlocks(id)) {
          throw RangeError('Offload exceeds the selected model limit');
        }
        final next = switch (key) {
          SettingKey.seedVramMode => seed.copyWith(
            blocksToSwap: text == 'low' ? 16 : 0,
          ),
          SettingKey.seedCpuOffload => seed.copyWith(blocksToSwap: n.toInt()),
          SettingKey.seedVaeTiling => seed.copyWith(vaeTiled: b),
          SettingKey.seedVaeTile => seed.copyWith(
            vaeTileSize: int.parse(text!),
          ),
          SettingKey.seedInputNoise => seed.copyWith(inputNoise: n),
          _ => seed.copyWith(latentNoise: n),
        };
        await ref
            .read(imageWorkflowControllerProvider.notifier)
            .setLocalSeedvr2Options(id, next);
      case SettingKey.kritaBridge:
        await ref.read(kritaBridgeNotifierProvider.notifier).setEnabled(b);
      case SettingKey.comfyEnabled:
        await storage.setSetting(StorageKeys.comfyuiEnabled, b);
        ref.invalidate(comfyUISettingsProvider);
      case SettingKey.comfyUrl:
        await storage.setSetting(StorageKeys.comfyuiServerUrl, text!);
        ref.invalidate(comfyUISettingsProvider);
      case SettingKey.proxyEnabled:
        await ref.read(proxySettingsNotifierProvider.notifier).setEnabled(b);
      case SettingKey.proxyMode:
        await ref
            .read(proxySettingsNotifierProvider.notifier)
            .setMode(text == 'system' ? ProxyMode.auto : ProxyMode.manual);
      case SettingKey.proxyHost:
      case SettingKey.proxyPort:
        final proxy = ref.read(proxySettingsNotifierProvider);
        final host = key == SettingKey.proxyHost ? text : proxy.manualHost;
        final port = key == SettingKey.proxyPort
            ? (text == null || text.isEmpty ? null : int.parse(text))
            : proxy.manualPort;
        if (port != null && (port < 1 || port > 65535)) {
          throw RangeError('Invalid proxy port');
        }
        await ref
            .read(proxySettingsNotifierProvider.notifier)
            .setManualFields(host: host, port: port);
      case SettingKey.stripMetadata:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setStripMetadataForCopyAndDrag(b);
      case SettingKey.confirmExternalSend:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setWarnExternalImageSend(b);
      case SettingKey.confirmDangerous:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setConfirmDangerousActions(b);
      case SettingKey.noOverwrite:
        await ref
            .read(shareImageSettingsProvider.notifier)
            .setPreventOverwrite(b);
      case SettingKey.blacklistAutoSync:
        await ref
            .read(onlineGalleryBlacklistNotifierProvider.notifier)
            .setAutoSyncOnStartup(b);
      case SettingKey.includePrerelease:
        await ref.read(updateCheckServiceReadyProvider.future);
        await ref.read(updateStateProvider.notifier).setIncludePrerelease(b);
      case SettingKey.logToFile:
        await AppLogger.setFileLoggingEnabled(b);
        await storage.setFileLoggingEnabled(AppLogger.fileLoggingEnabled);
      case SettingKey.defaultAccount:
        await ref
            .read(accountManagerNotifierProvider.notifier)
            .setDefaultAccountId(text);
      case SettingKey.autoLogin:
        await ref.read(authModeNotifierProvider.notifier).setAutoLogin(b);
    }
    ref.read(settingsRefreshProvider.notifier).state++;
  }
}
