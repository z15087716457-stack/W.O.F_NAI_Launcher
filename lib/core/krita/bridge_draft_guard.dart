import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Only editable fields are compared. Document identity also protects a block
/// edit whose text projection happens to be unchanged.
class BridgeDraftSnapshot {
  BridgeDraftSnapshot({required this.fields, this.documents = const {}});
  final Map<String, dynamic> fields;
  final Map<String, dynamic> documents;

  Map<String, String> get fieldVersions => {
    for (final e in fields.entries)
      e.key: sha256
          .convert(
            utf8.encode(jsonEncode(_canonical([e.value, documents[e.key]]))),
          )
          .toString(),
  };
  Map<String, dynamic> toJson() => {
    'fields': fields,
    'documents': documents,
    'field_versions': fieldVersions,
  };

  static String fieldFor(String key) => switch (key) {
    'clear_characters' => 'characters',
    'seed_lock' => 'seed',
    'quality_toggle' => 'quality_preset',
    _ => key,
  };

  bool matches(Map<String, dynamic> changes, Map<String, dynamic> expected) {
    final versions = fieldVersions;
    final affected = {
      ...changes.keys,
      if (changes.containsKey('model')) 'sampler',
    };
    return affected.every((key) {
      final field = fieldFor(key);
      return versions.containsKey(field) && expected[field] == versions[field];
    });
  }

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }
}

/// Validate the whole patch before any setter runs; a bad later field cannot
/// leave an earlier prompt setter partially applied.
void validateBridgePatch(Map<String, dynamic> patch) {
  const strings = {
    'prompt',
    'negative_prompt',
    'model',
    'sampler',
    'noise_schedule',
    'quality_preset',
  };
  const flags = {
    'seed_lock',
    'quality_toggle',
    'transparent_background',
    'variety_plus',
    'smea_auto',
    'smea',
    'smea_dyn',
    'use_coords',
    'clear_characters',
  };
  const numbers = {
    'width',
    'height',
    'steps',
    'cfg_scale',
    'seed',
    'n_samples',
    'uc_preset',
    'cfg_rescale',
  };
  for (final e in patch.entries) {
    final k = e.key, v = e.value;
    if (strings.contains(k)) {
      if (v is! String) throw FormatException('Expected a string: $k');
      if (k == 'quality_preset' && !{'standard', 'light', 'none'}.contains(v)) {
        throw const FormatException('Invalid quality preset');
      }
      if (!{'prompt', 'negative_prompt'}.contains(k) && v.isEmpty) {
        throw FormatException('Empty value: $k');
      }
    } else if (flags.contains(k)) {
      if (v is! bool) throw FormatException('Expected a boolean: $k');
    } else if (numbers.contains(k)) {
      if (v is! num || !v.isFinite) {
        throw FormatException('Expected a number: $k');
      }
      if (k != 'cfg_scale' && k != 'cfg_rescale' && v != v.roundToDouble()) {
        throw FormatException('Expected an integer: $k');
      }
      if ({'width', 'height', 'steps', 'n_samples'}.contains(k) && v <= 0) {
        throw FormatException('Expected a positive number: $k');
      }
      if ((k == 'width' || k == 'height') && v > 8192) {
        throw FormatException('Dimension is too large: $k');
      }
    } else if (k == 'characters') {
      if (v is! List) throw const FormatException('Expected a character list');
      final ids = <String>{};
      for (final c in v) {
        if (c is! Map ||
            c['prompt'] is! String ||
            (c['uc'] != null && c['uc'] is! String) ||
            (c['name'] != null && c['name'] is! String) ||
            (c['id'] != null && (c['id'] is! String || c['id'].isEmpty)) ||
            (c['name_is_custom'] != null && c['name_is_custom'] is! bool) ||
            (c['enabled'] != null && c['enabled'] is! bool) ||
            (c.containsKey('x') != c.containsKey('y')) ||
            (c['x'] != null && (c['x'] is! num || c['y'] is! num))) {
          throw const FormatException('Invalid character');
        }
        if (c['id'] is String && !ids.add(c['id'] as String)) {
          throw const FormatException('Duplicate character identity');
        }
        if (c.containsKey('x') &&
            (c['x'] is! num ||
                c['y'] is! num ||
                !(c['x'] as num).isFinite ||
                !(c['y'] as num).isFinite ||
                (c['x'] as num) < 0 ||
                (c['x'] as num) > 1 ||
                (c['y'] as num) < 0 ||
                (c['y'] as num) > 1)) {
          throw const FormatException('Invalid character position');
        }
      }
    } else {
      throw FormatException('Unsupported editable field: $k');
    }
  }
}
