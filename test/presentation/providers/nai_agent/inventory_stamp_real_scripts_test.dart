import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:path/path.dart' as p;

/// The folder stamps copy by hand what Pi reads (`loadSkillsFromDir`,
/// `loadTemplatesFromDir` in Pi 1.3.0). This runs the real `list-skills.mjs`
/// and `list-commands.mjs` with the installed Pi after each change to a set of
/// folders and checks that whenever what Node lists changes, the stamp changes
/// too. Run it after upgrading Pi: a new scanning rule shows up as a miss.
///
/// Needs `node` and `npm ci` in tool/nai_agent; skipped without them.
final _agent = p.join(Directory.current.path, 'tool', 'nai_agent');

String? _missingRuntime() {
  if (!Directory(
    p.join(_agent, 'node_modules', '@earendil-works', 'pi-coding-agent'),
  ).existsSync()) {
    return 'needs Pi in tool/nai_agent/node_modules (npm ci there)';
  }
  try {
    if (Process.runSync('node', ['--version']).exitCode == 0) return null;
  } on ProcessException {
    // Not installed.
  }
  return 'needs node on PATH';
}

Future<String> _list(String script, Map<String, Object?> input) async {
  final process = await Process.start('node', [
    p.join(_agent, script),
  ], workingDirectory: _agent);
  process.stdin.writeln(jsonEncode(input));
  await process.stdin.close();
  final out = await process.stdout.transform(utf8.decoder).join();
  final err = await process.stderr.transform(utf8.decoder).join();
  await process.exitCode;
  if (out.trim().isEmpty) throw StateError('$script printed nothing: $err');
  return out.trim();
}

void _skill(String folder, String name, String body) {
  Directory(p.join(folder, name)).createSync(recursive: true);
  File(p.join(folder, name, 'SKILL.md')).writeAsStringSync(body);
}

String _md(String name, String description, {String extra = ''}) =>
    '---\nname: $name\ndescription: $description\n$extra---\n\nBody.\n';

/// Applies each step in turn; returns the steps after which Node listed
/// something else while the stamp stayed the same.
Future<List<String>> _misses({
  required Map<String, void Function()> steps,
  required Future<String> Function() list,
  required Future<String?> Function() stamp,
}) async {
  final misses = <String>[];
  var lastList = await list();
  var lastStamp = await stamp();
  for (final MapEntry(key: name, value: change) in steps.entries) {
    change();
    final listed = await list();
    final stamped = await stamp();
    if (listed != lastList && stamped == lastStamp) misses.add(name);
    lastList = listed;
    lastStamp = stamped;
  }
  return misses;
}

/// Taken a minute ahead: the folders the test has just made count as old.
DateTime get _later => DateTime.now().add(const Duration(minutes: 1));

