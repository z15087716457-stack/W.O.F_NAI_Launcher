import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import '../../../core/utils/gallery_path_utils.dart';

/// Paths reported by the filesystem, coalesced until the gallery is visible.
class GalleryFileChanges {
  final Set<String> files = {};
  final Set<String> directories = {};
  final Map<String, String> directoryMoves = {};

  bool get isEmpty => files.isEmpty && directories.isEmpty;

  bool add(FileSystemEvent event, {String? root}) {
    if (event is FileSystemModifyEvent &&
        (event.isDirectory || !event.contentChanged)) {
      return false;
    }
    var accepted = false;
    void addPath(String path) {
      final normalized = normalizeGalleryFilePath(path);
      final parts = p.split(
        root == null ? normalized : p.relative(normalized, from: root),
      );
      if (parts.any(
        (part) => (part != '.' && part.startsWith('.')) || part == 'thumbs',
      )) {
        return;
      }
      if (event.isDirectory) {
        directories.add(normalized);
        accepted = true;
      } else if (const {
        '.png',
        '.jpg',
        '.jpeg',
        '.webp',
      }.contains(p.extension(normalized).toLowerCase())) {
        files.add(normalized);
        accepted = true;
      }
    }

    addPath(event.path);
    if (event is FileSystemMoveEvent && event.destination != null) {
      addPath(event.destination!);
      if (event.isDirectory &&
          directories.contains(normalizeGalleryFilePath(event.path))) {
        directoryMoves[normalizeGalleryFilePath(event.path)] =
            normalizeGalleryFilePath(event.destination!);
      }
    }
    return accepted;
  }
}

/// Native directory events only: no polling and no focus-triggered rescan.
class GalleryFileMonitor {
  GalleryFileMonitor({
    required this.loadRoots,
    required this.rootsChanged,
    required this.apply,
    required this.onError,
    this.watch = _watchDirectory,
    this.delay = const Duration(milliseconds: 500),
  });

  final Future<List<Directory>> Function() loadRoots;
  final Stream<void> rootsChanged;
  final Future<void> Function(GalleryFileChanges) apply;
  final void Function(Object, StackTrace) onError;
  final Stream<FileSystemEvent> Function(Directory) watch;
  final Duration delay;
  final _rootsLock = Lock();
  final Map<String, StreamSubscription<FileSystemEvent>> _subscriptions = {};
  StreamSubscription<void>? _rootsSubscription;
  GalleryFileChanges _pending = GalleryFileChanges();
  Timer? _timer;
  bool _active = false, _applying = false, _disposed = false;
  Future<void>? _start;

  static Stream<FileSystemEvent> _watchDirectory(Directory root) =>
      root.watch(recursive: true);

  Future<void> start() => _start ??= _startWatching();

  Future<void> _startWatching() async {
    _rootsSubscription = rootsChanged.listen((_) {
      unawaited(
        updateRoots().catchError((Object error, StackTrace stack) {
          if (!_disposed) onError(error, stack);
        }),
      );
    });
    await updateRoots();
  }

  Future<void> updateRoots() => _rootsLock.synchronized(() async {
    if (_disposed) return;
    final roots = await loadRoots();
    if (_disposed) return;
    final byKey = {
      for (final root in roots) galleryFilePathKey(root.path): root,
    };
    for (final key in _subscriptions.keys.toList()) {
      if (!byKey.containsKey(key)) {
        await _subscriptions.remove(key)!.cancel();
      }
    }
    for (final entry in byKey.entries) {
      if (_subscriptions.containsKey(entry.key)) continue;
      _subscriptions[entry.key] = watch(entry.value).listen(
        (event) {
          if (_disposed) return;
          if (_pending.add(event, root: entry.value.path)) _schedule();
        },
        onError: (Object error, StackTrace stack) {
          unawaited(_subscriptions.remove(entry.key)?.cancel());
          if (!_disposed) onError(error, stack);
        },
        onDone: () => _subscriptions.remove(entry.key),
      );
    }
  });

  void setActive(bool active) {
    if (_disposed) return;
    _active = active;
    _timer?.cancel();
    if (active) _schedule();
  }

  void _schedule() {
    if (!_active || _applying || _pending.isEmpty || _disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    if (!_active || _disposed) return;
    final batch = _pending;
    _pending = GalleryFileChanges();
    _applying = true;
    try {
      await apply(batch);
    } catch (error, stack) {
      if (!_disposed) onError(error, stack);
    } finally {
      _applying = false;
      _schedule();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _rootsSubscription?.cancel();
    await _rootsLock.synchronized(() async {
      for (final subscription in _subscriptions.values.toList()) {
        await subscription.cancel();
      }
      _subscriptions.clear();
    });
  }
}
