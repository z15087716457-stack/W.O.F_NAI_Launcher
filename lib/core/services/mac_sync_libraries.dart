import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_sha256.dart';
import 'verified_directory_copy.dart';

/// One box or SQLite database is identified by its primary file's path
/// relative to the profile. A Hive compacted file can recover a missing box.
class MacSyncLibraries {
  MacSyncLibraries._(this.root);

  final Directory root;
  final Set<String> _families = {}, _primaries = {};
  final Map<String, List<String>> _dictionaryCommits = {};
  final Set<String> members = {};
  final Set<String> parents = {};

  static final _hive = RegExp(
    r'^(.+\.hive)(?:c|\.(?:lock|crc))?$',
    caseSensitive: false,
  );
  static final _sqlite = RegExp(
    r'^(.+\.(?:db|sqlite3?))(?:-(?:wal|shm|journal))?$',
    caseSensitive: false,
  );
  static final _bareHiveCompanion = RegExp(
    r'^(.+)\.(?:lock|crc)$',
    caseSensitive: false,
  );

  static final _dictionaryCommit = RegExp(r'^commit-(tags|wiki)-[0-9]+\.json$');
  static final _objectHash = RegExp(r'^[a-f0-9]{64}$');

  // These two files are written alongside pool.sqlite by VectorPool.checkpoint.
  static bool _isVectorPool(String dir) {
    final parts = p.split(dir);
    return parts.length == 5 &&
        parts[0] == 'rag' &&
        parts[1] == 'v1' &&
        parts[2] == 'indices' &&
        parts[3] == 'pool-v2';
  }

  static Future<MacSyncLibraries> scan(Directory root) async {
    final result = MacSyncLibraries._(root);
    // Never walk through a link into another tree.
    final bare = <String, String>{};
    final linkFiles = <String>{};
    await for (final entry in root.list(recursive: true, followLinks: false)) {
      if (entry is Directory) continue;
      final relative = p.relative(entry.path, from: root.path);
      if (entry is Link) linkFiles.add(relative);
      final name = p.basename(relative);
      final dir = p.dirname(relative);
      final sqlite = _sqlite.firstMatch(name);
      final hive = _hive.firstMatch(name);
      if (sqlite != null) {
        result._add(p.normalize(p.join(dir, sqlite[1]!)), relative);
      } else if (hive != null) {
        result._add(p.normalize(p.join(dir, hive[1]!)), relative);
      } else if (_isVectorPool(dir) &&
          (name == 'ann.json' || name == 'vectors.usearch')) {
        result._add(p.join(dir, 'pool.sqlite'), relative);
      } else if (dir == 'dictionary_updates' &&
          _dictionaryCommit.hasMatch(name)) {
        final kind = _dictionaryCommit.firstMatch(name)![1]!;
        (result._dictionaryCommits[kind] ??= []).add(relative);
        result._mark(relative);
      } else if (_bareHiveCompanion.firstMatch(name) case final match?) {
        bare[relative] = p.normalize(p.join(dir, '${match[1]}.hive'));
      }
    }
    for (final entry in bare.entries) {
      if (result._families.contains(entry.value) ||
          p.split(entry.key).contains('hive')) {
        result._add(entry.value, entry.key);
      }
    }
    for (final alias in linkFiles.intersection(result.members)) {
      final target = await _internalFileTarget(
        root,
        File(p.join(root.path, alias)),
      );
      // A database alias can refer to an opaque file outside its usual
      // directory. It and the WAL actually used at the physical path belong
      // to the snapshot, rather than following other non-database files.
      for (final name in _linkedPayload(alias, target)) {
        if (await FileSystemEntity.type(
              p.join(root.path, name),
              followLinks: false,
            ) !=
            FileSystemEntityType.notFound) {
          result._mark(name);
        }
      }
    }
    return result;
  }

  void _add(String primary, String relative) {
    _families.add(primary);
    if (_isPrimary(relative, primary)) _primaries.add(primary);
    _mark(relative);
  }

