import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/local_storage_service.dart';
import '../../data/models/resources/floating_window_data.dart';
import '../../data/services/floating_resource_layout_store.dart';

export '../../data/models/resources/floating_window_data.dart';

final floatingResourceLayoutStoreProvider = Provider(
  (ref) => FloatingResourceLayoutStore(ref.read(localStorageServiceProvider)),
);
final floatingResourceWindowsProvider =
    NotifierProvider<FloatingResourceWindows, List<FloatingWindowData>>(
      FloatingResourceWindows.new,
    );

class FloatingResourceWindows extends Notifier<List<FloatingWindowData>> {
  static const maxWindows = 8;
  static const minimumSize = Size(280, 240);
  static const initialSize = Size(400, 360);
  Rect? _viewport;
  Future<void> _saved = Future.value();

  FloatingWindowData? window(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Allows hosts/tests to await persistence, including a reported write error.
  Future<void> get saved => _saved;

  @override
  List<FloatingWindowData> build() {
    final restored =
        ref
            .read(floatingResourceLayoutStoreProvider)
            .load()
            .take(maxWindows)
            .toList()
          ..sort((a, b) => a.z.compareTo(b.z));
    return List.unmodifiable([
      for (var i = 0; i < restored.length; i++) restored[i].copyWith(z: i),
    ]);
  }

  Rect _clamp(Rect rect) {
    final viewport = _viewport;
    // When the viewport itself is smaller than the minimum, keep the minimum
    // and anchor at its origin; both constraints cannot hold simultaneously.
    final width = viewport == null
        ? rect.width.clamp(minimumSize.width, double.infinity)
        : rect.width.clamp(
            minimumSize.width,
            viewport.width < minimumSize.width
                ? minimumSize.width
                : viewport.width,
          );
    final height = viewport == null
        ? rect.height.clamp(minimumSize.height, double.infinity)
        : rect.height.clamp(
            minimumSize.height,
            viewport.height < minimumSize.height
                ? minimumSize.height
                : viewport.height,
          );
    final left = viewport == null
        ? rect.left
        : rect.left.clamp(
            viewport.left,
            viewport.right - width < viewport.left
                ? viewport.left
                : viewport.right - width,
          );
    final top = viewport == null
        ? rect.top
        : rect.top.clamp(
            viewport.top,
            viewport.bottom - height < viewport.top
                ? viewport.top
                : viewport.bottom - height,
          );
    return Rect.fromLTWH(left, top, width, height);
  }

  void _publish(List<FloatingWindowData> windows, {bool persist = true}) {
    state = List.unmodifiable(windows);
    if (persist) {
      final snapshot = state;
      final store = ref.read(floatingResourceLayoutStoreProvider);
      _saved = _saved.then((_) => store.save(snapshot));
    }
  }

  /// Called by the shell host after layout, never during a widget build.
  void setViewport(Rect viewport) {
    if (_viewport == viewport) return;
    _viewport = viewport;
    final next = [
      for (final window in state) window.copyWith(rect: _clamp(window.rect)),
    ];
    if (next.indexed.any((item) => item.$2.rect != state[item.$1].rect)) {
      _publish(next);
    }
  }

  String? open(
    FloatingResourceKind kind, {
    FloatingResourceScope scope = const FloatingResourceScope(),
  }) {
    if (state.length >= maxWindows) return null;
    final previous = state.isEmpty ? null : state.last;
    final offset = previous == null
        ? (_viewport?.topLeft ?? Offset.zero) + const Offset(24, 24)
        : previous.rect.topLeft + const Offset(24, 24);
    final window = FloatingWindowData(
      id: const Uuid().v4(),
      kind: kind,
      rect: _clamp(offset & (previous?.rect.size ?? initialSize)),
      z: state.length,
      scope: scope,
    );
    _publish([...state, window]);
    return window.id;
  }

  void close(String id) {
    if (!state.any((w) => w.id == id)) return;
    final next = state.where((w) => w.id != id).toList();
    _publish([for (var i = 0; i < next.length; i++) next[i].copyWith(z: i)]);
  }

  void focus(String id) {
    final index = state.indexWhere((w) => w.id == id);
    if (index < 0 || index == state.length - 1) return;
    final next = [...state, state[index]];
    next.removeAt(index);
    _publish([for (var i = 0; i < next.length; i++) next[i].copyWith(z: i)]);
  }

  void _change(
    String id,
    FloatingWindowData Function(FloatingWindowData) update, {
    bool persist = true,
  }) {
    if (!state.any((w) => w.id == id)) return;
    _publish([
      for (final w in state)
        if (w.id == id) update(w) else w,
    ], persist: persist);
  }

  void move(String id, Rect rect) =>
      _change(id, (w) => w.copyWith(rect: _clamp(rect)));
  void resize(String id, Rect rect) => move(id, rect);
  void setQuery(String id, String query) =>
      _change(id, (w) => w.copyWith(query: query), persist: false);
  void setScope(String id, FloatingResourceScope scope) =>
      _change(id, (w) => w.copyWith(scope: scope));
  void setMinimized(String id, bool minimized) =>
      _change(id, (w) => w.copyWith(minimized: minimized));
}
