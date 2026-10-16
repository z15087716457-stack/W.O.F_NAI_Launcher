import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/desktop_app_shutdown_service.dart';

import '../../../data/models/upscale/local_upscale_models.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_values.dart';

final settingsValueStoreProvider = Provider(SettingsValueStore.new);
final settingsEditsProvider =
    NotifierProvider<SettingsEdits, SettingsEditState>(SettingsEdits.new);
typedef SettingsValueLabel = String Function(SettingKey key, Object? value);

class SettingsEdit {
  const SettingsEdit(this.change, this.before, this.after, this.seedModel);
  final SettingsChange change;
  final Map<SettingKey, Object?> before, after;
  final String? seedModel;
}

class SettingsEditState {
  const SettingsEditState({
    this.entries = const [],
    this.last,
    this.restartPending = false,
  });
  final List<SettingsEdit> entries;
  final SettingsChange? last;
  final bool restartPending;
}

class SettingsEdits extends Notifier<SettingsEditState> {
  Future<void> _writes = Future.value();
  var _sequence = 0;
  final _restartBaseline = <SettingKey, Object?>{};
  @override
  SettingsEditState build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() => settled);
    ref.onDispose(unregister);
    return const SettingsEditState();
  }

  SettingsValueStore get store => ref.read(settingsValueStoreProvider);

  Future<void> _serial(Future<void> Function() operation) {
    final next = _writes.catchError((Object _) {}).then((_) => operation());
    _writes = next;
    return next;
  }

  Future<void> transaction(Future<void> Function() operation) =>
      _serial(operation);
  Future<void> get settled => _writes.catchError((Object _) {});

  static bool isSeed(SettingKey key) => const {
    SettingKey.seedVramMode,
    SettingKey.seedCpuOffload,
    SettingKey.seedVaeTiling,
    SettingKey.seedVaeTile,
    SettingKey.seedInputNoise,
    SettingKey.seedLatentNoise,
  }.contains(key);

  Object? _read(SettingKey key, String? model) {
    if (model == null || !isSeed(key)) return store.values[key];
    final settings = ref.read(imageWorkflowControllerProvider).upscale;
    final value = settings.localSeedvr2Options[model] ?? const Seedvr2Options();
    return switch (key) {
      SettingKey.seedVramMode => value.blocksToSwap > 0 ? 'low' : 'recommended',
      SettingKey.seedCpuOffload => value.blocksToSwap.toDouble(),
      SettingKey.seedVaeTiling => value.vaeTiled,
      SettingKey.seedVaeTile => value.vaeTileSize.toString(),
      SettingKey.seedInputNoise => value.inputNoise,
      _ => value.latentNoise,
    };
  }

  Future<void> change(
    SettingKey key,
    Object? value, {
    required String title,
    SettingsValueLabel? label,
  }) => apply({key: value}, title: title, label: label);

  Future<void> reset(
    SettingKey key, {
    required String title,
    SettingsValueLabel? label,
  }) =>
      change(key, SettingSpec.of(key).defaultValue, title: title, label: label);

  Future<void> resetPage(
    SettingsPageId page, {
    required String title,
    SettingsValueLabel? label,
  }) => apply(
    {
      for (final key in SettingKey.values)
        if (SettingSpec.of(key).page == page)
          key: SettingSpec.of(key).defaultValue,
    },
    title: title,
    label: label,
  );

  Future<void> apply(
    Map<SettingKey, Object?> requested, {
    required String title,
    bool undoable = true,
    SettingsValueLabel? label,
  }) => _serial(() async {
    final seedModel = requested.keys.any(isSeed)
        ? settingsSeedModel(ref.read(imageWorkflowControllerProvider).upscale)
        : null;
    // A preset changes the numerical value. Undo restores the exact old value,
    // rather than reducing a custom count to the preset's 16 blocks.
    final changes = {...requested};
    if (changes.containsKey(SettingKey.seedVramMode)) {
      changes.putIfAbsent(
        SettingKey.seedCpuOffload,
        () => changes[SettingKey.seedVramMode] == 'low' ? 16.0 : 0.0,
      );
      changes.remove(SettingKey.seedVramMode);
    }
    final before = {for (final key in changes.keys) key: _read(key, seedModel)};
    final touched = <SettingKey>[];
    try {
      for (final entry in changes.entries) {
        if (_read(entry.key, seedModel) != before[entry.key]) {
          throw StateError('Preferences changed while saving');
        }
        if (entry.value == before[entry.key]) continue;
        touched.add(entry.key);
        await store.write(entry.key, entry.value, seedModel: seedModel);
      }
    } catch (_) {
      // Only restore our own writes; a later edit always wins.
      for (final key in touched.reversed) {
        if (_read(key, seedModel) == changes[key]) {
          await store.write(key, before[key], seedModel: seedModel);
        }
      }
      rethrow;
    }
    if (touched.isEmpty) return;
    final old = {for (final key in touched) key: before[key]};
    final after = {for (final key in touched) key: _read(key, seedModel)};
    _record(old, after, seedModel, title, undoable, label: label);
  });

  void _record(
    Map<SettingKey, Object?> before,
    Map<SettingKey, Object?> after,
    String? seedModel,
    String title,
    bool undoable, {
    SettingsValueLabel? label,
    String? fromLabel,
    String? toLabel,
  }) {
    final change = SettingsChange(
      id: '${DateTime.now().microsecondsSinceEpoch}-${++_sequence}',
      title: title,
      from:
          fromLabel ??
          before.entries
              .map((e) => label?.call(e.key, e.value) ?? e.value ?? '—')
              .join(', '),
      to:
          toLabel ??
          after.entries
              .map((e) => label?.call(e.key, e.value) ?? e.value ?? '—')
              .join(', '),
      at: DateTime.now(),
      undoable: undoable,
    );
    for (final key in after.keys.where((key) => SettingSpec.of(key).restart)) {
      _restartBaseline.putIfAbsent(key, () => before[key]);
    }
    state = SettingsEditState(
      entries: [
        SettingsEdit(change, before, after, seedModel),
        ...state.entries,
      ].take(20).toList(),
      last: change,
      restartPending: _restartBaseline.entries.any(
        (entry) => _read(entry.key, null) != entry.value,
      ),
    );
  }

  Future<void> undo(String id) => _serial(() async {
    final edit = state.entries.where((e) => e.change.id == id).firstOrNull;
    if (edit == null || !edit.change.undoable) return;
    for (final entry in edit.after.entries) {
      if (_read(entry.key, edit.seedModel) != entry.value) {
        throw StateError('Preference has changed since this edit');
      }
    }
    final touched = <SettingKey>[];
    try {
      for (final entry in edit.before.entries) {
        if (_read(entry.key, edit.seedModel) != edit.after[entry.key]) {
          throw StateError('Preference changed during undo');
        }
        touched.add(entry.key);
        await store.write(entry.key, entry.value, seedModel: edit.seedModel);
      }
    } catch (_) {
      for (final key in touched.reversed) {
        if (_read(key, edit.seedModel) == edit.before[key]) {
          await store.write(key, edit.after[key], seedModel: edit.seedModel);
        }
      }
      rethrow;
    }
    // Consume the original undo entry; a repeated click cannot replay it.
    state = SettingsEditState(
      entries: state.entries.where((e) => e != edit).toList(),
      last: state.last,
      restartPending: state.restartPending,
    );
    _record(
      edit.after,
      edit.before,
      edit.seedModel,
      edit.change.title,
      false,
      fromLabel: edit.change.to,
      toLabel: edit.change.from,
    );
  });
}