void main() {
  final skip = _missingRuntime();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-real-lists-');
  });
  tearDown(() => root.delete(recursive: true));

  test('skills: every change the real script sees changes the stamp', () async {
    final builtin = p.join(root.path, 'builtin');
    final global = p.join(root.path, 'global');
    final workspace = p.join(root.path, 'workspace');
    final elsewhere = p.join(root.path, 'elsewhere');
    for (final folder in [builtin, global, workspace]) {
      Directory(folder).createSync(recursive: true);
    }
    _skill(builtin, 'nai-prompt', _md('nai-prompt', 'Built-in'));
    _skill(global, 'demo', _md('demo', 'Demo skill'));
    File file(String path) => File(p.join(global, path));
    final misses = await _misses(
      list: () => _list('list-skills.mjs', {
        'builtinDirectory': builtin,
        'globalDirectory': global,
        'workspaceDirectory': workspace,
        'disabled': <String>[],
        'modes': <String, String>{},
      }),
      stamp: () =>
          naiAgentSkillFoldersStamp([builtin, global, workspace], _later),
      steps: {
        'skill added': () => _skill(global, 'added', _md('added', 'Added')),
        'description longer': () =>
            _skill(global, 'added', _md('added', 'Added, longer')),
        'description same size': () =>
            _skill(global, 'added', _md('added', 'Added, longeR')),
        'skill folder renamed': () => Directory(
          p.join(global, 'added'),
        ).renameSync(p.join(global, 'renamed')),
        'folder without SKILL.md': () =>
            Directory(p.join(global, 'empty')).createSync(),
        'SKILL.md appears in it': () =>
            file('empty/SKILL.md').writeAsStringSync(_md('empty', 'Now')),
        'name not the folder name': () =>
            _skill(global, 'empty', _md('other', 'Now')),
        'description removed': () => file(
          'empty/SKILL.md',
        ).writeAsStringSync('---\nname: empty\n---\nBody\n'),
        'manual by default': () => _skill(
          global,
          'demo',
          _md('demo', 'Demo skill', extra: 'disable-model-invocation: true\n'),
        ),
        '.gitignore hides a skill': () =>
            file('.gitignore').writeAsStringSync('demo/\n'),
        '.gitignore edited in place': () =>
            file('.gitignore').writeAsStringSync('none/\n'),
        '.gitignore removed': () => file('.gitignore').deleteSync(),
        '.ignore in a skill folder': () =>
            file('demo/.ignore').writeAsStringSync('SKILL.md\n'),
        '.ignore edited in place': () =>
            file('demo/.ignore').writeAsStringSync('none.md\n'),
        '.ignore removed': () => file('demo/.ignore').deleteSync(),
        'dot folder and node_modules': () {
          _skill(global, '.hidden', _md('hidden', 'Hidden'));
          _skill(global, 'node_modules', _md('node-modules', 'Deps'));
        },
        'workspace skill': () =>
            _skill(workspace, 'local', _md('local', 'Workspace skill')),
        'workspace copy shadows a global one': () =>
            _skill(workspace, 'demo', _md('demo', 'Workspace demo')),
        'SKILL.md in the source folder itself': () =>
            file('SKILL.md').writeAsStringSync(_md('global', 'Root')),
        'that SKILL.md removed': () => file('SKILL.md').deleteSync(),
        'skill folder linked from elsewhere': () {
          _skill(elsewhere, 'linked', _md('linked', 'Linked'));
          Link(
            p.join(global, 'linked'),
          ).createSync(p.join(elsewhere, 'linked'));
        },
        'linked SKILL.md edited': () =>
            _skill(elsewhere, 'linked', _md('linked', 'Linked, edited')),
        'built-in removed': () => Directory(
          p.join(builtin, 'nai-prompt'),
        ).deleteSync(recursive: true),
        'workspace folder removed': () =>
            Directory(workspace).deleteSync(recursive: true),
      },
    );
    expect(misses, isEmpty, reason: 'the stamp missed: $misses');
  }, skip: skip);

  test(
    'commands: every change the real script sees changes the stamp',
    () async {
      final cwd = p.join(root.path, 'workspace');
      final workspace = p.join(cwd, '.pi', 'prompts');
      final global = p.join(root.path, 'prompts');
      Directory(global).createSync(recursive: true);
      Directory(p.join(cwd, '.agent')).createSync(recursive: true);
      File template(String folder, String name) => File(p.join(folder, name));
      template(global, 'review.md').writeAsStringSync('Review the prompt\n');
      final misses = await _misses(
        list: () => _list('list-commands.mjs', {
          'cwd': cwd,
          'agentDir': p.join(cwd, '.agent'),
          'globalDirectory': global,
          'workspaceDirectory': workspace,
        }),
        stamp: () => naiAgentPromptFoldersStamp([workspace, global], _later),
        steps: {
          'workspace template': () {
            Directory(workspace).createSync(recursive: true);
            template(workspace, 'draft.md').writeAsStringSync('Draft it\n');
          },
          'edited longer': () => template(
            global,
            'review.md',
          ).writeAsStringSync('Review the prompt again\n'),
          'edited same size': () => template(
            global,
            'review.md',
          ).writeAsStringSync('Review the prompt agaiN\n'),
          'front matter': () => template(global, 'review.md').writeAsStringSync(
            '---\ndescription: Review\nargument-hint: "[focus]"\n---\n'
            'Body\n',
          ),
          'shadows the global one': () => template(
            workspace,
            'review.md',
          ).writeAsStringSync('Workspace review\n'),
          'file that is not .md': () =>
              template(global, 'notes.txt').writeAsStringSync('x'),
          'dot .md file': () =>
              template(global, '.hidden.md').writeAsStringSync('Hidden\n'),
          'renamed': () => template(
            workspace,
            'draft.md',
          ).renameSync(p.join(workspace, 'plan.md')),
          'removed': () => template(workspace, 'plan.md').deleteSync(),
          'workspace folder removed': () =>
              Directory(workspace).deleteSync(recursive: true),
        },
      );
      expect(misses, isEmpty, reason: 'the stamp missed: $misses');
    },
    skip: skip,
  );
}
