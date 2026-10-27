import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/models/gallery/nai_image_metadata.dart';
import '../widgets/common/image_detail/image_detail_data.dart';

class ImageViewerBackend extends ChangeNotifier {
  ImageViewerBackend({
    required List<String> keys,
    required String initialKey,
    required this.load,
    required this.readMetadata,
    this.deleteImage,
    this.restoreImage,
    this.pageSize = 60,
  }) : _keys = keys.toSet().toList(),
       currentKey = keys.contains(initialKey) ? initialKey : keys.firstOrNull;

  final Future<List<ImageDetailData>> Function(List<String>) load;
  final Future<NaiImageMetadata?> Function(ImageDetailData) readMetadata;
  final Future<bool> Function(String)? deleteImage;
  final Future<void> Function(String)? restoreImage;
  final int pageSize;
  final List<String> _keys;
  final _sources = <String, ImageDetailData>{};
  int _start = 0;
  int _end = 0;
  int _windowSerial = 0;
  int _selectionSerial = 0;
  int _undoSerial = 0;
  bool _disposed = false;
  bool _mutating = false;
  final _extensions = <bool>{};
  String? currentKey;
  NaiImageMetadata? metadata;
  bool metadataLoading = true;
  String? undoKey;
  int? _undoPosition;
  String? undoId;

  List<String> get keys => List.unmodifiable(_keys);
  int get total => _keys.length;
  int get position => currentKey == null ? 0 : _keys.indexOf(currentKey!);
  ImageDetailData? get current => _sources[currentKey];
  List<ImageDetailData> get sources => [
    for (final key in _keys.sublist(_start, _end))
      if (_sources[key] case final image?) image,
  ];

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (currentKey case final key?) await select(key, resetWindow: true);
  }

  void appendKeys(Iterable<String> keys) {
    final known = _keys.toSet();
    _keys.addAll(keys.where(known.add));
    _changed();
  }

  Future<void> _readWindow(int start, int end, {bool reset = false}) async {
    final serial = reset ? ++_windowSerial : _windowSerial;
    final paths = _keys.sublist(start, end);
    final loaded = await load(paths);
    if (_disposed || serial != _windowSerial) return;
    for (final source in loaded) {
      if (_keys.contains(source.identifier)) {
        _sources[source.identifier] = source;
      }
    }
    if (reset || _end == 0) {
      _start = start;
      _end = end;
    } else {
      _start = math.min(_start, start);
      _end = math.max(_end, end);
    }
    _end = math.min(_end, _keys.length);
    _start = math.min(_start, _end);
    _changed();
  }

  Future<void> select(String key, {bool resetWindow = false}) async {
    final index = _keys.indexOf(key);
    if (_disposed || index < 0) return;
    final serial = ++_selectionSerial;
    currentKey = key;
    metadata = null;
    metadataLoading = true;
    _changed();
    if (resetWindow ||
        index < _start ||
        index >= _end ||
        !_sources.containsKey(key)) {
      await _readWindow(
        math.max(0, index - pageSize),
        math.min(total, index + pageSize + 1),
        reset: resetWindow || _end == 0,
      );
    }
    if (_disposed || serial != _selectionSerial) return;
    final image = _sources[key];
    try {
      final result = image == null ? null : await readMetadata(image);
      if (_disposed || serial != _selectionSerial) return;
      metadata = result?.upgradeFromRawJsonIfNeeded();
    } finally {
      if (!_disposed && serial == _selectionSerial) {
        metadataLoading = false;
        _changed();
      }
    }
  }

  Future<void> step(int delta) async {
    final index = position + delta;
    if (currentKey != null && index >= 0 && index < total) {
      await select(_keys[index]);
    }
  }

  Future<void> jump({required bool last}) async {
    if (_keys.isNotEmpty) {
      await select(last ? _keys.last : _keys.first, resetWindow: true);
    }
  }

  Future<void> loadMore({required bool forward}) async {
    if (_disposed || _keys.isEmpty || !_extensions.add(forward)) return;
    try {
      final start = forward ? _end : math.max(0, _start - pageSize);
      final end = forward ? math.min(total, _end + pageSize) : _start;
      if (start < end) await _readWindow(start, end);
    } finally {
      _extensions.remove(forward);
    }
  }

  Future<bool> delete(String key) async {
    if (_disposed || _mutating || deleteImage == null || !_keys.contains(key)) {
      return false;
    }
    _mutating = true;
    try {
      if (!await deleteImage!(key) || _disposed) return false;
      final index = _keys.indexOf(key);
      if (index < 0) return false;
      final selected = currentKey == key;
      _keys.removeAt(index);
      if (index < _start) _start--;
      if (index < _end) _end--;
      undoKey = key;
      _undoPosition = index;
      undoId = '${++_undoSerial}';
      if (_keys.isEmpty) {
        currentKey = null;
        metadata = null;
        _selectionSerial++;
      } else if (selected) {
        await select(_keys[math.min(index, total - 1)]);
      }
      _changed();
      return true;
    } finally {
      _mutating = false;
    }
  }

  Future<void> undoDelete() async {
    final key = undoKey;
    final index = _undoPosition;
    if (_disposed ||
        _mutating ||
        key == null ||
        index == null ||
        restoreImage == null) {
      return;
    }
    _mutating = true;
    final selection = _selectionSerial;
    try {
      await restoreImage!(key);
      if (_disposed) return;
      if (!_keys.contains(key)) {
        final target = math.min(index, total);
        _keys.insert(target, key);
        if (target < _start) _start++;
        if (target <= _end) _end++;
      }
      dismissUndo();
      if (selection == _selectionSerial) await select(key, resetWindow: true);
      _changed();
    } finally {
      _mutating = false;
    }
  }

  void dismissUndo() {
    undoKey = null;
    undoId = null;
    _undoPosition = null;
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _windowSerial++;
    _selectionSerial++;
    super.dispose();
  }
}
