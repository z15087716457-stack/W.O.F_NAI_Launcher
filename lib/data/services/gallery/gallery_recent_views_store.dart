import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/gallery_path_utils.dart';

class GalleryRecentView {
  const GalleryRecentView(this.path, this.viewedAt);
  final String path;
  final DateTime viewedAt;
}

/// A bounded history of references; never copies or deletes image files.
class GalleryRecentViewsStore {
  static const limit = 300;
  static const key = 'gallery_recent_views_v1';
  Future<void> _tail = Future.value();

  Future<List<GalleryRecentView>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return [];
    final seen = <String>{};
    try {
      final value = jsonDecode(raw);
      if (value is! List) return [];
      return [
        for (final entry in value)
          if (entry is Map && entry['path'] is String && entry['at'] is String)
            if (DateTime.tryParse(entry['at'] as String) case final at?)
              if (seen.add(galleryFilePathKey(entry['path'] as String)))
                GalleryRecentView(entry['path'] as String, at),
      ].take(limit).toList();
    } on FormatException {
      return [];
    }
  }

  Future<List<GalleryRecentView>> record(String path, {DateTime? at}) {
    final next = _tail.then((_) async {
      final current = await load();
      final pathKey = galleryFilePathKey(path);
      final result = [
        GalleryRecentView(path, at ?? DateTime.now()),
        ...current.where((e) => galleryFilePathKey(e.path) != pathKey),
      ].take(limit).toList();
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(
        key,
        jsonEncode([
          for (final entry in result)
            {'path': entry.path, 'at': entry.viewedAt.toIso8601String()},
        ]),
      )) {
        throw StateError('Failed to save recent gallery views');
      }
      return result;
    });
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }
}
