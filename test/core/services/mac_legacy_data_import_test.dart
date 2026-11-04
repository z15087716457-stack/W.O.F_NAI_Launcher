import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_import.dart';
import 'package:path/path.dart' as p;

import 'mac_legacy_data_test_support.dart';

void main() {
  late Directory fixture;
  late Directory support;
  late Directory legacy;
  late Directory target;

  setUp(() async {
    // A synthetic ~/Library/Application Support. Never the real folders.
    fixture = await Directory.systemTemp.createTemp('mac-legacy-import-test-');
    support = Directory(p.join(fixture.path, 'Application Support'));
    legacy = Directory(p.join(support.path, 'com.aaalice.naiLauncher'));
    target = Directory(p.join(support.path, 'com.wof.naiStudio'));
    // path_provider creates the new folder before anything else runs.
    await target.create(recursive: true);
  });
  tearDown(() async {
    if (!Platform.isWindows) {
      await Process.run('chmod', ['-R', 'u+rwX', fixture.path]);
    }
    await fixture.delete(recursive: true);
  });

  test(
    'profile ownership blocks a second app before sync and allows a separate sandbox',
    () async {
      final profile = MacProfileLock();
      final first = await _holdLock(
        p.join(support.path, '.com.wof.naiStudio.running.lock'),
      );
      expect(first, isNotNull);
      try {
        await expectLater(
          profile.acquire(target),
          throwsA(isA<MacProfileInUse>()),
        );
        final alias = Link(p.join(fixture.path, 'linked-profile'));
        await alias.create(target.path);
        await expectLater(
          profile.acquire(Directory(alias.path)),
          throwsA(isA<MacProfileInUse>()),
        );
        final sandbox = MacProfileLock();
        await sandbox.acquire(
          Directory(p.join(fixture.path, 'sandbox', 'user-data')),
        );
        await sandbox.close();
        expect(await target.list().isEmpty, true);
      } finally {
        await first!.stdin.close();
        await first.exitCode;
      }
      await profile.acquire(target);
      await profile.close();
    },
    skip: !Platform.isMacOS,
  );

  test(
    'a running pre-lock build keeps its data and blocks a profile switch',
    () async {
      final hive = await Directory(p.join(target.path, 'hive')).create();
      final data = await File(
        p.join(hive.path, 'settings.hive'),
      ).writeAsBytes([42]);
      final previous = await _holdLock(p.join(hive.path, 'settings.lock'));
      expect(previous, isNotNull);
      final profile = MacProfileLock();
      try {
        await expectLater(
          profile.acquire(target),
          throwsA(isA<MacProfileInUse>()),
        );
        expect(await data.readAsBytes(), [42]);
      } finally {
        await previous!.stdin.close();
        await previous.exitCode;
      }
      await profile.acquire(target);
      await profile.close();
    },
    skip: !Platform.isMacOS,
  );

  Future<void> write(Directory root, String relative, Object content) async {
    final file = File(p.join(root.path, relative));
    await file.parent.create(recursive: true);
    if (content is List<int>) {
      await file.writeAsBytes(content);
    } else {
      await file.writeAsString('$content');
    }
  }

  /// Relative path to content and modification time, independent of the
  /// code under test. Directories map to a fixed marker.
  Future<Map<String, String>> tree(
    Directory root, {
    Set<String> skip = const {},
  }) async {
    final result = <String, String>{};
    if (!await root.exists()) return result;
    await for (final entry in root.list(recursive: true, followLinks: false)) {
      final relative = p.relative(entry.path, from: root.path);
      if (skip.contains(relative)) continue;
      if (entry is Link) {
        result[relative] = 'link -> ${await entry.target()}';
      } else if (entry is Directory) {
        result[relative] = 'dir';
      } else if (entry is File) {
        final stat = await entry.stat();
        result[relative] =
            '${base64.encode(await entry.readAsBytes())} '
            '@${stat.modified.millisecondsSinceEpoch}';
      }
    }
    return result;
  }

  Future<Map<String, Object?>> marker() async =>
      jsonDecode(
            await File(
              p.join(target.path, MacLegacyDataImport.markerName),
            ).readAsString(),
          )
          as Map<String, Object?>;

  Future<List<String>> leftovers() async => [
    await for (final entry in support.list())
      if (p.basename(entry.path).startsWith('.com.wof.naiStudio.import-'))
        p.basename(entry.path),
  ];

  /// The shape of a 1.x profile: Hive boxes, a WAL database, models and an
  /// empty library folder.
  Future<void> writeProfile() async {
    await write(legacy, 'hive/settings.hive', 'synthetic settings');
    await write(legacy, 'hive/history.hive', 'synthetic history');
    // Left behind by a crash; not locked by anyone.
    await write(legacy, 'hive/settings.lock', '');
    await write(legacy, 'databases/danbooru.db', 'synthetic database');
    await write(legacy, 'databases/danbooru.db-wal', 'synthetic wal');
    await write(legacy, 'databases/danbooru.db-shm', 'synthetic shm');
    await write(legacy, 'online_favorites/online_favorites.db', 'favorites');
    // Over 1 MB, so the system hash is used.
    await write(
      legacy,
      'models/efficientvit_sam/l0/encoder.onnx',
      Uint8List.fromList(
        List.generate(3 * 1024 * 1024 + 7, (index) => (index * 7) & 255),
      ),
    );
    await Directory(p.join(legacy.path, 'model3d_library')).create();
    await write(legacy, '.DS_Store', 'finder');
    await File(
      p.join(legacy.path, 'hive/settings.hive'),
    ).setLastModified(DateTime.utc(2025, 5, 4, 3, 2, 1));
  }

  MacLegacyDataImport import({
    bool Function()? running,
    Future<int> Function()? preferences,
    Future<void> Function()? beforeCommit,
  }) => MacLegacyDataImport(
    legacy: legacy,
    destination: target,
    isLegacyRunning: (_) async => running?.call() ?? false,
    preferences: preferences,
    beforeCommit: beforeCommit,
  );

  test('copies the previous data once and leaves it untouched', () async {
    await writeProfile();
    final original = await tree(legacy);

    final result = await import().prepare();

    expect(result.state, MacLegacyDataState.imported);
    expect(await tree(legacy), original);
    expect(
      await tree(target, skip: {MacLegacyDataImport.markerName}),
      original,
    );
    expect(
      (await File(
        p.join(target.path, 'hive/settings.hive'),
      ).stat()).modified.toUtc(),
      DateTime.utc(2025, 5, 4, 3, 2, 1),
    );
    final written = await marker();
    expect(written['state'], 'imported');
    expect(written['layout'], MacLegacyDataImport.layout);
    expect(written['legacy'], legacy.absolute.path);
    expect(written['preferences'], 'none');
    expect(await leftovers(), isEmpty);

    // Later launches do not copy again, even when the old app keeps going.
    await write(legacy, 'hive/settings.hive', 'changed in the old app');
    await write(legacy, 'later.json', 'new in the old app');
    final copied = await tree(target);
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
    expect(await tree(target), copied);
  });

  test('data already in the new folder is never overwritten', () async {
    await writeProfile();
    await write(target, 'hive/settings.hive', 'new profile');
    final original = await tree(legacy);
    final existing = await tree(target);

    final result = await import().prepare();

    expect(result.state, MacLegacyDataState.existingData);
    expect(await tree(legacy), original);
    expect(
      await tree(target, skip: {MacLegacyDataImport.markerName}),
      existing,
    );
    expect((await marker())['state'], 'existingData');
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
  });

  test('without a previous folder the new folder starts empty', () async {
    final result = await import().prepare();

    expect(result.state, MacLegacyDataState.fresh);
    expect(await legacy.exists(), isFalse);
    expect(await tree(target), {MacLegacyDataImport.markerName: anything});
    expect((await marker())['state'], 'fresh');
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
  });

  test('a previous folder with only Finder files counts as empty', () async {
    await write(legacy, '.DS_Store', 'finder');
    await write(target, '.DS_Store', 'finder');

    expect((await import().prepare()).state, MacLegacyDataState.fresh);
  });

  test('a failure before switching folders leaves nothing behind', () async {
    await writeProfile();
    final original = await tree(legacy);

    final failed = await import(
      beforeCommit: () async =>
          throw const FileSystemException('synthetic copy failure'),
    ).prepare();

    expect(failed.state, MacLegacyDataState.failed);
    expect(failed.error, isA<FileSystemException>());
    expect(await tree(target), isEmpty);
    expect(await target.exists(), isTrue);
    expect(await leftovers(), isEmpty);
    expect(await tree(legacy), original);

    // Nothing was recorded, so the next attempt simply copies.
    expect((await import().prepare()).state, MacLegacyDataState.imported);
    expect(
      await tree(target, skip: {MacLegacyDataImport.markerName}),
      original,
    );
  });

  test('data the old app writes while copying is not half copied', () async {
    await writeProfile();

    final failed = await import(
      beforeCommit: () => write(legacy, 'hive/settings.hive', 'newer edit'),
    ).prepare();

    expect(failed.state, MacLegacyDataState.failed);
    expect(await tree(target), isEmpty);
    expect(await leftovers(), isEmpty);

    expect((await import().prepare()).state, MacLegacyDataState.imported);
    expect(
      await File(p.join(target.path, 'hive/settings.hive')).readAsString(),
      'newer edit',
    );
  });

  test(
    'an unreadable file stops the copy and leaves the new folder empty',
    () async {
      await writeProfile();
      final locked = File(p.join(legacy.path, 'databases/danbooru.db'));
      await Process.run('chmod', ['000', locked.path]);

      final failed = await import().prepare();

      expect(failed.state, MacLegacyDataState.failed);
      expect(await tree(target), isEmpty);
      expect(await leftovers(), isEmpty);
    },
    skip: Platform.isWindows,
  );

  test('a running previous version is left alone until it quits', () async {
    await writeProfile();
    final original = await tree(legacy);
    var running = true;

    final waiting = await import(running: () => running).prepare();

    expect(waiting.state, MacLegacyDataState.legacyRunning);
    expect(await tree(target), isEmpty);
    expect(await tree(legacy), original);

    running = false;
    expect(
      (await import(running: () => running).prepare()).state,
      MacLegacyDataState.imported,
    );
  });

  test(
    'changes during the copy count as running when the old app is open',
    () async {
      await writeProfile();
      var running = false;

      final result = await import(
        running: () => running,
        beforeCommit: () async {
          running = true;
          await write(legacy, 'hive/settings.hive', 'written by 1.x');
        },
      ).prepare();

      expect(result.state, MacLegacyDataState.legacyRunning);
      expect(await tree(target), isEmpty);
    },
  );

  test('skipping records the choice and copies nothing later', () async {
    await writeProfile();

    await import().skip();

    expect((await marker())['state'], 'skipped');
    expect(await tree(target), {MacLegacyDataImport.markerName: anything});
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
    expect(await tree(target), {MacLegacyDataImport.markerName: anything});
  });

  test('an interrupted attempt is cleaned up before the next one', () async {
    await writeProfile();
    await write(
      support,
      '.com.wof.naiStudio.import-stale/hive/settings.hive',
      'half copied',
    );

    expect((await import().prepare()).state, MacLegacyDataState.imported);
    expect(await leftovers(), isEmpty);
  });

  test(
    'a link named like a leftover is not followed when cleaning up',
    () async {
      final outside = Directory(p.join(fixture.path, 'outside'));
      await write(outside, 'keep.txt', 'not ours');
      await Link(
        p.join(support.path, '.com.wof.naiStudio.import-link'),
      ).create(outside.path);

      await import().prepare();

      expect(
        await File(p.join(outside.path, 'keep.txt')).readAsString(),
        'not ours',
      );
    },
    skip: Platform.isWindows,
  );

  test('preferences are copied once, after the folder', () async {
    await writeProfile();
    var calls = 0;
    Future<int> preferences() async {
      calls++;
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).exists(),
        isTrue,
      );
      return 3;
    }

    await import(preferences: preferences).prepare();
    await import(preferences: preferences).prepare();

    expect(calls, 1);
    final written = await marker();
    expect(written['preferences'], 'imported');
    expect(written['preferencesCopied'], 3);
  });

  test('preferences interrupted by a crash are copied next time', () async {
    await writeProfile();
    await import().prepare();
    final interrupted = {...await marker(), 'preferences': 'pending'};
    await File(
      p.join(target.path, MacLegacyDataImport.markerName),
    ).writeAsString(jsonEncode(interrupted));

    var calls = 0;
    final result = await import(
      preferences: () async {
        calls++;
        return 2;
      },
    ).prepare();

    expect(result.state, MacLegacyDataState.prepared);
    expect(calls, 1);
    expect((await marker())['preferences'], 'imported');
  });

  test('a failed preference copy is recorded and not repeated', () async {
    await writeProfile();
    var calls = 0;
    Future<int> preferences() async {
      calls++;
      throw StateError('synthetic preferences failure');
    }

    expect(
      (await import(preferences: preferences).prepare()).state,
      MacLegacyDataState.imported,
    );
    await import(preferences: preferences).prepare();

    expect(calls, 1);
    expect((await marker())['preferences'], 'failed');
  });

  test('overlapping folders are rejected before anything changes', () async {
    await writeProfile();
    final original = await tree(legacy);
    for (final destination in [
      legacy,
      Directory(p.join(legacy.path, 'nested')),
    ]) {
      await expectLater(
        MacLegacyDataImport(legacy: legacy, destination: destination).prepare(),
        throwsA(isA<FileSystemException>()),
      );
    }
    expect(await tree(legacy), original);
  });

  test(
    'links inside the profile stay links; links outside stop the copy',
    () async {
      await write(legacy, 'python/versioned/python.txt', 'python fixture');
      await Link(p.join(legacy.path, 'python/current')).create('versioned');
      // A Python environment links its interpreter file by absolute path.
      await write(legacy, 'rag/v1/python/cpython/bin/python3.12', 'binary');
      await Link(p.join(legacy.path, 'rag/v1/runtime/bin/python3')).create(
        p.join(legacy.path, 'rag/v1/python/cpython/bin/python3.12'),
        recursive: true,
      );

      expect((await import().prepare()).state, MacLegacyDataState.imported);
      for (final (link, file, content) in [
        ('python/current', 'python/current/python.txt', 'python fixture'),
        ('rag/v1/runtime/bin/python3', 'rag/v1/runtime/bin/python3', 'binary'),
      ]) {
        expect(
          p.isAbsolute(await Link(p.join(target.path, link)).target()),
          isFalse,
          reason: link,
        );
        expect(await File(p.join(target.path, file)).readAsString(), content);
      }

      // Links to private data elsewhere, to a folder or to a file.
      final outside = Directory(p.join(fixture.path, 'private'));
      await write(outside, 'secret.txt', 'external data');
      for (final external in [
        outside.path,
        p.join(outside.path, 'secret.txt'),
      ]) {
        await target.delete(recursive: true);
        await target.create();
        final link = Link(p.join(legacy.path, 'external'));
        if (await link.exists()) await link.delete();
        await link.create(external);

        final failed = await import().prepare();
        expect(failed.state, MacLegacyDataState.failed, reason: external);
        expect(await tree(target), isEmpty);
      }
    },
    skip: Platform.isWindows,
  );

  test('a new folder that links elsewhere is left alone', () async {
    await writeProfile();
    final elsewhere = Directory(p.join(fixture.path, 'external-drive'));
    await elsewhere.create();
    await target.delete();
    await Link(target.path).create(elsewhere.path);

    expect((await import().prepare()).state, MacLegacyDataState.existingData);
    expect(await elsewhere.list().isEmpty, isTrue);
  }, skip: Platform.isWindows);

  group('Hive lock probe', () {
    late Directory hive;
    setUp(() async {
      hive = Directory(p.join(legacy.path, 'hive'));
      await hive.create(recursive: true);
    });

    test('no Hive folder or only stale lock files means not running', () async {
      await legacy.delete(recursive: true);
      expect(await MacLegacyDataImport.hiveBoxesOpenElsewhere(legacy), isFalse);
      await write(legacy, 'hive/settings.lock', '');
      await write(legacy, 'hive/settings.hive', 'box');
      expect(await MacLegacyDataImport.hiveBoxesOpenElsewhere(legacy), isFalse);
    });

    test('a box lock held by another process means running', () async {
      final lock = File(p.join(hive.path, 'settings.lock'));
      await lock.create();
      final holder = await _holdLock(lock.path);
      if (holder == null) {
        markTestSkipped('python3 is not available to hold a lock');
        return;
      }
      try {
        expect(
          await MacLegacyDataImport.hiveBoxesOpenElsewhere(legacy),
          isTrue,
        );
      } finally {
        await holder.stdin.close();
        await holder.exitCode;
      }
      expect(await MacLegacyDataImport.hiveBoxesOpenElsewhere(legacy), isFalse);
      // The probe only reads.
      expect(await lock.length(), 0);
    }, skip: Platform.isWindows);
  });

  group('runMacLegacyDataImport', () {
    test('normal launches show nothing', () async {
      final presenter = RecordingPresenter();
      expect(
        await runMacLegacyDataImport(import(), presenter: presenter),
        MacLegacyDataState.fresh,
      );
      expect(
        await runMacLegacyDataImport(import(), presenter: presenter),
        MacLegacyDataState.prepared,
      );
      expect(presenter.calls, isEmpty);
    });

    test('a copy shows progress, then hands over to the app', () async {
      await writeProfile();
      final presenter = RecordingPresenter();

      final state = await runMacLegacyDataImport(
        import(),
        presenter: presenter,
      );

      expect(state, MacLegacyDataState.imported);
      expect(presenter.calls, ['copying', 'starting']);
    });

    test('waits for the old app to quit, then copies by itself', () async {
      await writeProfile();
      var checks = 0;
      final presenter = RecordingPresenter();

      final state = await runMacLegacyDataImport(
        import(running: () => ++checks < 4),
        presenter: presenter,
        pollInterval: Duration.zero,
        settleDelay: Duration.zero,
      );

      expect(state, MacLegacyDataState.imported);
      expect(presenter.calls, ['running', 'copying', 'starting']);
      expect(
        await File(p.join(target.path, 'hive/settings.hive')).exists(),
        isTrue,
      );
    });

    test('a probe error while waiting does not stop startup', () async {
      await writeProfile();
      var checks = 0;
      final presenter = RecordingPresenter();

      final state = await runMacLegacyDataImport(
        import(
          running: () => switch (++checks) {
            1 => true,
            2 => throw const FileSystemException('synthetic probe failure'),
            _ => false,
          },
        ),
        presenter: presenter,
        pollInterval: Duration.zero,
        settleDelay: Duration.zero,
      );

      expect(state, MacLegacyDataState.imported);
      expect(presenter.calls, ['running', 'copying', 'starting']);
    });

    test('starting without copying while the old app is open', () async {
      await writeProfile();
      final presenter = RecordingPresenter(skipWhenRunning: true);

      final state = await runMacLegacyDataImport(
        import(running: () => true),
        presenter: presenter,
        pollInterval: const Duration(milliseconds: 5),
      );

      expect(state, MacLegacyDataState.skipped);
      expect(presenter.calls, ['running', 'starting']);
      expect((await marker())['state'], 'skipped');
    });

    test('a failed copy can be retried', () async {
      await writeProfile();
      var attempts = 0;
      final presenter = RecordingPresenter(retry: true);

      final state = await runMacLegacyDataImport(
        import(
          beforeCommit: () async {
            if (attempts++ == 0) {
              throw const FileSystemException('synthetic copy failure');
            }
          },
        ),
        presenter: presenter,
      );

      expect(state, MacLegacyDataState.imported);
      expect(presenter.calls, ['copying', 'failed', 'copying', 'starting']);
    });

    test('a failed copy can be skipped', () async {
      await writeProfile();
      final presenter = RecordingPresenter(retry: false);

      final state = await runMacLegacyDataImport(
        import(
          beforeCommit: () async =>
              throw const FileSystemException('synthetic copy failure'),
        ),
        presenter: presenter,
      );

      expect(state, MacLegacyDataState.skipped);
      expect((await marker())['state'], 'skipped');
      expect(await tree(target), {MacLegacyDataImport.markerName: anything});
    });

    test('without a window, startup stops instead of guessing', () async {
      await writeProfile();
      await expectLater(
        runMacLegacyDataImport(import(running: () => true)),
        throwsA(isA<FileSystemException>()),
      );
      await expectLater(
        runMacLegacyDataImport(
          import(
            beforeCommit: () async =>
                throw const FileSystemException('synthetic copy failure'),
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await tree(target), isEmpty);
    });
  });
}

/// Holds an exclusive fcntl lock from another process, as Hive does in the
/// previous version. Returns null where no Python is available; on macOS the
/// developer tools are checked first so no install prompt appears.
Future<Process?> _holdLock(String path) async {
  try {
    if (Platform.isMacOS &&
        (await Process.run('xcode-select', ['-p'])).exitCode != 0) {
      return null;
    }
    final process = await Process.start('python3', [
      '-c',
      'import fcntl, sys\n'
          'f = open(sys.argv[1], "a")\n'
          'fcntl.lockf(f, fcntl.LOCK_EX | fcntl.LOCK_NB)\n'
          'print("locked", flush=True)\n'
          'sys.stdin.read()\n',
      path,
    ]);
    final line = await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 20));
    if (line == 'locked') return process;
    process.kill();
    return null;
  } on Object {
    return null;
  }
}
