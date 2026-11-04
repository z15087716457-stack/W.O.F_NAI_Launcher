import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/nai_agent_list_stand_ins.dart';

/// A stamp taken a minute from now: folders made by the test count as old.
DateTime get _later => DateTime.now().add(const Duration(minutes: 1));

void main() {
  // Neither the cache nor the stamps branch on the system. What differs is
  // the file information: Windows reports the creation time as the change
  // time, so its run reads file times with that rule (windowsFileTimes).
  for (final platform in const [TargetPlatform.macOS, TargetPlatform.windows]) {
    final windows = platform == TargetPlatform.windows;
    group('${platform.name}:', () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() => debugDefaultTargetPlatformOverride = null);
      _cacheTests();
      _skillStampTests(windows ? windowsFileTimes() : FileStat.stat, windows);
      _promptStampTests(windows ? windowsFileTimes() : FileStat.stat);
    });
  }
}

/// The change time is the creation time on Windows (and so in the Windows
/// run); tests that need it to move on a write only run with POSIX times.
String? _posixOnly(bool windowsTimes) => windowsTimes || Platform.isWindows
    ? 'needs the POSIX change time; Windows reports the creation time'
    : null;

void _cacheTests() {
  group('NaiAgentInventoryCache', () {
    late List<String> calls;
    late NaiAgentInventoryCache cache;
    late int lists;
    final now = DateTime(2026, 10, 30, 12);
    setUp(() {
      calls = [];
      lists = 0;
      cache = NaiAgentInventoryCache(now: () => now);
    });

    Future<String> read(
      String request, {
      String slot = 'skills',
      String? stamp = 'folders',
      Future<String> Function()? list,
    }) => cache.read(
      slot: slot,
      request: request,
      folders: (takenAt) async {
        calls.add('folders ${takenAt.toIso8601String()}');
        return stamp;
      },
      list:
          list ??
          () async {
            calls.add('list $request');
            return 'list ${++lists}';
          },
    );

    test('the same request and folders give the first list back', () async {
      final first = await read('r');
      expect(await read('r'), first);
      expect(await read('r'), first);
      expect(calls.where((c) => c.startsWith('list')), ['list r']);
    });

    test(
      'the folders are stamped first, at the time the cache keeps',
      () async {
        await read('r');
        expect(calls, ['folders ${now.toIso8601String()}', 'list r']);
      },
    );

    test('asking again while the list runs shares that list', () async {
      final gate = Completer<void>();
      var started = 0;
      Future<String> slow() async {
        started++;
        await gate.future;
        return 'slow';
      }

      final first = read('r', list: slow);
      final second = read('r', list: slow);
      await pumpEventQueue();
      expect(started, 1);
      gate.complete();
      expect(await first, 'slow');
      expect(await second, 'slow');
      expect(await read('r'), 'slow');
      expect(started, 1);
    });

    test('a new request or new folders list again; each slot keeps only its '
        'newest list', () async {
      await read('a');
      await read('b');
      await read('a');
      expect(calls.where((c) => c.startsWith('list')), [
        'list a',
        'list b',
        'list a',
      ]);
      await read('a');
      await read('a', stamp: 'changed folders');
      expect(calls.where((c) => c.startsWith('list')).length, 4);

      // Another slot (commands, another workspace) is kept on its own.
      await read('a', slot: 'commands');
      await read('a', slot: 'commands');
      await read('a', stamp: 'changed folders');
      expect(calls.where((c) => c.startsWith('list')).length, 5);
    });

    test('an old list finishing late does not replace the newer one', () async {
      final gate = Completer<void>();
      final old = read(
        'old',
        list: () async {
          await gate.future;
          return 'old list';
        },
      );
      await pumpEventQueue();
      final newer = await read('new');
      gate.complete();
      expect(await old, 'old list');
      expect(await read('new'), newer);
      expect(calls.where((c) => c == 'list new').length, 1);
    });

    test('a failed list is not kept: the next read lists again', () async {
      final gate = Completer<void>();
      final failing = read(
        'r',
        list: () async {
          await gate.future;
          throw StateError('list-skills failed');
        },
      );
      // Someone else asking meanwhile gets the same failure.
      final joined = read('r');
      gate.complete();
      await expectLater(failing, throwsStateError);
      await expectLater(joined, throwsStateError);
      expect(await read('r'), 'list 1');
      expect(calls.where((c) => c.startsWith('list')), ['list r']);
    });

    test(
      'folders that cannot be told are listed every time, never kept',
      () async {
        await read('r', stamp: null);
        await read('r', stamp: null);
        await read('r');
        await read('r');
        expect(calls.where((c) => c.startsWith('list')).length, 3);
      },
    );
  });
}

