import 'dart:async';
import 'dart:io';

// Flutter's test clock dependency; no additional runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/gallery/gallery_file_changes.dart';

void main() {
  test('focus changes without file events perform no work', () {
    fakeAsync((clock) {
      final applied = <GalleryFileChanges>[];
      final monitor = GalleryFileMonitor(
        loadRoots: () async => [],
        rootsChanged: const Stream.empty(),
        apply: (batch) async => applied.add(batch),
        onError: (e, s) => fail('$e'),
      );
      monitor.start();
      clock.flushMicrotasks();
      for (var i = 0; i < 20; i++) {
        monitor.setActive(false);
        monitor.setActive(true);
        clock.elapse(const Duration(seconds: 6));
      }
      expect(applied, isEmpty);
      monitor.dispose();
      clock.flushMicrotasks();
    });
  });

  test('background events coalesce, in-flight events form one later batch', () {
    fakeAsync((clock) {
      final events = StreamController<FileSystemEvent>.broadcast();
      final applied = <GalleryFileChanges>[];
      final first = Completer<void>();
      final monitor = GalleryFileMonitor(
        loadRoots: () async => [Directory('C:/library')],
        rootsChanged: const Stream.empty(),
        watch: (_) => events.stream,
        apply: (batch) async {
          applied.add(batch);
          if (applied.length == 1) await first.future;
        },
        onError: (e, s) => fail('$e'),
      );
      monitor.start();
      clock.flushMicrotasks();
      events.add(FileSystemCreateEvent('C:/library/a.png', false));
      events.add(FileSystemModifyEvent('C:/library/a.png', false, true));
      events.add(FileSystemCreateEvent('C:/library/.thumbs/a.png', false));
      events.add(
        FileSystemCreateEvent('C:/library/.gallery_categories.json', false),
      );
      clock.elapse(const Duration(seconds: 5));
      expect(applied, isEmpty);
      monitor.setActive(true);
      clock.elapse(const Duration(milliseconds: 500));
      expect(applied.single.files, hasLength(1));
      expect(applied.single.files.single, endsWith('a.png'));
      events.add(FileSystemDeleteEvent('C:/library/b.png', false));
      clock.elapse(const Duration(seconds: 2));
      expect(applied, hasLength(1));
      first.complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(milliseconds: 500));
      expect(applied, hasLength(2));
      expect(applied.last.files.single, endsWith('b.png'));
      monitor.dispose();
      events.close();
      clock.flushMicrotasks();
    });
  });

  test('all roots subscribe and config changes cancel removed roots', () async {
    final changes = StreamController<void>.broadcast();
    final roots = <Directory>[Directory('C:/main'), Directory('D:/extra')];
    final streams = <String, StreamController<FileSystemEvent>>{};
    final cancelled = <String>[];
    final monitor = GalleryFileMonitor(
      loadRoots: () async => roots,
      rootsChanged: changes.stream,
      watch: (root) => (streams[root.path] = StreamController<FileSystemEvent>(
        onCancel: () {
          cancelled.add(root.path);
        },
      )).stream,
      apply: (_) async {},
      onError: (e, s) => fail('$e'),
    );
    await monitor.start();
    expect(streams, hasLength(2));
    final removed = roots.removeLast();
    changes.add(null);
    await monitor.updateRoots();
    expect(cancelled, [removed.path]);
    await monitor.dispose();
    await changes.close();
    expect(cancelled, hasLength(2));
  });

  test('native recursive watcher receives nested image changes', () async {
    final root = await Directory.systemTemp.createTemp('gallery_events_');
    final sub = await Directory('${root.path}/nested').create();
    final received = Completer<GalleryFileChanges>();
    final monitor = GalleryFileMonitor(
      loadRoots: () async => [root],
      rootsChanged: const Stream.empty(),
      apply: (batch) async {
        if (!received.isCompleted) received.complete(batch);
      },
      onError: (e, s) {
        if (!received.isCompleted) received.completeError(e, s);
      },
      delay: const Duration(milliseconds: 30),
    );
    try {
      await monitor.start();
      monitor.setActive(true);
      final file = await File('${sub.path}/new.png').writeAsString('test');
      final batch = await received.future.timeout(const Duration(seconds: 5));
      expect(
        batch.files.map(galleryFilePathKey),
        contains(galleryFilePathKey(file.path)),
      );
    } finally {
      await monitor.dispose();
      await root.delete(recursive: true);
    }
  });

  test('native directory rename carries old and new subtree paths', () async {
    final root = await Directory.systemTemp.createTemp('gallery_dir_events_');
    final old = await Directory('${root.path}/old').create();
    final next = normalizeGalleryFilePath('${root.path}/new');
    final received = Completer<GalleryFileChanges>();
    final monitor = GalleryFileMonitor(
      loadRoots: () async => [root],
      rootsChanged: const Stream.empty(),
      apply: (batch) async {
        if (!received.isCompleted) received.complete(batch);
      },
      onError: (e, s) {
        if (!received.isCompleted) received.completeError(e, s);
      },
      delay: const Duration(milliseconds: 30),
    );
    try {
      await monitor.start();
      await old.rename(next);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      monitor.setActive(true);
      final batch = await received.future.timeout(const Duration(seconds: 5));
      expect(batch.directoryMoves[normalizeGalleryFilePath(old.path)], next);
      expect(
        batch.directories,
        containsAll([normalizeGalleryFilePath(old.path), next]),
      );
    } finally {
      await monitor.dispose();
      await root.delete(recursive: true);
    }
  });
}
