import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../../core/services/settings_gpu_probe.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../data/services/advanced_upscale_component_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../widgets/common/local_upscale_labels.dart';
import 'settings_values.dart';

/// Public contract IDs are translated here; managers always receive catalog IDs.
const settingsUpscaleIds = <String, String>{
  'animeQuality': 'anime',
  'animeFast': 'anime-fast',
  'general': 'general',
  'seed3b': 'seedvr2-3b',
  'seed7b': 'seedvr2-7b',
  'seed7bSharp': 'seedvr2-7b-sharp',
  'rtxVideo': 'rtx-vsr',
};
String settingsUpscaleId(String id) => settingsUpscaleIds[id] ?? id;
final settingsGpuProbeProvider = Provider((ref) => SettingsGpuProbe());
final settingsGpuProvider = FutureProvider(
  (ref) => ref.read(settingsGpuProbeProvider).inspect(),
);

class SettingsUpscaleOperation {
  const SettingsUpscaleOperation({
    this.id,
    this.received = 0,
    this.total = 0,
    this.speed = 0,
    this.removing = false,
    this.cancelling = false,
    this.error,
    this.failedId,
    this.failedPhase,
  });
  final String? id;
  final int received, total, speed;
  final bool removing, cancelling;
  final LocalUpscaleException? error;
  final String? failedId, failedPhase;
}

final settingsUpscaleOperationProvider =
    NotifierProvider<SettingsUpscaleOperations, SettingsUpscaleOperation>(
      SettingsUpscaleOperations.new,
    );

class SettingsUpscaleOperations extends Notifier<SettingsUpscaleOperation> {
  CancelToken? _cancel;
  Future<void>? _pending;
  bool _disposed = false;
  @override
  SettingsUpscaleOperation build() {
    _disposed = false;
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _cancel?.cancel();
      await _pending;
    }, name: 'Upscale settings');
    ref.onDispose(() {
      _disposed = true;
      _cancel?.cancel();
      unregister();
    });
    return const SettingsUpscaleOperation();
  }

  void cancel(String id) {
    final actual = settingsUpscaleId(id);
    if (state.id == actual && !state.removing && !state.cancelling) {
      state = SettingsUpscaleOperation(
        id: actual,
        received: state.received,
        total: state.total,
        speed: state.speed,
        cancelling: true,
      );
      _cancel?.cancel();
    }
    if (ref.read(advancedUpscaleInstallProvider).id == actual) {
      ref.read(advancedUpscaleInstallProvider.notifier).cancel();
    }
  }

  Future<void> install(String id) => _run(settingsUpscaleId(id), false);
  Future<void> remove(String id) => _run(settingsUpscaleId(id), true);
  Future<void> _run(String id, bool remove) {
    if (_pending != null || ref.read(advancedUpscaleInstallProvider).running) {
      throw const LocalUpscaleException(LocalUpscaleError.busy);
    }
    final work = _operate(id, remove);
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  Future<void> _operate(String id, bool remove) async {
    state = SettingsUpscaleOperation(id: id, removing: remove);
    final token = _cancel = CancelToken();
    String? failedPhase;
    try {
      if (advancedUpscaleCatalog.any((model) => model.id == id)) {
        final actions = ref.read(advancedUpscaleInstallProvider.notifier);
        if (remove) {
          await actions.delete(id);
        } else {
          await actions.install(id);
        }
        final result = ref.read(advancedUpscaleInstallProvider);
        if (result.error case final error?) {
          if (!remove) failedPhase = result.phase;
          throw LocalUpscaleException(error, details: result.details);
        }
      } else {
        final manager = ref.read(localUpscaleModelManagerProvider);
        if (remove) {
          await manager.delete(id);
        } else {
          final watch = Stopwatch()..start();
          await manager.download(
            id,
            cancelToken: token,
            onProgress: (received, total) {
              if (!_disposed && !token.isCancelled) {
                state = SettingsUpscaleOperation(
                  id: id,
                  received: received,
                  total: total,
                  speed: received * 1000 ~/ (watch.elapsedMilliseconds + 1),
                );
              }
            },
          );
        }
      }
      if (!_disposed) state = const SettingsUpscaleOperation();
    } catch (error) {
      final cancelled =
          token.isCancelled ||
          error is LocalUpscaleException &&
              error.code == LocalUpscaleError.cancelled;
      if (!_disposed) {
        state = cancelled
            ? const SettingsUpscaleOperation()
            : SettingsUpscaleOperation(
                error: error is LocalUpscaleException
                    ? error
                    : LocalUpscaleException(
                        LocalUpscaleError.modelOperationFailed,
                        details:
                            AdvancedUpscaleComponentManager.safeDiagnostics(
                              '$error',
                            ),
                      ),
                failedId: id,
                failedPhase: failedPhase,
              );
      }
      if (cancelled) return;
      rethrow;
    } finally {
      _cancel = null;
      if (!_disposed) ref.invalidate(localUpscaleModelsProvider);
    }
  }

  Future<void> importModel() async {
    if (_pending != null || ref.read(advancedUpscaleInstallProvider).running) {
      throw const LocalUpscaleException(LocalUpscaleError.busy);
    }
    final selected = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['param', 'bin'],
    );
    if (selected == null) return;
    final paths = selected.files
        .map((file) => file.path)
        .whereType<String>()
        .toList();
    final param = paths
        .where((path) => path.toLowerCase().endsWith('.param'))
        .single;
    final bin = paths
        .where((path) => path.toLowerCase().endsWith('.bin'))
        .single;
    // The manager checks its inference/mutation lock and validates the pair.
    await ref
        .read(localUpscaleModelManagerProvider)
        .importPair(File(param), File(bin));
    if (!_disposed) ref.invalidate(localUpscaleModelsProvider);
  }
}

