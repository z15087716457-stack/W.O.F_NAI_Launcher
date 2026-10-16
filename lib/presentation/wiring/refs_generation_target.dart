import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../../core/constants/model_spec.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_api_utils.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/precise_ref/precise_ref_library_entry.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../../data/services/vibe_file_storage_service.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../ui/refs/refs_contract.dart';
import 'refs_mapping.dart';

final refsDraftBackupProvider = Provider<RefsDraftBackup>(
  (ref) => const RefsDraftBackup(),
);
final refsGenerationTargetProvider = Provider<RefsGenerationTarget>((ref) {
  final target = RefsGenerationTarget(ref, ref.read(refsDraftBackupProvider));
  ref.listen(generationParamsNotifierProvider, target.synchronize);
  return target;
});

class RefsDraftBackup {
  const RefsDraftBackup();

  Future<void> save(String snapshot) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'draft-backups'));
    await directory.create(recursive: true);
    await File(
      p.join(
        directory.path,
        'before-refs-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    ).writeAsString(snapshot, flush: true);
  }
}

class RefsGenerationSnapshot {
  const RefsGenerationSnapshot(this.version, this.workflow, this.json);
  final String version;
  final ImageWorkflowState workflow;
  final String json;
}

class RefsSendResult {
  const RefsSendResult(this.count, {this.truncated = false});
  final int count;
  final bool truncated;
}

class RefsGenerationTarget {
  RefsGenerationTarget(this.ref, this.backup);
  final Ref ref;
  final RefsDraftBackup backup;
  final vibeOrigins = <String, String>{};
  final preciseOrigins = <String, String>{};
  final _trayIds = Expando<String>();
  final _origins = Expando<String>();
  var _nextTrayId = 0;
  bool _writing = false;

  void synchronize(ImageParams? previous, ImageParams next) {
    if (previous == null) return;
    _synchronizeReferences(
      previous.vibeReferencesV4,
      next.vibeReferencesV4,
      (old, current) =>
          identical(old.rawImageData, current.rawImageData) &&
              old.vibeEncoding == current.vibeEncoding ||
          refsVibeFingerprint(old) == refsVibeFingerprint(current),
    );
    _synchronizeReferences(
      previous.preciseReferences,
      next.preciseReferences,
      (old, current) =>
          identical(old.image, current.image) ||
          refsBytesFingerprint(old.image) ==
              refsBytesFingerprint(current.image),
    );
  }

  void _synchronizeReferences<T extends Object>(
    List<T> previous,
    List<T> next,
    bool Function(T, T) sameSource,
  ) {
    for (var i = 0; i < next.length; i++) {
      if (_origins[next[i]] == null &&
          i < previous.length &&
          sameSource(previous[i], next[i])) {
        _origins[next[i]] = _origins[previous[i]];
      }
    }
    for (final removed in previous) {
      if (!next.any((item) => identical(item, removed))) {
        _trayIds[removed] = null;
      }
    }
  }

  RefsGenerationSnapshot capture({bool withBackup = true}) {
    final params = ref.read(generationParamsNotifierProvider);
    return RefsGenerationSnapshot(
      ref.read(bridgeDraftVersionProvider),
      ref.read(imageWorkflowControllerProvider),
      withBackup
          ? jsonEncode({
              ...readBridgeDraft(ref).toJson(),
              'generation': params.toJson(),
              'sourceImage': params.sourceImage == null
                  ? null
                  : base64Encode(params.sourceImage!),
              'maskImage': params.maskImage == null
                  ? null
                  : base64Encode(params.maskImage!),
              'vibes': [
                for (final vibe in params.vibeReferencesV4)
                  {
                    ...vibe.toJson(),
                    'rawImageData': vibe.rawImageData == null
                        ? null
                        : base64Encode(vibe.rawImageData!),
                    'thumbnail': vibe.thumbnail == null
                        ? null
                        : base64Encode(vibe.thumbnail!),
                  },
              ],
            })
          : '',
    );
  }

  void check(RefsGenerationSnapshot snapshot, bool Function() alive) {
    if (!alive() ||
        snapshot.version != ref.read(bridgeDraftVersionProvider) ||
        !identical(
          snapshot.workflow,
          ref.read(imageWorkflowControllerProvider),
        )) {
      throw StateError(currentL10n.bridge_conflict);
    }
    if (ref.read(imageGenerationNotifierProvider).isGenerating ||
        ref.read(imageWorkflowControllerProvider).isToolRunning ||
        (ref.exists(kritaBridgeNotifierProvider) &&
            ref.read(kritaBridgeNotifierProvider).isBridgeGenerating)) {
      throw StateError(currentL10n.networkError_conflict);
    }
  }

