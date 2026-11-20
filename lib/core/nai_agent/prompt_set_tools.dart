import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../constants/api_constants.dart';
import '../krita/bridge_draft_guard.dart';
import 'agent_tool.dart';
import 'prompt_set_icons.dart';

String mergeAgentPrompt(String shared, String item) => [shared, item]
    .expand((s) => s.split(','))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .join(', ');

typedef AgentPromptSetPosition = ({double x, double y});

/// Item null/missing entries inherit the shared default, by character index.
List<AgentPromptSetPosition?> effectiveAgentPromptSetPositions(
  Map shared,
  Map item,
) {
  final defaults = shared['positions'] as List? ?? const [];
  final overrides = item['positions'] as List? ?? const [];
  return [
    for (var j = 0; j < (shared['characters'] as List? ?? []).length; j++)
      switch ((j < overrides.length ? overrides[j] : null) ??
          (j < defaults.length ? defaults[j] : null)) {
        final Map p => (
          x: (p['x'] as num).toDouble(),
          y: (p['y'] as num).toDouble(),
        ),
        _ => null,
      },
  ];
}

const promptCardGenerationKeys = {
  'model',
  'width',
  'height',
  'steps',
  'cfg_scale',
  'seed',
  'sampler',
  'noise_schedule',
  'cfg_rescale',
  'smea_auto',
  'smea',
  'smea_dyn',
  'variety_plus',
  'quality_preset',
  'uc_preset',
};

/// Materialize legacy shared lanes at the storage boundary. Card IDs survive
/// subsequent edits and keep image history with its card across reordering.
Map<String, dynamic> independentPromptSet(Map<String, dynamic> value) {
  final shared = value['shared'] as Map?;
  if (shared == null) return value;
  final base = (shared['characters'] as List? ?? const []).cast<String>();
  return {
    for (final e in value.entries)
      if (e.key != 'shared') e.key: e.value,
    'items': [
      for (final (index, item) in (value['items'] as List).cast<Map>().indexed)
        () {
          final extra = (item['characters'] as List? ?? const [])
              .cast<String>();
          final positions = effectiveAgentPromptSetPositions(shared, item);
          return {
            ...item,
            'card_id': 'legacy-$index',
            'main': mergeAgentPrompt(shared['main'] ?? '', item['main'] ?? ''),
            'negative': shared['negative'] ?? '',
            'characters': [
              for (var j = 0; j < base.length; j++)
                mergeAgentPrompt(base[j], extra.elementAtOrNull(j) ?? ''),
            ],
            if (positions.any((p) => p != null)) ...{
              'use_coords': true,
              'positions': [
                for (final p in positions)
                  if (p == null) null else {'x': p.x, 'y': p.y},
              ],
            },
          };
        }(),
    ],
  };
}

/// Validation and persistence are independent of the UI and the Pi session.
class NaiAgentPromptSets {
  NaiAgentPromptSets(this.agentDirectory, {this.chatId});
  final Directory agentDirectory;
  final String? chatId;
  static final _tails = <String, Future<void>>{};
  static final idPattern = RegExp(r'^[a-f0-9]{12}$');

  static void validateId(Object? id) {
    if (id is! String || !idPattern.hasMatch(id)) {
      throw const NaiAgentToolError('invalid_set_id', 'Expected 12 hex digits');
    }
  }

  Future<T> _locked<T>(Future<T> Function() action) async {
    final key = p.normalize(p.absolute(agentDirectory.path));
    final previous = _tails[key] ?? Future<void>.value();
    final next = previous.then((_) => action());
    final tail = next.then<void>((_) {}, onError: (Object _) {});
    _tails[key] = tail;
    try {
      return await next;
    } finally {
      if (identical(_tails[key], tail)) _tails.remove(key);
    }
  }

  Future<Directory> _directory() async {
    await agentDirectory.create(recursive: true);
    final root = await agentDirectory.resolveSymbolicLinks();
    final dir = Directory(p.join(root, 'prompt-sets'));
    await dir.create(recursive: true);
    if (!p.isWithin(root, await dir.resolveSymbolicLinks())) {
      throw const NaiAgentToolError(
        'invalid_path',
        'Prompt sets leave Agent directory',
      );
    }
    return dir;
  }

