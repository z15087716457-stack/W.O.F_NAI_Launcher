import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/floating_resource_layout_store.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';

class MemoryWindowSettings extends LocalStorageService {
  final values = <String, Object?>{};
  final writes = <String>[];
  Completer<void>? wait;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    await wait?.future;
    writes.add(key);
    values[key] = value;
  }
}

void main() {
  late ProviderContainer container;
  late MemoryWindowSettings settings;
  late FloatingResourceWindows windows;
  setUp(() {
    settings = MemoryWindowSettings();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(settings)],
    );
    windows = container.read(floatingResourceWindowsProvider.notifier);
    windows.setViewport(const Rect.fromLTWH(0, 0, 1000, 800));
  });
  tearDown(() async {
    await windows.saved;
    container.dispose();
  });
  test(
    'all resource kinds open distinct windows with 24px cascade and cap 8',
    () async {
      final ids = <String>[];
      for (var i = 0; i < 8; i++) {
        ids.add(windows.open(FloatingResourceKind.values[i % 4])!);
      }
      final state = container.read(floatingResourceWindowsProvider);
      expect(ids.toSet(), hasLength(8));
      expect(state[0].rect.topLeft, const Offset(24, 24));
      expect(
        state[1].rect.topLeft - state[0].rect.topLeft,
        const Offset(24, 24),
      );
      expect(windows.open(FloatingResourceKind.gallery), isNull);
      expect(state.map((w) => w.z), orderedEquals(List.generate(8, (i) => i)));
      expect(() => state.clear(), throwsUnsupportedError);
    },
  );
  test('focus, close, query, scope and minimized are independent', () async {
    final a = windows.open(FloatingResourceKind.gallery)!;
    final b = windows.open(FloatingResourceKind.blocks)!;
    windows.focus(a);
    windows.setQuery(a, 'aokumo rin');
    windows.setScope(
      a,
      const FloatingResourceScope(folderPath: '/pictures', categoryId: 'cat'),
    );
    windows.setMinimized(a, true);
    final state = container.read(floatingResourceWindowsProvider);
    expect(state.last.id, a);
    expect(state.last.z, 1);
    expect(state.last.query, 'aokumo rin');
    expect(state.last.minimized, isTrue);
    expect(state.first.query, isEmpty);
    windows.close(b);
    expect(container.read(floatingResourceWindowsProvider).single.z, 0);
    windows.close('missing');
    windows.focus('missing');
    expect(container.read(floatingResourceWindowsProvider), hasLength(1));
  });
  test('move resize and viewport shrink clamp edges and minimum size', () {
    final id = windows.open(FloatingResourceKind.gallery)!;
    windows.move(id, const Rect.fromLTWH(999, -40, 9000, 9000));
    expect(
      container.read(floatingResourceWindowsProvider).single.rect,
      const Rect.fromLTWH(0, 0, 1000, 800),
    );
    windows.resize(id, const Rect.fromLTWH(-40, 900, 10, 10));
    expect(
      container.read(floatingResourceWindowsProvider).single.rect,
      const Rect.fromLTWH(0, 560, 280, 240),
    );
    windows.setViewport(const Rect.fromLTWH(10, 20, 500, 400));
    expect(
      container.read(floatingResourceWindowsProvider).single.rect,
      const Rect.fromLTWH(10, 180, 280, 240),
    );
    windows.setViewport(const Rect.fromLTWH(10, 20, 100, 100));
    expect(
      container.read(floatingResourceWindowsProvider).single.rect,
      const Rect.fromLTWH(10, 20, 280, 240),
    );
  });
  test('new cascade clips to viewport after last window is moved', () {
    final a = windows.open(FloatingResourceKind.precise)!;
    windows.move(a, const Rect.fromLTWH(600, 440, 400, 360));
    windows.open(FloatingResourceKind.vibe);
    expect(
      container.read(floatingResourceWindowsProvider).last.rect,
      const Rect.fromLTWH(600, 440, 400, 360),
    );
  });
  test(
    'ordered persistence restores scope, layout and z but not query',
    () async {
      settings.wait = Completer<void>();
      final a = windows.open(FloatingResourceKind.gallery)!;
      final b = windows.open(FloatingResourceKind.vibe)!;
      windows.focus(a);
      windows.setQuery(a, 'private session query');
      windows.setScope(
        a,
        const FloatingResourceScope(
          collectionId: 'collection',
          favoritesOnly: true,
        ),
      );
      windows.move(a, const Rect.fromLTWH(50, 60, 300, 260));
      windows.setMinimized(b, true);
      settings.wait!.complete();
      await windows.saved;
      expect(
        settings.writes.every(
          (key) => key == StorageKeys.floatingResourceWindows,
        ),
        isTrue,
      );
      expect(
        settings.values.values.single.toString(),
        isNot(contains('private session query')),
      );
      final restored = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(settings)],
      );
      addTearDown(restored.dispose);
      final state = restored.read(floatingResourceWindowsProvider);
      expect(state.map((w) => w.id), [b, a]);
      expect(state.last.rect, const Rect.fromLTWH(50, 60, 300, 260));
      expect(state.last.scope.collectionId, 'collection');
      expect(state.last.query, isEmpty);
      expect(state.first.minimized, isTrue);
    },
  );
  test('restored list enforces cap and normalizes z', () async {
    final store = FloatingResourceLayoutStore(settings);
    await store.save(
      List.generate(
        10,
        (i) => FloatingWindowData(
          id: '$i',
          kind: FloatingResourceKind.blocks,
          rect: const Rect.fromLTWH(2000, 2000, 400, 360),
          z: 20 - i,
        ),
      ),
    );
    final restored = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWithValue(settings)],
    );
    final manager = restored.read(floatingResourceWindowsProvider.notifier);
    manager.setViewport(const Rect.fromLTWH(0, 0, 800, 600));
    final state = restored.read(floatingResourceWindowsProvider);
    expect(state, hasLength(8));
    expect(state.map((w) => w.z), List.generate(8, (i) => i));
    expect(
      state.every((w) => w.rect.right <= 800 && w.rect.bottom <= 600),
      isTrue,
    );
    await manager.saved;
    restored.dispose();
  });
}