  void _mark(String relative) {
    members.add(relative);
    var dir = p.dirname(relative);
    while (dir != '.' && parents.add(dir)) {
      dir = p.dirname(dir);
    }
  }

  static List<String> _possibleMembers(String primary) {
    if (primary.toLowerCase().endsWith('.hive')) {
      final stem = primary.substring(0, primary.length - 5);
      return [
        primary,
        '${primary}c',
        '$stem.lock',
        '$stem.crc',
        '$primary.lock',
        '$primary.crc',
      ];
    }
    final dir = p.dirname(primary);
    return [
      primary,
      '$primary-wal',
      '$primary-shm',
      '$primary-journal',
      if (p.basename(primary) == 'pool.sqlite' && _isVectorPool(dir)) ...[
        p.join(dir, 'ann.json'),
        p.join(dir, 'vectors.usearch'),
      ],
    ];
  }

  static bool _isPrimary(String member, String primary) =>
      member == primary ||
      (primary.toLowerCase().endsWith('.hive') && member == '${primary}c');

  static Future<Map<String, FileSystemEntityType>> _present(
    Directory root,
    String primary,
  ) async {
    final present = <String, FileSystemEntityType>{};
    for (final member in _possibleMembers(primary)) {
      final type = await FileSystemEntity.type(
        p.join(root.path, member),
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound) present[member] = type;
    }
    return present;
  }

  /// Only changes a private staging copy. Existing primaries (even empty
  /// files) belong wholly to the previous app; do not repair or open them.
  Future<Future<void> Function()> copyMissingTo(Directory staging) async {
    final copied = <String, DataSnapshotEntry>{};
    final groups = <String, Set<String>>{};
    final previousObjects = await _planDictionaryRevisions(staging, copied);
    final links = <String, ({String target, String digest})>{};
    for (final primary in _primaries) {
      if (previousObjects.contains(primary)) continue;
      await safeMacLibraryParents(root, primary);
      await safeMacLibraryParents(staging, primary);
      final incoming = await _present(staging, primary);
      if (incoming.keys.any((entry) => _isPrimary(entry, primary))) {
        if (incoming.entries.any(
          (entry) =>
              _isPrimary(entry.key, primary) &&
              entry.value != FileSystemEntityType.file &&
              entry.value != FileSystemEntityType.link,
        )) {
          throw FileSystemException('Unsafe previous database file', primary);
        }
        continue;
      }
      final local = await _present(root, primary);
      if (!local.keys.any((entry) => _isPrimary(entry, primary))) {
        throw const ApplicationDataChangedException();
      }
      // Incomplete old journals/locks are not a database. Keep the source
      // untouched and remove only these orphans from its private copy.
      for (final entry in incoming.entries) {
        if (entry.value != FileSystemEntityType.file) {
          throw FileSystemException('Unsafe database companion', entry.key);
        }
        await File(p.join(staging.path, entry.key)).delete();
      }
      groups[primary] = local.keys.toSet();
      for (final entry in local.entries) {
        final file = File(p.join(root.path, entry.key));
        if (entry.value == FileSystemEntityType.link) {
          final target = await _internalFileTarget(root, file);
          await _stageLinkedPayload(staging, entry.key, target, copied);
          await Directory(
            p.dirname(p.join(staging.path, entry.key)),
          ).create(recursive: true);
          links[entry.key] = (target: target, digest: await fileSha256(file));
          copied[entry.key] = DataSnapshotEntry.link(target);
        } else if (entry.value == FileSystemEntityType.file) {
          copied[entry.key] = await _snapshot(file);
        } else {
          throw FileSystemException('Unsafe local database file', entry.key);
        }
      }
    }
    await copySnapshot(root, staging, copied, createLink: createRelativeLink);
    return () async {
      for (final entry in links.entries) {
        final original = File(p.join(root.path, entry.key));
        final staged = File(p.join(staging.path, entry.key));
        if (await _internalFileTarget(root, original) != entry.value.target ||
            await _internalFileTarget(staging, staged) != entry.value.target ||
            await fileSha256(original) != entry.value.digest ||
            await fileSha256(staged) != entry.value.digest) {
          throw const ApplicationDataChangedException();
        }
      }
      final current = await scan(root);
      if (current.members.length != members.length ||
          !members.containsAll(current.members)) {
        throw const ApplicationDataChangedException();
      }
      for (final entry in groups.entries) {
        await safeMacLibraryParents(root, entry.key);
        final now = await _present(root, entry.key);
        if (now.length != entry.value.length ||
            !entry.value.every(
              (name) =>
                  now[name] ==
                  (links.containsKey(name)
                      ? FileSystemEntityType.link
                      : FileSystemEntityType.file),
            )) {
          throw const ApplicationDataChangedException();
        }
      }
      for (final entry in copied.entries) {
        if (entry.value.isLink) continue;
        final file = File(p.join(root.path, entry.key));
        final stat = await file.stat();
        if (stat.size != entry.value.bytes ||
            stat.modified != entry.value.modified ||
            await fileSha256(file) != entry.value.digest) {
          throw const ApplicationDataChangedException();
        }
      }
    };
  }

