import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/rag/rag_client.dart';
import '../../../core/rag/rag_maintenance.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/rag/rag_runtime_probe.dart';
import '../../providers/rag_model_download_provider.dart';
import '../../providers/rag_provider.dart';
import '../../ui/settings/settings_contract.dart';

RagSource settingsRagSource(SettingsRagSourceKind kind) =>
    RagSource.values.byName(kind.name);

final settingsRagWeightsProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(ragSettingsProvider);
  Future<bool> exists(String directory) async =>
      directory.isNotEmpty &&
      await File(p.join(directory, 'config.json')).exists() &&
      (await File(p.join(directory, 'model.safetensors')).exists() ||
          await File(
            p.join(directory, 'model.safetensors.index.json'),
          ).exists());
  return exists(settings.embedding);
});

SettingsRagData settingsRagData(
  RagSettings settings,
  RagStatus status,
  AsyncValue<RagRuntimeInfo> runtime,
  RagModelDownloadState download,
  SettingsRagSessionState session,
  bool? weights, {
  int indexBytes = 0,
  SettingsRagSourceKind? preparing,
}) {
  final environment = runtime.valueOrNull;
  final ready = !runtime.isLoading && environment?.ready == true;
  final python = environment?.python ?? settings.python;
  SettingsRagStep model(String name, String path, bool? available) =>
      SettingsRagStep(
        value: name,
        detail: path,
        tone: available == null
            ? SettingsTone.idle
            : available
            ? SettingsTone.ok
            : SettingsTone.warn,
      );
  return SettingsRagData(
    indexBusy: status.anyBusy,
    initializing:
        settings.enabled &&
        (status.initializing ||
            RagSource.values.any(
              (source) =>
                  !status.forSource(source).hasIndexStatus &&
                  status.forSource(source).error == null,
            )),
    initializationPhase: status.initializationPhase,
    initializationProcessed: status.initializationProcessed,
    initializationTotal: status.initializationTotal,
    runtime: SettingsRagStep(
      value: python,
      tone: ready ? SettingsTone.ok : SettingsTone.idle,
    ),
    embedder: model('EmbeddingGemma 2', settings.embedding, weights),
    device: SettingsRagStep(
      value: settings.device.name,
      tone: status.suspended ? SettingsTone.warn : SettingsTone.idle,
    ),
    sources: [
      for (final kind in SettingsRagSourceKind.values)
        () {
          final source = settingsRagSource(kind);
          final item = status.forSource(source);
          final gallery = source == RagSource.gallery;
          return SettingsRagSource(
            kind: kind,
            state: !settings.enabled
                ? SettingsRagState.off
                : status.initializing ||
                      (!item.hasIndexStatus && item.error == null)
                ? SettingsRagState.loading
                : item.busy && item.phase == 'building'
                ? SettingsRagState.building
                : item.busy && !(item.complete || item.indexed >= item.total)
                ? SettingsRagState.loading
                : item.phase == 'paused'
                ? SettingsRagState.paused
                : item.error != null
                ? SettingsRagState.error
                : item.indexed > 0 || item.complete
                ? SettingsRagState.ready
                : SettingsRagState.empty,
            known: item.hasIndexStatus,
            done: gallery
                ? item.details['visual_indexed'] ?? 0
                : item.busy && item.phase == 'building'
                ? item.processed
                : item.indexed,
            total: gallery ? item.details['images'] ?? 0 : item.total,
            secondary: gallery ? item.details['parameters_indexed'] ?? 0 : null,
            skipped: item.details['skipped'] ?? 0,
            error: item.error,
            upgradeAvailable: item.upgradeAvailable,
            upgradeFailed: item.upgradeFailed,
            upgradeCleaning: item.upgradeCleaning,
            cleanupOnly: item.cleanupOnly,
          );
        }(),
    ],
    indexBytes: indexBytes,
    preparing: preparing,
    checking: runtime.isLoading,
    runtimeReady: ready,
    runtimeCuda: environment?.cuda == true,
    runtimePython: python,
    runtimeIssue: runtime.hasError
        ? SettingsRagRuntimeIssue.importFailed
        : environment?.issue == null
        ? null
        : SettingsRagRuntimeIssue.values.byName(environment!.issue!.name),
    runtimePackages: environment?.packages ?? const [],
    pythonPending:
        settings.python.isNotEmpty &&
        environment != null &&
        !p.equals(
          p.normalize(settings.python),
          p.normalize(environment.python),
        ),
    install: status.installPhase == null
        ? null
        : SettingsRagInstall(
            phase:
                SettingsRagInstallPhase.values
                    .where((phase) => phase.name == status.installPhase)
                    .firstOrNull ??
                SettingsRagInstallPhase.packages,
            elapsed: Duration(seconds: status.installElapsed),
            detail: status.installDetail,
          ),
    download: !download.active
        ? null
        : SettingsRagDownload(
            model: SettingsRagModel.embedder,
            received: download.progress?.received ?? 0,
            total: download.progress?.total ?? 0,
            verifying: download.progress?.checking ?? false,
          ),
    modelsMissing: session.modelsMissing,
    plan: session.plan,
    error: download.error ?? status.error,
  );
}

