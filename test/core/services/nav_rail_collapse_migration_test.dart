import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/data_migration_service.dart';

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

  test('存量展开态被一次性重置为收起并落标记', () async {
    await settingsBox().put(StorageKeys.mainNavRailExpanded, true);

    await DataMigrationService.instance.migrateNavRailCollapse();

    expect(settingsBox().get(StorageKeys.mainNavRailExpanded), isFalse);
    expect(
      settingsBox().get(StorageKeys.mainNavRailCollapseMigrated),
      isTrue,
    );
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
      settingsBox().get(
        StorageKeys.mainNavRailExpanded,
        defaultValue: false,
      ),
      isFalse,
    );
    expect(
      settingsBox().get(StorageKeys.mainNavRailCollapseMigrated),
      isTrue,
    );
  });
}