  static Iterable<String> _linkedPayload(String alias, String target) => [
    target,
    if (_sqlite.firstMatch(p.basename(alias))?[1] == p.basename(alias)) ...[
      '$target-wal',
      '$target-shm',
      '$target-journal',
    ],
  ];

  Future<void> _stageLinkedPayload(
    Directory staging,
    String alias,
    String target,
    Map<String, DataSnapshotEntry> copied,
  ) async {
    await safeMacLibraryParents(staging, target);
    final hasOld =
        await FileSystemEntity.type(
          p.join(staging.path, target),
          followLinks: false,
        ) !=
        FileSystemEntityType.notFound;
    for (final name in _linkedPayload(alias, target)) {
      final from = File(p.join(root.path, name)),
          to = File(p.join(staging.path, name));
      final sourceType = await FileSystemEntity.type(
        from.path,
        followLinks: false,
      );
      final stagedType = await FileSystemEntity.type(
        to.path,
        followLinks: false,
      );
      if (sourceType != FileSystemEntityType.notFound &&
              sourceType != FileSystemEntityType.file ||
          stagedType != FileSystemEntityType.notFound &&
              stagedType != FileSystemEntityType.file) {
        throw FileSystemException('Unsafe linked database payload', name);
      }
      if (hasOld &&
          (sourceType != stagedType ||
              sourceType == FileSystemEntityType.file &&
                  await fileSha256(from) != await fileSha256(to))) {
        throw FileSystemException('Conflicting linked database payload', name);
      }
      if (!hasOld && sourceType == FileSystemEntityType.file) {
        copied[name] = await _snapshot(from);
      } else if (!hasOld && stagedType == FileSystemEntityType.file) {
        await to.delete(); // An orphan companion in the staging copy.
      }
    }
  }

  static Future<String> _internalFileTarget(Directory root, File link) async {
    final physicalRoot = await root.resolveSymbolicLinks();
    final target = await link.resolveSymbolicLinks();
    if (!p.isWithin(physicalRoot, target) ||
        await FileSystemEntity.type(target) != FileSystemEntityType.file) {
      throw FileSystemException('Database link leaves its profile', link.path);
    }
    return p.relative(target, from: physicalRoot);
  }

