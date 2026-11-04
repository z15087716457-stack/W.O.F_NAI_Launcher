import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_import.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_sync.dart';
import 'package:nai_launcher/core/utils/app_support_directory.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_legacy_data.dart';
import 'package:path/path.dart' as p;

import '../../../core/services/mac_legacy_data_test_support.dart';

void main() {
  late Directory fixture;
  late Directory legacy;
  late Directory target;

  setUp(() async {
    // A synthetic ~/Library/Application Support. Never the real folders.
    fixture = await Directory.systemTemp.createTemp('settings-legacy-test-');
    final support = p.join(fixture.path, 'Application Support');
    legacy = Directory(p.join(support, 'com.aaalice.naiLauncher'));
    target = Directory(p.join(support, 'com.wof.naiStudio'));
    await writeData(legacy, 'hive/settings.hive', '1.1.1 settings');
    await writeData(
      target,
      MacLegacyDataImport.markerName,
      jsonEncode({'state': 'imported', 'at': '2026-10-23T06:05:00.000Z'}),
    );
    await writeData(target, 'hive/settings.hive', '2.0 settings');
  });
  tearDown(() => fixture.delete(recursive: true));

  MacLegacyDataImport import() => MacLegacyDataImport(
    legacy: legacy,
    destination: target,
    isLegacyRunning: (_) async => false,
  );

  Future<SettingsLegacyData?> read(
    MacLegacyDataImport? Function() locate,
  ) async {
    final container = ProviderContainer(
      overrides: [
        macLegacyDataLocatorProvider.overrideWithValue(() async => locate()),
      ],
    );
    addTearDown(container.dispose);
    return container.read(settingsLegacyDataProvider.future);
  }

  test('the section shows what the data came from', () async {
    final data = (await read(import))!;

    expect(data.appName, macLegacyAppName);
    expect(data.copiedAt, DateTime.utc(2026, 10, 23, 6, 5).toLocal());
    expect(data.syncedAt, isNull);
    expect(data.switchBack, isNull);
    expect(data.running, isFalse);
  });

  test(
    'the second row swaps between the data before and after a sync',
    () async {
      Future<SettingsLegacySwitch> row() async =>
          (await read(import))!.switchBack!;
      Future<MacLegacyDataBackup> newest() async =>
          (await import().dataSwitch.backups()).first;

      await import().request(const MacLegacyDataRequest.sync());
      await import().prepare();
      var back = await row();
      var backup = await newest();
      expect(back.kind, SettingsLegacySwitchKind.undo);
      expect((back.backup, back.at), (backup.id, backup.at));

      await import().request(MacLegacyDataRequest.undo(back.backup));
      await import().prepare();
      back = await row();
      backup = await newest();
      expect(back.kind, SettingsLegacySwitchKind.redo);
      expect((back.backup, back.at), (backup.id, backup.at));

      await import().request(MacLegacyDataRequest.redo(back.backup));
      await import().prepare();
      back = await row();
      backup = await newest();
      expect(back.kind, SettingsLegacySwitchKind.undoAgain);
      expect((back.backup, back.at), (backup.id, backup.at));
      expect(legacySwitchBack(null), isNull);
    },
  );

  test('hidden off macOS, in a sandbox and without previous data', () async {
    // The locator gives nothing on Windows, in tests and in a sandbox
    // (macLegacySyncOffered), so the section disappears.
    expect(await read(() => null), isNull);
    expect(
      macLegacySyncOffered(
        layout: SupportDirectoryLayout.executableAdjacent,
        sandboxRoot: null,
      ),
      isFalse,
    );
    expect(
      macLegacySyncOffered(
        layout: SupportDirectoryLayout.macLegacyImport,
        sandboxRoot: '/tmp/sandbox',
      ),
      isFalse,
    );

    await legacy.delete(recursive: true);
    expect(await read(import), isNull);
  });

  test('sync and switching back record the request and restart', () async {
    var restarts = 0;
    final actions = SettingsLegacyActions(
      locate: () async => import(),
      restart: () async => restarts++,
    );

    await actions.sync();
    expect(restarts, 1);
    expect(
      (await import().dataSwitch.readRequest())?.task,
      MacLegacyDataTask.sync,
    );

    const backup = '20261029-153000-000-before-undo';
    await actions.redo(backup);
    expect(restarts, 2);
    final request = await import().dataSwitch.readRequest();
    expect((request?.task, request?.backup), (MacLegacyDataTask.redo, backup));
  });

  test('a refused restart drops the request again', () async {
    await expectLater(
      SettingsLegacyActions(
        locate: () async => import(),
        restart: () async => throw StateError('A task is running'),
      ).undo('20261029-140100-000-before-sync'),
      throwsA(isA<SettingsLegacyBusy>()),
    );
    expect(await import().dataSwitch.pending(), isFalse);
  });

  test('nothing can be synced where it is not offered', () async {
    var restarts = 0;
    await expectLater(
      SettingsLegacyActions(
        locate: () async => null,
        restart: () async => restarts++,
      ).sync(),
      throwsA(isA<StateError>()),
    );
    expect(restarts, 0);
    expect(await MacLegacyDataSwitch(target).pending(), isFalse);
  });
}
