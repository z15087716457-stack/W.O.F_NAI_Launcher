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

final settingsRagWeightsProvider =
    FutureProvider<({bool embedding, bool reranker})>((ref) async {
      final settings = ref.watch(ragSettingsProvider);
      Future<bool> exists(String directory) async =>
          directory.isNotEmpty &&
          await File(p.join(directory, 'config.json')).exists() &&
          (await File(p.join(directory, 'model.safetensors')).exists() ||
              await File(
                p.join(directory, 'model.safetensors.index.json'),
              ).exists());
      return (
        embedding: await exists(settings.embedding),
        reranker: await exists(settings.reranker),
      );
    });

SettingsRagData settingsRagData(
  RagSettings settings,
  RagStatus status,
  AsyncValue<RagRuntimeInfo> runtime,
  RagModelDownloadState download,
  SettingsRagSessionState session,
  ({bool embedding, bool reranker})? weights, {
  int indexBytes = 0,
  SettingsRagSourceKind? preparing,
}) {
  final environment = runtime.valueOrNull;
  final ready =
      environment?.ready == true ||
      (runtime.isLoading && environment == null && status.runtimeReady);
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
  bool sourceSelected(RagSource source) => switch (source) {
    RagSource.tags => settings.tagsEnabled,
    RagSource.wiki => settings.wikiEnabled,
    RagSource.blocks => settings.blocksEnabled,
    RagSource.gallery => settings.galleryEnabled,
  };
  return SettingsRagData(
    initializing:
        settings.enabled &&
        (status.initializing ||
            RagSource.values.any(
              (source) =>
                  settings.enabledFor(source) &&
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
    embedder: model('EmbeddingGemma 2', settings.embedding, weights?.embedding),
    reranker: model(
      'Qwen3-Reranker-0.6B',
      settings.reranker,
      weights?.reranker,
    ),
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
            enabled: sourceSelected(source),
            state: !settings.enabledFor(source)
                ? SettingsRagState.off
                : status.initializing ||
                      (!item.hasIndexStatus && item.error == null)
                ? SettingsRagState.loading
                : item.busy
                ? SettingsRagState.building
                : item.phase == 'paused'
                ? SettingsRagState.paused
                : item.error != null
                ? SettingsRagState.error
                : item.indexed > 0 || item.complete
                ? SettingsRagState.ready
                : SettingsRagState.empty,
            known: item.hasIndexStatus,
            done: gallery ? item.details['visual_indexed'] ?? 0 : item.indexed,
            total: gallery ? item.details['images'] ?? 0 : item.total,
            secondary: gallery ? item.details['parameters_indexed'] ?? 0 : null,
            skipped: item.details['skipped'] ?? 0,
            error: item.error,
          );
        }(),
    ],
    indexBytes: indexBytes,
    preparing: preparing,
    checking: runtime.isLoading,
    runtimeReady: ready,
    runtimeCuda: environment?.cuda == true,
    runtimePython: python,
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
            model: download.kind == 'embedding'
                ? SettingsRagModel.embedder
                : SettingsRagModel.reranker,
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
              : count('total'),
          documents: count('documents'),
          images: count('images'),
          roots: roots,
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

  Future<void> sourceEnabled(SettingsRagSourceKind kind, bool enabled) async {
    final current = ref.read(ragSettingsProvider);
    await ref.read(ragSettingsProvider.notifier).update(switch (kind) {
      SettingsRagSourceKind.tags => current.copyWith(tagsEnabled: enabled),
      SettingsRagSourceKind.wiki => current.copyWith(wikiEnabled: enabled),
      SettingsRagSourceKind.blocks => current.copyWith(blocksEnabled: enabled),
      SettingsRagSourceKind.gallery => current.copyWith(
        galleryEnabled: enabled,
      ),
    });
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
        final reranker = p.join(base, 'Qwen3-Reranker-0.6B');
        if (await File(p.join(embedding, 'model.safetensors')).exists() &&
            await File(p.join(reranker, 'model.safetensors')).exists()) {
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
                  reranker: latest.reranker == before.reranker
                      ? reranker
                      : latest.reranker,
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
