import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/adjacent_app_data_migration.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory fixture;
  late Directory legacy;
  late Directory target;

  setUp(() async {
    // Never use real application directories, credentials, models or drafts.
    fixture = await Directory.systemTemp.createTemp('adjacent-data-test-');
    legacy = Directory(p.join(fixture.path, 'old-profile', 'nai_launcher'));
    target = Directory(p.join(fixture.path, 'installed-app', 'user-data'));
  });
  tearDown(() async {
    if (await FileSystemEntity.type(legacy.path, followLinks: false) ==
        FileSystemEntityType.link) {
      await Link(legacy.path).delete();
    }
    await fixture.delete(recursive: true);
  });

  Future<void> write(String relative, String content, {Directory? root}) async {
    final file = File(p.join((root ?? legacy).path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  AdjacentAppDataMigration migration({
    Future<void> Function()? beforeCommit,
    CompatibilityDirectoryCreator? createLink,
  }) => AdjacentAppDataMigration(
    legacy: legacy,
    destination: target,
    beforeCommit: beforeCommit,
    createCompatibilityDirectory: createLink,
  );

  test(
    'fresh installation creates adjacent storage without copying a profile',
    () async {
      expect(await migration().prepare(), target);
      expect(await target.exists(), isTrue);
      expect(await legacy.exists(), isFalse);
      final marker =
          jsonDecode(
                await File(
                  p.join(target.path, AdjacentAppDataMigration.markerName),
                ).readAsString(),
              )
              as Map;
      expect(marker['layout'], 'executable-adjacent');
      expect(marker['backup'], isNull);
    },
  );

  test(
    'verified migration preserves absolute paths and an independent backup',
    () async {
      await write('hive/settings.hive', 'synthetic settings');
      await write('draft-backups/latest.json', 'original draft');
      await write('rag/v1/runtime/model.bin', 'synthetic model');
      await Directory(p.join(legacy.path, 'empty-folder')).create();
      final oldModified = DateTime.utc(2025, 5, 4, 3, 2, 1);
      await File(
        p.join(legacy.path, 'hive/settings.hive'),
      ).setLastModified(oldModified);

      await migration().prepare();

      expect(
        await legacy.resolveSymbolicLinks(),
        await target.resolveSymbolicLinks(),
      );
      expect(
        await File(
          p.join(legacy.path, 'rag/v1/runtime/model.bin'),
        ).readAsString(),
        'synthetic model',
      );
      expect(
        await Directory(p.join(target.path, 'empty-folder')).exists(),
        isTrue,
      );
      expect(
        (await File(
          p.join(target.path, 'hive/settings.hive'),
        ).stat()).modified.toUtc(),
        oldModified,
      );
      final marker =
          jsonDecode(
                await File(
                  p.join(target.path, AdjacentAppDataMigration.markerName),
                ).readAsString(),
              )
              as Map;
      final backup = Directory(marker['backup'] as String);
      await write('draft-backups/latest.json', 'new draft', root: target);
      expect(
        await File(
          p.join(backup.path, 'draft-backups/latest.json'),
        ).readAsString(),
        'original draft',
      );
      expect(
        await legacy.parent
            .list()
            .where(
              (e) => p.basename(e.path).startsWith('.nai_launcher-migrated-'),
            )
            .isEmpty,
        isTrue,
      );
      await migration().prepare();
      expect(
        await target.parent
            .list()
            .where((e) => p.basename(e.path).startsWith('.studio-data-backup-'))
            .length,
        1,
      );
    },
    skip: !Platform.isWindows,
  );

  test(
    'different data at both locations is never merged or overwritten',
    () async {
      await write('hive/settings.hive', 'old profile');
      await write('hive/settings.hive', 'new profile', root: target);
      await expectLater(
        migration().prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await File(p.join(legacy.path, 'hive/settings.hive')).readAsString(),
        'old profile',
      );
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'new profile',
      );
    },
  );

  test(
    'a draft edited during copying prevents switching directories',
    () async {
      await write('draft.json', 'old draft');
      await expectLater(
        migration(
          beforeCommit: () => write('draft.json', 'newer user edit'),
        ).prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await File(p.join(legacy.path, 'draft.json')).readAsString(),
        'newer user edit',
      );
      expect(await target.exists(), isFalse);
    },
  );

  test(
    'files added during copying prevent committing a stale snapshot',
    () async {
      await write('draft.json', 'old draft');
      await expectLater(
        migration(
          beforeCommit: () => write('new.json', 'newly saved data'),
        ).prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await File(p.join(legacy.path, 'new.json')).readAsString(),
        'newly saved data',
      );
      expect(await target.exists(), isFalse);
    },
  );

  test(
    'failure to create the compatibility junction restores original location',
    () async {
      await write('draft.json', 'untouched draft');
      await expectLater(
        migration(
          createLink: (_, _) async {
            throw const FileSystemException('synthetic junction failure');
          },
        ).prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await FileSystemEntity.type(legacy.path, followLinks: false),
        FileSystemEntityType.directory,
      );
      expect(
        await File(p.join(legacy.path, 'draft.json')).readAsString(),
        'untouched draft',
      );
      expect(await target.exists(), isFalse);
    },
  );

  test('a destination created during copying is not deleted', () async {
    await write('draft.json', 'old profile');
    await expectLater(
      migration(
        beforeCommit: () => write('new.json', 'new target data', root: target),
      ).prepare(),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await File(p.join(target.path, 'new.json')).readAsString(),
      'new target data',
    );
    expect(
      await File(p.join(legacy.path, 'draft.json')).readAsString(),
      'old profile',
    );
  });

  test('nested migration paths are rejected before any data changes', () async {
    await write('draft.json', 'old profile');
    await expectLater(
      AdjacentAppDataMigration(
        legacy: legacy,
        destination: Directory(p.join(legacy.path, 'nested')),
      ).prepare(),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await File(p.join(legacy.path, 'draft.json')).readAsString(),
      'old profile',
    );
  });

  test(
    'an existing adjacent profile is used when no legacy profile exists',
    () async {
      await write('hive/settings.hive', 'portable profile', root: target);
      await migration().prepare();
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'portable profile',
      );
    },
  );

  test('a legacy junction to another installation is not retargeted', () async {
    final other = Directory(p.join(fixture.path, 'other-install'));
    await other.create();
    await legacy.parent.create(recursive: true);
    await AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
      legacy,
      other,
    );
    await expectLater(
      migration().prepare(),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await legacy.resolveSymbolicLinks(),
      await other.resolveSymbolicLinks(),
    );
  }, skip: !Platform.isWindows);

  test(
    'links inside a profile cannot pull external files into migration',
    () async {
      final external = Directory(p.join(fixture.path, 'external'));
      await external.create();
      await write('private.txt', 'external data', root: external);
      await legacy.create(recursive: true);
      final link = Directory(p.join(legacy.path, 'external'));
      await AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
        link,
        external,
      );
      try {
        await expectLater(
          migration().prepare(),
          throwsA(isA<FileSystemException>()),
        );
        expect(
          await File(p.join(external.path, 'private.txt')).readAsString(),
          'external data',
        );
        expect(await target.exists(), isFalse);
      } finally {
        await Link(link.path).delete();
      }
    },
    skip: !Platform.isWindows,
  );

  test(
    'internal Python aliases are rebased in both backup and final data',
    () async {
      await write('python/versioned/python.txt', 'python fixture');
      final alias = Directory(p.join(legacy.path, 'python/current'));
      await AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
        alias,
        Directory(p.join(legacy.path, 'python/versioned')),
      );
      await migration().prepare();
      final marker =
          jsonDecode(
                await File(
                  p.join(target.path, AdjacentAppDataMigration.markerName),
                ).readAsString(),
              )
              as Map;
      final backup = Directory(marker['backup'] as String);
      expect(
        await Directory(
          p.join(target.path, 'python/current'),
        ).resolveSymbolicLinks(),
        await Directory(
          p.join(target.path, 'python/versioned'),
        ).resolveSymbolicLinks(),
      );
      expect(
        await Directory(
          p.join(backup.path, 'python/current'),
        ).resolveSymbolicLinks(),
        await Directory(
          p.join(backup.path, 'python/versioned'),
        ).resolveSymbolicLinks(),
      );
      expect(
        await File(
          p.join(legacy.path, 'python/current/python.txt'),
        ).readAsString(),
        'python fixture',
      );
      // Remove the test-only internal junctions before recursive fixture cleanup.
      await Link(p.join(target.path, 'python/current')).delete();
      await Link(p.join(backup.path, 'python/current')).delete();
    },
    skip: !Platform.isWindows,
  );
}