SettingsUpscaleData settingsUpscaleData(
  List<LocalUpscaleModel> models,
  SettingsUpscaleOperation operation,
  AdvancedUpscaleInstallState advanced,
  UpscaleWorkflowSettings workflow, {
  SettingsGpuInfo? gpu,
  AppLocalizations? l10n,
}) {
  final l = l10n ?? currentL10n;
  SettingsUpscaleModel map(LocalUpscaleModel model) {
    final id =
        settingsUpscaleIds.entries
            .where((entry) => entry.value == model.id)
            .firstOrNull
            ?.key ??
        model.id;
    final active = operation.id == model.id
        ? !operation.removing
        : advanced.id == model.id;
    final progress = active && advanced.id == model.id
        ? advanced.progress
        : null;
    final cancelling =
        (operation.id == model.id && operation.cancelling) ||
        (advanced.id == model.id && advanced.cancelling);
    final failure = !active && operation.failedId == model.id
        ? operation.error
        : null;
    String? status;
    String? diagnostics;
    if (failure != null) {
      final reason = localUpscaleErrorLabel(l, failure.code);
      final phase = operation.failedPhase;
      status = phase == null
          ? reason
          : '${l.localUpscale_installFailed(localUpscaleInstallPhaseLabel(l, phase))}\n$reason';
      final details = failure.details;
      diagnostics = details == null || details.isEmpty
          ? status
          : '$status\n$details';
    } else if (cancelling) {
      status = l.localUpscale_cancelling;
    } else if (progress != null) {
      status = localUpscaleInstallPhaseLabel(l, progress.phase);
    }
    return SettingsUpscaleModel(
      id: id,
      state: active
          ? SettingsInstallState.downloading
          : model.bundled
          ? SettingsInstallState.builtin
          : model.installed
          ? SettingsInstallState.installed
          : failure != null
          ? SettingsInstallState.failed
          : SettingsInstallState.notInstalled,
      bytes: model.modelBytes,
      file: model.engineName,
      received: progress?.received ?? (active ? operation.received : 0),
      total: progress?.total ?? (active ? operation.total : 0),
      speed: progress?.speed ?? (active ? operation.speed : 0),
      status: status,
      diagnostics: diagnostics,
      cancelling: cancelling,
      isDefault:
          workflow.backend == UpscaleBackend.local &&
          workflow.localModel == model.id,
    );
  }

  return SettingsUpscaleData(
    busy: operation.id != null || advanced.running,
    gpuName: gpu?.name,
    vramGb: gpu == null ? 0 : (gpu.vramMb / 1024).round(),
    cudaVersion: gpu?.cuda ?? '',
    caps: {
      if (gpu != null && gpu.cuda.isNotEmpty) SettingsGpuCap.cuda,
      if (gpu?.int8 == true) SettingsGpuCap.int8,
      if (gpu?.rtxVideo == true) SettingsGpuCap.rtxVideo,
    },
    esrgan: [
      for (final model in models.where(
        (m) => m.method == LocalUpscaleMethod.standard,
      ))
        map(model),
    ],
    seed: [
      for (final model in models.where(
        (m) => m.method == LocalUpscaleMethod.seedvr2,
      ))
        map(model),
    ],
    rtx: models.any((m) => m.method == LocalUpscaleMethod.rtx)
        ? map(models.firstWhere((m) => m.method == LocalUpscaleMethod.rtx))
        : null,
    seedOffloadMaxBlocks: Seedvr2Options.maxBlocks(settingsSeedModel(workflow)),
  );
}
