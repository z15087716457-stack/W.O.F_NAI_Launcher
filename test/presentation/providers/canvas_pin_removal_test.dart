import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  bool failWrites = false;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (failWrites) throw StateError('test write failed');
    values[key] = value;
  }
}

void main() {
  test('queued pin removal is idempotent and retains disk copies', () async {
    final folder = await Directory.systemTemp.createTemp('pin_remove_test_');
    addTearDown(() => folder.delete(recursive: true));
    final storage = _Storage();
    final repo = CanvasPinRepository(storage: storage, directory: folder);
    final container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(canvasPinnedNotifierProvider.notifier)
      ..debugRepository = repo;
    GeneratedImage image(String id, int value) => GeneratedImage(
      id: id,
      bytes: Uint8List.fromList(
        img.encodePng(
          img.Image(width: 2, height: 2)..setPixelRgb(0, 0, value, 0, 0),
        ),
      ),
      width: 2,
      height: 2,
    );
    final target = image('target', 32);
    final other = image('other', 64);
    await notifier.toggle(target);
    await notifier.toggle(other);
    final files = folder.listSync().whereType<File>().toList();
    expect(files, hasLength(2));
    await Future.wait([notifier.remove(target.id), notifier.remove(target.id)]);
    expect(container.read(canvasPinnedNotifierProvider), {other.id});
    expect(notifier.images.map((image) => image.id), [other.id]);
    expect(repo.readManifest().map((record) => record.imageId), [other.id]);
    expect(files.every((file) => file.existsSync()), isTrue);
    storage.failWrites = true;
    await expectLater(notifier.remove(other.id), throwsStateError);
    expect(container.read(canvasPinnedNotifierProvider), {other.id});
    expect(notifier.images.single.id, other.id);
    storage.failWrites = false;
    await notifier.remove(other.id);
    expect(container.read(canvasPinnedNotifierProvider), isEmpty);
  });
}
