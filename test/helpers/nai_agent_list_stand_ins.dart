import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

/// File information with Windows' times, in place of [FileStat.stat] for the
/// folder stamps, so the Windows rules run on any machine.
///
/// On Windows `FileStat.changed` is the creation time: editing a file in
/// place leaves it as it was, and only the modification time moves (POSIX
/// also moves the change time on every write, which hides what the
/// modification time does). Here everything reads as created at [created],
/// long before the test; the rest is the real file information.
NaiAgentFileStat windowsFileTimes({DateTime? created}) {
  final at = created ?? DateTime(2026);
  return (path) async => _WindowsFileStat(await FileStat.stat(path), at);
}

class _WindowsFileStat implements FileStat {
  _WindowsFileStat(this._real, this.changed);
  final FileStat _real;
  @override
  final DateTime changed;
  @override
  DateTime get modified => _real.modified;
  @override
  DateTime get accessed => _real.accessed;
  @override
  FileSystemEntityType get type => _real.type;
  @override
  int get mode => _real.mode;
  @override
  int get size => _real.size;
  @override
  String modeString() => _real.modeString();
}

/// One `node <script>` run: what was started, where, the JSON line written to
/// its stdin and whether it was stopped.
class NodeListRun {
  NodeListRun(this.executable, this.arguments, this.workingDirectory);
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  Map<String, dynamic>? input;
  bool killed = false;
  String get script => p.basename(arguments.single);

  @override
  String toString() => killed ? '$script (stopped)' : script;
}

/// Stands in for Node running `list-skills.mjs` / `list-commands.mjs`: records
/// every start and, once the JSON line on stdin is in, lists the folders it
/// names there and then, answering one line shaped like the real scripts'.
///
/// Skills are the folders in each source (dot names left out), described by
/// the `description:` line of their SKILL.md; commands are the `.md` files in
/// the prompt folders, described by their first line. Only there to count runs
/// and to show whether a list followed the folders; the real scripts' rules
/// (shadowing, error kinds) are not copied.
class NodeListStandIn {
  final runs = <NodeListRun>[];

  /// While set, every run lists and answers only once it completes: Node is
  /// still listing.
  Completer<void>? hold;

  final _failing = <String, String>{};

  /// The next run of [script] (`list-skills.mjs` / `list-commands.mjs`)
  /// answers `{"error": message}`.
  void failNext(String script, String message) => _failing[script] = message;

  int get skillRuns => runs.where((r) => r.script == 'list-skills.mjs').length;
  int get commandRuns =>
      runs.where((r) => r.script == 'list-commands.mjs').length;

  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final run = NodeListRun(executable, List.of(arguments), workingDirectory);
    runs.add(run);
    final failure = _failing.remove(run.script);
    return _StandInProcess(run, (input) async {
      await hold?.future;
      if (failure != null) return jsonEncode({'error': failure});
      return run.script == 'list-skills.mjs'
          ? _listSkills(input)
          : _listCommands(input);
    });
  }
}

String _listSkills(Map<String, dynamic> config) {
  final disabled = {...config['disabled'] as List};
  final modes = config['modes'] as Map;
  final report = <Map<String, dynamic>>[];
  var catalog = 0;
  for (final source in const ['workspace', 'global', 'builtin']) {
    final path = config['${source}Directory'] as String?;
    if (path == null || !Directory(path).existsSync()) continue;
    final folders = [
      for (final entity in Directory(path).listSync())
        if (entity is Directory && !p.basename(entity.path).startsWith('.'))
          entity.path,
    ]..sort();
    for (final folder in folders) {
      final name = p.basename(folder);
      final file = File(p.join(folder, 'SKILL.md'));
      final description = file.existsSync()
          ? RegExp(
                  r'^description: (.*)$',
                  multiLine: true,
                ).firstMatch(file.readAsStringSync())?.group(1) ??
                ''
          : '';
      final key = '$source/$name';
      final enabled = !disabled.contains(key);
      report.add({
        'key': key,
        'name': name,
        'source': source,
        'description': description,
        'directory': folder,
        'file': file.path,
        'enabled': enabled,
        'mode': modes[key] ?? 'auto',
        'state': enabled ? 'active' : 'disabled',
      });
      if (enabled) catalog += name.length + description.length + 60;
    }
  }
  return jsonEncode({'skills': report, 'catalogChars': catalog});
}

String _listCommands(Map<String, dynamic> input) {
  final commands = <Map<String, dynamic>>[];
  for (final (source, key) in const [
    ('workspace', 'workspaceDirectory'),
    ('global', 'globalDirectory'),
  ]) {
    final directory = Directory(input[key] as String);
    if (!directory.existsSync()) continue;
    final files = [
      for (final entity in directory.listSync())
        if (entity is File && entity.path.endsWith('.md')) entity,
    ]..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      commands.add({
        'kind': 'template',
        'name': p.basenameWithoutExtension(file.path),
        'description': file.readAsLinesSync().firstOrNull ?? '',
        'source': source,
      });
    }
  }
  return jsonEncode({'commands': commands});
}

class _StandInProcess implements Process {
  _StandInProcess(
    this._run,
    Future<String> Function(Map<String, dynamic>) reply,
  ) {
    final input = StreamController<List<int>>();
    stdin = IOSink(input);
    utf8.decoder.bind(input.stream).join().then((text) async {
      final request = jsonDecode(text) as Map<String, dynamic>;
      _run.input = request;
      final line = await reply(request);
      if (_run.killed) return;
      _stdout.add(utf8.encode('$line\n'));
      unawaited(_stdout.close());
      _exit.complete(0);
    });
  }

  final NodeListRun _run;
  final _stdout = StreamController<List<int>>();
  final _exit = Completer<int>();

  @override
  late final IOSink stdin;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Future<int> get exitCode => _exit.future;

  @override
  int get pid => 0;

  /// Like a real process being stopped: it exits without answering.
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (_exit.isCompleted) return false;
    _run.killed = true;
    unawaited(_stdout.close());
    _exit.complete(-15);
    return true;
  }
}

/// Lays out the bundled Agent runtime under [root]. Only its presence is
/// checked, so the files are empty. Node is `node.exe` on Windows and `node`
/// on macOS, as in naiAgentRuntimePathsProvider.
NaiAgentRuntimePaths writeStandInRuntime(
  Directory root, {
  required bool windows,
}) {
  final directory = Directory(p.join(root.path, 'runtime', 'nai-agent'))
    ..createSync(recursive: true);
  for (final name in [
    windows ? 'node.exe' : 'node',
    'host.mjs',
    'list-skills.mjs',
    'list-commands.mjs',
  ]) {
    File(p.join(directory.path, name)).writeAsStringSync('');
  }
  return NaiAgentRuntimePaths(
    node: p.join(directory.path, windows ? 'node.exe' : 'node'),
    host: p.join(directory.path, 'host.mjs'),
  );
}

/// Writes (or rewrites) the skill folder `name/SKILL.md` in [source].
void writeSkill(Directory source, String name, String description) {
  final folder = Directory(p.join(source.path, name))
    ..createSync(recursive: true);
  File(p.join(folder.path, 'SKILL.md')).writeAsStringSync(
    '---\nname: $name\ndescription: $description\n---\n\nBody.\n',
  );
}

/// Writes (or rewrites) the command template `name.md` in [prompts].
void writeTemplate(Directory prompts, String name, String description) {
  prompts.createSync(recursive: true);
  File(
    p.join(prompts.path, '$name.md'),
  ).writeAsStringSync('$description\n\nTemplate body.\n');
}
