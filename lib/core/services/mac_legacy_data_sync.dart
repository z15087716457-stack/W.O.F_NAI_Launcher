import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'adjacent_app_data_migration.dart';
import 'mac_sync_libraries.dart';

/// What the previous-version data step does on this launch.
enum MacLegacyDataTask {
  /// First launch: copy the previous version's data once.
  import,

  /// Settings → Sync from previous version: replace this version's data with
  /// a fresh copy, keeping a backup.
  sync,

  /// Settings → Undo last sync: switch back to the newest backup, the data
  /// from before the sync.
  undo,

  /// Settings → Switch back to synced data, offered after an undo: switch
  /// back to the backup the undo made, the data from after the sync.
  redo,
}

/// A sync, undo or redo the user asked for in Settings. Hive and the
/// databases are open while the app runs, so the request is carried out on
/// the next launch, before anything opens.
class MacLegacyDataRequest {
  const MacLegacyDataRequest.sync()
    : task = MacLegacyDataTask.sync,
      backup = null;

  const MacLegacyDataRequest.undo(String this.backup)
    : task = MacLegacyDataTask.undo;

  const MacLegacyDataRequest.redo(String this.backup)
    : task = MacLegacyDataTask.redo;

  final MacLegacyDataTask task;

  /// Undo or redo: the backup to switch back to.
  final String? backup;
}

/// This version's data as it was right before a sync, an undo or a redo.
class MacLegacyDataBackup {
  const MacLegacyDataBackup(
    this.directory,
    this.task,
    this.at, [
    this.sequence = 0,
  ]);

  final Directory directory;

  /// The task the backup was made for: [MacLegacyDataTask.sync],
  /// [MacLegacyDataTask.undo] or [MacLegacyDataTask.redo].
  final MacLegacyDataTask task;
  final DateTime at;
  final int sequence;

  String get id => p.basename(directory.path);
}

/// Requests, backups and the folder switch behind "Sync from previous
/// version", "Undo last sync" and switching back to the synced data. Undo and
/// redo swap the data from before and after a sync back and forth: each
/// switch keeps the data it replaces as the newest backup.
///
/// Sync stages and verifies the database families to retain before renaming
/// either profile. Undo and redo take all database files from their snapshot.
/// Other contents of a one-sided top-level folder continue to follow the
/// active profile. A journal records the same-volume moves and any directories
/// needed for them, so a failed or interrupted switch can be recovered.
class MacLegacyDataSwitch {
  MacLegacyDataSwitch(
    this.destination, {
    DateTime Function()? clock,
    this.onStep,
  }) : _clock = clock ?? DateTime.now;

  static const keep = 2;
  static const carryRootsKey = 'syncOneSidedDirectories';
  static const carryGenerationKey = 'syncLibraryGeneration';
  Future<bool> hasSwitchJournal() => _journal.exists();

  final Directory destination;
  final DateTime Function() _clock;

  /// Test hook: called before each rename of a switch (`backup`, `carry`,
  /// `publish`); throwing there simulates a failure at that point.
  final Future<void> Function(String step)? onStep;

  String get _name => p.basename(destination.path);
  Directory get backupRoot =>
      Directory(p.join(destination.parent.path, '$_name.backups'));
  File get _request =>
      File(p.join(destination.parent.path, '.$_name.sync-request.json'));
  File get _journal =>
      File(p.join(destination.parent.path, '.$_name.sync-journal.json'));

