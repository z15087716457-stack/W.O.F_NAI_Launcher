import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// Private query text; deliberately excluded from preference export.
class GallerySearchHistoryStore {
  GallerySearchHistoryStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const maxItems = 12;
  final Future<SharedPreferences> Function() _preferences;
  Future<void> _tail = Future.value();
  List<String>? _items;
  List<String> get items => List.unmodifiable(_items ?? const <String>[]);

  static List<String> _clean(Object? value) {
    if (value is! List) return [];
    final result = <String>[];
    for (final item in value) {
      if (item is! String) continue;
      final text = item.trim();
      if (text.isNotEmpty && !result.contains(text)) result.add(text);
      if (result.length == maxItems) break;
    }
    return result;
  }

  Future<List<String>> _enqueue(Future<void> Function() operation) {
    final result = _tail.then((_) async {
      await operation();
      return items;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _load() async {
    if (_items != null) return;
    final prefs = await _preferences();
    _items = _clean(prefs.get(StorageKeys.localGallerySearchHistory));
  }

  Future<List<String>> load() => _enqueue(_load);

  Future<List<String>> _change(void Function(List<String>) change) =>
      _enqueue(() async {
        await _load();
        final next = [..._items!];
        change(next);
        final prefs = await _preferences();
        if (!await prefs.setStringList(
          StorageKeys.localGallerySearchHistory,
          next,
        )) {
          throw StateError('Failed to persist gallery search history');
        }
        _items = next;
      });

  Future<List<String>> add(String query) => _change((items) {
    final text = query.trim();
    if (text.isEmpty) return;
    items.remove(text);
    items.insert(0, text);
    if (items.length > maxItems) items.removeRange(maxItems, items.length);
  });

  Future<List<String>> remove(String query) =>
      _change((items) => items.remove(query.trim()));
  Future<List<String>> clear() => _change((items) => items.clear());
}
