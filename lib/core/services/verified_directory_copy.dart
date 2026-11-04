import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_sha256.dart';

/// Creates [link] as an alias of the directory [target]. Both lie inside the
/// same application data root.
typedef DirectoryLinkCreator =
    Future<void> Function(Directory link, Directory target);

/// One entry of an application data snapshot: a file (size, modification
/// time and SHA-256), a directory, or a directory link inside the root.
class DataSnapshotEntry {
  const DataSnapshotEntry.file(this.bytes, this.modified, this.digest);

  DataSnapshotEntry.directory()
    : bytes = -1,
      modified = DateTime.fromMillisecondsSinceEpoch(0),
      digest = '';

  /// [target] is relative to the root the link resolves into.
  DataSnapshotEntry.link(String target)
    : bytes = -2,
      modified = DateTime.fromMillisecondsSinceEpoch(0),
      digest = target;

  final int bytes;
  final DateTime modified;

  /// SHA-256 for files, the root-relative target for links.
  final String digest;

  bool get isDirectory => bytes == -1;
  bool get isLink => bytes == -2;
  bool get isFile => bytes >= 0;

  @override
  bool operator ==(Object other) =>
      other is DataSnapshotEntry &&
      bytes == other.bytes &&
      modified == other.modified &&
      digest == other.digest;

  @override
  int get hashCode => Object.hash(bytes, modified, digest);
}

/// Root-relative path to entry. Never follows links: a directory link is
/// recorded as an alias and may only point inside [root] (or inside
/// [originalRoot], for a copy whose aliases still point at the original).
/// Links outside the root are rejected so no external data is pulled into a
/// copy. Links to files are rejected too unless [fileLinks] is set (macOS:
/// Python environments link their interpreter files).
Future<Map<String, DataSnapshotEntry>> snapshotDirectory(
  Directory root, {
  Directory? originalRoot,
  bool fileLinks = false,
}) async {
  final result = <String, DataSnapshotEntry>{};
  final physicalRoot = await root.resolveSymbolicLinks();
  final physicalOriginal = await originalRoot?.resolveSymbolicLinks();
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    final type = await FileSystemEntity.type(entry.path, followLinks: false);
    final relative = p.relative(entry.path, from: root.path);
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
      final targetType = await FileSystemEntity.type(entry.path);
      if (targetType != FileSystemEntityType.directory &&
          !(fileLinks && targetType == FileSystemEntityType.file)) {
        throw FileSystemException(
          'Application data contains a file link',
          entry.path,
        );
      }
      result[relative] = DataSnapshotEntry.link(
        p.relative(resolved, from: linkRoot),
      );
      continue;
    }
    if (type == FileSystemEntityType.directory) {
      result[relative] = DataSnapshotEntry.directory();
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
    result[relative] = DataSnapshotEntry.file(
      stat.size,
      stat.modified,
      await fileSha256(file),
    );
  }
  return result;
}

/// Copies every snapshot entry from [source] into [target], keeping
/// modification times, and checks each copied file against the snapshot.
/// Directory aliases are recreated last with [createLink].
Future<void> copySnapshot(
  Directory source,
  Directory target,
  Map<String, DataSnapshotEntry> snapshot, {
  required DirectoryLinkCreator createLink,
}) async {
  final links = <MapEntry<String, DataSnapshotEntry>>[];
  for (final entry in snapshot.entries) {
    if (entry.value.isLink) {
      links.add(entry);
      continue;
    }
    if (entry.value.isDirectory) {
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
    await createLink(
      Directory(p.join(target.path, link.key)),
      Directory(p.join(target.path, link.value.digest)),
    );
  }
}

/// Throws when [root] no longer matches [expected], for example because the
/// application that owns it wrote to it while it was being copied.
Future<void> verifySnapshot(
  Directory root,
  Map<String, DataSnapshotEntry> expected, {
  Directory? originalRoot,
  bool fileLinks = false,
}) async {
  final current = await snapshotDirectory(
    root,
    originalRoot: originalRoot,
    fileLinks: fileLinks,
  );
  if (current.length != expected.length ||
      expected.entries.any((entry) => current[entry.key] != entry.value)) {
    throw const ApplicationDataChangedException();
  }
}

/// The source changed while it was being copied; the copy must not be used.
class ApplicationDataChangedException extends FileSystemException {
  const ApplicationDataChangedException()
    : super('Application data changed during migration; originals preserved');
}

/// Relative symbolic link (to a folder or a file), so an alias keeps working
/// after its root moves.
Future<void> createRelativeLink(Directory link, Directory target) async {
  await Link(
    link.path,
  ).create(p.relative(target.path, from: p.dirname(link.path)));
}
