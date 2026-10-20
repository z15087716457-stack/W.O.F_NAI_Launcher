import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/settings_tools.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_settings_binding.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_settings_card.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_settings_undo.dart';
import '../../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

final _tools = Provider.family<NaiAgentSettingsTools, Directory>(
  (ref, dir) => bindNaiAgentSettings(ref, dir, () => true),
);

class _BackupSettings extends SettingsPreferencesService {
  _BackupSettings(super.storage, this.dir, this.afterBackup);
  final Directory dir;
  final void Function() afterBackup;
  @override
  Future<File> backup(Map<String, Object?> values) async {
    final file = await File(
      '${dir.path}/backup.json',
    ).writeAsString(encode(values));
    afterBackup();
    return file;
  }
}

void main() {
  late Directory dir;
  late MemoryStorage storage;
  late ProviderContainer container;
  late NaiAgentSettingsTools tools;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('agent-settings-');
    storage = MemoryStorage();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    tools = container.read(_tools(dir));
  });
  tearDown(() async {
    container.dispose();
    await dir.delete(recursive: true);
  });
  Future<Map> read([Map<String, dynamic> params = const {}]) async =>
      (await tools.read(params, NaiAgentCancellation()))['details'] as Map;
  Future<Map> update(Map<String, Object?> changes, String version) async =>
      (await tools.update({
            'changes': changes,
            'expected_version': version,
          }, NaiAgentCancellation()))['details']
          as Map;

  test(
    'public reads, partial reads and version exclude credentials and model configuration',
    () async {
      storage.values.addAll({
        'token': 'synthetic-secret',
        StorageKeys.promptAssistantConfigJson: 'private',
        StorageKeys.fontScale: 1.1,
      });
      final all = await read();
      expect(jsonEncode(all), isNot(contains('synthetic-secret')));
      expect(
        all['allowed_keys'],
        isNot(contains(StorageKeys.promptAssistantConfigJson)),
      );
      final part = await read({
        'keys': [StorageKeys.fontScale],
      });
      expect(part['values'], {StorageKeys.fontScale: 1.1});
      expect(part['version'], all['version']);
      await expectLater(
        read({
          'keys': ['token'],
        }),
        throwsA(isA<NaiAgentToolError>()),
      );
    },
  );
  test(
    'native persisted readback, safe workspace backup and null reset',
    () async {
      storage.values[StorageKeys.fontScale] = 1.1;
      final result = await update({
        StorageKeys.fontScale: 1.3,
        StorageKeys.enableCooccurrenceRecommendation: false,
      }, (await read())['version'] as String);
      expect(result['values'][StorageKeys.fontScale], 1.3);
      expect(result['before'][StorageKeys.fontScale], 1.1);
      expect(
        (result['before'] as Map).keys.toSet(),
        SettingsPreferencesService.keys,
      );
      final backup = jsonDecode(
        await File(result['backup_path'] as String).readAsString(),
      );
      expect(backup['generation']['preferences'][StorageKeys.fontScale], 1.1);
      expect(
        result['backup_path'],
        startsWith(await dir.resolveSymbolicLinks()),
      );
      await update({StorageKeys.fontScale: null}, result['version'] as String);
      expect(storage.values.containsKey(StorageKeys.fontScale), isFalse);
    },
  );
  test(
    'card undo restores before including null, allows unrelated edits, rejects changed fields',
    () async {
      storage.values[StorageKeys.fontScale] = 1.1;
      final result = await update({
        StorageKeys.fontScale: 1.3,
      }, (await read())['version'] as String);
      final restore = AgentSettingsRestore(
        'id',
        result['version'] as String,
        Map<String, Object?>.from(result['before'] as Map),
        Map<String, Object?>.from(result['values'] as Map),
        [StorageKeys.fontScale],
      );
      storage.values[StorageKeys.locale] = 'en';
      expect(await AgentSettingsUndo(tools).restore(restore), true);
      expect(storage.values[StorageKeys.fontScale], 1.1);
      expect(storage.values[StorageKeys.locale], 'en');
      storage.values[StorageKeys.fontScale] = 1.4;
      expect(await AgentSettingsUndo(tools).restore(restore), false);
      expect(storage.values[StorageKeys.fontScale], 1.4);
      const reset = AgentSettingsRestore(
        'reset',
        'v',
        {StorageKeys.fontScale: null},
        {StorageKeys.fontScale: 1.4},
        [StorageKeys.fontScale],
      );
      expect(await AgentSettingsUndo(tools).restore(reset), true);
      expect(storage.values.containsKey(StorageKeys.fontScale), false);
    },
  );

  test('card undo refuses changes during asynchronous backup', () async {
    storage.values[StorageKeys.fontScale] = 1.3;
    tools = NaiAgentSettingsTools(
      _BackupSettings(
        storage,
        dir,
        () => storage.values[StorageKeys.fontScale] = 1.4,
      ),
      isAlive: () => true,
      refresh: () {},
    );
    expect(
      await AgentSettingsUndo(tools).restore(
        const AgentSettingsRestore(
          'id',
          'v',
          {StorageKeys.fontScale: 1.1},
          {StorageKeys.fontScale: 1.3},
          [StorageKeys.fontScale],
        ),
      ),
      false,
    );
    expect(storage.values[StorageKeys.fontScale], 1.4);
  });

  test(
    'stale versions, unsupported keys and invalid native values never overwrite',
    () async {
      final version = (await read())['version'] as String;
      storage.values[StorageKeys.fontScale] = 1.2;
      await expectLater(
        update({StorageKeys.fontScale: 1.4}, version),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'settings_conflict',
          ),
        ),
      );
      for (final changes in [
        {'token': 'bad'},
        {StorageKeys.fontScale: 100},
        {StorageKeys.locale: 'invalid'},
      ]) {
        await expectLater(
          update(changes, (await read())['version'] as String),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
      expect(storage.values[StorageKeys.fontScale], 1.2);
      expect(await dir.list().toList(), isEmpty);
    },
  );
  test(
    'cancellation and concurrent changes during backup are checked at the actual write',
    () async {
      final token = NaiAgentCancellation();
      tools = NaiAgentSettingsTools(
        _BackupSettings(storage, dir, token.cancel),
        isAlive: () => true,
        refresh: () {},
      );
      final params = {
        'changes': {StorageKeys.fontScale: 1.3},
        'expected_version': (await read())['version'],
      };
      await expectLater(
        tools.update(params, token),
        throwsA(
          isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(storage.values, isEmpty);
      tools = NaiAgentSettingsTools(
        _BackupSettings(
          storage,
          dir,
          () => storage.values[StorageKeys.fontScale] = 1.4,
        ),
        isAlive: () => true,
        refresh: () {},
      );
      await expectLater(
        tools.update(params, NaiAgentCancellation()),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.fontScale], 1.4);
    },
  );
  test(
    'native rollback keeps subsequent user writes when a later field fails',
    () async {
      storage.values[StorageKeys.fontScale] = 1.1;
      storage.failKey = StorageKeys.enableCooccurrenceRecommendation;
      storage.beforeWrite = (key) {
        if (key == storage.failKey) {
          storage.values[StorageKeys.fontScale] = 1.45;
        }
      };
      await expectLater(
        update({
          StorageKeys.fontScale: 1.3,
          StorageKeys.enableCooccurrenceRecommendation: true,
        }, (await read())['version'] as String),
        throwsStateError,
      );
      expect(storage.values[StorageKeys.fontScale], 1.45);
    },
  );
}
