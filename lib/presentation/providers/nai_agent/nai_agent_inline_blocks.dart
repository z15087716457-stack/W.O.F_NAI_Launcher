part of 'nai_agent_block_binding.dart';

bool _hasDisplay(Map<String, dynamic> changes) =>
    const ['title', 'color', 'icon'].any(changes.containsKey);

void _validateDisplay(Map<String, dynamic> changes, {bool required = false}) {
  if (required || changes.containsKey('title')) {
    final title = changes['title'];
    if (title is! String ||
        title.trim().isEmpty ||
        title.trim().runes.length > 40) {
      throw const NaiAgentToolError(
        'invalid_arguments',
        'instance.title must contain 1..40 characters after trimming',
      );
    }
    changes['title'] = title.trim();
  }
  if (changes.containsKey('color')) {
    final color = changes['color'];
    if (color is! String ||
        !RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(color)) {
      throw const NaiAgentToolError(
        'invalid_arguments',
        'instance.color must be #RRGGBB or #AARRGGBB',
      );
    }
    changes['color'] = (color.length == 7 ? '#FF${color.substring(1)}' : color)
        .toUpperCase();
  }
  if (changes.containsKey('icon') &&
      !kPromptBlockIconOptions.containsKey(changes['icon'])) {
    throw const NaiAgentToolError(
      'invalid_arguments',
      'instance.icon must be a preset key from nai-studio/references/blocks.md',
    );
  }
}

TranslationPill _translation(
  Object? raw, {
  TranslationPill? original,
  String? selected,
}) {
  if (raw is! Map ||
      raw.keys.any(
        (key) => !const {'source', 'zh', 'language_code'}.contains(key),
      )) {
    throw const NaiAgentToolError(
      'invalid_translation',
      'Provide translation source/zh/language_code',
    );
  }
  for (final key in ['source', 'zh']) {
    if (raw.containsKey(key) &&
        (raw[key] is! String ||
            (raw[key] as String).isEmpty ||
            (raw[key] as String).length > 100000 ||
            PillDocumentEditor.stripMarkers(raw[key] as String) != raw[key])) {
      throw NaiAgentToolError(
        'invalid_translation',
        'Expected nonempty marker-free translation.$key (max 100000 UTF-16 units)',
      );
    }
  }
  if (selected != null &&
      raw.containsKey('source') &&
      raw['source'] != selected) {
    throw const NaiAgentToolError(
      'invalid_translation',
      'Converted translation.source must equal the selected text',
    );
  }
  final source = selected ?? raw['source'] as String? ?? original?.source;
  final zh = raw['zh'] as String? ?? original?.zh;
  if (source == null || zh == null) {
    throw const NaiAgentToolError(
      'invalid_translation',
      'translation.source and translation.zh are required',
    );
  }
  final language = raw['language_code'] ?? original?.languageCode ?? 'zh';
  if (!PromptTranslationLanguage.isCode(language)) {
    throw const NaiAgentToolError(
      'invalid_translation',
      'language_code must be zh, zh-TW, en, ja or ko',
    );
  }
  final sourceChanged = original != null && source != original.source;
  return TranslationPill(
    source: source,
    zh: zh,
    marks: zh == original?.zh ? original!.marks : const [],
    languageCode: language as String,
    translationEdited: true,
    showOriginal: original?.showOriginal ?? false,
    needsReview:
        !raw.containsKey('zh') &&
        (sourceChanged || (original?.needsReview ?? false)),
  );
}

PillAnchorRange _anchor(
  Object? raw,
  PillDocument document, {
  required bool replace,
}) {
  if (raw is! Map ||
      raw.keys.any(
        (key) => !const {'text', 'occurrence', 'mode'}.contains(key),
      ) ||
      raw['text'] is! String ||
      (raw['text'] as String).isEmpty ||
      (raw.containsKey('occurrence') &&
          (raw['occurrence'] is! int || (raw['occurrence'] as int) < 0)) ||
      !(replace ? const {'replace'} : const {'before', 'after'}).contains(
        raw['mode'],
      )) {
    throw const NaiAgentToolError(
      'invalid_position',
      'anchor needs nonempty text, optional zero-based occurrence and a valid mode',
    );
  }
  try {
    return PillDocumentEditor.resolveAnchor(
      document.text,
      raw['text'] as String,
      occurrence: raw['occurrence'] as int?,
    );
  } on PillAnchorException catch (error) {
    throw NaiAgentToolError(
      error.code,
      'Anchor failed (${error.matches} matches)',
      {'matches': error.matches},
    );
  }
}

