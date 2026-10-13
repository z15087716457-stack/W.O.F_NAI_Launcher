import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_backend.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';

ImageDetailData source(String key) => GeneratedImageDetailData(
  imageBytes: Uint8List(0),
  id: key,
  metadata: NaiImageMetadata(prompt: key),
);

ImageViewerBackend backend({
  int count = 300,
  int initial = 100,
  Future<NaiImageMetadata?> Function(ImageDetailData)? metadata,
  Future<bool> Function(String)? delete,
  Future<void> Function(String)? restore,
}) => ImageViewerBackend(
  keys: List.generate(count, (i) => '$i'),
  initialKey: '$initial',
  load: (keys) async => keys.map(source).toList(),
  readMetadata: metadata ?? (image) async => image.metadata,
  deleteImage: delete,
  restoreImage: restore,
);

void main() {
  test('initial window retains position and whole range count', () async {
    final data = backend();
    addTearDown(data.dispose);
    await data.initialize();
    expect(
      data.sources.map((i) => i.identifier),
      List.generate(121, (i) => '${i + 40}'),
    );
    expect(data.position, 100);
    expect(data.total, 300);
    expect(data.metadata?.prompt, '100');
  });

  test('forward and backward extension keep the current identity', () async {
    final data = backend();
    addTearDown(data.dispose);
    await data.initialize();
    await data.loadMore(forward: true);
    await data.loadMore(forward: false);
    expect(data.currentKey, '100');
    expect(data.sources.first.identifier, '0');
    expect(data.sources.last.identifier, '220');
  });

  test('step past loaded edge reads the next window', () async {
    final data = backend(initial: 0);
    addTearDown(data.dispose);
    await data.initialize();
    await data.select('60');
    await data.step(1);
    expect(data.currentKey, '61');
    expect(data.sources.any((i) => i.identifier == '61'), isTrue);
    await data.step(-1);
    expect(data.currentKey, '60');
  });

  test('home and end refer to the entire result, not loaded items', () async {
    final data = backend();
    addTearDown(data.dispose);
    await data.initialize();
    await data.jump(last: true);
    expect(data.currentKey, '299');
    expect(data.position, 299);
    await data.step(1);
    expect(data.currentKey, '299');
    await data.jump(last: false);
    expect(data.currentKey, '0');
    await data.step(-1);
    expect(data.currentKey, '0');
  });

  test('late metadata cannot overwrite the latest selected image', () async {
    final slow = Completer<NaiImageMetadata?>();
    final data = backend(
      metadata: (image) => image.identifier == '100'
          ? slow.future
          : Future.value(image.metadata),
    );
    addTearDown(data.dispose);
    final opening = data.initialize();
    await Future<void>.delayed(Duration.zero);
    await data.select('101');
    slow.complete(const NaiImageMetadata(prompt: 'stale'));
    await opening;
    expect(data.currentKey, '101');
    expect(data.metadata?.prompt, '101');
  });

  test(
    'deleting current image selects next, and last selects previous',
    () async {
      final data = backend(count: 3, initial: 1, delete: (_) async => true);
      addTearDown(data.dispose);
      await data.initialize();
      await data.delete('1');
      expect(data.currentKey, '2');
      expect(data.total, 2);
      await data.delete('2');
      expect(data.currentKey, '0');
      expect(data.total, 1);
      await data.delete('0');
      expect(data.total, 0);
      expect(data.currentKey, isNull);
    },
  );

  test('failed soft delete keeps current image and range unchanged', () async {
    final data = backend(delete: (_) async => false);
    addTearDown(data.dispose);
    await data.initialize();
    await data.delete('100');
    expect(data.total, 300);
    expect(data.currentKey, '100');
    expect(data.undoKey, isNull);
  });

  test(
    'undo restores exactly the last deleted image, not older history',
    () async {
      final restored = <String>[];
      final data = backend(
        delete: (_) async => true,
        restore: (key) async => restored.add(key),
      );
      addTearDown(data.dispose);
      await data.initialize();
      await data.delete('100');
      final firstUndo = data.undoId;
      await data.delete('101');
      expect(data.undoId, isNot(firstUndo));
      await data.undoDelete();
      await data.undoDelete();
      expect(restored, ['101']);
      expect(data.currentKey, '101');
      expect(data.total, 299);
      expect(data.keys, isNot(contains('100')));
    },
  );

  test('repeat delete while pending issues one request', () async {
    var calls = 0;
    final gate = Completer<bool>();
    final data = backend(
      delete: (_) {
        calls++;
        return gate.future;
      },
    );
    addTearDown(data.dispose);
    await data.initialize();
    final first = data.delete('100');
    await data.delete('100');
    gate.complete(true);
    await first;
    expect(calls, 1);
    expect(data.total, 299);
  });

  test('failed restoration retains undo for retry', () async {
    var attempts = 0;
    final data = backend(
      delete: (_) async => true,
      restore: (_) async {
        if (++attempts == 1) throw StateError('unavailable');
      },
    );
    addTearDown(data.dispose);
    await data.initialize();
    await data.delete('100');
    await expectLater(data.undoDelete(), throwsStateError);
    expect(data.undoKey, '100');
    await data.undoDelete();
    expect(data.currentKey, '100');
    expect(data.total, 300);
  });

  test(
    'navigation during delete does not overwrite the new selection',
    () async {
      final gate = Completer<bool>();
      final data = backend(delete: (_) => gate.future);
      addTearDown(data.dispose);
      await data.initialize();
      final deleting = data.delete('100');
      await data.select('105');
      gate.complete(true);
      await deleting;
      expect(data.currentKey, '105');
      expect(data.metadata?.prompt, '105');
    },
  );

  test(
    'dismissing undo does not physically delete or restore anything',
    () async {
      final restored = <String>[];
      final data = backend(
        delete: (_) async => true,
        restore: (key) async => restored.add(key),
      );
      addTearDown(data.dispose);
      await data.initialize();
      await data.delete('100');
      data.dismissUndo();
      await data.undoDelete();
      expect(restored, isEmpty);
      expect(data.total, 299);
    },
  );
}
