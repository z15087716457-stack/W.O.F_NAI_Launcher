import 'dart:convert';
import 'dart:io';

import 'package:nai_launcher/core/database/dictionary_data_store.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_import.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_sync.dart';
import 'package:nai_launcher/core/utils/app_support_directory.dart';
import 'package:path/path.dart' as p;

import 'mac_legacy_data_test_support.dart';

void main() {
  late Directory fixture;
  late Directory support;
  late Directory legacy;
  late Directory target;
  late DateTime now;

  setUp(() async {
    // A synthetic ~/Library/Application Support. Never the real folders.
    fixture = await Directory.systemTemp.createTemp('mac-legacy-sync-test-');
    support = Directory(p.join(fixture.path, 'Application Support'));
    legacy = Directory(p.join(support.path, 'com.aaalice.naiLauncher'));
    target = Directory(p.join(support.path, 'com.wof.naiStudio'));
    now = DateTime(2026, 10, 29, 14);
    await writeData(legacy, 'hive/settings.hive', '1.1.1 latest settings');
    await writeData(legacy, 'hive/history.hive', '1.1.1 history');
    await writeData(legacy, 'databases/danbooru.db', '1.1.1 gallery');
    // This version, after the first-launch copy and some use.
    await writeData(
      target,
      MacLegacyDataImport.markerName,
      jsonEncode({'state': 'imported', 'at': '2026-10-23T06:05:00.000Z'}),
    );
    await writeData(target, 'hive/settings.hive', '2.0 settings');
    await writeData(target, 'hive/prompt_blocks.hive', '2.0 blocks');
    await writeData(target, 'agent-data/session.json', 'agent session');
    await writeData(target, 'settings_backups/v2/a.json', 'preference backup');
    await writeData(target, 'draft-backups/draft.json', 'draft');
  });
  tearDown(() => fixture.delete(recursive: true));

  MacLegacyDataImport import({
    bool Function()? running,
    Future<void> Function()? beforeCommit,
    Future<void> Function(String step)? onStep,
    Future<int> Function()? preferences,
  }) => MacLegacyDataImport(
    legacy: legacy,
    destination: target,
    isLegacyRunning: (_) async => running?.call() ?? false,
    beforeCommit: beforeCommit,
    preferences: preferences,
    dataSwitch: MacLegacyDataSwitch(
      target,
      clock: () => now = now.add(const Duration(minutes: 1)),
      onStep: onStep,
    ),
  );

  Future<String> read(Directory root, String relative) =>
      File(p.join(root.path, relative)).readAsString();

  Future<bool> exists(Directory root, String relative) async =>
      await FileSystemEntity.type(
        p.join(root.path, relative),
        followLinks: false,
      ) !=
      FileSystemEntityType.notFound;

  Future<Map<String, Object?>> marker() async =>
      jsonDecode(await read(target, MacLegacyDataImport.markerName))
          as Map<String, Object?>;

  Future<List<String>> leftovers() async => [
    await for (final entry in support.list())
      if (p.basename(entry.path).startsWith('.com.wof.naiStudio.import-') ||
          p.basename(entry.path).endsWith('.sync-journal.json'))
        p.basename(entry.path),
  ];

  Future<MacLegacyDataImportResult> sync() async {
    await import().request(const MacLegacyDataRequest.sync());
    return import().prepare();
  }

  /// Undo or redo to the newest backup, as Settings offers it.
  Future<MacLegacyDataImportResult> switchBack(
    MacLegacyDataRequest Function(String backup) request,
  ) async {
    final newest = (await import().dataSwitch.backups()).first;
    await import().request(request(newest.id));
    return import().prepare();
  }

  Future<List<MacLegacyDataTask>> backupTasks() async => [
    for (final backup in await import().dataSwitch.backups()) backup.task,
  ];

  test('a sync replaces the data, keeps a backup and moves this version\'s '
      'own folders over', () async {
    final original = await treeOf(legacy);

    final result = await sync();

    expect(result.state, MacLegacyDataState.synced);
    expect(result.task, MacLegacyDataTask.sync);
    expect(await read(target, 'hive/settings.hive'), '1.1.1 latest settings');
    expect(await read(target, 'databases/danbooru.db'), '1.1.1 gallery');
    // Folders only this version has came along unchanged.
    expect(await read(target, 'agent-data/session.json'), 'agent session');
    expect(
      await read(target, 'settings_backups/v2/a.json'),
      'preference backup',
    );
    expect(await read(target, 'draft-backups/draft.json'), 'draft');
    expect(await read(target, 'hive/prompt_blocks.hive'), '2.0 blocks');
    expect((await marker())['state'], 'synced');

    final backups = await import().dataSwitch.backups();
    expect(backups, hasLength(1));
    expect(backups.single.task, MacLegacyDataTask.sync);
    final backup = backups.single.directory;
    expect(await read(backup, 'hive/settings.hive'), '2.0 settings');
    expect(await read(backup, 'hive/prompt_blocks.hive'), '2.0 blocks');
    expect(await exists(backup, 'agent-data'), isFalse);

    expect(await treeOf(legacy), original);
    expect(await import().dataSwitch.pending(), isFalse);
    expect(await leftovers(), isEmpty);
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
  });

  test(
    'the newest sync can still be undone after the clock goes backwards',
    () async {
      for (final version in ['v1', 'v2', 'v3']) {
        if (version == 'v3') now = now.subtract(const Duration(days: 2));
        await writeData(target, 'hive/settings.hive', version);
        expect((await sync()).state, MacLegacyDataState.synced);
      }
      final backups = await import().dataSwitch.backups();
      expect(await read(backups.first.directory, 'hive/settings.hive'), 'v3');
      expect(
        (await switchBack(MacLegacyDataRequest.undo)).state,
        MacLegacyDataState.undone,
      );
      expect(await read(target, 'hive/settings.hive'), 'v3');
    },
  );

  test('only the newest two backups are kept', () async {
    for (final version in ['v1', 'v2', 'v3']) {
      await writeData(target, 'hive/settings.hive', version);
      expect((await sync()).state, MacLegacyDataState.synced);
    }

    final backups = await import().dataSwitch.backups();
    expect(backups, hasLength(MacLegacyDataSwitch.keep));
    expect(
      [
        for (final backup in backups)
          await read(backup.directory, 'hive/settings.hive'),
      ],
      ['v3', 'v2'],
    );
    expect(
      await import().dataSwitch.backupRoot.list().length,
      MacLegacyDataSwitch.keep,
    );
  });

  test(
    'database families stay together at every profile path, including the root',
    () async {
      final old = await treeOf(legacy);
      for (final suffix in [
        '.lock',
        '.crc',
        '.hive.lock',
        '.hive.crc',
        '.hivec',
      ]) {
        await writeData(
          target,
          'hive/settings$suffix',
          'wrong settings companion',
        );
        await writeData(
          target,
          'hive/prompt_blocks$suffix',
          'own companion $suffix',
        );
      }
      await writeData(legacy, 'root.sqlite', 'old root');
      await writeData(target, 'root.sqlite', 'new root');
      await writeData(legacy, 'root.sqlite-wal', 'old committed WAL');
      await writeData(target, 'root.sqlite-shm', 'wrong SHM');
      await writeData(target, 'root.sqlite-journal', 'wrong journal');
      for (final dir in [
        'databases',
        'autocomplete',
        'tag_semantics',
        'online_favorites',
        'rag/pool-v2/fingerprint',
      ]) {
        await writeData(legacy, '$dir/common.db', 'old $dir');
        await writeData(target, '$dir/common.db', 'new $dir');
        await writeData(target, '$dir/common.db-wal', 'wrong WAL');
        await writeData(target, '$dir/deeper/new.sqlite3', 'own $dir');
        await writeData(target, '$dir/deeper/new.sqlite3-wal', 'own WAL');
        await writeData(target, '$dir/deeper/new.sqlite3-shm', 'own SHM');
        await writeData(
          target,
          '$dir/deeper/new.sqlite3-journal',
          'own journal',
        );
        await writeData(target, '$dir/deeper/local-note.json', 'not a library');
      }
      final source = await treeOf(legacy);
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await read(target, 'root.sqlite-wal'), 'old committed WAL');
      expect(await exists(target, 'root.sqlite-shm'), false);
      expect(await exists(target, 'root.sqlite-journal'), false);
      for (final suffix in [
        '.lock',
        '.crc',
        '.hive.lock',
        '.hive.crc',
        '.hivec',
      ]) {
        expect(await exists(target, 'hive/settings$suffix'), false);
        expect(
          await read(target, 'hive/prompt_blocks$suffix'),
          'own companion $suffix',
        );
      }
      for (final dir in [
        'databases',
        'autocomplete',
        'tag_semantics',
        'online_favorites',
        'rag/pool-v2/fingerprint',
      ]) {
        expect(await read(target, '$dir/common.db'), 'old $dir');
        expect(await exists(target, '$dir/common.db-wal'), false);
        expect(await read(target, '$dir/deeper/new.sqlite3'), 'own $dir');
        for (final suffix in ['-wal', '-shm', '-journal']) {
          expect(await exists(target, '$dir/deeper/new.sqlite3$suffix'), true);
        }
        expect(await exists(target, '$dir/deeper/local-note.json'), false);
      }
      expect(await treeOf(legacy), source);
      expect(source.keys, containsAll(old.keys));
    },
  );

  test(
    'real Hive and SQLite survive sync, undo and redo as independent snapshots',
    () async {
      final hi = await Hive.openBox<String>(
        'new_library',
        path: p.join(target.path, 'hive'),
      );
      await hi.put('sample', 'before sync');
      await hi.close();
      Future<void> sqlite(Directory root, String name, String value) async {
        final path = p.join(root.path, 'online_favorites', name);
        await File(path).parent.create(recursive: true);
        final db = sqlite3.open(path);
        try {
          db.execute(
            'CREATE TABLE IF NOT EXISTS samples (name TEXT PRIMARY KEY)',
          );
          db.execute('INSERT INTO samples VALUES (?)', [value]);
        } finally {
          db.dispose();
        }
      }

      Future<List<String>> rows(Directory root, String name) async {
        final db = sqlite3.open(
          p.join(root.path, 'online_favorites', name),
          mode: OpenMode.readOnly,
        );
        try {
          return [
            for (final v in db.select('SELECT name FROM samples ORDER BY name'))
              v['name'] as String,
          ];
        } finally {
          db.dispose();
        }
      }

      await sqlite(legacy, 'common.db', 'previous');
      await sqlite(target, 'common.db', 'current');
      await sqlite(target, 'own.db', 'before sync');
      expect((await sync()).state, MacLegacyDataState.synced);
      final box = await Hive.openBox<String>(
        'new_library',
        path: p.join(target.path, 'hive'),
      );
      expect(box.get('sample'), 'before sync');
      await box.put('sample', 'after sync');
      await box.close();
      expect(await rows(target, 'common.db'), ['previous']);
      expect(await rows(target, 'own.db'), ['before sync']);
      await sqlite(target, 'own.db', 'after sync');
      expect(
        (await switchBack(MacLegacyDataRequest.undo)).state,
        MacLegacyDataState.undone,
      );
      expect(await rows(target, 'common.db'), ['current']);
      expect(await rows(target, 'own.db'), ['before sync']);
      final before = await Hive.openBox<String>(
        'new_library',
        path: p.join(target.path, 'hive'),
      );
      expect(before.get('sample'), 'before sync');
      await before.close();
      expect(
        (await switchBack(MacLegacyDataRequest.redo)).state,
        MacLegacyDataState.redone,
      );
      expect(await rows(target, 'own.db'), ['after sync', 'before sync']);
    },
  );

  test(
    'one-sided mixed folders carry their non-database files while databases switch snapshots',
    () async {
      await writeData(target, 'my-plugin/nested/only.db', 'before');
      await writeData(target, 'my-plugin/nested/notes.json', 'notes');
      await writeData(legacy, 'previous-only/old.sqlite', 'old');
      expect((await sync()).state, MacLegacyDataState.synced);
      final backup = (await import().dataSwitch.backups()).first.directory;
      expect(await read(backup, 'my-plugin/nested/only.db'), 'before');
      await writeData(target, 'my-plugin/nested/only.db', 'after');
      await writeData(target, 'my-plugin/nested/notes.json', 'latest notes');
      expect(
        (await switchBack(MacLegacyDataRequest.undo)).state,
        MacLegacyDataState.undone,
      );
      expect(await read(target, 'my-plugin/nested/only.db'), 'before');
      expect(await read(target, 'my-plugin/nested/notes.json'), 'latest notes');
      expect(await exists(target, 'previous-only/old.sqlite'), false);
      expect(
        (await switchBack(MacLegacyDataRequest.redo)).state,
        MacLegacyDataState.redone,
      );
      expect(await read(target, 'my-plugin/nested/only.db'), 'after');
      expect(await read(target, 'my-plugin/nested/notes.json'), 'latest notes');
      expect(await read(target, 'previous-only/old.sqlite'), 'old');
    },
  );

  test(
    'a new SQLite retains committed WAL rows when the old app only has orphan journals',
    () async {
      final writer = await Directory(p.join(fixture.path, 'writer')).create();
      final original = p.join(writer.path, 'sample.sqlite');
      final db = sqlite3.open(original);
      const library = 'autocomplete/sample.sqlite';
      try {
        db.execute('PRAGMA journal_mode=WAL');
        db.execute('PRAGMA wal_autocheckpoint=0');
        db.execute('CREATE TABLE sample(name TEXT)');
        db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
        db.execute("INSERT INTO sample VALUES ('committed in WAL')");
        for (final suffix in ['', '-wal', '-shm']) {
          await writeData(
            target,
            library + suffix,
            await File(original + suffix).readAsBytes(),
          );
        }
      } finally {
        db.dispose();
      }
      await writeData(
        legacy,
        '$library-journal',
        'orphan from previous version',
      );
      await writeData(legacy, '$library-wal', 'invalid orphan');
      await writeData(
        legacy,
        'hive/compacted.hivec',
        'old recoverable compaction',
      );
      await writeData(
        target,
        'hive/compacted.hive',
        'new box must not be mixed',
      );
      final previous = await treeOf(legacy);
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await exists(target, '$library-journal'), false);
      expect(await exists(target, 'hive/compacted.hive'), false);
      expect(
        await read(target, 'hive/compacted.hivec'),
        'old recoverable compaction',
      );
      final restored = sqlite3.open(p.join(target.path, library));
      try {
        expect(
          restored.select('SELECT name FROM sample').single['name'],
          'committed in WAL',
        );
      } finally {
        restored.dispose();
      }
      expect(await treeOf(legacy), previous);
    },
  );

  test(
    'only the real vector pool takes its matching checkpoint and dictionary revisions stay usable',
    () async {
      const dir = 'rag/v1/indices/pool-v2/fixture-model';
      await writeData(target, '$dir/pool.sqlite', 'local pool');
      await writeData(target, '$dir/ann.json', 'matching ANN');
      await writeData(target, '$dir/vectors.usearch', 'matching vectors');
      await writeData(legacy, '$dir/ann.json', 'orphan checkpoint');
      await writeData(legacy, 'other/keep.txt', 'old');
      for (final name in ['pool.sqlite', 'ann.json', 'vectors.usearch']) {
        await writeData(target, 'other/$name', 'local $name');
      }
      Future<String> dictionary(
        Directory root,
        String kind,
        String content,
        int revision,
      ) async {
        final staged = File(p.join(fixture.path, 'source-$revision.sqlite'));
        final db = sqlite3.open(staged.path);
        try {
          if (kind == 'tags') {
            db.execute(
              'CREATE TABLE tags(id INTEGER, name TEXT, category INTEGER, post_count INTEGER)',
            );
            db.execute('CREATE TABLE aliases(tag_id INTEGER, alias TEXT)');
            db.execute(
              'CREATE TABLE tag_search(term, search_key, tag_id, kind)',
            );
            db.execute('INSERT INTO tags VALUES (1,?,0,1)', [content]);
          } else {
            db.execute('CREATE TABLE wiki_pages(tag, body, source_url)');
            db.execute('INSERT INTO wiki_pages VALUES (?, ?, ?)', [
              content,
              'body',
              'fixture',
            ]);
          }
        } finally {
          db.dispose();
        }
        final store = DictionaryDataStore(
          Directory(p.join(root.path, 'dictionary_updates')),
        );
        final type = DictionaryKind.values.byName(kind);
        await store.publish(type, staged, {'count': 1}, expectedPath: null);
        return p.basenameWithoutExtension(store.activePath(type)!);
      }

      await writeData(
        legacy,
        'dictionary_updates/commit-tags-999999999999999999.json',
        jsonEncode({
          'kind': 'tags',
          'sha256': 'f' * 64,
          'bytes': 13,
          'count': 1,
        }),
      );
      final oldWiki = await dictionary(legacy, 'wiki', 'old wiki', 1);
      final localWiki = await dictionary(target, 'wiki', 'new wiki', 2);
      final localTags = await dictionary(target, 'tags', 'new tags', 3);
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await read(target, '$dir/ann.json'), 'matching ANN');
      expect(await read(target, '$dir/vectors.usearch'), 'matching vectors');
      expect(await exists(target, 'other/ann.json'), false);
      expect(await exists(target, 'other/vectors.usearch'), false);
      final store = DictionaryDataStore(
        Directory(p.join(target.path, 'dictionary_updates')),
      );
      expect(
        p.basename(await store.resolve(DictionaryKind.wiki, 'missing')),
        '$oldWiki.db',
      );
      expect(await exists(target, 'dictionary_updates/$localWiki.db'), false);
      expect(
        p.basename(await store.resolve(DictionaryKind.tags, 'missing')),
        '$localTags.db',
      );
      await writeData(legacy, '$dir/pool.sqlite', 'old pool');
      await writeData(legacy, '$dir/ann.json', 'old checkpoint');
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await read(target, '$dir/ann.json'), 'old checkpoint');
      expect(await exists(target, '$dir/vectors.usearch'), false);
    },
  );

  test(
    'a changed local family, a new box, or a symlink blocks publication without losing either tree',
    () async {
      await writeData(target, 'autocomplete/new.db', 'local');
      await writeData(legacy, 'autocomplete/old.db', 'previous');
      final old = await treeOf(legacy);
      await import().request(const MacLegacyDataRequest.sync());
      expect(
        (await import(
          beforeCommit: () =>
              writeData(target, 'autocomplete/new.db-wal', 'racing commit'),
        ).prepare()).state,
        MacLegacyDataState.failed,
      );
      expect(await read(target, 'autocomplete/new.db-wal'), 'racing commit');
      expect(
        (await import(
          beforeCommit: () =>
              writeData(target, 'hive/appeared.hive', 'newly created'),
        ).prepare()).state,
        MacLegacyDataState.failed,
      );
      final external = File(p.join(fixture.path, 'unrelated.db'));
      await external.writeAsString('outside');
      final link = Link(p.join(target.path, 'autocomplete', 'external.db'));
      await link.create(external.path);
      final before = await treeOf(target);
      expect((await import().prepare()).state, MacLegacyDataState.failed);
      expect(await treeOf(target), before);
      expect(await treeOf(legacy), old);
      expect(await external.readAsString(), 'outside');
      expect(await import().dataSwitch.backups(), isEmpty);
    },
    skip: Platform.isWindows,
  );

  test(
    'safe internal database aliases stay relative, and an external or conflicting target is never overwritten',
    () async {
      await writeData(target, 'databases/origin.db', 'same bytes');
      await Link(
        p.join(target.path, 'databases', 'alias.db'),
      ).create('origin.db');
      await writeData(legacy, 'databases/previous.db', 'previous');
      await Link(
        p.join(legacy.path, 'databases', 'old-alias.db'),
      ).create('previous.db');
      await writeData(
        target,
        'databases/old-alias.db',
        'local must not replace previous alias',
      );
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(
        await Link(p.join(target.path, 'databases', 'alias.db')).target(),
        'origin.db',
      );
      expect(await read(target, 'databases/alias.db'), 'same bytes');
      expect(
        await Link(p.join(target.path, 'databases', 'old-alias.db')).target(),
        'previous.db',
      );
      await writeData(legacy, 'databases/origin.db', 'different bytes');
      final before = await treeOf(target);
      expect((await sync()).state, MacLegacyDataState.failed);
      expect(await treeOf(target), before);
    },
    skip: Platform.isWindows,
  );

  test(
    'a nested carry failure restores the original mixed folder and the requested undo can retry',
    () async {
      await writeData(target, 'exclusive/a/kept.db', 'before');
      await writeData(target, 'exclusive/a/user.txt', 'notes');
      await writeData(legacy, 'other/old.db', 'old');
      expect((await sync()).state, MacLegacyDataState.synced);
      await writeData(target, 'exclusive/a/kept.db', 'after');
      await writeData(target, 'exclusive/a/user.txt', 'changed notes');
      final backup = (await import().dataSwitch.backups()).single;
      final live = await treeOf(target), saved = await treeOf(backup.directory);
      await import().request(MacLegacyDataRequest.undo(backup.id));
      final failed = await import(
        onStep: (step) async {
          if (step == 'publish') throw const FileSystemException('fixture');
        },
      ).prepare();
      expect(failed.state, MacLegacyDataState.failed);
      expect(await treeOf(target), live);
      expect(await treeOf(backup.directory), saved);
      expect((await import().prepare()).state, MacLegacyDataState.undone);
      expect(await read(target, 'exclusive/a/kept.db'), 'before');
      expect(await read(target, 'exclusive/a/user.txt'), 'changed notes');
    },
  );

  test(
    'a later sync respects a folder that the previous version has since acquired',
    () async {
      await writeData(target, 'mixed/own.db', 'local database');
      await writeData(target, 'mixed/my-note.txt', 'local note');
      expect((await sync()).state, MacLegacyDataState.synced);
      await writeData(
        legacy,
        'mixed/previous-note.txt',
        'new from previous app',
      );
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await exists(target, 'mixed/my-note.txt'), false);
      expect(
        (await switchBack(MacLegacyDataRequest.undo)).state,
        MacLegacyDataState.undone,
      );
      expect(await read(target, 'mixed/my-note.txt'), 'local note');
      expect(await exists(target, 'mixed/previous-note.txt'), false);
      expect(
        (await switchBack(MacLegacyDataRequest.redo)).state,
        MacLegacyDataState.redone,
      );
      expect(await exists(target, 'mixed/my-note.txt'), false);
      expect(
        await read(target, 'mixed/previous-note.txt'),
        'new from previous app',
      );
    },
  );

  test(
    'a linked backup root cannot redirect a normal sync or prune outside the profile',
    () async {
      final external = await Directory(
        p.join(fixture.path, 'unrelated-backups'),
      ).create();
      for (final stamp in ['01', '02', '03']) {
        await writeData(
          external,
          '20261101-0000$stamp-000-before-sync/keep.txt',
          'untouched',
        );
      }
      final before = await treeOf(target), outside = await treeOf(external);
      await Link(import().dataSwitch.backupRoot.path).create(external.path);
      await expectLater(
        import().dataSwitch.prune(),
        throwsA(isA<FileSystemException>()),
      );
      expect((await sync()).state, MacLegacyDataState.failed);
      expect(await treeOf(target), before);
      expect(await treeOf(external), outside);
    },
    skip: Platform.isWindows,
  );

  test(
    'a library in a link-only folder keeps its opaque internal payload and physical SQLite companions',
    () async {
      await writeData(target, 'objects/opaque', 'primary');
      await writeData(target, 'objects/opaque-wal', 'committed WAL');
      final alias = Link(p.join(target.path, 'only-alias', 'library.db'));
      await alias.parent.create();
      await alias.create('../objects/opaque');
      await writeData(legacy, 'objects/other.txt', 'previous');
      expect((await sync()).state, MacLegacyDataState.synced);
      expect(await Link(alias.path).target(), '../objects/opaque');
      expect(await read(target, 'only-alias/library.db'), 'primary');
      expect(await read(target, 'objects/opaque-wal'), 'committed WAL');
      await writeData(target, 'objects/opaque', 'after');
      expect(
        (await switchBack(MacLegacyDataRequest.undo)).state,
        MacLegacyDataState.undone,
      );
      expect(await read(target, 'only-alias/library.db'), 'primary');
      expect(
        (await switchBack(MacLegacyDataRequest.redo)).state,
        MacLegacyDataState.redone,
      );
      expect(await read(target, 'only-alias/library.db'), 'after');
    },
    skip: Platform.isWindows,
  );

  test(
    'restart after publish consumes the existing sync or undo request exactly once',
    () async {
      await import().request(const MacLegacyDataRequest.sync());
      Future<MacLegacyDataImportResult> interrupted() => import(
        onStep: (step) async {
          if (step == 'committed') {
            throw const FileSystemException(
              'simulated exit before consuming request',
            );
          }
        },
      ).prepare();
      expect((await interrupted()).state, MacLegacyDataState.failed);
      expect(await import().dataSwitch.pending(), true);
      expect((await import().prepare()).state, MacLegacyDataState.prepared);
      final saved = (await import().dataSwitch.backups()).single;
      expect(await read(saved.directory, 'hive/settings.hive'), '2.0 settings');
      await import().request(MacLegacyDataRequest.undo(saved.id));
      expect((await interrupted()).state, MacLegacyDataState.failed);
      expect((await import().prepare()).state, MacLegacyDataState.prepared);
      expect(await import().dataSwitch.pending(), false);
      expect(await read(target, 'hive/settings.hive'), '2.0 settings');
      expect(
        (await import().dataSwitch.backups()).single.task,
        MacLegacyDataTask.undo,
      );
      final redo = (await import().dataSwitch.backups()).single;
      await import().request(MacLegacyDataRequest.redo(redo.id));
      expect((await interrupted()).state, MacLegacyDataState.failed);
      // Also cover a crash after unlinking the request but before deleting
      // the commit journal. The committed snapshot is still recognizable.
      await import().dataSwitch.clearRequest();
      expect(await import().dataSwitch.pending(), true);
      expect((await import().prepare()).state, MacLegacyDataState.prepared);
      expect(await read(target, 'hive/settings.hive'), '1.1.1 latest settings');
      expect(
        (await import().dataSwitch.backups()).single.task,
        MacLegacyDataTask.redo,
      );
      expect(await import().dataSwitch.pending(), false);
    },
  );

  test(
    'a journaled nested move never follows a replacement symlink to an external destination',
    () async {
      final external = await Directory(
        p.join(fixture.path, 'external-dir'),
      ).create();
      await writeData(external, 'keep.txt', 'untouched');
      final staging = await Directory(
        p.join(support.path, '.com.wof.naiStudio.import-fixture'),
      ).create();
      await Link(p.join(staging.path, 'shared')).create(external.path);
      await writeData(target, 'shared/owned.json', 'keep inside the backup');
      final before = await treeOf(target);
      final backup = Directory(
        p.join(
          import().dataSwitch.backupRoot.path,
          '20261029-140000-000-before-sync',
        ),
      );
      await backup.parent.create();
      await target.rename(backup.path);
      await target.create();
      final journal = File(
        p.join(support.path, '.com.wof.naiStudio.sync-journal.json'),
      );
      await journal.writeAsString(
        jsonEncode({
          'task': 'sync',
          'incoming': staging.path,
          'incomingIsBackup': false,
          'backup': backup.path,
          'carry': ['shared/owned.json'],
          'createDirectories': [],
        }),
      );
      await expectLater(
        import().prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(await treeOf(backup), before);
      expect(await read(external, 'keep.txt'), 'untouched');
      expect(await exists(external, 'owned.json'), false);
      expect(await journal.exists(), true);
    },
    skip: Platform.isWindows,
  );

  test(
    'an invalid journal cannot touch another folder or an unsafe nested carry target',
    () async {
      final unrelated = await Directory(
        p.join(fixture.path, 'unrelated'),
      ).create();
      await writeData(unrelated, 'untouched.txt', 'keep');
      final journal = File(
        p.join(support.path, '.com.wof.naiStudio.sync-journal.json'),
      );
      await journal.writeAsString(
        jsonEncode({
          'task': 'sync',
          'incoming': unrelated.path,
          'incomingIsBackup': false,
          'backup': p.join(
            support.path,
            'com.wof.naiStudio.backups',
            '20261029-140000-000-before-sync',
          ),
          'carry': ['../escape'],
        }),
      );
      final before = await treeOf(target);
      await expectLater(
        import().prepare(),
        throwsA(isA<FileSystemException>()),
      );
      expect(await read(unrelated, 'untouched.txt'), 'keep');
      expect(await treeOf(target), before);
      expect(await journal.exists(), true);
    },
  );

  test('undo switches back and keeps the synced data as a backup', () async {
    await sync();
    await writeData(target, 'hive/settings.hive', 'edited after the sync');
    await writeData(target, 'agent-data/session.json', 'newer agent session');
    final syncBackup = (await import().dataSwitch.backups()).single;

    await import().request(MacLegacyDataRequest.undo(syncBackup.id));
    final result = await import().prepare();

    expect(result.state, MacLegacyDataState.undone);
    expect(await read(target, 'hive/settings.hive'), '2.0 settings');
    expect(await read(target, 'hive/prompt_blocks.hive'), '2.0 blocks');
    // This version's own folders keep their newest state.
    expect(
      await read(target, 'agent-data/session.json'),
      'newer agent session',
    );
    expect((await marker())['state'], 'imported');

    final backups = await import().dataSwitch.backups();
    expect(backups.single.task, MacLegacyDataTask.undo);
    expect(
      await read(backups.single.directory, 'hive/settings.hive'),
      'edited after the sync',
    );
    expect(await syncBackup.directory.exists(), isFalse);
    expect(await import().dataSwitch.pending(), isFalse);
  });

  test(
    'undo and switching back swap the two sides and keep later changes',
    () async {
      final original = await treeOf(legacy);
      Future<void> expectBackups(List<MacLegacyDataTask> tasks) async {
        expect(await backupTasks(), tasks);
        expect(
          await import().dataSwitch.backupRoot.list().length,
          lessThanOrEqualTo(MacLegacyDataSwitch.keep),
        );
      }

      // Sync, then keep working in this version.
      expect((await sync()).state, MacLegacyDataState.synced);
      await writeData(target, 'hive/settings.hive', 'changed after the sync');
      await writeData(target, 'hive/history.hive', 'history after the sync');
      await writeData(target, 'agent-data/session.json', 'agent session 2');
      await expectBackups([MacLegacyDataTask.sync]);

      // Undo: the data from before the sync.
      var result = await switchBack(MacLegacyDataRequest.undo);
      expect(result.state, MacLegacyDataState.undone);
      expect(result.task, MacLegacyDataTask.undo);
      expect(await read(target, 'hive/settings.hive'), '2.0 settings');
      expect(await read(target, 'hive/prompt_blocks.hive'), '2.0 blocks');
      expect(await exists(target, 'hive/history.hive'), isFalse);
      expect((await marker())['state'], 'imported');
      await expectBackups([MacLegacyDataTask.undo]);
      await writeData(target, 'hive/settings.hive', 'changed after the undo');

      // Switch back: the synced data, with what changed after the sync.
      result = await switchBack(MacLegacyDataRequest.redo);
      expect(result.state, MacLegacyDataState.redone);
      expect(result.task, MacLegacyDataTask.redo);
      expect(
        await read(target, 'hive/settings.hive'),
        'changed after the sync',
      );
      expect(await read(target, 'hive/history.hive'), 'history after the sync');
      expect(await read(target, 'databases/danbooru.db'), '1.1.1 gallery');
      expect(await read(target, 'hive/prompt_blocks.hive'), '2.0 blocks');
      expect((await marker())['state'], 'synced');
      await expectBackups([MacLegacyDataTask.redo]);

      // Undo again: the data from before the sync, with its own later change.
      result = await switchBack(MacLegacyDataRequest.undo);
      expect(result.state, MacLegacyDataState.undone);
      expect(
        await read(target, 'hive/settings.hive'),
        'changed after the undo',
      );
      expect(await read(target, 'hive/prompt_blocks.hive'), '2.0 blocks');
      expect(await exists(target, 'hive/history.hive'), isFalse);
      await expectBackups([MacLegacyDataTask.undo]);
      final synced = (await import().dataSwitch.backups()).single.directory;
      expect(
        await read(synced, 'hive/settings.hive'),
        'changed after the sync',
      );
      expect(await read(synced, 'hive/history.hive'), 'history after the sync');

      // This version's own folders followed every switch.
      expect(await read(target, 'agent-data/session.json'), 'agent session 2');
      expect(
        await read(target, 'settings_backups/v2/a.json'),
        'preference backup',
      );
      expect(await exists(synced, 'agent-data'), isFalse);
      expect(await treeOf(legacy), original);
      expect(await import().dataSwitch.pending(), isFalse);
      expect(await leftovers(), isEmpty);
    },
  );

  test('backups from syncs, undos and redos count together', () async {
    await sync();
    await switchBack(MacLegacyDataRequest.undo);
    await sync();
    expect(await backupTasks(), [
      MacLegacyDataTask.sync,
      MacLegacyDataTask.undo,
    ]);

    // The third backup pushes out the oldest, whatever made it.
    await sync();
    expect(await backupTasks(), [
      MacLegacyDataTask.sync,
      MacLegacyDataTask.sync,
    ]);

    // Undo and redo each use up the backup they switch to.
    await switchBack(MacLegacyDataRequest.undo);
    await switchBack(MacLegacyDataRequest.redo);
    expect(await backupTasks(), [
      MacLegacyDataTask.redo,
      MacLegacyDataTask.sync,
    ]);
    await sync();
    expect(await backupTasks(), [
      MacLegacyDataTask.sync,
      MacLegacyDataTask.redo,
    ]);
    expect(
      await import().dataSwitch.backupRoot.list().length,
      MacLegacyDataSwitch.keep,
    );
  });

  test('a sync that fails while copying changes nothing', () async {
    final before = await treeOf(target);

    await import().request(const MacLegacyDataRequest.sync());
    final failed = await import(
      beforeCommit: () async =>
          throw const FileSystemException('synthetic copy failure'),
    ).prepare();

    expect(failed.state, MacLegacyDataState.failed);
    expect(failed.task, MacLegacyDataTask.sync);
    expect(await treeOf(target), before);
    expect(await import().dataSwitch.backups(), isEmpty);
    expect(await leftovers(), isEmpty);

    // Starting without syncing drops the request; nothing happens later.
    await import().skip();
    expect(await import().dataSwitch.pending(), isFalse);
    expect((await import().prepare()).state, MacLegacyDataState.prepared);
    expect(await treeOf(target), before);
  });

  for (final (step, failAt) in [('backup', 1), ('carry', 2), ('publish', 1)]) {
    test('a sync that fails at "$step" is rolled back completely', () async {
      final before = await treeOf(target);
      var calls = 0;

      await import().request(const MacLegacyDataRequest.sync());
      final failed = await import(
        onStep: (current) async {
          if (current == step && ++calls == failAt) {
            throw const FileSystemException('synthetic switch failure');
          }
        },
      ).prepare();

      expect(failed.state, MacLegacyDataState.failed);
      expect(await treeOf(target), before);
      expect(await import().dataSwitch.backups(), isEmpty);
      expect(await leftovers(), isEmpty);
      // Retrying later works.
      expect((await import().prepare()).state, MacLegacyDataState.synced);
    });
  }

  test('a switch a crash interrupted is finished on the next launch', () async {
    // The state right after the old data moved into its backup and one of
    // this version's folders moved into the new data.
    final backup = Directory(
      p.join(
        support.path,
        'com.wof.naiStudio.backups',
        '20261029-140000-000-before-sync',
      ),
    );
    final staging = Directory(
      p.join(support.path, '.com.wof.naiStudio.import-crash'),
    );
    await writeData(staging, 'hive/settings.hive', '1.1.1 latest settings');
    await writeData(
      staging,
      MacLegacyDataImport.markerName,
      jsonEncode({'state': 'synced', 'at': '2026-10-29T06:00:00.000Z'}),
    );
    await backup.parent.create(recursive: true);
    await target.rename(backup.path);
    await Directory(
      p.join(backup.path, 'agent-data'),
    ).rename(p.join(staging.path, 'agent-data'));
    // path_provider creates the folder again before anything else runs.
    await target.create();
    await import().request(const MacLegacyDataRequest.sync());
    await File(
      p.join(support.path, '.com.wof.naiStudio.sync-journal.json'),
    ).writeAsString(
      jsonEncode({
        'task': 'sync',
        'incoming': staging.path,
        'incomingIsBackup': false,
        'backup': backup.path,
        'carry': ['agent-data', 'draft-backups', 'settings_backups'],
      }),
    );

    expect((await import().prepare()).state, MacLegacyDataState.prepared);

    expect(await read(target, 'hive/settings.hive'), '1.1.1 latest settings');
    expect(await read(target, 'agent-data/session.json'), 'agent session');
    expect(await read(target, 'draft-backups/draft.json'), 'draft');
    expect(
      await read(target, 'settings_backups/v2/a.json'),
      'preference backup',
    );
    expect(await read(backup, 'hive/settings.hive'), '2.0 settings');
    expect(await import().dataSwitch.pending(), isFalse);
    expect(await leftovers(), isEmpty);
  });

  test(
    'a switch interrupted before anything moved is simply retried',
    () async {
      final staging = Directory(
        p.join(support.path, '.com.wof.naiStudio.import-crash'),
      );
      await writeData(staging, 'hive/settings.hive', 'stale copy');
      await import().request(const MacLegacyDataRequest.sync());
      await File(
        p.join(support.path, '.com.wof.naiStudio.sync-journal.json'),
      ).writeAsString(
        jsonEncode({
          'task': 'sync',
          'incoming': staging.path,
          'incomingIsBackup': false,
          'backup': p.join(
            support.path,
            'com.wof.naiStudio.backups',
            '20261029-140000-000-before-sync',
          ),
          'carry': ['agent-data'],
        }),
      );

      expect((await import().prepare()).state, MacLegacyDataState.synced);
      expect(await read(target, 'hive/settings.hive'), '1.1.1 latest settings');
      expect(await read(target, 'agent-data/session.json'), 'agent session');
      expect(await leftovers(), isEmpty);
    },
  );

  test('a sync waits while the old app runs and can be dropped', () async {
    await import().request(const MacLegacyDataRequest.sync());
    var checks = 0;
    final waiting = RecordingPresenter();

    expect(
      await runMacLegacyDataImport(
        import(running: () => ++checks < 3),
        presenter: waiting,
        pollInterval: Duration.zero,
        settleDelay: Duration.zero,
      ),
      MacLegacyDataState.synced,
    );
    expect(waiting.calls, ['running:sync', 'copying:sync', 'starting']);

    await import().request(const MacLegacyDataRequest.sync());
    final dropped = RecordingPresenter(skipWhenRunning: true);
    expect(
      await runMacLegacyDataImport(
        import(running: () => true),
        presenter: dropped,
        pollInterval: const Duration(milliseconds: 5),
      ),
      MacLegacyDataState.skipped,
    );
    expect(dropped.calls, ['running:sync', 'starting']);
    expect(await import().dataSwitch.pending(), isFalse);
    expect(await import().dataSwitch.backups(), hasLength(1));
  });

  test('a failed sync offers retry and dropping it', () async {
    await import().request(const MacLegacyDataRequest.sync());
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

    expect(state, MacLegacyDataState.synced);
    expect(presenter.calls, [
      'copying:sync',
      'failed:sync',
      'copying:sync',
      'starting',
    ]);
  });

  test('settings see the data source, backups and a running old app', () async {
    final first = await import(running: () => true).status();
    expect(first!.copiedAt, DateTime.utc(2026, 10, 23, 6, 5).toLocal());
    expect(first.syncedAt, isNull);
    expect(first.backups, isEmpty);
    expect(first.legacyRunning, isTrue);

    await import().request(const MacLegacyDataRequest.sync());
    expect((await import().status())!.pending?.task, MacLegacyDataTask.sync);
    await import().prepare();
    final synced = (await import().status())!;
    expect(synced.syncedAt, isNotNull);
    expect(synced.copiedAt, isNull);
    expect(synced.backups.single.task, MacLegacyDataTask.sync);
  });

  test('without previous data there is nothing to show or sync', () async {
    await legacy.delete(recursive: true);
    expect(await import().status(), isNull);

    await import().request(const MacLegacyDataRequest.sync());
    final failed = await import().prepare();
    expect(failed.state, MacLegacyDataState.failed);
    expect(await read(target, 'hive/settings.hive'), '2.0 settings');
  });

  test('the sync is offered only on macOS outside a sandbox', () {
    for (final (layout, sandbox, offered) in [
      (SupportDirectoryLayout.macLegacyImport, null, true),
      (SupportDirectoryLayout.macLegacyImport, '/tmp/sandbox', false),
      (SupportDirectoryLayout.executableAdjacent, null, false),
      (SupportDirectoryLayout.system, null, false),
    ]) {
      expect(
        macLegacySyncOffered(layout: layout, sandboxRoot: sandbox),
        offered,
        reason: '$layout $sandbox',
      );
    }
  });
}
