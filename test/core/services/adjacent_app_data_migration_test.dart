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
    createCompatibilityDirectory:
        createLink ??
        (Platform.isWindows
            ? null
            : (old, destination) =>
                  Link(old.path).create(destination.path, recursive: true)),
  );

  test(
    'fresh installation creates adjacent storage without copying a profile',
    () async {
      expect(await migration().prepare(), target);
      expect(await target.exists(), isTrue);
      expect(
        await legacy.resolveSymbolicLinks(),
        await target.resolveSymbolicLinks(),
      );
      final marker =
          jsonDecode(
                await File(
                  p.join(target.path, AdjacentAppDataMigration.markerName),
                ).readAsString(),
              )
              as Map;
      expect(marker['layout'], 'executable-adjacent');
      expect(marker['backup'], isNull);
      // Native plugins still use this path after the first frame. A second
      // process/start must see the same data instead of two separate profiles.
      await write('flutter_secure_storage.dat', 'synthetic encrypted account');
      await write('shared_preferences.json', '{"synthetic":true}');
      await migration().prepare();
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'synthetic encrypted account',
      );
    },
  );

  test(
    'an empty legacy directory is replaced without losing adjacent data',
    () async {
      await legacy.create(recursive: true);
      await write('draft.json', 'adjacent draft', root: target);
      await migration().prepare();
      expect(
        await legacy.resolveSymbolicLinks(),
        await target.resolveSymbolicLinks(),
      );
      expect(
        await File(p.join(legacy.path, 'draft.json')).readAsString(),
        'adjacent draft',
      );
      await migration().prepare();
    },
  );

  test('fresh junction failure keeps data and can be retried', () async {
    await legacy.create(recursive: true);
    await expectLater(
      migration(
        createLink: (_, __) async {
          throw const FileSystemException('synthetic junction failure');
        },
      ).prepare(),
      throwsA(isA<AdjacentAppDataException>()),
    );
    expect(
      await FileSystemEntity.type(legacy.path, followLinks: false),
      FileSystemEntityType.directory,
    );
    expect(
      await File(
        p.join(target.path, AdjacentAppDataMigration.markerName),
      ).exists(),
      true,
    );
    await migration().prepare();
    expect(
      await legacy.resolveSymbolicLinks(),
      await target.resolveSymbolicLinks(),
    );
  });

  Future<void> splitProfile({
    Map<String, Object?> markerPatch = const {},
  }) async {
    await write('hive/settings.hive', 'current settings', root: target);
    await write(
      AdjacentAppDataMigration.markerName,
      jsonEncode({
        'schema': 1,
        'layout': 'executable-adjacent',
        'legacy': legacy.absolute.path,
        'backup': null,
        ...markerPatch,
      }),
      root: target,
    );
    await write('flutter_secure_storage.dat', 'encrypted synthetic account');
    await write('shared_preferences.json', '{"synthetic":true}');
    await write('danbooru_api_key.secure', 'synthetic legacy secure value');
  }

  test(
    'recorded fresh split recovers plugin files with independent backups',
    () async {
      await splitProfile();
      await migration().prepare();
      expect(
        await legacy.resolveSymbolicLinks(),
        await target.resolveSymbolicLinks(),
      );
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'current settings',
      );
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      expect(
        await File(
          p.join(target.path, 'danbooru_api_key.secure'),
        ).readAsString(),
        'synthetic legacy secure value',
      );
      final marker =
          jsonDecode(
                await File(
                  p.join(target.path, AdjacentAppDataMigration.markerName),
                ).readAsString(),
              )
              as Map;
      for (final path in [marker['backup'], marker['recovered_legacy']]) {
        expect(
          await File(
            p.join(path as String, 'flutter_secure_storage.dat'),
          ).readAsString(),
          'encrypted synthetic account',
        );
      }
      await write('flutter_secure_storage.dat', 'new account', root: target);
      expect(
        await File(
          p.join(marker['backup'] as String, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      await migration().prepare();
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'new account',
      );
    },
  );

  test(
    'identical plugin files are kept without rewriting destination timestamps',
    () async {
      await splitProfile();
      await write(
        'shared_preferences.json',
        '{"synthetic":true}',
        root: target,
      );
      final file = File(p.join(target.path, 'shared_preferences.json'));
      final modified = DateTime.utc(2020, 1, 2);
      await file.setLastModified(modified);
      await migration().prepare();
      expect((await file.stat()).modified.toUtc(), modified);
    },
  );

  for (final invalid in [
    'different token',
    'unknown file',
    'nested profile',
    'wrong marker',
    'prior migration',
    'missing marker',
    'malformed marker',
  ]) {
    test(
      'split recovery refuses $invalid and preserves both originals',
      () async {
        await splitProfile(
          markerPatch: {
            if (invalid == 'wrong marker')
              'legacy': p.join(fixture.path, 'someone-else'),
            if (invalid == 'prior migration')
              'backup': p.join(fixture.path, 'old-backup'),
          },
        );
        if (invalid == 'different token') {
          await write(
            'flutter_secure_storage.dat',
            'different current token',
            root: target,
          );
        }
        if (invalid == 'unknown file') await write('draft.json', 'old draft');
        if (invalid == 'nested profile') {
          await write('hive/settings.hive', 'old settings');
        }
        final marker = File(
          p.join(target.path, AdjacentAppDataMigration.markerName),
        );
        if (invalid == 'missing marker') await marker.delete();
        if (invalid == 'malformed marker') await marker.writeAsString('{bad');
        await expectLater(
          migration().prepare(),
          throwsA(isA<AdjacentAppDataException>()),
        );
        expect(
          await File(
            p.join(legacy.path, 'flutter_secure_storage.dat'),
          ).readAsString(),
          'encrypted synthetic account',
        );
        expect(
          await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
          'current settings',
        );
        if (invalid == 'different token') {
          expect(
            await File(
              p.join(target.path, 'flutter_secure_storage.dat'),
            ).readAsString(),
            'different current token',
          );
        } else {
          expect(
            await File(
              p.join(target.path, 'flutter_secure_storage.dat'),
            ).exists(),
            false,
          );
        }
        expect(
          await FileSystemEntity.type(legacy.path, followLinks: false),
          FileSystemEntityType.directory,
        );
      },
    );
  }

  for (final change in ['source', 'new target', 'existing target', 'marker']) {
    test('split recovery rechecks $change after backup', () async {
      await splitProfile();
      if (change == 'existing target') {
        await write(
          'shared_preferences.json',
          '{"synthetic":true}',
          root: target,
        );
      }
      await expectLater(
        migration(
          beforeCommit: () async {
            switch (change) {
              case 'source':
                await write('flutter_secure_storage.dat', 'edited source');
              case 'new target':
                await write(
                  'flutter_secure_storage.dat',
                  'new target',
                  root: target,
                );
              case 'existing target':
                await write(
                  'shared_preferences.json',
                  'edited target',
                  root: target,
                );
              case 'marker':
                await write(
                  AdjacentAppDataMigration.markerName,
                  '{}',
                  root: target,
                );
            }
          },
        ).prepare(),
        throwsA(isA<AdjacentAppDataException>()),
      );
      expect(
        await FileSystemEntity.type(legacy.path, followLinks: false),
        FileSystemEntityType.directory,
      );
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'current settings',
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        change == 'source' ? 'edited source' : 'encrypted synthetic account',
      );
      if (change == 'new target') {
        expect(
          await File(
            p.join(target.path, 'flutter_secure_storage.dat'),
          ).readAsString(),
          'new target',
        );
      }
      if (change == 'existing target') {
        expect(
          await File(
            p.join(target.path, 'shared_preferences.json'),
          ).readAsString(),
          'edited target',
        );
      }
    });
  }

  test(
    'failed split junction rolls back only files created by recovery',
    () async {
      await splitProfile();
      await expectLater(
        migration(
          createLink: (_, __) async {
            throw const FileSystemException('synthetic junction failure');
          },
        ).prepare(),
        throwsA(isA<AdjacentAppDataException>()),
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      expect(
        await File(p.join(target.path, 'flutter_secure_storage.dat')).exists(),
        false,
      );
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'current settings',
      );
      await migration().prepare();
      expect(
        await legacy.resolveSymbolicLinks(),
        await target.resolveSymbolicLinks(),
      );
    },
  );

  test(
    'rollback preserves a destination file edited after recovery copied it',
    () async {
      await splitProfile();
      await expectLater(
        migration(
          createLink: (_, __) async {
            await write(
              'flutter_secure_storage.dat',
              'new user edit',
              root: target,
            );
            throw const FileSystemException('synthetic junction failure');
          },
        ).prepare(),
        throwsA(isA<AdjacentAppDataException>()),
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'new user edit',
      );
    },
  );

  test('a split plugin file link cannot import external bytes', () async {
    await splitProfile();
    final external = File(p.join(fixture.path, 'outside', 'private.dat'));
    await external.parent.create();
    await external.writeAsString('external bytes');
    final file = File(p.join(legacy.path, 'flutter_secure_storage.dat'));
    await file.delete();
    if (Platform.isWindows) {
      await AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
        Directory(file.path),
        external.parent,
      );
    } else {
      await Link(file.path).create(external.path);
    }
    await expectLater(
      migration().prepare(),
      throwsA(isA<AdjacentAppDataException>()),
    );
    expect(await external.readAsString(), 'external bytes');
    expect(
      await File(p.join(target.path, 'flutter_secure_storage.dat')).exists(),
      false,
    );
    await Link(file.path).delete();
  });

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