int _insertionPosition(Map<String, dynamic> params, PillDocument document) {
  if (params.containsKey('offset') && params.containsKey('anchor')) {
    throw const NaiAgentToolError(
      'invalid_position',
      'offset and anchor are mutually exclusive',
    );
  }
  if (params.containsKey('anchor')) {
    final range = _anchor(params['anchor'], document, replace: false);
    return (params['anchor'] as Map)['mode'] == 'before'
        ? range.start
        : range.end;
  }
  final offset = params['offset'];
  if (offset != null &&
      (offset is! int ||
          !PillDocumentEditor.isUtf16Boundary(document.text, offset))) {
    throw const NaiAgentToolError(
      'invalid_offset',
      'offset must be a raw document UTF-16 boundary; omit to append',
    );
  }
  return offset as int? ?? document.text.length;
}

/// Resolve generation-text anchors while preserving complete reading blocks.
({PillAnchorRange range, String content, List<TranslationPill> translations})
_temporarySelection(Object? anchor, PillDocument document) {
  final projected = StringBuffer();
  final boundaries = <int, int>{0: 0};
  for (var index = 0; index < document.text.length; index++) {
    final marker = document.text[index];
    final instance = document.instances[marker];
    if (instance?.translation != null &&
        !instance!.temporary &&
        instance.enabled) {
      projected.write(instance.translation!.source);
    } else {
      projected.write(marker);
    }
    boundaries[projected.length] = index + 1;
  }
  final range = _anchor(
    anchor,
    PillDocument(text: projected.toString(), instances: const {}),
    replace: true,
  );
  final start = boundaries[range.start], end = boundaries[range.end];
  if (start == null || end == null) {
    throw const NaiAgentToolError(
      'invalid_position',
      'Include complete translation blocks when converting to a temporary block',
    );
  }
  final translations = <TranslationPill>[];
  for (var index = start; index < end; index++) {
    final instance = document.instances[document.text[index]];
    if (instance?.translation != null &&
        !instance!.temporary &&
        instance.enabled) {
      translations.add(instance.translation!);
    }
  }
  return (
    range: (start: start, end: end),
    content: projected.toString().substring(range.start, range.end),
    translations: translations,
  );
}

void _validateTempTranslations(
  String content,
  List<TranslationPill> translations,
) {
  if (PillTempContent.retainTranslations(content, translations).length !=
      translations.length) {
    throw const NaiAgentToolError(
      'invalid_translation',
      'Translation sources must occur completely in content, in source order',
    );
  }
}

List<PillInlineEdit> _inlinePlan(
  Map<String, dynamic> params,
  PillDocument document,
) {
  final convert = params['action'] == 'instance_convert';
  final segments = convert ? params['segments'] : [params];
  if (segments is! List || segments.isEmpty || segments.length > 64) {
    throw const NaiAgentToolError(
      'invalid_arguments',
      'Provide 1..64 segments',
    );
  }
  final edits = <PillInlineEdit>[];
  for (var index = 0; index < segments.length; index++) {
    try {
      final raw = segments[index];
      if (raw is! Map ||
          (convert &&
              raw.keys.any(
                (key) => !const {
                  'anchor',
                  'kind',
                  'instance',
                  'translation',
                }.contains(key),
              ))) {
        throw const NaiAgentToolError(
          'invalid_arguments',
          'Invalid segment object',
        );
      }
      final part = Map<String, dynamic>.from(raw);
      final kind = part['kind'];
      if (kind != 'temporary' && kind != 'translation') {
        throw const NaiAgentToolError(
          'unsupported_kind',
          'kind must be temporary or translation',
        );
      }
      final changes = _instanceChanges(
        part['instance'],
        optional: true,
        inline: true,
      );
      if (changes.containsKey('negative_content') ||
          changes.containsKey('negative_translations')) {
        throw const NaiAgentToolError(
          'unsupported_bundle',
          'Inline creation/conversion does not support negative_content; create a separate negative-scope instance',
        );
      }
      if (kind == 'translation' &&
          (changes.containsKey('content') ||
              changes.containsKey('translations') ||
              _hasDisplay(changes))) {
        throw const NaiAgentToolError(
          'invalid_arguments',
          'Translation instances do not accept content/title/color/icon',
        );
      }
      if (kind == 'temporary' && part.containsKey('translation')) {
        throw const NaiAgentToolError(
          'invalid_arguments',
          'Temporary instances do not accept translation',
        );
      }
      final PillAnchorRange range;
      String? selectedContent;
      var selectedTranslations = <TranslationPill>[];
      if (convert) {
        if (kind == 'temporary') {
          final selected = _temporarySelection(part['anchor'], document);
          range = selected.range;
          selectedContent = selected.content;
          selectedTranslations = selected.translations;
        } else {
          range = _anchor(part['anchor'], document, replace: true);
        }
      } else {
        final offset = _insertionPosition(part, document);
        range = (start: offset, end: offset);
      }
      final selected = convert
          ? selectedContent ?? document.text.substring(range.start, range.end)
          : null;
      if (edits.any(
        (other) => range.start < other.end && other.start < range.end,
      )) {
        throw const NaiAgentToolError(
          'overlapping_segments',
          'Segments must not overlap',
        );
      }
      if (convert && changes['enabled'] == false) {
        throw const NaiAgentToolError(
          'projection_changed',
          'Converted segments must remain enabled',
        );
      }
      PillTempContent? temp;
      TranslationPill? translation;
      if (kind == 'temporary') {
        _validateDisplay(changes, required: true);
        final content = selected ?? changes['content'];
        if (content is! String ||
            PillDocumentEditor.stripMarkers(content) != content) {
          throw const NaiAgentToolError(
            'invalid_arguments',
            'instance.content is required and must not contain markers',
          );
        }
        if (convert &&
            changes.containsKey('content') &&
            changes['content'] != selected) {
          throw const NaiAgentToolError(
            'invalid_arguments',
            'Converted content must equal the selected text',
          );
        }
        final translations =
            changes['translations'] as List<TranslationPill>? ??
            selectedTranslations;
        _validateTempTranslations(content, translations);
        temp = PillTempContent(
          content: content,
          originalContent: '',
          editedAt: DateTime.now(),
          editedBy: 'agent',
          title: changes['title'] as String,
          color: changes['color'] as String?,
          iconName: changes['icon'] as String?,
          translations: translations,
        );
      } else {
        translation = _translation(part['translation'], selected: selected);
      }
      edits.add(
        PillInlineEdit(
          start: range.start,
          end: range.end,
          temp: temp,
          translation: translation,
          enabled: changes['enabled'] as bool? ?? true,
        ),
      );
    } on NaiAgentToolError catch (error) {
      if (!convert) rethrow;
      throw NaiAgentToolError(
        error.code,
        'Segment ${index + 1}: ${error.message}',
        {...error.details, 'segment': index + 1},
      );
    }
  }
  return edits;
}