final settingsRagSessionProvider =
    NotifierProvider<SettingsRagSession, SettingsRagSessionState>(
      SettingsRagSession.new,
    );

class SettingsRagSessionState {
  const SettingsRagSessionState({
    this.plan,
    this.planId,
    this.modelsMissing = false,
  });
  final SettingsRagPlan? plan;
  final String? planId;
  final bool modelsMissing;
}

class SettingsRagSession extends Notifier<SettingsRagSessionState> {
  int _revision = 0;
  bool _disposed = false;
  @override
  SettingsRagSessionState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _revision++;
    });
    ref.listen(ragSettingsProvider, (previous, next) {
      if (previous?.connectionKey != next.connectionKey) cancelPlan();
    });
    return const SettingsRagSessionState();
  }

  void cancelPlan() {
    final id = state.planId;
    if (id != null) ref.read(ragControllerProvider.notifier).discardPlan(id);
    _revision++;
    state = SettingsRagSessionState(modelsMissing: state.modelsMissing);
  }

  Future<void> preview(
    SettingsRagSourceKind kind, {
    bool rebuild = false,
  }) async {
    if (ref.read(ragMaintenanceProvider).busy ||
        ref.read(ragControllerProvider).anyBusy) {
      throw const RagException('index_busy');
    }
    cancelPlan();
    final revision = ++_revision;
    final controller = ref.read(ragControllerProvider.notifier);
    state = SettingsRagSessionState(
      modelsMissing: state.modelsMissing,
      plan: SettingsRagPlan(kind: kind, rebuild: rebuild, loading: true),
    );
    try {
      final plan = await controller.preview(source: settingsRagSource(kind));
      final roots = kind == SettingsRagSourceKind.gallery
          ? await ref.read(ragGalleryRootsProvider)()
          : const <String>[];
      if (_disposed || revision != _revision) {
        controller.discardPlan(plan['plan_id'] as String);
        return;
      }
      int count(String key) => (plan[key] as num?)?.toInt() ?? 0;
      state = SettingsRagSessionState(
        modelsMissing: state.modelsMissing,
        planId: plan['plan_id'] as String,
        plan: SettingsRagPlan(
          kind: kind,
          rebuild: rebuild,
          total: kind == SettingsRagSourceKind.gallery
              ? count('parameter_chunks')
              : kind == SettingsRagSourceKind.tags
              ? count('tags')
              : count('total'),
          documents: count('documents'),
          images: count('images'),
          roots: roots,
          upgrade: plan['upgrade_available'] == true,
          cleanupOnly: !rebuild && plan['cleanup_only'] == true,
          legacyBytes: count('legacy_bytes'),
        ),
      );
    } catch (_) {
      if (!_disposed && revision == _revision) cancelPlan();
      rethrow;
    }
  }

  Future<void> start() async {
    final selected = state;
    if (selected.plan == null ||
        selected.plan!.loading ||
        selected.planId == null) {
      throw const RagException('invalid_plan');
    }
    // Consume the view confirmation without discarding its backend token.
    _revision++;
    state = SettingsRagSessionState(modelsMissing: state.modelsMissing);
    await ref
        .read(ragControllerProvider.notifier)
        .start(
          selected.planId!,
          rebuild: selected.plan!.rebuild,
          source: settingsRagSource(selected.plan!.kind),
        );
  }

  Future<void> discover() async {
    final before = ref.read(ragSettingsProvider);
    for (final start in [
      Directory.current.path,
      p.dirname(Platform.resolvedExecutable),
    ]) {
      var cursor = start;
      for (var depth = 0; depth < 9; depth++) {
        final base = p.join(cursor, '04_工具', 'models');
        final embedding = p.join(base, 'embeddinggemma-2');
        if (await File(p.join(embedding, 'model.safetensors')).exists()) {
          if (_disposed) return;
          final latest = ref.read(ragSettingsProvider);
          // Directory discovery cannot overwrite a selection made while waiting.
          await ref
              .read(ragSettingsProvider.notifier)
              .update(
                latest.copyWith(
                  embedding: latest.embedding == before.embedding
                      ? embedding
                      : latest.embedding,
                ),
              );
          if (!_disposed) state = const SettingsRagSessionState();
          return;
        }
        final parent = p.dirname(cursor);
        if (parent == cursor) break;
        cursor = parent;
      }
    }
    if (_disposed) return;
    state = SettingsRagSessionState(
      plan: state.plan,
      planId: state.planId,
      modelsMissing: true,
    );
  }
}
