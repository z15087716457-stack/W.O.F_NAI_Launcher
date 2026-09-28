import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../utils/tag_normalizer.dart';

class WikiBookmarkCollection {
  const WikiBookmarkCollection({
    required this.id,
    required this.name,
    this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
  };

  factory WikiBookmarkCollection.fromJson(Map<String, dynamic> json) =>
      WikiBookmarkCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
      );
}

/// Personal pointers to canonical tags. The encyclopedia data is never copied.
class WikiBookmarkStore extends ChangeNotifier {
  static const _key = 'wiki_bookmarks_v1';

  final List<WikiBookmarkCollection> _collections = [];
  final Set<String> _bookmarked = {};
  final Map<String, Set<String>> _members = {};
  Future<void> _pendingSave = Future.value();
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<WikiBookmarkCollection> get collections =>
      List.unmodifiable(_collections);
  int get bookmarkCount => _bookmarked.length;
  bool contains(String tag) =>
      _bookmarked.contains(TagNormalizer.normalize(tag));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _collections.addAll(
          (data['collections'] as List<dynamic>? ?? const []).map(
            (item) =>
                WikiBookmarkCollection.fromJson(item as Map<String, dynamic>),
          ),
        );
        _bookmarked.addAll(
          List<String>.from(data['bookmarked'] as List<dynamic>? ?? const []),
        );
        final members = data['members'] as Map<String, dynamic>? ?? const {};
        for (final entry in members.entries) {
          _members[entry.key] = List<String>.from(entry.value as List).toSet();
        }
      } on FormatException {
        // Keep malformed preferences untouched; the page can still open.
      } on TypeError {
        // Older or partial payloads do not block the encyclopedia.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  List<WikiBookmarkCollection> childrenOf(String? parentId) =>
      _collections.where((item) => item.parentId == parentId).toList();

  Set<String> tagsIn(String? collectionId) {
    if (collectionId == null) return Set.unmodifiable(_bookmarked);
    final result = <String>{};
    final visited = <String>{};
    void collect(String id) {
      if (!visited.add(id)) return;
      result.addAll(_members[id] ?? const {});
      for (final child in childrenOf(id)) {
        collect(child.id);
      }
    }

    collect(collectionId);
    return result;
  }

  bool isInCollection(String tag, String id) =>
      _members[id]?.contains(TagNormalizer.normalize(tag)) ?? false;

  Future<void> toggle(String tag) async {
    final name = TagNormalizer.normalize(tag);
    if (name.isEmpty) return;
    if (!_bookmarked.add(name)) {
      _bookmarked.remove(name);
      for (final members in _members.values) {
        members.remove(name);
      }
    }
    notifyListeners();
    await _save();
  }

  Future<void> addToCollection(String tag, String id) async {
    if (!_collections.any((item) => item.id == id)) return;
    final name = TagNormalizer.normalize(tag);
    if (name.isEmpty) return;
    _bookmarked.add(name);
    _members.putIfAbsent(id, () => <String>{}).add(name);
    notifyListeners();
    await _save();
  }

  Future<void> removeFromCollection(String tag, String id) async {
    _members[id]?.remove(TagNormalizer.normalize(tag));
    notifyListeners();
    await _save();
  }

  Future<WikiBookmarkCollection> createCollection(
    String name, {
    String? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    if (parentId != null && !_collections.any((item) => item.id == parentId)) {
      throw ArgumentError.value(parentId, 'parentId');
    }
    final item = WikiBookmarkCollection(
      id: const Uuid().v4(),
      name: trimmed,
      parentId: parentId,
    );
    _collections.add(item);
    notifyListeners();
    await _save();
    return item;
  }

  Future<void> renameCollection(String id, String name) async {
    final index = _collections.indexWhere((item) => item.id == id);
    if (index < 0 || name.trim().isEmpty) return;
    final prior = _collections[index];
    _collections[index] = WikiBookmarkCollection(
      id: prior.id,
      name: name.trim(),
      parentId: prior.parentId,
    );
    notifyListeners();
    await _save();
  }

  Future<void> deleteCollection(String id) async {
    final descendants = <String>{id};
    var changed = true;
    while (changed) {
      changed = false;
      for (final collection in _collections) {
        if (collection.parentId != null &&
            descendants.contains(collection.parentId) &&
            descendants.add(collection.id)) {
          changed = true;
        }
      }
    }
    _collections.removeWhere((item) => descendants.contains(item.id));
    for (final childId in descendants) {
      _members.remove(childId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final payload = jsonEncode({
      'collections': _collections.map((item) => item.toJson()).toList(),
      'bookmarked': _bookmarked.toList()..sort(),
      'members': {
        for (final entry in _members.entries)
          entry.key: entry.value.toList()..sort(),
      },
    });
    _pendingSave = _pendingSave.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, payload);
    });
    return _pendingSave;
  }
}

final wikiBookmarkStoreProvider = ChangeNotifierProvider<WikiBookmarkStore>((
  ref,
) {
  final store = WikiBookmarkStore();
  unawaited(store.load());
  return store;
});
