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

  test('fresh profiles never create an AppData alias', () async {
    expect(
      await migration(
        createLink: (_, _) async {
          fail('A fresh profile must not create an AppData junction');
        },
      ).prepare(),
      target,
    );
    expect(await target.exists(), isTrue);
    expect(await legacy.exists(), isFalse);
    final marker =
        jsonDecode(
              await File(
                p.join(target.path, AdjacentAppDataMigration.markerName),
              ).readAsString(),
            )
            as Map;
    expect(marker['schema'], 2);
    expect(marker['backup'], isNull);
    await write('shared_preferences.json', '{"synthetic":true}', root: target);
    await migration().prepare();
    expect(await legacy.exists(), isFalse);
  });

  test(
    'existing adjacent data wins without replacing an empty old directory',
    () async {
      await legacy.create(recursive: true);
      await write('draft.json', 'current draft', root: target);
      await migration().prepare();
      expect(
        await File(p.join(target.path, 'draft.json')).readAsString(),
        'current draft',
      );
      expect(await legacy.list().isEmpty, isTrue);
      expect(
        await FileSystemEntity.type(legacy.path, followLinks: false),
        FileSystemEntityType.directory,
      );
    },
  );

  test('prepared profiles no longer inspect the old data path', () async {
    await migration().prepare();
    await legacy.parent.create(recursive: true);
    await File(legacy.path).writeAsString('unrelated old path');
    await migration().prepare();
    expect(await File(legacy.path).readAsString(), 'unrelated old path');
  });

  test(
    'fresh profiles ignore a different installation or its broken alias',
    () async {
      for (final broken in [false, true]) {
        final other = Directory(p.join(fixture.path, 'other-$broken'));
        await other.create();
        await write('draft.json', 'other installation', root: other);
        await legacy.parent.create(recursive: true);
        await (Platform.isWindows
            ? AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
                legacy,
                other,
              )
            : Link(legacy.path).create(other.path));
        if (broken) {
          await File(p.join(other.path, 'draft.json')).delete();
          await other.delete();
        }
        await migration().prepare();
        expect(await File(p.join(target.path, 'draft.json')).exists(), isFalse);
        if (!broken) {
          expect(
            await File(p.join(other.path, 'draft.json')).readAsString(),
            'other installation',
          );
        }
        await Link(legacy.path).delete();
        await File(
          p.join(target.path, AdjacentAppDataMigration.markerName),
        ).delete();
        await target.delete();
      }
    },
  );

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
    'old plugin split imports missing files once, preserving source and backup',
    () async {
      await splitProfile();
      await migration(
        createLink: (_, _) async {
          fail('Importing plugin files must not create an AppData junction');
        },
      ).prepare();
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
      expect(marker['schema'], 2);
      final backup = Directory(marker['backup'] as String);
      expect(
        await File(
          p.join(backup.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      await write(
        'flutter_secure_storage.dat',
        'new current account',
        root: target,
      );
      await write('flutter_secure_storage.dat', 'other old account');
      await migration(
        beforeCommit: () async {
          fail('A prepared profile must not reimport AppData');
        },
      ).prepare();
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'new current account',
      );
      expect(
        await File(
          p.join(backup.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
    },
  );

  test(
    'current plugin files win, including different content and original timestamps',
    () async {
      await splitProfile();
      await write(
        'flutter_secure_storage.dat',
        'current account',
        root: target,
      );
      await write('shared_preferences.json', '{"current":true}', root: target);
      final file = File(p.join(target.path, 'shared_preferences.json'));
      final modified = DateTime.utc(2020, 1, 2);
      await file.setLastModified(modified);
      await migration().prepare();
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'current account',
      );
      expect(await file.readAsString(), '{"current":true}');
      expect((await file.stat()).modified.toUtc(), modified);
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
    },
  );

  for (final state in [
    'unknown file',
    'nested profile',
    'wrong marker',
    'prior migration',
    'missing marker',
    'malformed marker',
  ]) {
    test('existing profile starts without importing $state', () async {
      await splitProfile(
        markerPatch: {
          if (state == 'wrong marker') 'legacy': p.join(fixture.path, 'other'),
          if (state == 'prior migration')
            'backup': p.join(fixture.path, 'old-backup'),
        },
      );
      if (state == 'unknown file') await write('draft.json', 'old draft');
      if (state == 'nested profile') {
        await write('hive/settings.hive', 'old settings');
      }
      final marker = File(
        p.join(target.path, AdjacentAppDataMigration.markerName),
      );
      if (state == 'missing marker') await marker.delete();
      if (state == 'malformed marker') await marker.writeAsString('{bad');
      await migration().prepare();
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
        'current settings',
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'encrypted synthetic account',
      );
      expect(
        await File(p.join(target.path, 'flutter_secure_storage.dat')).exists(),
        isFalse,
      );
      if (state == 'prior migration') {
        expect(
          (jsonDecode(await marker.readAsString()) as Map)['backup'],
          p.join(fixture.path, 'old-backup'),
        );
      }
    });
  }

  test(
    'source changes abort the one-time plugin import and allow retry',
    () async {
      await splitProfile();
      await expectLater(
        migration(
          beforeCommit: () =>
              write('flutter_secure_storage.dat', 'edited source'),
        ).prepare(),
        throwsA(isA<AdjacentAppDataException>()),
      );
      expect(
        await File(p.join(target.path, 'flutter_secure_storage.dat')).exists(),
        isFalse,
      );
      expect(
        await File(
          p.join(legacy.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'edited source',
      );
      await migration().prepare();
      expect(
        await File(
          p.join(target.path, 'flutter_secure_storage.dat'),
        ).readAsString(),
        'edited source',
      );
    },
  );

  test('a current file added during one-time import is preserved', () async {
    await splitProfile();
    await migration(
      beforeCommit: () => write(
        'flutter_secure_storage.dat',
        'new current account',
        root: target,
      ),
    ).prepare();
    expect(
      await File(
        p.join(target.path, 'flutter_secure_storage.dat'),
      ).readAsString(),
      'new current account',
    );
    expect(
      await File(p.join(target.path, 'shared_preferences.json')).readAsString(),
      '{"synthetic":true}',
    );
    expect(
      await File(
        p.join(legacy.path, 'flutter_secure_storage.dat'),
      ).readAsString(),
      'encrypted synthetic account',
    );
  });

  test(
    'plugin split links never import external bytes or block the current profile',
    () async {
      await splitProfile();
      final external = Directory(p.join(fixture.path, 'external'));
      await external.create();
      await write('private.txt', 'external data', root: external);
      await File(p.join(legacy.path, 'flutter_secure_storage.dat')).delete();
      final link = Directory(p.join(legacy.path, 'flutter_secure_storage.dat'));
      await (Platform.isWindows
          ? AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
              link,
              external,
            )
          : Link(link.path).create(external.path));
      await migration().prepare();
      expect(
        await File(p.join(external.path, 'private.txt')).readAsString(),
        'external data',
      );
      expect(
        await File(p.join(target.path, 'flutter_secure_storage.dat')).exists(),
        isFalse,
      );
      await Link(link.path).delete();
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
      await migration().prepare();
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

  test(
    'a legacy junction to another installation does not block or retarget the current profile',
    () async {
      final other = Directory(p.join(fixture.path, 'other-install'));
      await other.create();
      await legacy.parent.create(recursive: true);
      await AdjacentAppDataMigration.createWindowsCompatibilityDirectory(
        legacy,
        other,
      );
      await write('draft.json', 'current draft', root: target);
      await migration().prepare();
      expect(
        await File(p.join(target.path, 'draft.json')).readAsString(),
        'current draft',
      );
      expect(
        await legacy.resolveSymbolicLinks(),
        await other.resolveSymbolicLinks(),
      );
    },
    skip: !Platform.isWindows,
  );

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
