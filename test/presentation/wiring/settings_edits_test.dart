import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_values.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import '../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

class _MemoryStore extends SettingsValueStore {
  _MemoryStore(super.ref);
  final data = <SettingKey, Object?>{};
  Completer<void>? block;
  bool fail = false;
  int writes = 0;
  int? failAt;
  @override
  SettingsValues get values => SettingsValues(data);
  @override
  Future<void> write(SettingKey key, Object? value, {String? seedModel}) async {
    if (SettingsEdits.isSeed(key)) {
      await super.write(key, value, seedModel: seedModel);
      return;
    }
    if (block != null) await block!.future;
    if (fail || failAt == writes + 1) {
      failAt = null;
      throw StateError('write failed');
    }
    writes++;
    data[key] = value;
  }
}

class _Workflow extends ImageWorkflowController {
  @override
  ImageWorkflowState build() => const ImageWorkflowState(
    upscale: UpscaleWorkflowSettings(
      localModel: 'seedvr2-7b',
      localSeedvr2Options: {
        'seedvr2-7b': Seedvr2Options(blocksToSwap: 35, vaeTileSize: 1536),
        'seedvr2-3b': Seedvr2Options(blocksToSwap: 12),
      },
    ),
  );
  void select(String model) => state = state.copyWith(
    upscale: state.upscale.copyWith(localModel: model),
  );
  @override
  Future<void> setLocalSeedvr2Options(String id, Seedvr2Options options) async {
    state = state.copyWith(
      upscale: state.upscale.copyWith(
        localSeedvr2Options: {
          ...state.upscale.localSeedvr2Options,
          id: options,
        },
      ),
    );
  }
}