  /// DictionaryDataStore selects commit-<kind>-<time>.json and validates the
  /// content-addressed DB it names. Preserve an absent kind with its receipts;
  /// never activate a newer local commit over the previous version's kind.
  Future<Set<String>> _planDictionaryRevisions(
    Directory staging,
    Map<String, DataSnapshotEntry> copied,
  ) async {
    if (_dictionaryCommits.isEmpty) return {};
    const folder = 'dictionary_updates';
    await safeMacLibraryParents(staging, '$folder/.check');
    final staged = Directory(p.join(staging.path, folder));
    final incomingKinds = <String>{};
    if (await staged.exists()) {
      await for (final entry in staged.list(followLinks: false)) {
        final kind = _dictionaryCommit.firstMatch(p.basename(entry.path))?[1];
        if (kind == null || incomingKinds.contains(kind) || entry is! File) {
          continue;
        }
        if (await _dictionaryObject(entry, kind, verify: true) != null) {
          incomingKinds.add(kind);
        }
      }
    }
    final localOnly = <String>{}, previousKinds = <String>{};
    for (final group in _dictionaryCommits.entries) {
      final keep = incomingKinds.contains(group.key);
      var found = false;
      for (final name in group.value) {
        final file = File(p.join(root.path, name));
        final object = await _dictionaryObject(file, group.key, verify: !keep);
        if (object == null) {
          continue; // DictionaryDataStore also skips damaged older revisions.
        }
        found = true;
        if (keep) {
          previousKinds.add(object);
          continue;
        }
        localOnly.add(object);
        final target = File(p.join(staging.path, object));
        final type = await FileSystemEntity.type(
          target.path,
          followLinks: false,
        );
        if (type != FileSystemEntityType.notFound &&
            (type != FileSystemEntityType.file ||
                await fileSha256(target) !=
                    p.basenameWithoutExtension(object))) {
          throw FileSystemException(
            'Conflicting content-addressed database',
            object,
          );
        }
        final receiptType = await FileSystemEntity.type(
          p.join(staging.path, name),
          followLinks: false,
        );
        if (receiptType != FileSystemEntityType.notFound &&
            receiptType != FileSystemEntityType.file) {
          throw FileSystemException('Unsafe dictionary revision target', name);
        }
        copied[name] = await _snapshot(file);
      }
      if (!keep && !found) {
        throw FileSystemException(
          'No readable local dictionary revision',
          group.key,
        );
      }
    }
    return previousKinds.difference(localOnly);
  }

  static Future<String?> _dictionaryObject(
    File receipt,
    String kind, {
    required bool verify,
  }) async {
    if (await FileSystemEntity.type(receipt.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw FileSystemException('Unsafe dictionary revision', receipt.path);
    }
    Object? data;
    try {
      data = jsonDecode(await receipt.readAsString());
    } on FormatException {
      return null;
    }
    if (data is! Map || data['kind'] != kind) return null;
    final hash = data['sha256'];
    if (hash is! String || !_objectHash.hasMatch(hash)) return null;
    final object = File(p.join(receipt.parent.path, '$hash.db'));
    if (verify &&
        (await FileSystemEntity.type(object.path, followLinks: false) !=
                FileSystemEntityType.file ||
            data['bytes'] != await object.length() ||
            await fileSha256(object) != hash)) {
      return null;
    }
    return p.join('dictionary_updates', '$hash.db');
  }

  static Future<DataSnapshotEntry> _snapshot(File file) async {
    final stat = await file.stat();
    return DataSnapshotEntry.file(
      stat.size,
      stat.modified,
      await fileSha256(file),
    );
  }

  static String? possibleBareHivePrimary(String path) {
    final match = _bareHiveCompanion.firstMatch(p.basename(path));
    return match == null
        ? null
        : p.normalize(p.join(p.dirname(path), '${match[1]}.hive'));
  }
}

/// The relative names in a switch journal may contain subdirectories.
/// Validate every ancestor before creating, moving or removing a file.
Future<List<String>> safeMacLibraryParents(
  Directory root,
  String relative,
) async {
  if (p.isAbsolute(relative) ||
      p.normalize(relative) != relative ||
      p.split(relative).any((part) => part == '.' || part == '..')) {
    throw FileSystemException(
      'Invalid relative application data path',
      relative,
    );
  }
  final missing = <String>[];
  var dir = '.';
  for (final name in p.split(relative).take(p.split(relative).length - 1)) {
    dir = p.normalize(p.join(dir, name));
    final type = await FileSystemEntity.type(
      p.join(root.path, dir),
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) {
      missing.add(dir);
    } else if (type != FileSystemEntityType.directory) {
      throw FileSystemException('Unsafe application data directory', dir);
    }
  }
  return missing;
}
