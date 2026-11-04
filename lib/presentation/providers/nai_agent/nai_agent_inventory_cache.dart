import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/nai_agent/node_runtime_environment.dart';

/// 起 `list-skills.mjs`、`list-commands.mjs` 这种一次性的 Node 进程。测试换成假的来数次数。
typedef NaiAgentListProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

Future<Process> startNaiAgentListProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) => Process.start(
  executable,
  arguments,
  workingDirectory: workingDirectory,
  environment: nodeRuntimeEnvironment(executable),
);

final naiAgentListProcessStarterProvider = Provider<NaiAgentListProcessStarter>(
  (ref) => startNaiAgentListProcess,
);

/// Pi resolves package manifests and resource globs outside Studio's ordinary
/// folders. Until those files participate in the stamp, reread enabled packages
/// on a new visit so in-place edits cannot leave a stale skill/command list.
bool naiAgentHasEnabledPackages(Map<String, dynamic> config) =>
    (config['entries'] as List? ?? const []).any(
      (entry) => entry is Map && entry['enabled'] != false,
    );

/// 这次运行里列过的技能、命令清单。
///
/// 生图页不保活，切走再回来 Agent 面板整个重建，两份清单的 provider 跟着重来；以前每次都起
/// Node 重列一遍。现在每份清单（[read] 的 `slot`：哪种清单、哪个工作区）记着最近一次：
/// 要问 Node 的内容（`request`：脚本、配置、技能开关、显式刷新的序号）和 Node 会读的文件夹
/// （`folders` 给的戳）都没变，就直接给那次的结果，还在列就等那一次；有一样变了才重列。
/// 列失败的不留，下次照常再列。
///
/// 跟着应用这次运行，不存盘：重开应用第一次打开面板照常列。
class NaiAgentInventoryCache {
  NaiAgentInventoryCache({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _lists = <String, _Listing>{};

  Future<T> read<T>({
    required String slot,
    required String request,
    required Future<String?> Function(DateTime takenAt) folders,
    required Future<T> Function() list,
  }) async {
    // 先给文件夹打戳再列：列的途中有改动，下次的戳就和这次的不一样，会重列，不会把旧结果当新的。
    final stamp = await folders(_now());
    if (stamp == null) return list();
    final key = '$request\n$stamp';
    final last = _lists[slot];
    if (last != null && last.key == key) return (await last.value) as T;
    final listing = _Listing(key, Future.sync(list));
    _lists[slot] = listing;
    try {
      return (await listing.value) as T;
    } catch (_) {
      if (identical(_lists[slot], listing)) _lists.remove(slot);
      rethrow;
    }
  }
}

class _Listing {
  _Listing(this.key, this.value);
  final String key;
  final Future<Object?> value;
}

/// 跟着应用这次运行，不随页面销毁。
final naiAgentInventoryCacheProvider = Provider<NaiAgentInventoryCache>(
  (ref) => NaiAgentInventoryCache(),
);

/// 打戳时取文件信息（类型、时间、大小）。正式运行就是 [FileStat.stat]。
///
/// 两个系统给的时间不一样：POSIX 的 `changed` 是变更时间，每次写都会动；Windows 的 `changed`
/// 是创建时间，原地改文件不动，只有修改时间会变。所以戳里修改时间和变更时间两样都记、
/// 2 秒规则两样都看。测试换成按 Windows 规则给时间的，在哪台机器上都能测到这一点。
typedef NaiAgentFileStat = Future<FileStat> Function(String path);

final naiAgentFileStatProvider = Provider<NaiAgentFileStat>(
  (ref) => FileStat.stat,
);

/// 有的文件系统记时间很粗（FAT 2 秒一格，HFS+ 1 秒）：同一格里再改一次，时间不变。
/// 打戳时看到离现在这么近的时间，这一次照常列但不留，下次再看。
const _settle = Duration(seconds: 2);

/// Pi 在每层文件夹里认的忽略文件，外加技能本身。
const _skillFiles = ['SKILL.md', '.gitignore', '.ignore', '.fdignore'];

/// `list-skills.mjs`（`tool/nai_agent/lib/skills.mjs` 和 Pi 的 `loadSkillsFromDir`）会读的东西打一个戳。
/// 规则与 Pi 的扫描行为同步；升级后跑 `inventory_stamp_real_scripts_test.dart` 和真脚本对一遍。
///
/// 每个来源文件夹：它本身、里面的名字、它的 [_skillFiles]；其中每个技能文件夹（跳过点开头的和
/// node_modules，链接跟到目标，和脚本一样）：它本身和它的 [_skillFiles]。每样记类型、修改时间、
/// 变更时间、文件大小。新增、删除、改名靠名字发现，不只靠文件夹的修改时间。
///
/// 读不了文件夹，或者有时间离 [takenAt] 不到 [_settle]，给 null：照常列，不留。
Future<String?> naiAgentSkillFoldersStamp(
  List<String> directories,
  DateTime takenAt, {
  NaiAgentFileStat stat = FileStat.stat,
}) {
  final stamp = _FolderStamp(takenAt, stat);
  return stamp.build(() async {
    for (final directory in directories) {
      final names = await stamp.folder(directory);
      if (names == null) continue;
      await stamp.entries([
        for (final name in _skillFiles) p.join(directory, name),
      ]);
      final children = [
        for (final name in names)
          if (!name.startsWith('.') && name != 'node_modules')
            p.join(directory, name),
      ];
      final types = await stamp.entries(children);
      await stamp.entries([
        for (final (index, child) in children.indexed)
          if (types[index] == FileSystemEntityType.directory)
            for (final name in _skillFiles) p.join(child, name),
      ]);
    }
  });
}

/// `list-commands.mjs`（Pi 的 `loadTemplatesFromDir`）会读的东西打一个戳：每个提示词文件夹
/// 本身、里面的名字、其中每个 `.md`（链接跟到目标）。规则同 [naiAgentSkillFoldersStamp]。
Future<String?> naiAgentPromptFoldersStamp(
  List<String> directories,
  DateTime takenAt, {
  NaiAgentFileStat stat = FileStat.stat,
}) {
  final stamp = _FolderStamp(takenAt, stat);
  return stamp.build(() async {
    for (final directory in directories) {
      final names = await stamp.folder(directory);
      if (names == null) continue;
      await stamp.entries([
        for (final name in names)
          if (name.endsWith('.md')) p.join(directory, name),
      ]);
    }
  });
}

class _FolderStamp {
  _FolderStamp(this.takenAt, this._stat);
  final DateTime takenAt;
  final NaiAgentFileStat _stat;
  final _lines = <String>[];
  var _settled = true;

  Future<String?> build(Future<void> Function() body) async {
    try {
      await body();
    } on FileSystemException {
      return null;
    }
    return _settled ? _lines.join('\n') : null;
  }

  /// 记下 [path] 本身；是文件夹就再记下里面的名字（排好序）并返回，不是就返回 null。
  Future<List<String>?> folder(String path) async {
    final [type] = await entries([path]);
    if (type != FileSystemEntityType.directory) return null;
    final names = [
      await for (final entity in Directory(path).list(followLinks: false))
        p.basename(entity.path),
    ]..sort();
    _lines.add(jsonEncode(names));
    return names;
  }

  /// 按顺序记下每个路径（链接跟到目标），返回各自的类型。
  Future<List<FileSystemEntityType>> entries(List<String> paths) async {
    final stats = await Future.wait(paths.map(_stat));
    final recent = takenAt.subtract(_settle);
    for (final (index, stat) in stats.indexed) {
      if (stat.type == FileSystemEntityType.notFound) {
        _lines.add('${paths[index]}\t-');
        continue;
      }
      if (stat.modified.isAfter(recent) || stat.changed.isAfter(recent)) {
        _settled = false;
      }
      _lines.add(
        [
          paths[index],
          stat.type,
          stat.modified.microsecondsSinceEpoch,
          stat.changed.microsecondsSinceEpoch,
          if (stat.type == FileSystemEntityType.file) stat.size,
        ].join('\t'),
      );
    }
    return [for (final stat in stats) stat.type];
  }
}