void _validateExisting(Map<String, dynamic> params, PillInstance instance) {
  final action = params['action'];
  if (action == 'instance_update') {
    final changes = _instanceChanges(
      params['instance'],
      optional: params.containsKey('translation'),
    );
    for (final (key, text) in [
      ('translations', changes['content'] as String? ?? instance.temp?.content),
      (
        'negative_translations',
        changes['negative_content'] as String? ??
            instance.temp?.negativeContent,
      ),
    ]) {
      if (!changes.containsKey(key)) continue;
      if (text == null) {
        throw const NaiAgentToolError(
          'invalid_translation',
          'Provide content together with translations when editing a library block',
        );
      }
      _validateTempTranslations(text, changes[key] as List<TranslationPill>);
    }
    if (_hasDisplay(changes) &&
        (instance.blockId.isNotEmpty || !instance.temporary)) {
      throw const NaiAgentToolError(
        'unsupported_kind',
        'Display fields can only edit library-free temporary blocks',
      );
    }
    if (instance.blockId.isEmpty &&
        !instance.temporary &&
        instance.translation == null) {
      throw const NaiAgentToolError(
        'unsupported_kind',
        'Invalid empty block instance',
      );
    }
    if (instance.blockId.isEmpty &&
        (changes.containsKey('negative_content') ||
            changes.containsKey('negative_translations'))) {
      throw const NaiAgentToolError(
        'unsupported_bundle',
        'Library-free instances do not support negative_content',
      );
    }
    if (params.containsKey('translation')) {
      if (instance.translation == null ||
          instance.temporary ||
          changes.containsKey('content') ||
          changes.containsKey('negative_content')) {
        throw const NaiAgentToolError(
          'unsupported_kind',
          'Use translation fields only on a non-temporary translation instance',
        );
      }
      _translation(params['translation'], original: instance.translation);
    }
  } else if (action == 'instance_promote') {
    if (instance.translation != null || instance.temp == null) {
      throw const NaiAgentToolError(
        'unsupported_kind',
        'Only temporary blocks can be promoted; translations are unsupported',
      );
    }
    final raw = params['changes'] ?? <String, dynamic>{};
    if (raw is! Map ||
        raw.keys.any(
          (key) =>
              !const {'title', 'folderId', 'color', 'iconName'}.contains(key),
        )) {
      throw const NaiAgentToolError(
        'invalid_changes',
        'Promote accepts title/folderId/color/iconName',
      );
    }
    validateNaiAgentBlockChanges({
      'title': instance.temp!.title,
      ...Map<String, dynamic>.from(raw),
    });
  }
}