  Future<Map<String, dynamic>?> read(String id) async {
    validateId(id);
    final dir = await _directory();
    final file = File(p.join(dir.path, '$id.json'));
    if (!await file.exists()) return null;
    if (!p.isWithin(
          await dir.resolveSymbolicLinks(),
          await file.resolveSymbolicLinks(),
        ) ||
        await file.length() > 4 * 1024 * 1024) {
      throw const NaiAgentToolError('invalid_path', 'Invalid prompt set file');
    }
    final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    validateId(value['set_id']);
    if (value['set_id'] != id) {
      throw const FormatException('Set identity mismatch');
    }
    final content = independentPromptSet(validate(value));
    final items = content['items'] as List;
    if (value['revision'] is! int ||
        (value['revision'] as int) < 1 ||
        value['changed_items'] is! List ||
        (value['changed_items'] as List).any(
          (i) => i is! int || i < 0 || i >= items.length,
        ) ||
        value['images'] is! Map) {
      throw const FormatException('Invalid prompt set metadata');
    }
    for (final entry in (value['images'] as Map).entries) {
      final index = int.tryParse(entry.key.toString());
      if (index == null ||
          index < 0 ||
          index >= items.length ||
          entry.value is! List) {
        throw const FormatException('Invalid prompt set images');
      }
      for (final image in entry.value as List) {
        if (image is! Map ||
            image['path'] is! String ||
            image['created_at'] is! String ||
            (image['width'] != null && image['width'] is! int) ||
            (image['height'] != null && image['height'] is! int) ||
            (image['image_id'] != null && image['image_id'] is! String)) {
          throw const FormatException('Invalid prompt set image');
        }
      }
    }
    value.remove('shared');
    return {...value, ...content};
  }

