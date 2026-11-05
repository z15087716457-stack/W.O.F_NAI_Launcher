import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/adjacent_app_data_migration.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory fixture;
  late Directory legacy;
  late Directory profile;
  late AdjacentAppDataMigration migration;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mac-first-profile-');
    legacy = await Directory(p.join(fixture.path, 'old')).create();
    profile = await Directory(p.join(fixture.path, 'new')).create();
    migration = AdjacentAppDataMigration(legacy: legacy, destination: profile);
  });

  tearDown(() => fixture.delete(recursive: true));

  test(
    'initial copy publishes verified data once and keeps the originals',
    () async {
      final hive = await Directory(p.join(legacy.path, 'hive')).create();
      final original = await File(
        p.join(hive.path, 'settings.hive'),
      ).writeAsString('legacy');
      await File(p.join(hive.path, 'settings.lock')).create();
      await Directory(
        p.join(legacy.path, 'rag', 'runtime'),
      ).create(recursive: true);

      expect(
        await migration.copyFirstLaunch(legacyRunning: () async => false),
        isTrue,
      );
      final copied = File(p.join(profile.path, 'hive', 'settings.hive'));
      expect(await copied.readAsString(), 'legacy');
      expect(await original.readAsString(), 'legacy');
      expect(
        await File(p.join(profile.path, 'hive', 'settings.lock')).exists(),
        isFalse,
      );
      expect(
        await Directory(p.join(profile.path, 'rag', 'runtime')).exists(),
        isFalse,
      );
      await copied.writeAsString('current data');
      await original.writeAsString('edited elsewhere');
      expect(
        await migration.copyFirstLaunch(legacyRunning: () async => false),
        isFalse,
      );
      expect(await copied.readAsString(), 'current data');
    },
  );

  test('a previous app still running leaves both profiles intact', () async {
    final original = await File(
      p.join(legacy.path, 'settings.hive'),
    ).writeAsString('legacy');
    await expectLater(
      migration.copyFirstLaunch(legacyRunning: () async => true),
      throwsA(isA<FileSystemException>()),
    );
    expect(await original.readAsString(), 'legacy');
    expect(await profile.list().isEmpty, isTrue);
  });
}
