import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/canvas_channel_provider.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/online_gallery_blacklist_provider.dart';
import '../../providers/rag_model_download_provider.dart';
import '../../providers/rag_provider.dart';
import '../../providers/settings_navigation_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../ui/settings/settings_format.dart';
import '../../ui/settings/settings_page.dart';
import '../../ui/settings/settings_search.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/danbooru_login_dialog.dart';
import 'settings_accounts.dart';
import 'settings_agent.dart';
import 'settings_backups.dart';
import 'settings_connections.dart';
import 'settings_data.dart';
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

SettingsPageId settingsPageForLegacy(int section, {bool bridge = false}) =>
    switch (section) {
      0 => SettingsPageId.account,
      1 => SettingsPageId.appearance,
      2 => SettingsPageId.generation,
      3 => SettingsPageId.storage,
      4 => SettingsPageId.privacy,
      5 => SettingsPageId.network,
      6 => SettingsPageId.shortcuts,
      7 => SettingsPageId.models,
      8 => SettingsPageId.bridges,
      9 => SettingsPageId.about,
      10 => SettingsPageId.upscale,
      11 => SettingsPageId.agent,
      12 => SettingsPageId.rag,
      _ => SettingsPageId.overview,
    };

SettingsPageId settingsPageFromUri(Uri uri) =>
    uri.queryParameters['bridge'] == '1'
    ? SettingsPageId.bridges
    : switch (uri.queryParameters['section']) {
        'local-upscale' || 'localUpscale' => SettingsPageId.upscale,
        'storage' => SettingsPageId.storage,
        'agent' => SettingsPageId.agent,
        'rag' => SettingsPageId.rag,
        'models' || 'promptAssistant' => SettingsPageId.models,
        'integrations' => SettingsPageId.bridges,
        'account' => SettingsPageId.account,
        'appearance' => SettingsPageId.appearance,
        'shortcuts' => SettingsPageId.shortcuts,
        'privacy' => SettingsPageId.privacy,
        'network' => SettingsPageId.network,
        _ => SettingsPageId.overview,
      };

/// Reusable dialogs remain owned by their existing providers.
class SettingsWiring extends ConsumerStatefulWidget {
  const SettingsWiring({
    super.key,
    this.initialPage = SettingsPageId.overview,
    this.initialQuery = '',
  });
  final SettingsPageId initialPage;
  final String initialQuery;
  @override
  ConsumerState<SettingsWiring> createState() => _SettingsWiringState();
}