  Future<void> _write(Map<String, dynamic> value) async {
    final dir = await _directory();
    final target = File(p.join(dir.path, '${value['set_id']}.json'));
    final temp = File('${target.path}.${Random.secure().nextInt(1 << 32)}.tmp');
    final bytes = utf8.encode(jsonEncode(value));
    if (bytes.length > 4 * 1024 * 1024) {
      throw const NaiAgentToolError(
        'invalid_prompt_set',
        'Prompt set exceeds 4 MiB',
      );
    }
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(target.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  static Map<String, dynamic> validate(Map<String, dynamic> input) {
    Never invalid(String field) =>
        throw NaiAgentToolError('invalid_prompt_set', 'Invalid $field');
    String string(Map value, String key, int max, {bool required = false}) {
      final s = value[key];
      if (s == null && !required) return '';
      if (s is! String ||
          s.runes.length > max ||
          (required && s.trim().isEmpty)) {
        invalid(key);
      }
      return s.trim();
    }

    String icon(Map value, String key) {
      final s = string(value, key, 24, required: true);
      if (!agentPromptSetGlyphNames.contains(s)) invalid(key);
      return s;
    }

    List<String> characters(Map value, int max, int length) {
      final list = value['characters'] ?? <String>[];
      if (list is! List || list.length > length) invalid('characters');
      return [
        for (final s in list)
          if (s is String && s.runes.length <= max)
            s.trim()
          else
            invalid('characters'),
      ];
    }

    List<Map<String, double>?> positions(Map value, int length) {
      final list = value['positions'];
      if (list is! List || list.length > length) invalid('positions');
      return [
        for (final entry in list)
          if (entry == null)
            null
          else if (entry is Map &&
              entry.length == 2 &&
              entry['x'] is num &&
              entry['y'] is num &&
              (entry['x'] as num).isFinite &&
              (entry['y'] as num).isFinite &&
              (entry['x'] as num) >= 0 &&
              (entry['x'] as num) <= 1 &&
              (entry['y'] as num) >= 0 &&
              (entry['y'] as num) <= 1)
            {
              'x': (entry['x'] as num).toDouble(),
              'y': (entry['y'] as num).toDouble(),
            }
          else
            invalid('positions'),
      ];
    }

    Map<String, dynamic> independentItem(Map item) {
      final id = string(item, 'card_id', 64, required: true);
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) invalid('card_id');
      final chars = characters(item, 8192, 32);
      final negatives = item['character_negatives'] ?? const [];
      if (negatives is! List ||
          negatives.length > chars.length ||
          negatives.any((n) => n is! String || n.runes.length > 8192)) {
        invalid('character_negatives');
      }
      final coords = item['use_coords'];
      if (coords != null && coords is! bool) invalid('use_coords');
      final points = item.containsKey('positions')
          ? positions(item, chars.length)
          : null;
      final settings = item['generation'];
      if (settings != null) {
        if (settings is! Map<String, dynamic> ||
            settings.keys.any((k) => !promptCardGenerationKeys.contains(k))) {
          invalid('generation');
        }
        try {
          validateBridgePatch(settings);
        } on FormatException catch (e) {
          invalid(e.message);
        }
        if (settings['model'] case final String model
            when !ImageModels.allModels.contains(model)) {
          invalid('generation.model');
        }
        if (settings['steps'] case final num n when n > 50) {
          invalid('generation.steps');
        }
        if (settings['cfg_scale'] case final num n when n < 0) {
          invalid('generation.cfg_scale');
        }
        if (settings['cfg_rescale'] case final num n when n < 0 || n > 1) {
          invalid('generation.cfg_rescale');
        }
        if (settings['seed'] case final num n when n < -1 || n > 4294967295) {
          invalid('generation.seed');
        }
        if (settings['uc_preset'] case final num n
            when !{0, 1, 2, 3, 7, 8, 9}.contains(n)) {
          invalid('generation.uc_preset');
        }
      }
      return {
        'card_id': id,
        'icon': icon(item, 'icon'),
        'title': string(item, 'title', 40, required: true),
        'note': string(item, 'note', 240),
        'main': string(item, 'main', 16384),
        'negative': string(item, 'negative', 16384),
        'characters': chars,
        if (negatives.isNotEmpty)
          'character_negatives': negatives.cast<String>(),
        if (coords != null || (points?.any((p) => p != null) ?? false))
          'use_coords': coords ?? true,
        if (points != null && coords != false) 'positions': points,
        if (settings is Map && settings.isNotEmpty)
          'generation': {
            for (final e in settings.entries)
              e.key:
                  const {
                    'width',
                    'height',
                    'steps',
                    'uc_preset',
                    'seed',
                  }.contains(e.key)
                  ? (e.value as num).toInt()
                  : e.value,
          },
      };
    }

    final shared = input['shared'];
    final items = input['items'];
    if ((shared != null && shared is! Map) ||
        items is! List ||
        items.length < (shared == null ? 1 : 2) ||
        items.length > 24 ||
        input['ordered'] is! bool) {
      invalid('shared/items/ordered');
    }
    final header = {
      'kind': string(input, 'kind', 24, required: true),
      'kind_icon': icon(input, 'kind_icon'),
      'title': string(input, 'title', 60, required: true),
      'unit': string(input, 'unit', 8, required: true),
      'ordered': input['ordered'],
    };
    if (shared == null) {
      final cards = [
        for (final item in items)
          if (item is Map) independentItem(item) else invalid('item'),
      ];
      if (cards.map((c) => c['card_id']).toSet().length != cards.length) {
        invalid('duplicate card_id');
      }
      return {...header, 'items': cards};
    }
    if (items.any((item) => item is Map && item.containsKey('card_id'))) {
      invalid('mixed shared and independent cards');
    }
    final chars = characters(shared as Map, 1000, 6);
    return {
      ...header,
      'shared': {
        'main': string(shared, 'main', 2000),
        'characters': chars,
        if (shared.containsKey('positions'))
          'positions': positions(shared, chars.length),
        'negative': string(shared, 'negative', 2000),
      },
      'items': [
        for (final item in items)
          if (item is Map)
            {
              'icon': icon(item, 'icon'),
              'title': string(item, 'title', 40, required: true),
              'note': string(item, 'note', 240),
              'main': string(item, 'main', 1000),
              'characters': characters(item, 600, chars.length),
              if (item.containsKey('positions'))
                'positions': positions(item, chars.length),
            }
          else
            invalid('item'),
      ],
    };
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) => _locked(() async {
    token.check();
    final action = params['action'];
    if (!['create', 'update', 'read'].contains(action)) {
      throw const NaiAgentToolError(
        'invalid_action',
        'Use create, update or read',
      );
    }
    Map<String, dynamic>? old;
    if (action != 'create') {
      validateId(params['set_id']);
      old = await read(params['set_id'] as String);
      if (old == null) {
        throw const NaiAgentToolError('set_missing', 'Prompt set not found');
      }
    }
    if (action == 'read') {
      final images = old!['images'] as Map? ?? {};
      return naiAgentTextResult({
        ...old,
        'ok': true,
        'count': (old['items'] as List).length,
        'images': {
          for (var i = 0; i < (old['items'] as List).length; i++)
            '$i': (images['$i'] as List? ?? []).length,
        },
      });
    }
    if (action == 'update' &&
        (params['expected_revision'] is! int ||
            params['expected_revision'] != old!['revision'])) {
      throw const NaiAgentToolError(
        'revision_conflict',
        'Read the set and retry with its current expected_revision',
      );
    }
    var input = params;
    if (params.containsKey('card')) {
      final card = params['card'];
      if (old == null || card is! Map || params.containsKey('items')) {
        throw const NaiAgentToolError(
          'invalid_prompt_set',
          'Use card only for a single-card update',
        );
      }
      final items = List.of(old['items'] as List);
      final index = items.indexWhere(
        (item) => item['card_id'] == card['card_id'],
      );
      if (index < 0) {
        throw const NaiAgentToolError(
          'card_missing',
          'Read the set for its current card IDs',
        );
      }
      items[index] = card;
      input = {...old, 'items': items};
    }
    final content = independentPromptSet(validate(input));
    final items = content['items'] as List;
    final previous = old?['items'] as List? ?? const [];
    final byId = {for (final (i, card) in previous.indexed) card['card_id']: i};
    final changed = [
      if (old != null)
        for (final (i, card) in items.indexed)
          if (byId[card['card_id']] == null ||
              !const DeepCollectionEquality().equals(
                card,
                previous[byId[card['card_id']]!],
              ))
            i,
    ];
    String id;
    if (old != null) {
      id = old['set_id'] as String;
    } else {
      do {
        id = List.generate(
          6,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
      } while (await read(id) != null);
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final value = <String, dynamic>{
      'set_id': id,
      if (chatId != null) 'chat_id': chatId,
      'revision': (old?['revision'] as int? ?? 0) + 1,
      'created_at': old?['created_at'] ?? now,
      'updated_at': now,
      ...content,
      'changed_items': changed,
      'images': {
        for (final (i, card) in items.indexed)
          if (old?['images']?['${byId[card['card_id']]}']
              case final List images)
            '$i': images,
      },
    };
    token.check();
    await _write(value);
    return naiAgentTextResult({
      'ok': true,
      'set_id': id,
      'revision': value['revision'],
      'count': items.length,
      'changed_items': changed,
      'title': value['title'],
    });
  });

  Future<void> appendImages(
    String id,
    int index,
    List<Map<String, dynamic>> images, {
    String? cardId,
  }) => _locked(() async {
    final value = await read(id);
    if (value != null && cardId != null) {
      index = (value['items'] as List).indexWhere(
        (card) => card['card_id'] == cardId,
      );
    }
    if (value == null ||
        index < 0 ||
        index >= (value['items'] as List).length) {
      throw const NaiAgentToolError('set_missing', 'Prompt set item not found');
    }
    final all = Map<String, dynamic>.from(value['images'] as Map? ?? {});
    all['$index'] = [...all['$index'] as List? ?? [], ...images];
    value['images'] = all;
    value['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _write(value);
  });
}
