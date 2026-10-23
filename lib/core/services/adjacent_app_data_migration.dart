import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_sha256.dart';

typedef CompatibilityDirectoryCreator =
    Future<void> Function(Directory legacy, Directory destination);

class AdjacentAppDataException extends FileSystemException {
  AdjacentAppDataException(
    FileSystemException cause, {
    required this.legacyPath,
    required this.destinationPath,
  }) : super(cause.message, cause.path, cause.osError);

  final String legacyPath, destinationPath;
}

/// Moves only this application's support directory, before any database opens.
/// A verified, independent backup remains beside the executable. The old name
/// becomes a junction so saved absolute paths and Python environments still work.
class AdjacentAppDataMigration {
  AdjacentAppDataMigration({
    required this.legacy,
    required this.destination,
    CompatibilityDirectoryCreator? createCompatibilityDirectory,
    this.beforeCommit,
    this.onPhase,
  }) : _createCompatibilityDirectory =
           createCompatibilityDirectory ?? createWindowsCompatibilityDirectory;

  static const markerName = '.studio-data-location.json';
  final Directory legacy;
  final Directory destination;
  final CompatibilityDirectoryCreator _createCompatibilityDirectory;
  final Future<void> Function()? beforeCommit;
  final void Function(String)? onPhase;

  Future<Directory> prepare() async {
    try {
      return await _prepare();
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AdjacentAppDataException(
          error,
          legacyPath: legacy.absolute.path,
          destinationPath: destination.absolute.path,
        ),
        stackTrace,
      );
    }
  }

  Future<Directory> _prepare() async {
    final oldPath = p.normalize(legacy.absolute.path);
    final newPath = p.normalize(destination.absolute.path);
    if (p.equals(oldPath, newPath) ||
        p.isWithin(oldPath, newPath) ||
        p.isWithin(newPath, oldPath)) {
      throw const FileSystemException('Application data paths overlap');
    }
    await destination.parent.create(recursive: true);
    final lock = await File(
      p.join(destination.parent.path, '.studio-data-migration.lock'),
    ).open(mode: FileMode.append);
    await lock.lock(FileLock.blockingExclusive);
    try {
      return await _prepareLocked();
    } finally {
      await lock.close();
    }
  }

  Future<Directory> _prepareLocked() async {
    if (await FileSystemEntity.type(destination.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FileSystemException(
        'Adjacent application data must be a real directory',
      );
    }
    final oldType = await FileSystemEntity.type(
      legacy.path,
      followLinks: false,
    );
    if (oldType == FileSystemEntityType.link) {
      if (!await destination.exists() ||
          !p.equals(
            await legacy.resolveSymbolicLinks(),
            await destination.resolveSymbolicLinks(),
          )) {
        throw const FileSystemException(
          'Legacy application data points to another installation',
        );
      }
      return destination;
    }
    if (oldType != FileSystemEntityType.directory &&
        oldType != FileSystemEntityType.notFound) {
      throw const FileSystemException('Legacy data path is not a directory');
    }
    final hasLegacy =
        await legacy.exists() && !await legacy.list(followLinks: false).isEmpty;
    if (await destination.exists() &&
        !await destination.list(followLinks: false).isEmpty) {
      if (hasLegacy) {
        if (await _recoverPluginSplit()) return destination;
        throw const FileSystemException(
          'Both application data directories contain data; refusing to merge',
        );
      }
      await _ensureCompatibilityDirectory();
      return destination;
    }
    if (!hasLegacy) {
      await destination.create(recursive: true);
      await _writeMarker(null);
      await _ensureCompatibilityDirectory();
      return destination;
    }

    // All mutable state is copied while unopened. No source file is overwritten.
    // A second complete copy protects drafts/settings even after the C: copy is
    // removed. The two copies do not share file hardlinks.
    final backup = await destination.parent.createTemp('.studio-data-backup-');
    onPhase?.call('Reading and hashing original data');
    final snapshot = await _snapshot(legacy);
    onPhase?.call('Creating and verifying independent backup');
    await _copyVerified(legacy, backup, snapshot);
    final staging = await destination.parent.createTemp(
      '.studio-data-staging-',
    );
    onPhase?.call('Creating and verifying adjacent application data');
    await _copyVerified(backup, staging, snapshot);
    await beforeCommit?.call();
    onPhase?.call('Checking original data has not changed');
    await _verifySnapshot(legacy, snapshot);

    // Rename on the source volume first: locked files stop the operation while
    // the original is intact. Only publish a fully verified destination.
    final retired = Directory(
      p.join(
        legacy.parent.path,
        '.nai_launcher-migrated-${p.basename(backup.path)}',
      ),
    );
    await legacy.rename(retired.path);
    onPhase?.call('Switching data directory and compatibility junction');
    var published = false;
    try {
      if (await destination.exists()) {
        // Nonrecursive: an unexpectedly nonempty destination is never removed.
        await destination.delete();
      }
      await staging.rename(destination.path);
      published = true;
      for (final entry in snapshot.entries) {
        if (entry.value.bytes != -2) continue;
        final link = Link(p.join(destination.path, entry.key));
        await link.delete();
        await createWindowsCompatibilityDirectory(
          Directory(link.path),
          Directory(p.join(destination.path, entry.value.digest)),
        );
      }
      await _createCompatibilityDirectory(legacy, destination);
      if (!p.equals(
        await legacy.resolveSymbolicLinks(),
        await destination.resolveSymbolicLinks(),
      )) {
        throw const FileSystemException(
          'Compatibility directory verification failed',
        );
      }
      await _writeMarker(backup);
    } catch (_) {
      if (await FileSystemEntity.type(legacy.path, followLinks: false) ==
              FileSystemEntityType.link &&
          p.equals(
            await legacy.resolveSymbolicLinks(),
            await destination.resolveSymbolicLinks(),
          )) {
        await Link(legacy.path).delete();
      }
      if (published) await destination.rename(staging.path);
      if (!await legacy.exists()) await retired.rename(legacy.path);
      rethrow;
    }

    // This exact, generated sibling is the only recursive deletion target.
    // Check its physical parent and content again; never follow links.
    final expectedParent = await legacy.parent.resolveSymbolicLinks();
    if (await FileSystemEntity.type(retired.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        !p.equals(
          await retired.parent.resolveSymbolicLinks(),
          expectedParent,
        ) ||
        p.basename(retired.path) !=
            '.nai_launcher-migrated-${p.basename(backup.path)}') {
      throw const FileSystemException(
        'Retired data directory boundary changed',
      );
    }
    await _verifySnapshot(retired, snapshot, originalRoot: legacy);
    onPhase?.call('Removing verified original copy from system drive');
    await retired.delete(recursive: true);
    return destination;
  }

  /// Fresh profiles need the same alias as migrated profiles: native plugins
  /// continue to resolve the historical Windows path independently of Dart.
  Future<void> _ensureCompatibilityDirectory() async {
    final type = await FileSystemEntity.type(legacy.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      if (await _isOurCompatibilityDirectory()) return;
      throw const FileSystemException(
        'Legacy application data points to another installation',
      );
    }
    if (type != FileSystemEntityType.directory &&
        type != FileSystemEntityType.notFound) {
      throw const FileSystemException('Legacy data path is not a directory');
    }
    final existed = type == FileSystemEntityType.directory;
    if (existed) await legacy.delete(); // Nonrecursive; never removes data.
    await legacy.parent.create(recursive: true);
    try {
      await _createCompatibilityDirectory(legacy, destination);
      if (!await _isOurCompatibilityDirectory()) {
        throw const FileSystemException(
          'Compatibility directory verification failed',
        );
      }
    } catch (_) {
      if (await _isOurCompatibilityDirectory()) {
        await Link(legacy.path).delete();
      }
      if (existed && !await legacy.exists()) await legacy.create();
      rethrow;
    }
  }

  Future<bool> _isOurCompatibilityDirectory() async =>
      await FileSystemEntity.type(legacy.path, followLinks: false) ==
          FileSystemEntityType.link &&
      await legacy.exists() &&
      p.equals(
        await legacy.resolveSymbolicLinks(),
        await destination.resolveSymbolicLinks(),
      );

  /// Repair only the missing-alias bug in a recorded fresh profile. This is not
  /// a general profile merge: unknown files, links, untrusted markers and any
  /// differing same-name file keep both directories intact and stop startup.
  Future<bool> _recoverPluginSplit() async {
    bool pluginFile(String name) =>
        name == 'flutter_secure_storage.dat' ||
        name == 'shared_preferences.json' ||
        (name.endsWith('.secure') && name.length > '.secure'.length);
    final marker = File(p.join(destination.path, markerName));
    if (await FileSystemEntity.type(marker.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return false;
    }
    final markerText = await marker.readAsString();
    final Object? decoded;
    try {
      decoded = jsonDecode(markerText);
    } on FormatException {
      return false;
    }
    if (decoded is! Map ||
        decoded['schema'] != 1 ||
        decoded['layout'] != 'executable-adjacent' ||
        !decoded.containsKey('backup') ||
        decoded['backup'] != null ||
        decoded['legacy'] is! String ||
        !p.equals(
          p.normalize(decoded['legacy'] as String),
          p.normalize(legacy.absolute.path),
        )) {
      return false;
    }
    // Inspect the root first, without traversing arbitrary user directories.
    await for (final entry in legacy.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if (await FileSystemEntity.type(entry.path, followLinks: false) !=
              FileSystemEntityType.file ||
          !pluginFile(name)) {
        return false;
      }
    }
    final snapshot = await _snapshot(legacy);
    if (snapshot.entries.any(
      (entry) => entry.value.bytes < 0 || !pluginFile(entry.key),
    )) {
      return false;
    }
    final missing = <String>{};
    Future<bool> targetsUnchanged() async {
      if (await marker.readAsString() != markerText) return false;
      for (final entry in snapshot.entries) {
        final file = File(p.join(destination.path, entry.key));
        final type = await FileSystemEntity.type(file.path, followLinks: false);
        if (type == FileSystemEntityType.notFound &&
            missing.contains(entry.key)) {
          continue;
        }
        if (type != FileSystemEntityType.file ||
            missing.contains(entry.key) ||
            await file.length() != entry.value.bytes ||
            await fileSha256(file) != entry.value.digest) {
          return false;
        }
      }
      return true;
    }

    for (final entry in snapshot.entries) {
      final file = File(p.join(destination.path, entry.key));
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        missing.add(entry.key);
      }
    }
    if (!await targetsUnchanged()) return false;
    final backup = await destination.parent.createTemp('.studio-data-backup-');
    onPhase?.call('Backing up split plugin data');
    await _copyVerified(legacy, backup, snapshot);
    await beforeCommit?.call();
    await _verifySnapshot(legacy, snapshot);
    if (!await targetsUnchanged()) {
      throw const FileSystemException(
        'Application data changed during recovery; originals preserved',
      );
    }
    final retired = Directory(
      p.join(
        legacy.parent.path,
        '.nai_launcher-recovered-${p.basename(backup.path)}',
      ),
    );
    await legacy.rename(retired.path);
    final created = <String>{};
    try {
      for (final name in missing) {
        final file = File(p.join(destination.path, name));
        final bytes = await File(p.join(backup.path, name)).readAsBytes();
        await file.create(exclusive: true); // Never overwrite an existing file.
        created.add(name);
        final handle = await file.open(mode: FileMode.append);
        try {
          await handle.lock(FileLock.exclusive);
          if (await handle.length() != 0) {
            throw const FileSystemException(
              'Application data changed during recovery; originals preserved',
            );
          }
          await handle.writeFrom(bytes);
          await handle.flush();
        } finally {
          await handle.close();
        }
        await file.setLastModified(snapshot[name]!.modified);
        if (await fileSha256(file) != snapshot[name]!.digest) {
          throw const FileSystemException(
            'Recovered plugin data failed verification',
          );
        }
      }
      await _verifySnapshot(retired, snapshot);
      for (final entry in snapshot.entries) {
        final file = File(p.join(destination.path, entry.key));
        if (await FileSystemEntity.type(file.path, followLinks: false) !=
                FileSystemEntityType.file ||
            await fileSha256(file) != entry.value.digest) {
          throw const FileSystemException(
            'Application data changed during recovery; originals preserved',
          );
        }
      }
      await _ensureCompatibilityDirectory();
      await _writeMarker(backup, recoveredLegacy: retired);
    } catch (_) {
      try {
        if (await _isOurCompatibilityDirectory()) {
          await Link(legacy.path).delete();
        }
        for (final name in created) {
          final file = File(p.join(destination.path, name));
          if (await FileSystemEntity.type(file.path, followLinks: false) ==
                  FileSystemEntityType.file &&
              await fileSha256(file) == snapshot[name]!.digest) {
            await file.delete();
          }
        }
      } finally {
        if (await FileSystemEntity.type(legacy.path, followLinks: false) ==
            FileSystemEntityType.notFound) {
          await retired.rename(legacy.path);
        }
      }
      rethrow;
    }
    return true;
  }

  Future<void> _writeMarker(
    Directory? backup, {
    Directory? recoveredLegacy,
  }) async {
    await File(p.join(destination.path, markerName)).writeAsString(
      jsonEncode({
        'schema': 1,
        'layout': 'executable-adjacent',
        'legacy': legacy.absolute.path,
        'backup': backup?.absolute.path,
        if (recoveredLegacy != null)
          'recovered_legacy': recoveredLegacy.absolute.path,
      }),
      flush: true,
    );
  }

  Future<Map<String, _DataFile>> _snapshot(
    Directory root, {
    Directory? originalRoot,
  }) async {
    final result = <String, _DataFile>{};
    final physicalRoot = await root.resolveSymbolicLinks();
    final physicalOriginal = await originalRoot?.resolveSymbolicLinks();
    await for (final entry in root.list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entry.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        final resolved = await Directory(entry.path).resolveSymbolicLinks();
        final String linkRoot;
        if (p.isWithin(physicalRoot, resolved)) {
          linkRoot = physicalRoot;
        } else if (physicalOriginal != null &&
            p.isWithin(physicalOriginal, resolved)) {
          linkRoot = physicalOriginal;
        } else {
          throw FileSystemException(
            'Application data contains an external link',
            entry.path,
          );
        }
        if (await FileSystemEntity.type(entry.path) !=
            FileSystemEntityType.directory) {
          throw FileSystemException(
            'Application data contains a file link',
            entry.path,
          );
        }
        result[p.relative(entry.path, from: root.path)] = _DataFile(
          -2,
          DateTime.fromMillisecondsSinceEpoch(0),
          p.relative(resolved, from: linkRoot),
        );
        continue;
      }
      if (type == FileSystemEntityType.directory) {
        result[p.relative(entry.path, from: root.path)] = _DataFile(
          -1,
          DateTime.fromMillisecondsSinceEpoch(0),
          '',
        );
        continue;
      }
      if (type != FileSystemEntityType.file) {
        throw FileSystemException(
          'Unsupported application data entry',
          entry.path,
        );
      }
      final file = File(entry.path);
      final stat = await file.stat();
      result[p.relative(file.path, from: root.path)] = _DataFile(
        stat.size,
        stat.modified,
        await fileSha256(file),
      );
    }
    return result;
  }

  Future<void> _copyVerified(
    Directory source,
    Directory target,
    Map<String, _DataFile> snapshot,
  ) async {
    final links = <MapEntry<String, _DataFile>>[];
    for (final entry in snapshot.entries) {
      if (entry.value.bytes == -2) {
        links.add(entry);
        continue;
      }
      if (entry.value.bytes == -1) {
        await Directory(p.join(target.path, entry.key)).create(recursive: true);
        continue;
      }
      final file = File(p.join(target.path, entry.key));
      await file.parent.create(recursive: true);
      await File(p.join(source.path, entry.key)).copy(file.path);
      await file.setLastModified(entry.value.modified);
      if (await file.length() != entry.value.bytes ||
          await fileSha256(file) != entry.value.digest) {
        throw FileSystemException(
          'Application data copy verification failed',
          file.path,
        );
      }
    }
    for (final link in links) {
      await createWindowsCompatibilityDirectory(
        Directory(p.join(target.path, link.key)),
        Directory(p.join(target.path, link.value.digest)),
      );
    }
  }

  Future<void> _verifySnapshot(
    Directory root,
    Map<String, _DataFile> expected, {
    Directory? originalRoot,
  }) async {
    final current = await _snapshot(root, originalRoot: originalRoot);
    if (current.length != expected.length ||
        expected.entries.any((entry) => current[entry.key] != entry.value)) {
      throw const FileSystemException(
        'Application data changed during migration; originals preserved',
      );
    }
  }

  static Future<void> createWindowsCompatibilityDirectory(
    Directory legacy,
    Directory destination,
  ) async {
    final result = await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r"$ErrorActionPreference='Stop'; New-Item -ItemType Junction -Path $env:STUDIO_LEGACY_DATA -Target $env:STUDIO_ADJACENT_DATA | Out-Null",
      ],
      environment: {
        'STUDIO_LEGACY_DATA': legacy.absolute.path,
        'STUDIO_ADJACENT_DATA': destination.absolute.path,
      },
    );
    if (result.exitCode != 0) {
      throw const FileSystemException(
        'Cannot create legacy data compatibility directory',
      );
    }
  }
}

class _DataFile {
  const _DataFile(this.bytes, this.modified, this.digest);
  final int bytes;
  final DateTime modified;
  final String digest;

  @override
  bool operator ==(Object other) =>
      other is _DataFile &&
      bytes == other.bytes &&
      modified == other.modified &&
      digest == other.digest;

  @override
  int get hashCode => Object.hash(bytes, modified, digest);
}
