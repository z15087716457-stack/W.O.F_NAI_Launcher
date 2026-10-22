import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

/// Private, metadata-free artwork; never falls back to synthetic gradients.
class ShotImages {
  ShotImages() {
    final index = File('$directory/index.json');
    if (!index.existsSync()) return;
    entries = (jsonDecode(index.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    for (final e in entries) {
      if (!File('$directory/${e['file']}').existsSync()) {
        throw StateError('Missing artwork: ${e['file']}');
      }
    }
  }

  static const directory = '.dart_tool/readme-shots/images';
  List<Map<String, dynamic>> entries = [];
  final _cache = <String, ImageProvider>{};
  final _assigned = <String, String>{};
  final _next = <String, int>{};
  bool get available => entries.isNotEmpty;

  String orientation(int w, int h) => w == h
      ? 'square'
      : w > h
      ? 'landscape'
      : 'portrait';

  ImageProvider image(String key, {String direction = 'portrait'}) =>
      _cache.putIfAbsent('$direction/$key', () {
        final pool = entries
            .where((e) => e['orientation'] == direction)
            .toList();
        if (pool.isEmpty) throw StateError('No $direction artwork');
        final i = _next.update(direction, (n) => n + 1, ifAbsent: () => 0);
        final file = pool[i % pool.length]['file'] as String;
        _assigned['$direction/$key'] = file;
        return fileImage(file);
      });

  ImageProvider fileImage(String file) => _cache.putIfAbsent(
    'file/$file',
    () => MemoryImage(File('$directory/$file').readAsBytesSync()),
  );

  ImageProvider channel(String key) => key == 'g07'
      ? image('channel/$key', direction: 'square')
      : key == 'g41'
      ? image('channel/$key', direction: 'landscape')
      : gen(key);

  ImageProvider gen(String key) =>
      image('gen/$key', direction: key == 'g19' ? 'landscape' : 'portrait');

  ImageProvider viewer(String key, bool thumb) => image(
    'viewer/$key',
    direction: int.tryParse(key)?.isEven == true ? 'landscape' : 'portrait',
  );

  Iterable<ImageProvider> get providers => _cache.values.toSet();
  Map<String, String> get assignments => Map.unmodifiable(_assigned);
}
