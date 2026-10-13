import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/data_migration_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'nav_rail_collapse_migration_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.box(StorageKeys.settingsBox).clear();
    } else {
      await Hive.openBox(StorageKeys.settingsBox);
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Box settingsBox() => Hive.box(StorageKeys.settingsBox);

  test(
    'new navigation migration preserves pinned intent and retires the legacy reset',
    () async {
      final storage = LocalStorageService();
      await storage.setMainNavRailExpanded(true);
      await storage.setMainNavHiddenBranches(['statistics']);
      await storage.setMainNavCtrlNumbers(false);
      await storage.setMainNavCtrlHintSeen(true);
      await DataMigrationService.instance.migrateMainNavPreferences();
      await DataMigrationService.instance.migrateNavRailCollapse();
      await settingsBox().close();
      await Hive.openBox(StorageKeys.settingsBox);
      expect(storage.getMainNavRailExpanded(), isTrue);
      expect(storage.getMainNavHiddenBranches(), ['statistics']);
      expect(storage.getMainNavCtrlNumbers(), isFalse);
      expect(storage.getMainNavCtrlHintSeen(), isTrue);
      expect(
        settingsBox().get(StorageKeys.mainNavRailCollapseMigrated),
        isTrue,
      );
    },
  );

  test(
    'fresh navigation migration keeps default preferences and does not create an expansion value',
    () async {
      await DataMigrationService.instance.migrateMainNavPreferences();
      final storage = LocalStorageService();
      expect(storage.getMainNavRailExpanded(), isFalse);
      expect(storage.getMainNavHiddenBranches(), isEmpty);
      expect(storage.getMainNavCtrlNumbers(), isTrue);
      expect(storage.getMainNavCtrlHintSeen(), isFalse);
      expect(
        settingsBox().containsKey(StorageKeys.mainNavRailExpanded),
        isFalse,
      );
    },
  );

  test('存量展开态被一次性重置为收起并落标记', () async {
    await settingsBox().put(StorageKeys.mainNavRailExpanded, true);

    await DataMigrationService.instance.migrateNavRailCollapse();

    expect(settingsBox().get(StorageKeys.mainNavRailExpanded), isFalse);
    expect(settingsBox().get(StorageKeys.mainNavRailCollapseMigrated), isTrue);
  });

  test('已迁移后不重复写——用户手动展开保持展开', () async {
    await settingsBox().put(StorageKeys.mainNavRailCollapseMigrated, true);
    await settingsBox().put(StorageKeys.mainNavRailExpanded, true);

    await DataMigrationService.instance.migrateNavRailCollapse();

    expect(settingsBox().get(StorageKeys.mainNavRailExpanded), isTrue);
  });

  test('无展开键的新装用户只落标记不产生展开态', () async {
    await DataMigrationService.instance.migrateNavRailCollapse();

    expect(
      settingsBox().get(StorageKeys.mainNavRailExpanded, defaultValue: false),
      isFalse,
    );
    expect(settingsBox().get(StorageKeys.mainNavRailCollapseMigrated), isTrue);
  });
}