  Future<void> _commit(
    RefsGenerationSnapshot snapshot,
    bool Function() alive,
    void Function() write,
  ) async {
    check(snapshot, alive);
    await backup.save(snapshot.json);
    check(snapshot, alive);
    write();
  }

  Future<RefsSendResult> addVibes(
    List<String> keys, {
    bool replace = false,
    Map<String, RefsSendOverride> overrides = const {},
    List<int>? indexes,
    Map<int, RefsSendOverride> childOverrides = const {},
    required bool Function() alive,
  }) async {
    if (_writing) return const RefsSendResult(0);
    _writing = true;
    try {
      final snapshot = capture();
      final model = ref.read(generationParamsNotifierProvider).model;
      if (!ModelSpecs.of(model).vibetransfer) {
        throw StateError(currentL10n.preciseRef_v4Only);
      }
      final prepared = <({String key, VibeReference vibe})>[];
      final storage = ref.read(vibeLibraryStorageServiceProvider);
      for (final key in keys.toSet()) {
        final entry = await storage.getEntry(key);
        check(snapshot, alive);
        if (entry == null) {
          throw StateError(currentL10n.preciseRefLib_imageMissing);
        }
        final vibes = entry.isBundle && entry.filePath != null
            ? await VibeFileStorageService().extractVibesFromBundle(
                entry.filePath!,
              )
            : entry.isBundle
            ? refsBundleVibes(entry)
            : [entry.toVibeReference()];
        check(snapshot, alive);
        if (vibes.isEmpty) {
          throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
        }
        final selected = indexes == null
            ? List.generate(vibes.length, (i) => i)
            : indexes.toSet().toList();
        for (final i in selected) {
          if (i < 0 || i >= vibes.length) continue;
          final vibe = refsVibeOverride(
            vibes[i],
            childOverrides[i] ?? overrides[key],
          );
          final status = RefsVibeStatus.fromEntry(
            VibeLibraryEntry.fromVibeReference(
              name: entry.name,
              vibeData: vibe,
            ),
          );
          if (status.encoding(model) == RefsEncoding.unusable) {
            throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
          }
          prepared.add((key: key, vibe: vibe));
        }
      }
      final before = ref
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4;
      final next = replace ? <VibeReference>[] : [...before];
      final applied = <({String key, VibeReference vibe})>[];
      var truncated = false;
      for (final item in prepared) {
        if (next.length >= refsCosts().maxVibes) {
          truncated = true;
          continue;
        }
        next.add(item.vibe);
        applied.add(item);
      }
      if (applied.isEmpty) return RefsSendResult(0, truncated: truncated);
      await _commit(snapshot, alive, () {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .setVibeReferences(next);
        for (final item in applied) {
          _origins[item.vibe] = item.key;
          vibeOrigins[refsVibeFingerprint(item.vibe)] = item.key;
        }
      });
      for (final key in applied.map((e) => e.key).toSet()) {
        await ref.read(vibeLibraryNotifierProvider.notifier).recordUsage(key);
      }
      return RefsSendResult(applied.length, truncated: truncated);
    } finally {
      _writing = false;
    }
  }

  Future<RefsSendResult> addPrecise(
    List<PreciseRefLibraryEntry> entries, {
    bool replace = false,
    required bool Function() alive,
  }) async {
    if (_writing) return const RefsSendResult(0);
    _writing = true;
    try {
      final snapshot = capture();
      if (!ModelSpecs.of(
        ref.read(generationParamsNotifierProvider).model,
      ).characterReferences) {
        throw StateError(currentL10n.preciseRef_v4Only);
      }
      final prepared = <({PreciseRefLibraryEntry entry, Uint8List bytes})>[];
      for (final entry in entries) {
        final bytes = await ref
            .read(preciseRefLibraryStorageServiceProvider)
            .readImageBytes(entry.id);
        if (bytes == null) {
          throw StateError(currentL10n.preciseRefLib_imageMissing);
        }
        final normalized = await NAIApiUtils.ensurePngFormatAsync(bytes);
        check(snapshot, alive);
        prepared.add((entry: entry, bytes: normalized));
      }
      if (prepared.isEmpty) return const RefsSendResult(0);
      await _commit(snapshot, alive, () {
        final params = ref.read(generationParamsNotifierProvider.notifier);
        if (replace) params.clearPreciseReferences();
        for (final item in prepared) {
          params.addPreciseReference(
            item.bytes,
            type: item.entry.type,
            strength: item.entry.strength,
            fidelity: item.entry.fidelity,
            isNormalizedPng: true,
          );
          _origins[ref
                  .read(generationParamsNotifierProvider)
                  .preciseReferences
                  .last] =
              item.entry.id;
          preciseOrigins[refsBytesFingerprint(item.bytes)] = item.entry.id;
        }
      });
      for (final entry in entries) {
        await ref
            .read(preciseRefLibraryNotifierProvider.notifier)
            .recordUsage(entry.id);
      }
      return RefsSendResult(prepared.length);
    } finally {
      _writing = false;
    }
  }