void main() {
  late ProviderContainer container;
  late _MemoryStore store;
  late SettingsEdits edits;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        settingsValueStoreProvider.overrideWith(
          (ref) => store = _MemoryStore(ref),
        ),
        imageWorkflowControllerProvider.overrideWith(_Workflow.new),
      ],
    );
    edits = container.read(settingsEditsProvider.notifier);
    container.read(settingsValueStoreProvider);
  });
  tearDown(() => container.dispose());

  test(
    'opening and saving the same value do not write or create history',
    () async {
      expect(store.writes, 0);
      await edits.change(SettingKey.themeMode, 'dark', title: 'Theme');
      expect(store.writes, 0);
      expect(container.read(settingsEditsProvider).entries, isEmpty);
    },
  );
  test(
    'save and undo restore the precise old value and consume the undo',
    () async {
      await edits.change(SettingKey.costThreshold, 88.0, title: 'Threshold');
      final saved = container.read(settingsEditsProvider).last!;
      expect(store.values.number(SettingKey.costThreshold), 88);
      await edits.undo(saved.id);
      expect(store.values.number(SettingKey.costThreshold), 50);
      expect(container.read(settingsEditsProvider).last!.undoable, isFalse);
      final count = store.writes;
      await edits.undo(saved.id);
      expect(store.writes, count);
    },
  );
  test('undo rejects a subsequent edit to the same key', () async {
    await edits.change(SettingKey.costThreshold, 88.0, title: 'Threshold');
    final saved = container.read(settingsEditsProvider).last!;
    store.data[SettingKey.costThreshold] = 99.0;
    await expectLater(edits.undo(saved.id), throwsStateError);
    expect(store.values.number(SettingKey.costThreshold), 99);
  });
  test('undo keeps unrelated newer preferences', () async {
    await edits.change(SettingKey.costThreshold, 88.0, title: 'Threshold');
    final saved = container.read(settingsEditsProvider).last!;
    store.data[SettingKey.themeMode] = 'light';
    await edits.undo(saved.id);
    expect(store.values.text(SettingKey.themeMode), 'light');
  });
  test(
    'undo retains the display labels captured with the original save',
    () async {
      await edits.change(
        SettingKey.themeMode,
        'light',
        title: 'Theme',
        label: (_, value) => value == 'light' ? 'Light label' : 'Dark label',
      );
      final saved = container.read(settingsEditsProvider).last!;
      expect(saved.from, 'Dark label');
      expect(saved.to, 'Light label');
      await edits.undo(saved.id);
      final undo = container.read(settingsEditsProvider).last!;
      expect(undo.from, 'Light label');
      expect(undo.to, 'Dark label');
    },
  );
  test('undoing a restart setting clears the pending restart banner', () async {
    await edits.change(
      SettingKey.appDataPath,
      'fixture-path',
      title: 'Storage',
    );
    expect(container.read(settingsEditsProvider).restartPending, isTrue);
    await edits.undo(container.read(settingsEditsProvider).last!.id);
    expect(container.read(settingsEditsProvider).restartPending, isFalse);
  });
  test('a partial undo failure rolls back only its own writes', () async {
    await edits.apply({
      SettingKey.costThreshold: 88.0,
      SettingKey.themeMode: 'light',
    }, title: 'Group');
    final id = container.read(settingsEditsProvider).last!.id;
    store.failAt = store.writes + 2;
    await expectLater(edits.undo(id), throwsStateError);
    expect(store.values.number(SettingKey.costThreshold), 88);
    expect(store.values.text(SettingKey.themeMode), 'light');
    await edits.undo(id);
    expect(store.values.number(SettingKey.costThreshold), 50);
    expect(store.values.text(SettingKey.themeMode), 'dark');
  });
  test(
    'default upscale persists atomically and keeps unrelated Seed options',
    () async {
      final storage = MemoryStorage();
      final isolated = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          imageWorkflowControllerProvider.overrideWith(_Workflow.new),
        ],
      );
      addTearDown(isolated.dispose);
      final controller = isolated.read(
        imageWorkflowControllerProvider.notifier,
      );
      await controller.setDefaultUpscale(
        UpscaleBackend.local,
        model: 'seedvr2-3b-int8',
      );
      expect(storage.values[StorageKeys.localSeedvr2Model], 'seedvr2-3b-int8');
      expect(
        isolated
            .read(imageWorkflowControllerProvider)
            .upscale
            .localSeedvr2Options['seedvr2-7b']!
            .blocksToSwap,
        35,
      );
      storage.failKey = StorageKeys.localUpscaleModel;
      await expectLater(
        controller.setDefaultUpscale(
          UpscaleBackend.local,
          model: 'seedvr2-7b-int8',
        ),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.localSeedvr2Model], 'seedvr2-3b-int8');
      expect(
        isolated.read(imageWorkflowControllerProvider).upscale.localModel,
        'seedvr2-3b-int8',
      );
    },
  );
  test('writes are serialized in input order', () async {
    store.block = Completer<void>();
    final first = edits.change(SettingKey.costThreshold, 88.0, title: 'A');
    final second = edits.change(SettingKey.costThreshold, 99.0, title: 'B');
    await Future<void>.delayed(Duration.zero);
    expect(store.writes, 0);
    store.block!.complete();
    await Future.wait([first, second]);
    expect(store.values.number(SettingKey.costThreshold), 99);
    expect(container.read(settingsEditsProvider).entries.first.before.values, [
      88.0,
    ]);
  });
  test(
    'a failed save creates no saved toast and later saves still work',
    () async {
      store.fail = true;
      await expectLater(
        edits.change(SettingKey.costThreshold, 88.0, title: 'A'),
        throwsStateError,
      );
      expect(container.read(settingsEditsProvider).last, isNull);
      store.fail = false;
      await edits.change(SettingKey.costThreshold, 99.0, title: 'B');
      expect(store.values.number(SettingKey.costThreshold), 99);
    },
  );
  test('reset page is one undo entry and preserves other pages', () async {
    store.data.addAll({
      SettingKey.themeMode: 'light',
      SettingKey.costThreshold: 88.0,
    });
    await edits.resetPage(SettingsPageId.appearance, title: 'Reset');
    final saved = container.read(settingsEditsProvider).last!;
    expect(store.values.text(SettingKey.themeMode), 'dark');
    expect(store.values.number(SettingKey.costThreshold), 88);
    await edits.undo(saved.id);
    expect(store.values.text(SettingKey.themeMode), 'light');
  });
  test(
    'restart marker follows restart settings and history is bounded',
    () async {
      await edits.change(SettingKey.proxyEnabled, false, title: 'Proxy');
      expect(container.read(settingsEditsProvider).restartPending, isTrue);
      for (var i = 1; i <= 25; i++) {
        await edits.change(SettingKey.costThreshold, i.toDouble(), title: '$i');
      }
      expect(container.read(settingsEditsProvider).entries.length, 20);
    },
  );
  test('low-memory preset undo restores the custom 35 blocks', () async {
    await edits.change(SettingKey.seedVramMode, 'recommended', title: 'Memory');
    final saved = container.read(settingsEditsProvider).last!;
    final workflow =
        container.read(imageWorkflowControllerProvider.notifier) as _Workflow;
    workflow.select('seedvr2-3b');
    await edits.undo(saved.id);
    final models = container.read(imageWorkflowControllerProvider).upscale;
    expect(models.localSeedvr2Options['seedvr2-7b']!.blocksToSwap, 35);
    expect(models.localSeedvr2Options['seedvr2-3b']!.blocksToSwap, 12);
    expect(models.localModel, 'seedvr2-3b');
  });
  test('VAE custom tile survives selecting a preset then undoing', () async {
    await edits.change(SettingKey.seedVaeTile, '512', title: 'VAE');
    final saved = container.read(settingsEditsProvider).last!;
    await edits.undo(saved.id);
    expect(
      container
          .read(imageWorkflowControllerProvider)
          .upscale
          .localSeedvr2Options['seedvr2-7b']!
          .vaeTileSize,
      1536,
    );
  });
  test('3B rejects 36, while 7B permits 36', () async {
    await edits.change(SettingKey.seedCpuOffload, 36.0, title: 'Blocks');
    final workflow =
        container.read(imageWorkflowControllerProvider.notifier) as _Workflow;
    workflow.select('seedvr2-3b');
    await expectLater(
      edits.change(SettingKey.seedCpuOffload, 36.0, title: 'Blocks'),
      throwsRangeError,
    );
    expect(
      container
          .read(imageWorkflowControllerProvider)
          .upscale
          .localSeedvr2Options['seedvr2-3b']!
          .blocksToSwap,
      12,
    );
  });
}
