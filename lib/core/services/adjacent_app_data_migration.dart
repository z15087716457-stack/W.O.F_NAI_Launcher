import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_sha256.dart';

typedef CompatibilityDirectoryCreator =
    Future<void> Function(Directory legacy, Directory destination);

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
        throw const FileSystemException(
          'Both application data directories contain data; refusing to merge',
        );
      }
      return destination;
    }
    if (!hasLegacy) {
      await destination.create(recursive: true);
      await _writeMarker(null);
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

  Future<void> _writeMarker(Directory? backup) async {
    await File(p.join(destination.path, markerName)).writeAsString(
      jsonEncode({
        'schema': 1,
        'layout': 'executable-adjacent',
        'legacy': legacy.absolute.path,
        'backup': backup?.absolute.path,
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