void _skillStampTests(NaiAgentFileStat fileStat, bool windowsTimes) {
  group('skill folder stamp', () {
    late Directory root, builtin, global, workspace;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('nai-agent-skill-stamp-');
      builtin = Directory(p.join(root.path, 'builtin'));
      global = Directory(p.join(root.path, 'global'));
      workspace = Directory(p.join(root.path, 'workspace'))..createSync();
      writeSkill(builtin, 'nai-prompt', 'Built-in skill');
      writeSkill(global, 'demo', 'Demo skill');
    });
    tearDown(() async {
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['-R', 'u+rwx', root.path]);
      }
      await root.delete(recursive: true);
    });

    Future<String?> stamp([DateTime? takenAt]) => naiAgentSkillFoldersStamp(
      [builtin.path, global.path, workspace.path],
      takenAt ?? _later,
      stat: fileStat,
    );

    /// After [change] the stamp is new, and stays the same when taken again.
    Future<void> expectChange(String what, void Function() change) async {
      final before = await stamp();
      change();
      final after = await stamp();
      expect(after, isNotNull, reason: what);
      expect(after, isNot(before), reason: what);
      expect(await stamp(), after, reason: what);
    }

    test('stays the same while nothing changes', () async {
      final first = await stamp();
      expect(first, isNotNull);
      expect(await stamp(), first);
    });

    test('changes when a skill folder is added, renamed or removed', () async {
      await expectChange(
        'added to the workspace',
        () => writeSkill(workspace, 'local', 'Workspace skill'),
      );
      await expectChange('added globally', () => writeSkill(global, 'b', 'B'));
      await expectChange(
        'renamed',
        () => Directory(
          p.join(global.path, 'b'),
        ).renameSync(p.join(global.path, 'c')),
      );
      await expectChange(
        'removed',
        () => Directory(p.join(global.path, 'c')).deleteSync(recursive: true),
      );
      await expectChange(
        'built-in removed',
        () => Directory(
          p.join(builtin.path, 'nai-prompt'),
        ).deleteSync(recursive: true),
      );
    });

    test(
      'changes when SKILL.md is edited, also to the same size, or removed',
      () async {
        final file = File(p.join(global.path, 'demo', 'SKILL.md'));
        await expectChange(
          'longer description',
          () => writeSkill(global, 'demo', 'A longer demo skill'),
        );
        final size = file.lengthSync();
        await expectChange('same size', () {
          writeSkill(global, 'demo', 'A longer demo skilL');
          // Coarse file clocks (FAT, Windows' 16 ms tick) can keep the old
          // time on a quick rewrite; the guard for that is the 2 s rule below.
          file.setLastModifiedSync(
            DateTime.now().add(const Duration(seconds: 5)),
          );
        });
        expect(file.lengthSync(), size);
        await expectChange('removed', file.deleteSync);
      },
    );

    test('changes when a same-size rewrite puts the old time back', () async {
      final file = File(p.join(global.path, 'demo', 'SKILL.md'));
      final modified = file.lastModifiedSync();
      await expectChange('time restored', () {
        writeSkill(global, 'demo', 'Demo skilL');
        file.setLastModifiedSync(modified);
      });
      expect(file.lastModifiedSync(), modified);
    }, skip: _posixOnly(windowsTimes));

    test('a same-size edit that leaves the change time alone is found by '
        'its modification time', () async {
      // What an edit looks like on Windows, where the change time is the
      // creation time; elsewhere the change time moves as well.
      final file = File(p.join(global.path, 'demo', 'SKILL.md'));
      final size = file.lengthSync();
      await expectChange('same size, later modification time', () {
        writeSkill(global, 'demo', 'Demo skilL');
        file.setLastModifiedSync(
          DateTime.now().add(const Duration(seconds: 5)),
        );
      });
      expect(file.lengthSync(), size);
    });

    test('changes when an ignore file is added or edited, at the top or in a '
        'skill folder', () async {
      final top = File(p.join(global.path, '.gitignore'));
      await expectChange('top added', () => top.writeAsStringSync('demo/\n'));
      await expectChange(
        'top edited',
        () => top.writeAsStringSync('demo/\nother/\n'),
      );
      for (final name in const ['.gitignore', '.ignore', '.fdignore']) {
        final inner = File(p.join(global.path, 'demo', name));
        await expectChange('$name added', () => inner.writeAsStringSync('x\n'));
        await expectChange(
          '$name edited',
          () => inner.writeAsStringSync('SKILL.md\n'),
        );
      }
    });

    test('changes when a source folder itself gets a SKILL.md', () async {
      await expectChange(
        'root SKILL.md',
        () => File(p.join(global.path, 'SKILL.md')).writeAsStringSync('x'),
      );
    });

    test(
      'a missing source folder stamps the same until it is created',
      () async {
        workspace.deleteSync();
        final missing = await stamp();
        expect(missing, isNotNull);
        expect(await stamp(), missing);
        workspace.createSync();
        expect(await stamp(), isNot(missing));
      },
    );

    test('a skill folder that is a link is followed', () async {
      final elsewhere = Directory(p.join(root.path, 'elsewhere'));
      writeSkill(elsewhere, 'linked', 'Linked skill');
      try {
        Link(
          p.join(global.path, 'linked'),
        ).createSync(p.join(elsewhere.path, 'linked'));
      } on FileSystemException catch (e) {
        markTestSkipped('cannot create links here: $e');
        return;
      }
      await expectChange(
        'linked SKILL.md edited',
        () => writeSkill(elsewhere, 'linked', 'Linked skill, edited'),
      );
    });

    test('is not trusted while a time is less than 2 s old', () async {
      writeSkill(global, 'fresh', 'Just written');
      final now = DateTime.now();
      expect(await stamp(now), isNull);
      expect(await stamp(now.add(const Duration(seconds: 1))), isNull);
      expect(await stamp(now.add(const Duration(seconds: 3))), isNotNull);
    });

    test('is not trusted while a change time is less than 2 s old, also with '
        'the modification time put back', () async {
      // Let everything the fixture made get older than 2 s first.
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      final file = File(p.join(global.path, 'demo', 'SKILL.md'));
      final modified = file.lastModifiedSync();
      writeSkill(global, 'demo', 'Demo skilL');
      file.setLastModifiedSync(modified);
      final now = DateTime.now();
      expect(await stamp(now), isNull);
      expect(await stamp(now.add(const Duration(seconds: 3))), isNotNull);
    }, skip: _posixOnly(windowsTimes));

    test('is not trusted when a source folder cannot be listed', () async {
      Process.runSync('chmod', ['000', global.path]);
      expect(await stamp(), isNull);
    }, skip: Platform.isWindows ? 'uses POSIX permissions' : false);
  });
}