class _SettingsWiringState extends ConsumerState<SettingsWiring> {
  late SettingsPageId _page = widget.initialPage;
  Timer? _cacheTimer;
  @override
  void didUpdateWidget(covariant SettingsWiring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) _page = widget.initialPage;
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    super.dispose();
  }

  void _run(FutureOr<void> Function() action) {
    unawaited(
      Future<void>.sync(action).catchError((Object _) {
        if (mounted) {
          AppToast.error(context, context.l10n.styleExplore_operationFailed);
        }
      }),
    );
  }

  Future<void> _pick(SettingKey key, SettingsValueLabel label) async {
    final before = ref.read(settingsValuesProvider)[key];
    final path =
        key == SettingKey.ragPythonPath || key == SettingKey.completionSoundFile
        ? (await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: key == SettingKey.ragPythonPath
                ? ['exe']
                : ['mp3', 'wav', 'ogg', 'flac'],
          ))?.files.single.path
        : await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;
    if (ref.read(settingsValuesProvider)[key] != before) {
      throw StateError('Path changed while choosing');
    }
    await ref
        .read(settingsEditsProvider.notifier)
        .change(key, path, title: settingTitle(context, key), label: label);
    ref.invalidate(settingsFoldersProvider);
    ref.invalidate(settingsStorageDataProvider);
  }

  Future<void> _openPath(SettingKey key) async {
    final value = ref.read(settingsValuesProvider)[key] as String?;
    if (value != null) {
      await SettingsStorageActions(
        context,
        ref,
      ).open(File(value).existsSync() ? File(value).parent.path : value);
      return;
    }
    final folder = switch (key) {
      SettingKey.imageSavePath => SettingsFolder.images,
      SettingKey.vibePath => SettingsFolder.vibes,
      SettingKey.appDataPath => SettingsFolder.appData,
      _ => null,
    };
    if (folder == null) throw StateError('A path has not been selected');
    await SettingsStorageActions(context, ref).openFolder(folder);
  }

  Future<bool> _instructions(
    String global,
    String prefix,
    String expectedGlobal,
    String expectedPrefix,
  ) async {
    try {
      await ref
          .read(settingsAgentBackendProvider)
          .saveInstructions(
            global: global,
            prefix: prefix,
            expectedGlobal: expectedGlobal,
            expectedPrefix: expectedPrefix,
          );
      return true;
    } catch (_) {
      if (mounted) {
        AppToast.error(context, context.l10n.set_agInstructionsFailed);
      }
      return false;
    }
  }

  SettingsActions _actions(SettingsViewData data) {
    final label = settingsValueLabels(context, data);
    final edits = ref.read(settingsEditsProvider.notifier);
    final account = SettingsAccountActions(context, ref);
    final shortcuts = SettingsShortcutActions(context, ref);
    final storage = SettingsStorageActions(context, ref);
    final models = SettingsModelActions(context, ref);
    final agent = SettingsAgentActions(context, ref);
    final agentBackend = ref.read(settingsAgentBackendProvider);
    final rag = ref.read(ragControllerProvider.notifier);
    final plans = ref.read(settingsRagSessionProvider.notifier);
    final upscale = ref.read(settingsUpscaleOperationProvider.notifier);
    final connections = SettingsConnectionActions(context, ref);
    final backup = SettingsBackupActions(context, ref);
    final system = SettingsSystemActions(context, ref);
    return SettingsActions(
      onOpenPage: (page) => setState(() {
        _page = page;
      }),
      onChanged: (key, value) => _run(
        () => edits.change(
          key,
          value,
          title: settingTitle(context, key),
          label: label,
        ),
      ),
      onReset: (key) => _run(
        () => edits.reset(key, title: settingTitle(context, key), label: label),
      ),
      onResetPage: (page) => _run(
        () => edits.resetPage(
          page,
          title: SettingsFormat.page(context, page),
          label: label,
        ),
      ),
      onUndo: (id) => _run(() => edits.undo(id)),
      onPickPath: (key) => _run(() => _pick(key, label)),
      onOpenPath: (key) => _run(() => _openPath(key)),
      onRestart: () => _run(system.restart),
      onPreviewSound: () => _run(() async {
        final sound = ref
            .read(notificationSettingsNotifierProvider)
            .customSoundPath;
        if (!await ref.read(notificationSoundPreviewProvider)(sound)) {
          throw StateError('Sound preview failed');
        }
      }),
      onPreviewNotification: () =>
          AppToast.success(context, context.l10n.set_apPreview),
      onSwitchAccount: (id) => _run(() => account.switchTo(id)),
      onAddAccount: () => _run(account.add),
      onEditAccount: (id) => _run(() => account.edit(id)),
      onUpdateCredentials: (id) => _run(() => account.credentials(id)),
      onSetDefaultAccount: (id) => _run(
        () => ref
            .read(accountManagerNotifierProvider.notifier)
            .setDefaultAccountId(id),
      ),
      onDeleteAccount: (id) => _run(() => account.delete(id)),
      onOpenAccountPortal: () => _run(account.portal),
      onChannelChanged: (value) => _run(
        () => ref.read(canvasChannelNotifierProvider.notifier).set(value),
      ),
      onShortcutRecorded: (id, keys) => _run(() => shortcuts.record(id, keys)),
      onShortcutCleared: (id) => _run(() => shortcuts.clear(id)),
      onShortcutReset: (id) => _run(() => shortcuts.reset(id)),
      onShortcutsResetAll: () => _run(shortcuts.resetAll),
      onShortcutsImport: () => _run(shortcuts.importConfig),
      onShortcutsExport: () => _run(shortcuts.exportConfig),
      onShowShortcutHelp: shortcuts.help,
      onRecomputeStorage: storage.refresh,
      onAddGalleryRoot: () => _run(storage.addRoot),
      onRemoveGalleryRoot: (id) => _run(() => storage.removeRoot(id)),
      onOpenGalleryRoot: (id) => _run(() => storage.open(id)),
      onImportTagIndex: () => _run(storage.importTags),
      onRescanGallery: () => _run(storage.rescan),
      onCleanThumbnails: () => _run(storage.cleanThumbnails),
      onOpenFolder: (folder) => _run(() => storage.openFolder(folder)),
      onClearCache: (kind) => _run(() => storage.clearCache(kind)),
      onResetCacheStats: storage.resetStatistics,
      onUpdateDictionary: (kind) => _run(
        () => ref.read(settingsDictionaryUpdateProvider.notifier).start(kind),
      ),
      onCancelDictionaryUpdate: () =>
          ref.read(settingsDictionaryUpdateProvider.notifier).cancel(),
      onImportTagSemantics: () => _run(storage.importTagSemantics),
      onExportTagSemantics: () => _run(storage.exportTagSemantics),
      onAddProvider: () => _run(models.edit),
      onImportModelConfig: () => _run(models.importConfig),
      onCopyModelConfig: () => _run(models.copy),
      onTestProvider: (id) => _run(() => models.test(id)),
      onProviderEnabled: (id, value) => _run(() => models.enabled(id, value)),
      onProviderField: (id, field, value) =>
          _run(() => models.field(id, field, value)),
      onRefreshModels: (id) => _run(() => models.refresh(id)),
      onAddModel: (id) => _run(() => models.addModel(id)),
      onRemoveModel: (id, model) => _run(() => models.removeModel(id, model)),
      onProviderAdvanced: (id) => _run(() => models.edit(id)),
      onDeleteProvider: (id) => _run(() => models.delete(id)),
      onAssign:
          (
            task, {
            providerId,
            modelId,
            presetId,
            reasoningEffort,
            clearReasoningEffort = false,
          }) => _run(
            () => models.assign(
              task,
              providerId: providerId,
              modelId: modelId,
              presetId: presetId,
              reasoningEffort: reasoningEffort,
              clearReasoningEffort: clearReasoningEffort,
            ),
          ),
      onEditPreset: (id) => _run(() => models.editPreset(id)),
      onRequestDetails: (id) => _run(() => models.requestDetails(id)),
      onDeletePreset: (id) => _run(() => models.deletePreset(id)),
      onSaveInstructions:
          ({
            required global,
            required prefix,
            required expectedGlobal,
            required expectedPrefix,
          }) => _instructions(global, prefix, expectedGlobal, expectedPrefix),
      onSaveSystemPrompt:
          ({
            required scope,
            required text,
            required workspaceId,
            required expectedText,
          }) async {
            try {
              await agentBackend.saveSystemPrompt(
                scope: scope,
                text: text,
                workspaceId: workspaceId,
                expectedGlobal: expectedText,
                expectedWorkspace: expectedText,
              );
              return true;
            } catch (_) {
              return false;
            }
          },
      onViewBuiltinPrompt: () => _run(() => agent.viewPrompt(builtin: true)),
      onViewFinalPrompt: () => _run(agent.viewPrompt),
      onExtensionEnabled: (id, value) =>
          _run(() => agentBackend.extension(id, enabled: value)),
      onRemoveExtension: (id) =>
          _run(() => agentBackend.extension(id, remove: true)),
      onAddExtension: (directory) => _run(() => agent.addExtension(directory)),
      onMcpEnabled: (id, value) =>
          _run(() => agentBackend.mcp(id, enabled: value)),
      onMcpMode: (id, mode) => _run(() => agentBackend.mcp(id, mode: mode)),
      onMcpLogin: (id) => _run(() => agentBackend.mcpLogin(id)),
      onEditMcp: (id) => _run(() => agent.editMcp(id)),
      onRemoveMcp: (id) => _run(() => agentBackend.mcp(id, remove: true)),
      onOpenAgent: () => _run(() async {
        if (!ref.read(naiAgentUiPreferencesProvider).settings.panelExpanded) {
          await ref.read(naiAgentWindowControllerProvider).toggle();
        }
        if (mounted) context.go('/generation');
      }),
      onRagSourceEnabled: (kind, value) =>
          _run(() => plans.sourceEnabled(kind, value)),
      onRagPause: (kind) =>
          _run(() => rag.pause(source: settingsRagSource(kind))),
      onRagResume: (kind) => _run(
        () => runSettingsRagStartup(
          ref,
          context,
          kind,
          () => rag.resume(source: settingsRagSource(kind)),
        ),
      ),
      onRagBuild: (kind) => _run(
        () => runSettingsRagStartup(
          ref,
          context,
          kind,
          () => plans.preview(kind),
        ),
      ),
      onRagRebuild: (kind) => _run(
        () => runSettingsRagStartup(
          ref,
          context,
          kind,
          () => plans.preview(kind, rebuild: true),
        ),
      ),
      onRagStartPlan: () => _run(() async {
        final kind = ref.read(settingsRagSessionProvider).plan?.kind;
        if (kind != null) {
          await runSettingsRagStartup(ref, context, kind, plans.start);
        }
      }),
      onRagCancelPlan: plans.cancelPlan,
      onRagClear: (kind) =>
          _run(() => rag.clear(source: settingsRagSource(kind))),
      onRagRefresh: () => _run(rag.refresh),
      onRagCheckRuntime: () {
        ref.invalidate(ragRuntimeInfoProvider);
        ref.invalidate(settingsRagWeightsProvider);
      },
      onRagInstallRuntime: ({required cuda}) =>
          _run(() => rag.installRuntime(cuda: cuda)),
      onRagCancelInstall: rag.cancelInstall,
      onRagUsePython: () => _run(() async {
        final environment = await ref.read(ragRuntimeInfoProvider.future);
        await rag.installRuntime(cuda: environment.cuda);
      }),
      onRagDownload: (model) => _run(
        () => ref
            .read(ragModelDownloadProvider.notifier)
            .download(
              model == SettingsRagModel.embedder ? 'embedding' : 'reranker',
            ),
      ),
      onRagCancelDownload: () =>
          ref.read(ragModelDownloadProvider.notifier).cancel(),
      onRagDiscoverModels: () => _run(plans.discover),
      onUpscaleInstall: (id) => _run(() => upscale.install(id)),
      onUpscaleCancel: upscale.cancel,
      onUpscaleRemove: (id) => _run(() => upscale.remove(id)),
      onUpscaleImport: () => _run(upscale.importModel),
      onCopyKritaEndpoint: () => _run(connections.copyEndpoint),
      onRegenerateKritaSession: () => _run(
        () =>
            ref.read(kritaBridgeNotifierProvider.notifier).regenerateSession(),
      ),
      onOpenKritaDiscovery: () => _run(connections.openDiscovery),
      onCopyAgentTakeover: () => _run(connections.copyTakeover),
      onEndAgentConnections: () => _run(
        () => ref.read(kritaBridgeNotifierProvider.notifier).disconnectAgents(),
      ),
      onTestComfy: () => _run(connections.testComfy),
      onCheckEndpoints: () =>
          _run(() => ref.read(settingsNetworkProvider.notifier).check()),
      onAddBlacklistTag: (tag) => _run(
        () => ref
            .read(onlineGalleryBlacklistNotifierProvider.notifier)
            .addLocalTag(tag),
      ),
      onRemoveBlacklistTag: (tag) => _run(
        () => ref
            .read(onlineGalleryBlacklistNotifierProvider.notifier)
            .removeLocalTag(tag),
      ),
      onSyncBlacklist: () => _run(
        () =>
            ref.read(onlineGalleryBlacklistNotifierProvider.notifier).syncNow(),
      ),
      onDanbooruLogin: () => _run(
        () => showDialog<void>(
          context: context,
          builder: (_) => const DanbooruLoginDialog(),
        ),
      ),
      onExportPreferences: () => _run(backup.exportConfig),
      onImportPreferences: () => _run(backup.importConfig),
      onUndoImport: () => _run(backup.undoImport),
      onResetScopes: (scopes) => _run(() => backup.reset(scopes)),
      onRestoreBackup: (id) => _run(() => backup.restore(id)),
      onCheckUpdate: () => _run(system.checkUpdate),
      onInstallUpdate: () => _run(system.installUpdate),
      onOpenChangelog: () => _run(system.changelog),
      onCopyDiagnostics: () => _run(() async {
        final status = ref.read(ragControllerProvider);
        await Clipboard.setData(
          ClipboardData(
            text: settingsDiagnostics(
              version: AppVersion.fullVersion,
              os: Platform.operatingSystemVersion,
              runtime: Platform.version.split(' ').first,
              ragEnabled: ref.read(ragSettingsProvider).enabled,
              indexed: status.indexed,
              runtimeReady: status.runtimeReady,
              providers: ref
                  .read(promptAssistantConfigProvider)
                  .providers
                  .length,
            ),
          ),
        );
      }),
      onOpenRepository: () => _run(
        () => system.openUrl(
          'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher',
        ),
      ),
      onOpenUpstream: () => _run(
        () => system.openUrl(
          'https://github.com/Aaalice233/Aaalice_NAI_Launcher',
        ),
      ),
      onOpenLicenses: system.licenses,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsAccountOpenRequestProvider,
      (_, __) => setState(() => _page = SettingsPageId.account),
    );
    ref.listen(
      settingsBridgeOpenRequestProvider,
      (_, __) => setState(() => _page = SettingsPageId.bridges),
    );
    final data = settingsViewData(context, ref, _page);
    if (_page == SettingsPageId.dictionaries &&
        data.values.flag(SettingKey.cacheStatsAutoRefresh)) {
      _cacheTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          ref.invalidate(settingsCacheStatsProvider);
          ref.invalidate(settingsDictionaryDataProvider);
          ref.invalidate(settingsCacheFootprintProvider);
        }
      });
    } else {
      _cacheTimer?.cancel();
      _cacheTimer = null;
    }
    return SettingsPage(
      data: data,
      actions: _actions(data),
      initialQuery: widget.initialQuery,
    );
  }
}
