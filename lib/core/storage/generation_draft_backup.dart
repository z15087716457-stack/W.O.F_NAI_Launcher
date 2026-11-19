import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// A v2 manifest retains the original draft shape; only the listed media fields
/// refer to sibling content-addressed files. Legacy JSON remains standalone.
class GenerationDraftBackup {
  static const directoryName = 'draft-backups';
  static const _format = 'generation-draft-v2';

  static Iterable<(Map<String, dynamic>, String)> _media(
    Map<String, dynamic> draft,
  ) sync* {
    yield (draft, 'sourceImage');
    yield (draft, 'maskImage');
    for (final vibe in (draft['vibes'] as List).cast<Map<String, dynamic>>()) {
      for (final key in ['rawImageData', 'thumbnail', 'vibeEncoding']) {
        yield (vibe, key);
      }
    }
    for (final ref in (draft['precise'] as List).cast<Map<String, dynamic>>()) {
      yield (ref, 'image');
    }
    yield (draft['workflow'] as Map<String, dynamic>, 'temporaryEnhanceSource');
  }

  static File write(Directory directory, Map<String, dynamic> draft) {
    final objects = Directory(p.join(directory.path, 'media'));
    objects.createSync(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (final (map, key) in _media(draft)) {
      final value = map[key];
      if (value == null || (key == 'vibeEncoding' && value == '')) continue;
      // Encoding strings are provider payloads; preserve their exact spelling.
      final bytes = key == 'vibeEncoding'
          ? utf8.encode(value as String)
          : value as Uint8List;
      final digest = sha256.convert(bytes).toString();
      final file = File(p.join(objects.path, digest));
      if (!file.existsSync()) {
        final pending = File('${file.path}.$stamp.tmp');
        pending.writeAsBytesSync(bytes, flush: true);
        pending.renameSync(file.path);
      }
      map[key] = digest;
    }
    final manifest = File(
      p.join(directory.path, 'before-generation-$stamp.json'),
    );
    final pending = File('${manifest.path}.tmp');
    pending.writeAsStringSync(
      jsonEncode({'format': _format, 'draft': draft}),
      flush: true,
    );
    return pending.renameSync(manifest.path);
  }

  /// Expands either version into the original self-contained JSON structure.
  static Map<String, dynamic> read(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (!json.containsKey('format')) return json;
    if (json['format'] != _format) {
      throw const FormatException('Unknown draft backup format');
    }
    final draft = json['draft'] as Map<String, dynamic>;
    for (final (map, key) in _media(draft)) {
      final digest = map[key] as String?;
      if (digest == null || digest.isEmpty) continue;
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
        throw const FormatException('Invalid media reference');
      }
      final bytes = File(
        p.join(file.parent.path, 'media', digest),
      ).readAsBytesSync();
      if (sha256.convert(bytes).toString() != digest) {
        throw const FormatException('Damaged backup media');
      }
      map[key] = key == 'vibeEncoding'
          ? utf8.decode(bytes)
          : base64Encode(bytes);
    }
    return draft;
  }
}