Set<String> _affectedScopes(
  Map<String, dynamic> params,
  BridgeDraftSnapshot draft,
  String scope,
) {
  final scopes = <String>{scope};
  if (_document(draft, scope).instances[params['marker']]?.bundleId != null) {
    if (scope == PillScopes.main || scope == PillScopes.negative) {
      scopes.addAll([PillScopes.main, PillScopes.negative]);
    } else {
      final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope)!;
      scopes.addAll([
        PillScopes.charPos(match[1]!),
        PillScopes.charNeg(match[1]!),
      ]);
    }
  }
  return scopes;
}

String _draftProjection(BridgeDraftSnapshot draft, String scope) {
  if (scope == PillScopes.main) return draft.fields['prompt'] as String;
  if (scope == PillScopes.negative) {
    return draft.fields['negative_prompt'] as String;
  }
  final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope)!;
  final character = (draft.fields['characters'] as List)
      .cast<Map>()
      .singleWhere((c) => c['id'] == match[1]);
  return character[match[2] == 'pos' ? 'prompt' : 'uc'] as String;
}

List<String> _applyInline(
  Ref ref,
  Map<String, dynamic> params,
  String scope,
  PillDocument document,
  String projection,
) {
  final provider = pillWorkspaceProvider(scope);
  final edits = _inlinePlan(params, document);
  final lane = ref.read(provider.notifier);
  final convert = params['action'] == 'instance_convert';
  final tail = document.text.trimRight();
  final prefix =
      !convert &&
          !params.containsKey('offset') &&
          !params.containsKey('anchor') &&
          tail.isNotEmpty &&
          !tail.endsWith(',')
      ? ', '
      : '';
  // Keep the native translation insertion entry point for single creation.
  final translation = convert ? null : edits.single.translation;
  if (translation != null) {
    final edit = edits.single;
    final marker = PillDocumentEditor.allocateMarker(document);
    lane.insertTranslationAt(
      offset: edit.start,
      source: translation.source,
      zh: translation.zh,
      languageCode: translation.languageCode,
      translationEdited: true,
      enabled: edit.enabled,
      prefix: prefix,
      document: document,
    );
    return [marker];
  }
  return lane.applyInlineEdits(
    edits,
    prefix: prefix,
    document: document,
    afterApply: convert
        ? () {
            if (ref.read(provider).projection != projection) {
              throw const NaiAgentToolError(
                'projection_changed',
                'Conversion changed the generation projection; operation rolled back',
              );
            }
          }
        : null,
  );
}

void _removeInline(Ref ref, Map<String, dynamic> params, String scope) {
  final lane = ref.read(pillWorkspaceProvider(scope).notifier);
  var marker = params['marker'] as String;
  if (params['action'] == 'instance_delete') {
    if (params.containsKey('occurrence')) {
      marker = lane.isolateMarkerOccurrence(
        marker,
        occurrence: params['occurrence'] as int,
      );
    }
    lane.removeMarker(marker);
  } else {
    final original = ref
        .read(pillWorkspaceProvider(scope))
        .document
        .instances[marker]!;
    if (original.translation != null && original.bundleId == null) {
      marker = lane.isolateMarkerOccurrence(
        marker,
        occurrence: params['occurrence'] as int? ?? 0,
      );
      lane.unwrapTranslation(marker, source: original.translation!.source);
    } else {
      // Native expansion also unwraps both faces of library-backed bundles.
      lane.expandMarker(marker, occurrence: params['occurrence'] as int? ?? 0);
    }
  }
}

Map<String, dynamic> _readback(
  Ref ref,
  Set<String> scopes,
  Map<String, Set<String>> priorMarkers,
) {
  final result = <String, dynamic>{};
  for (final key in scopes) {
    final actual = ref.read(pillWorkspaceProvider(key));
    if (key == PillScopes.main) {
      ref
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately(actual.projection);
    } else if (key == PillScopes.negative) {
      ref
          .read(generationParamsNotifierProvider.notifier)
          .updateNegativePromptImmediately(actual.projection);
    } else {
      ref
          .read(pillRollCoordinatorProvider)
          .syncLaneProjection(key, actual.projection);
    }
    result[key] = {
      'document': actual.document.toJson(),
      'projection': actual.projection,
      'inserted_markers': actual.document.instances.keys
          .where(
            (m) =>
                !(priorMarkers[key] ?? actual.document.instances.keys.toSet())
                    .contains(m),
          )
          .toList(),
    };
  }
  return result;
}