  static final _backupName = RegExp(
    r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})-(\d{3})-before-(sync|undo|redo)(?:-r(\d+))?$',
  );

  /// A request or an interrupted switch waits for this launch.
  Future<bool> pending() async =>
      await _request.exists() || await _journal.exists();

  Future<MacLegacyDataRequest?> readRequest() async {
    if (!await _request.exists()) return null;
    try {
      final value = jsonDecode(await _request.readAsString());
      if (value is Map) {
        final backup = value['backup'];
        switch (MacLegacyDataTask.values.asNameMap()[value['task']]) {
          case MacLegacyDataTask.sync:
            return const MacLegacyDataRequest.sync();
          case MacLegacyDataTask.undo when backup is String:
            return MacLegacyDataRequest.undo(backup);
          case MacLegacyDataTask.redo when backup is String:
            return MacLegacyDataRequest.redo(backup);
          case _:
        }
      }
    } on FormatException {
      // Unreadable: treated as no request, and removed below.
    }
    await clearRequest();
    return null;
  }

  Future<void> writeRequest(MacLegacyDataRequest request) async {
    await destination.parent.create(recursive: true);
    await _request.writeAsString(
      jsonEncode({
        'task': request.task.name,
        if (request.backup != null) 'backup': request.backup,
        'at': _clock().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  Future<void> clearRequest() async {
    if (await _request.exists()) await _request.delete();
  }

  /// Newest first. Only real folders with the backup name pattern count.
  Future<List<MacLegacyDataBackup>> backups() async {
    if (!await _hasBackupRoot()) return const [];
    final result = <MacLegacyDataBackup>[];
    await for (final entry in backupRoot.list(followLinks: false)) {
      final match = _backupName.firstMatch(p.basename(entry.path));
      if (match == null ||
          await FileSystemEntity.type(entry.path, followLinks: false) !=
              FileSystemEntityType.directory) {
        continue;
      }
      final [year, month, day, hour, minute, second, millisecond] = [
        for (var group = 1; group <= 7; group++) int.parse(match[group]!),
      ];
      result.add(
        MacLegacyDataBackup(
          Directory(entry.path),
          MacLegacyDataTask.values.byName(match[8]!),
          DateTime(year, month, day, hour, minute, second, millisecond),
          int.tryParse(match[9] ?? '') ?? 0,
        ),
      );
    }
    return result..sort((a, b) {
      final order = b.sequence.compareTo(a.sequence);
      return order != 0 ? order : b.id.compareTo(a.id);
    });
  }

  Future<bool> _hasBackupRoot() async {
    final type = await FileSystemEntity.type(
      backupRoot.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException('Unsafe backup directory', backupRoot.path);
    }
    return true;
  }

  /// Removes all but the newest [keep] backups.
  Future<void> prune() async {
    for (final backup in (await backups()).skip(keep)) {
      await deleteFolderQuietly(backup.directory);
    }
  }

  /// Puts [incoming] in place of the data folder. The current data becomes
  /// a backup made before [task] (none when the folder is empty), and its
  /// retained non-database entries follow the live data. On failure the
  /// original files move back and the error is rethrown.
  Future<MacLegacyDataBackup?> switchTo(
    Directory incoming, {
    required MacLegacyDataTask task,
    required bool incomingIsBackup,
  }) async {
    final hadData = !await isEmptyDataFolder(destination);
    if (!await _hasBackupRoot()) await backupRoot.create(recursive: true);
    final at = _clock();
    // Existing timestamp-only backups precede numbered ones. Wall time stays
    // available for display, but clock changes cannot reorder an undo point.
    final sequence = ((await backups()).firstOrNull?.sequence ?? 0) + 1;
    final backup = await _freeBackupDirectory(at, task, sequence);
    final incomingLayout = await _layout(incoming);
    final currentLayout = incomingIsBackup
        ? await _layout(destination)
        : incomingLayout;
    final carryRoots = currentLayout.generation > incomingLayout.generation
        ? currentLayout.roots
        : incomingLayout.roots;
    final carry = hadData
        ? await _onlyIn(destination, notIn: incoming, carryRoots: carryRoots)
        : <String>[];
    final createDirectories = <String>{};
    for (final name in carry) {
      createDirectories.addAll(await safeMacLibraryParents(incoming, name));
    }
    final journalStaging = await destination.parent.createTemp(
      '.$_name.switch-record-',
    );
    try {
      final record = File(p.join(journalStaging.path, 'record.json'));
      await record.writeAsString(
        jsonEncode({
          'task': task.name,
          'incoming': incoming.absolute.path,
          'incomingIsBackup': incomingIsBackup,
          'backup': backup.absolute.path,
          'carry': carry,
          'createDirectories': createDirectories.toList(),
        }),
        flush: true,
      );
      await record.rename(_journal.path);
    } finally {
      await deleteFolderQuietly(journalStaging);
    }
    var movedCurrent = false;
    final carried = <String>[];
    try {
      if (hadData) {
        await onStep?.call('backup');
        await destination.rename(backup.path);
        movedCurrent = true;
      }
      for (final name in createDirectories) {
        await Directory(p.join(incoming.path, name)).create();
      }
      for (final name in carry) {
        await onStep?.call('carry');
        await safeMacLibraryParents(backup, name);
        await safeMacLibraryParents(incoming, name);
        await _move(p.join(backup.path, name), p.join(incoming.path, name));
        carried.add(name);
      }
      await onStep?.call('publish');
      await publishDataFolder(incoming, destination);
    } catch (error, stackTrace) {
      try {
        for (final name in carried.reversed) {
          await safeMacLibraryParents(backup, name);
          await safeMacLibraryParents(incoming, name);
          await _move(p.join(incoming.path, name), p.join(backup.path, name));
        }
        if (movedCurrent) {
          for (final name in createDirectories.toList().reversed) {
            final dir = Directory(p.join(incoming.path, name));
            if (await dir.exists() &&
                await dir.list(followLinks: false).isEmpty) {
              await dir.delete();
            }
          }
          if (await destination.exists()) await destination.delete();
          await backup.rename(destination.path);
        }
        await _journal.delete();
      } catch (_) {
        // The journal stays; the next launch finishes putting it back.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    await _finishPublished();
    return hadData ? MacLegacyDataBackup(backup, task, at, sequence) : null;
  }

  /// Completes or reverses a switch a crash interrupted. Returns true when
  /// the switch is now complete (its request is done).
  Future<bool> recover() async {
    final recordType = await FileSystemEntity.type(
      _journal.path,
      followLinks: false,
    );
    if (recordType == FileSystemEntityType.notFound) return false;
    if (recordType != FileSystemEntityType.file) {
      throw FileSystemException('Unsafe switch journal', _journal.path);
    }
    final Directory incoming;
    final Directory backup;
    final List<String> carry, createDirectories;
    final bool incomingIsBackup;
    try {
      final journal = jsonDecode(await _journal.readAsString()) as Map;
      incoming = Directory(journal['incoming'] as String);
      backup = Directory(journal['backup'] as String);
      carry = [...(journal['carry'] as List).cast<String>()];
      createDirectories = [
        ...(journal['createDirectories'] as List? ?? const []).cast<String>(),
      ];
      incomingIsBackup = journal['incomingIsBackup'] == true;
    } on Object {
      throw FileSystemException(
        'Unreadable switch journal; data left in place',
        _journal.path,
      );
    }
    bool directChild(Directory child, Directory parent) =>
        p.isAbsolute(child.path) &&
        p.normalize(child.path) == child.path &&
        p.equals(child.parent.path, parent.absolute.path);
    if (!directChild(backup, backupRoot) ||
        !_backupName.hasMatch(p.basename(backup.path)) ||
        (incomingIsBackup
            ? !directChild(incoming, backupRoot) ||
                  !_backupName.hasMatch(p.basename(incoming.path))
            : !directChild(incoming, destination.parent) ||
                  !p.basename(incoming.path).startsWith('.$_name.import-'))) {
      throw FileSystemException('Invalid switch journal paths', _journal.path);
    }
    for (final directory in [destination, backupRoot, backup, incoming]) {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw FileSystemException('Unsafe switch directory', directory.path);
      }
    }
    for (final name in [...carry, ...createDirectories]) {
      // Validate even if the operation had not yet reached the first rename.
      await safeMacLibraryParents(backup, name);
      await safeMacLibraryParents(incoming, name);
    }
    final hasCurrent = !await isEmptyDataFolder(destination);
    if (await incoming.exists()) {
      if (!hasCurrent && await backup.exists()) {
        // The data folder was already moved away: finish the switch.
        for (final name in createDirectories) {
          await safeMacLibraryParents(incoming, p.join(name, '.child'));
          await Directory(p.join(incoming.path, name)).create();
        }
        for (final name in carry) {
          await safeMacLibraryParents(backup, name);
          await safeMacLibraryParents(incoming, name);
          final from = p.join(backup.path, name);
          final to = p.join(incoming.path, name);
          if (await _exists(from)) {
            if (await _exists(to)) {
              throw FileSystemException(
                'Conflicting interrupted data move',
                to,
              );
            }
            await _move(from, to);
          } else if (!await _exists(to)) {
            throw FileSystemException('Missing interrupted data move', from);
          }
        }
        await publishDataFolder(incoming, destination);
        await _finishPublished();
        return true;
      }
      if (await backup.exists()) {
        throw FileSystemException(
          'Both replacement and current data exist; switch needs recovery',
          _journal.path,
        );
      }
      // Nothing was moved yet: drop a staging copy, never a backup.
      if (!incomingIsBackup) await deleteFolderQuietly(incoming);
      await _journal.delete();
      return false;
    }
    if (hasCurrent) {
      await _finishPublished();
      return true;
    }
    if (await backup.exists()) {
      for (final name in carry) {
        if (!await _exists(p.join(backup.path, name))) {
          throw FileSystemException(
            'Missing data from interrupted switch',
            name,
          );
        }
      }
      await publishDataFolder(backup, destination);
    }
    await _journal.delete();
    return false;
  }

  // Keep the durable commit record until the request has been consumed.
  // Otherwise a crash here replays a completed sync or loses its undo target.
  Future<void> _finishPublished() async {
    await onStep?.call('committed');
    await clearRequest();
    await _journal.delete();
  }

  Future<Directory> _freeBackupDirectory(
    DateTime at,
    MacLegacyDataTask task,
    int sequence,
  ) async {
    var stamp = at;
    while (true) {
      String two(int value) => value.toString().padLeft(2, '0');
      final name =
          '${stamp.year.toString().padLeft(4, '0')}${two(stamp.month)}'
          '${two(stamp.day)}-${two(stamp.hour)}${two(stamp.minute)}'
          '${two(stamp.second)}-'
          '${stamp.millisecond.toString().padLeft(3, '0')}-before-${task.name}-r$sequence';
      final directory = Directory(p.join(backupRoot.path, name));
      if (!await _exists(directory.path)) return directory;
      stamp = stamp.add(const Duration(milliseconds: 1));
    }
  }

  /// Remember the original top-level policy before retaining databases creates
  /// new directories in staging. On undo and redo their non-database contents
  /// still follow the live profile, while database bytes come from the snapshot.
  static Future<Set<String>> oneSidedDirectories(
    Directory a,
    Directory b,
  ) async {
    final result = <String>{};
    for (final (root, other) in [(a, b), (b, a)]) {
      await for (final entry in root.list(followLinks: false)) {
        if (entry is! Directory) continue;
        final name = p.basename(entry.path);
        if (!await _exists(p.join(other.path, name))) result.add(name);
      }
    }
    return result;
  }

  /// Two consecutive syncs can have different one-sided folders. Undo/redo
  /// uses the newest layout of the pair, even when wall time moves backwards.
  Future<int> nextLibraryGeneration() async {
    final active = (await _layout(destination)).generation;
    final previous = (await backups()).firstOrNull?.sequence ?? 0;
    return (active > previous ? active : previous) + 1;
  }

  static Future<({int generation, Set<String> roots})> _layout(
    Directory root,
  ) async {
    const none = (generation: 0, roots: <String>{});
    final file = File(p.join(root.path, AdjacentAppDataMigration.markerName));
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return none;
    }
    Object? marker;
    try {
      marker = jsonDecode(await file.readAsString());
    } on FormatException {
      return none;
    }
    if (marker is! Map ||
        marker[carryGenerationKey] is! int ||
        marker[carryRootsKey] is! List) {
      return none;
    }
    return (
      generation: marker[carryGenerationKey] as int,
      roots: {
        for (final name in marker[carryRootsKey] as List)
          if (name is String) name,
      },
    );
  }

  static Future<List<String>> _onlyIn(
    Directory root, {
    required Directory notIn,
    required Set<String> carryRoots,
  }) async {
    final libraries = await MacSyncLibraries.scan(root);
    final result = <String>[];
    Future<void> consider(FileSystemEntity entity, String relative) async {
      if (libraries.members.contains(relative)) return;
      final primary = entity is Directory
          ? null
          : MacSyncLibraries.possibleBareHivePrimary(relative);
      if (primary != null) {
        if (await _exists(p.join(notIn.path, primary)) ||
            await _exists(p.join(notIn.path, '${primary}c'))) {
          return;
        }
      }
      final other = await FileSystemEntity.type(
        p.join(notIn.path, relative),
        followLinks: false,
      );
      if (other == FileSystemEntityType.notFound &&
          !libraries.parents.contains(relative)) {
        result.add(relative);
        return;
      }
      if (entity is Directory &&
          (other == FileSystemEntityType.notFound ||
              other == FileSystemEntityType.directory)) {
        await for (final child in entity.list(followLinks: false)) {
          await consider(child, p.join(relative, p.basename(child.path)));
        }
      }
    }

    await for (final entry in root.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if (name == AdjacentAppDataMigration.markerName || name == _finderFile) {
        continue;
      }
      if (carryRoots.contains(name) ||
          !await _exists(p.join(notIn.path, name))) {
        await consider(entry, name);
      }
    }
    return result..sort();
  }

  static Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) !=
      FileSystemEntityType.notFound;

  static Future<void> _move(String from, String to) async {
    if (await _exists(to)) {
      throw FileSystemException('Data move target already exists', to);
    }
    switch (await FileSystemEntity.type(from, followLinks: false)) {
      case FileSystemEntityType.directory:
        await Directory(from).rename(to);
      case FileSystemEntityType.link:
        await Link(from).rename(to);
      case FileSystemEntityType.notFound:
        throw FileSystemException('Entry to move is missing', from);
      default:
        await File(from).rename(to);
    }
  }
}

/// Finder writes this into any folder it shows; it is not user data.
const _finderFile = '.DS_Store';

/// Missing, or holding nothing but Finder files.
Future<bool> isEmptyDataFolder(Directory directory) async {
  if (!await directory.exists()) return true;
  await for (final entry in directory.list(followLinks: false)) {
    if (p.basename(entry.path) != _finderFile) return false;
  }
  return true;
}

/// Renames [incoming] into [destination], which must be missing or empty.
/// The destination is removed non-recursively, so anything that appeared in
/// it meanwhile stops the rename instead of being deleted.
Future<void> publishDataFolder(
  Directory incoming,
  Directory destination,
) async {
  if (await destination.exists()) {
    final finder = File(p.join(destination.path, _finderFile));
    if (await finder.exists()) await finder.delete();
    await destination.delete();
  }
  try {
    await incoming.rename(destination.path);
  } catch (_) {
    await destination.create(recursive: true);
    rethrow;
  }
}

/// Staging folders and old backups are this feature's own; one that cannot
/// be removed now is removed by a later attempt.
Future<void> deleteFolderQuietly(Directory directory) async {
  try {
    if (await directory.exists()) await directory.delete(recursive: true);
  } on FileSystemException {
    // Left for a later attempt.
  }
}