  Future<bool> sendImg2Img(String key, {required bool Function() alive}) async {
    if (_writing) return false;
    _writing = true;
    try {
      final snapshot = capture();
      final bytes = await ref
          .read(preciseRefLibraryStorageServiceProvider)
          .readImageBytes(key);
      if (bytes == null) {
        throw StateError(currentL10n.preciseRefLib_imageMissing);
      }
      await _commit(snapshot, alive, () {
        final workflow = ref.read(imageWorkflowControllerProvider.notifier);
        workflow.replaceSourceImage(bytes);
        workflow.enterBaseMode(clearMask: true);
        workflow.setPanelExpanded(true);
      });
      await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .recordUsage(key);
      return true;
    } finally {
      _writing = false;
    }
  }

  String _trayId(Object reference, String kind) =>
      _trayIds[reference] ??= '$kind:${_nextTrayId++}';

  RefsTray tray(
    RefsKind kind, {
    Map<String, RefsVibeStatus> statuses = const {},
  }) {
    final params = ref.read(generationParamsNotifierProvider);
    if (kind == RefsKind.vibe) {
      return RefsTray(
        items: [
          for (final vibe in params.vibeReferencesV4)
            RefsTrayItem(
              id: _trayId(vibe, 'vibe'),
              entryKey:
                  _origins[vibe] ??
                  vibeOrigins[refsVibeFingerprint(vibe)] ??
                  statuses.entries
                      .where(
                        (e) => e.value.fingerprints.contains(
                          refsVibeFingerprint(vibe),
                        ),
                      )
                      .map((e) => e.key)
                      .firstOrNull,
              thumb: vibe.thumbnail == null
                  ? null
                  : MemoryImage(vibe.thumbnail!),
              value: vibe.strength,
              enabled: vibe.enabled,
            ),
        ],
      );
    }
    return RefsTray(
      items: [
        for (final reference in params.preciseReferences)
          RefsTrayItem(
            id: _trayId(reference, 'precise'),
            entryKey:
                _origins[reference] ??
                preciseOrigins[refsBytesFingerprint(reference.image)],
            thumb: ResizeImage(MemoryImage(reference.image), width: 128),
            value: reference.strength,
            enabled: reference.enabled,
          ),
      ],
      otherVibes: params.enabledVibeReferencesV4.length,
      vibesPaused:
          params.vibeReferencesV4.isNotEmpty &&
          params.enabledVibeReferencesV4.isEmpty,
    );
  }

  Future<void> removeTray(
    RefsKind kind,
    String? id, {
    required bool Function() alive,
  }) async {
    final snapshot = capture();
    final items = tray(kind).items;
    final index = id == null ? -1 : items.indexWhere((item) => item.id == id);
    if (id != null && index < 0) return;
    await _commit(snapshot, alive, () {
      final params = ref.read(generationParamsNotifierProvider.notifier);
      if (kind == RefsKind.vibe) {
        if (id == null) {
          params.clearVibeReferences();
        } else {
          params.removeVibeReference(index);
        }
      } else {
        if (id == null) {
          params.clearPreciseReferences();
        } else {
          params.removePreciseReference(index);
        }
      }
    });
  }

  Future<void> pauseVibes(bool paused, {required bool Function() alive}) async {
    final snapshot = capture();
    await _commit(snapshot, alive, () {
      final params = ref.read(generationParamsNotifierProvider.notifier);
      for (
        var i = 0;
        i < ref.read(generationParamsNotifierProvider).vibeReferencesV4.length;
        i++
      ) {
        params.updateVibeReference(i, enabled: !paused);
      }
    });
  }
}
