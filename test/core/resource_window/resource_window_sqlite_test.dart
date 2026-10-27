import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart';

Future<(int, bool)> _readInIndependentIsolate(String path) => Isolate.run(() {
  sqfliteFfiInit();
  final reader = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    final count =
        reader.select('SELECT COUNT(*) AS n FROM images').single['n'] as int;
    var refusedWrite = false;
    try {
      reader.execute("INSERT INTO images(path) VALUES('must-not-write')");
    } on SqliteException {
      refusedWrite = true;
    }
    return (count, refusedWrite);
  } finally {
    reader.dispose();
  }
});

void main() {
  test(
    'independent read-only isolate sees committed WAL data, not pending writes',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'resource_sqlite_',
      );
      final path = '${directory.path}/gallery.db';
      final writer = sqlite3.open(path);
      try {
        expect(
          writer.select('PRAGMA journal_mode=WAL').single.values.single,
          'wal',
        );
        writer.execute(
          'CREATE TABLE images(id INTEGER PRIMARY KEY, path TEXT NOT NULL)',
        );
        writer.execute("INSERT INTO images(path) VALUES('committed')");
        writer.execute('BEGIN IMMEDIATE');
        writer.execute("INSERT INTO images(path) VALUES('pending')");
        expect(await _readInIndependentIsolate(path), (1, true));
        writer.execute('COMMIT');
        expect(await _readInIndependentIsolate(path), (2, true));
      } finally {
        writer.dispose();
        await directory.delete(recursive: true);
      }
    },
  );
}