void _promptStampTests(NaiAgentFileStat fileStat) {
  group('prompt folder stamp', () {
    late Directory root, workspace, global;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('nai-agent-prompt-stamp-');
      workspace = Directory(p.join(root.path, 'workspace', '.pi', 'prompts'));
      global = Directory(p.join(root.path, 'prompts'));
      writeTemplate(global, 'review', 'Review the prompt');
    });
    tearDown(() => root.delete(recursive: true));

    Future<String?> stamp([DateTime? takenAt]) => naiAgentPromptFoldersStamp(
      [workspace.path, global.path],
      takenAt ?? _later,
      stat: fileStat,
    );

    test('stays the same while nothing changes; changes when a template is '
        'added, edited or removed', () async {
      final first = await stamp();
      expect(first, isNotNull);
      expect(await stamp(), first);

      writeTemplate(workspace, 'draft', 'Draft');
      final added = await stamp();
      expect(added, isNot(first));
      expect(await stamp(), added);

      final file = File(p.join(global.path, 'review.md'));
      writeTemplate(global, 'review', 'Review the prompT');
      file.setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
      final edited = await stamp();
      expect(edited, isNot(added));

      file.deleteSync();
      final removed = await stamp();
      expect(removed, isNot(edited));
      expect(await stamp(), removed);
    });

    test('is not trusted while a time is less than 2 s old', () async {
      writeTemplate(global, 'fresh', 'Just written');
      final now = DateTime.now();
      expect(await stamp(now), isNull);
      expect(await stamp(now.add(const Duration(seconds: 3))), isNotNull);
    });
  });
}
