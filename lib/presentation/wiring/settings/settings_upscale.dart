import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../../core/services/settings_gpu_probe.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../ui/settings/settings_contract.dart';
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
    this.error,
    this.failedId,
  });
  final String? id;
  final int received, total, speed;
  final Object? error;
  final String? failedId;
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
    });
    ref.onDispose(() {
      _disposed = true;
      _cancel?.cancel();
      unregister();
    });
    return const SettingsUpscaleOperation();
  }

  void cancel(String id) {
    final actual = settingsUpscaleId(id);
    if (state.id == actual) _cancel?.cancel();
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
    state = SettingsUpscaleOperation(id: id);
    final token = _cancel = CancelToken();
    try {
      if (advancedUpscaleCatalog.any((model) => model.id == id)) {
        final actions = ref.read(advancedUpscaleInstallProvider.notifier);
        if (remove) {
          await actions.delete(id);
        } else {
          await actions.install(id);
        }
        final error = ref.read(advancedUpscaleInstallProvider).error;
        if (error != null) throw LocalUpscaleException(error);
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
            : SettingsUpscaleOperation(error: error, failedId: id);
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
}) {
  SettingsUpscaleModel map(LocalUpscaleModel model) {
    final id =
        settingsUpscaleIds.entries
            .where((entry) => entry.value == model.id)
            .firstOrNull
            ?.key ??
        model.id;
    final active = operation.id == model.id || advanced.id == model.id;
    return SettingsUpscaleModel(
      id: id,
      state: operation.failedId == model.id && operation.error != null
          ? SettingsInstallState.failed
          : active
          ? SettingsInstallState.downloading
          : model.bundled
          ? SettingsInstallState.builtin
          : model.installed
          ? SettingsInstallState.installed
          : SettingsInstallState.notInstalled,
      bytes: operation.id == model.id && operation.total > 0
          ? operation.total
          : model.diskBytes,
      file: model.engineName,
      received: operation.id == model.id ? operation.received : 0,
      speed: operation.id == model.id ? operation.speed : 0,
      isDefault:
          workflow.backend == UpscaleBackend.local &&
          workflow.localModel == model.id,
    );
  }

  return SettingsUpscaleData(
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
