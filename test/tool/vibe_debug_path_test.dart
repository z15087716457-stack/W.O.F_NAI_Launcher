import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/vibe/vibe_analyzer.dart' as analyzer;

class _Writes {
  _Writes(this.directoryExists);
  final bool directoryExists;
  final created = <String>[];
  final files = <String, List<int>>{};
  File file(String path) => _File(path, this);
  Directory directory(String path) => _Directory(path, this);
}

class _File implements File {
  _File(this.path, this.owner);
  @override
  final String path;
  final _Writes owner;
  @override
  Directory get parent => owner.directory(p.dirname(path));
  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    owner.files[path] = List.of(bytes);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Directory implements Directory {
  _Directory(this.path, this.owner);
  @override
  final String path;
  final _Writes owner;
  @override
  Directory get parent => owner.directory(p.dirname(path));
  @override
  Future<bool> exists() async =>
      owner.directoryExists || owner.created.contains(path);
  @override
  Future<Directory> create({bool recursive = false}) async {
    owner.created.add(path);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final directoryExists in [false, true]) {
    test(
      'debug thumbnails have separate filenames with existing directory=$directoryExists',
      () async {
        final writes = _Writes(directoryExists);
        await IOOverrides.runZoned(
          () async {
            await analyzer.saveDebugFile(
              'thumbnail_bundle_0.jpg',
              Uint8List.fromList([1, 2, 3]),
            );
            await analyzer.saveDebugFile(
              'thumbnail_bundle_1.jpg',
              Uint8List.fromList([4, 5, 6]),
            );
          },
          createFile: writes.file,
          createDirectory: writes.directory,
        );
        expect(writes.files, hasLength(2));
        expect(
          {
            for (final entry in writes.files.entries)
              p.basename(entry.key): entry.value,
          },
          {
            'thumbnail_bundle_0.jpg': [1, 2, 3],
            'thumbnail_bundle_1.jpg': [4, 5, 6],
          },
        );
        expect(
          writes.files.keys.every(
            (path) => p.basename(p.dirname(path)) == 'debug_output',
          ),
          isTrue,
        );
        expect(writes.created, hasLength(directoryExists ? 0 : 1));
      },
    );
  }
}
