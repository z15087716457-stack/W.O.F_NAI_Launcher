import 'dart:convert';

import '../../data/models/prompt_block/pill_document.dart';
import 'nai_prompt_syntax.dart';
import 'pill_document_editor.dart';

typedef PromptTranslationGroup = ({int start, int end, String zh});

/// A lossless request snapshot. The model can group segment IDs, but it never
/// supplies source text or offsets for document mutation.
class PromptTranslationSegment {
  const PromptTranslationSegment({
    required this.id,
    required this.fieldId,
    required this.run,
    required this.start,
    required this.end,
    required this.source,
  });

  final String id;
  final String fieldId;
  final int run;
  final int start;
  final int end;
  final String source;
}

class PromptTranslationBatch {
  PromptTranslationBatch._(this.documents, this.segments);

  final Map<String, PillDocument> documents;
  final Map<String, List<PromptTranslationSegment>> segments;

  bool get isEmpty => segments.values.every((items) => items.isEmpty);

  /// Normal requests stay whole. Very long requests are split at segment
  /// boundaries while retaining the same immutable source snapshot.
  List<PromptTranslationBatch> partitions({int maxSourceChars = 18000}) {
    final result = <PromptTranslationBatch>[];
    var current = <String, List<PromptTranslationSegment>>{};
    var count = 0;
    void flush() {
      if (current.isEmpty) return;
      result.add(PromptTranslationBatch._(documents, current));
      current = {};
      count = 0;
    }

    for (final entry in segments.entries) {
      for (final item in entry.value) {
        if (count > 0 && count + item.source.length > maxSourceChars) flush();
        current.putIfAbsent(entry.key, () => []).add(item);
        count += item.source.length;
      }
    }
    flush();
    return result;
  }

  factory PromptTranslationBatch.prepare(Map<String, PillDocument> documents) {
    final fields = <String, List<PromptTranslationSegment>>{};
    for (final entry in documents.entries) {
      final field = entry.key;
      final document = entry.value;
      final items = <PromptTranslationSegment>[];
      final text = document.text;
      var run = 0;
      var start = 0;
      void collect(int end) {
        if (start >= end || text.substring(start, end).trim().isEmpty) return;
        final source = text.substring(start, end);
        final cuts = <int>{};
        for (final token in NaiPromptSyntax.scan(source)) {
          if (token.kind == NaiPromptTokenKind.comma) cuts.add(token.end);
          if (token.kind == NaiPromptTokenKind.text) {
            for (var i = token.start; i < token.end; i++) {
              if (source.codeUnitAt(i) == 10) cuts.add(i + 1);
            }
          }
        }
        var local = 0;
        for (final cut in [...cuts.toList()..sort(), source.length]) {
          if (cut <= local) continue;
          final slice = source.substring(local, cut);
          if (slice.trim().isNotEmpty) {
            items.add(
              PromptTranslationSegment(
                id: '$field:${items.length}',
                fieldId: field,
                run: run,
                start: start + local,
                end: start + cut,
                source: slice,
              ),
            );
          }
          local = cut;
        }
      }

      for (var i = 0; i < text.length; i++) {
        if (!isPillMarkerCodeUnit(text.codeUnitAt(i))) continue;
        collect(i);
        start = i + 1;
        run++;
      }
      collect(text.length);
      fields[field] = items;
    }
    return PromptTranslationBatch._(Map.unmodifiable(documents), fields);
  }

  /// Exact candidates only. The caller verifies these against the unified
  /// Danbooru catalog before adding any entry to the glossary.
  Set<String> get tagCandidates {
    final result = <String>{};
    final allowed = RegExp(r'^[a-zA-Z0-9_():.!+\- ]+$');
    for (final item in segments.values.expand((items) => items)) {
      var value = item.source.trim().replaceFirst(RegExp(r'[,，]\s*$'), '');
      value = value.replaceFirst(RegExp(r'^[-+]?\d+(?:\.\d+)?::'), '');
      value = value.replaceFirst(RegExp(r'::$'), '');
      while (value.length > 2 &&
          ((value.startsWith('{') && value.endsWith('}')) ||
              (value.startsWith('[') && value.endsWith(']')))) {
        value = value.substring(1, value.length - 1).trim();
      }
      if (value.length > 80 || !allowed.hasMatch(value)) continue;
      result.add(value.toLowerCase().replaceAll(' ', '_'));
      if (result.length >= 160) return result;
    }
    return result;
  }

  String requestJson(List<Map<String, String>> glossary) => jsonEncode({
    'fields': [
      for (final entry in segments.entries)
        if (entry.value.isNotEmpty)
          {
            'id': entry.key,
            'segments': [
              for (final item in entry.value)
                {'id': item.id, 'run': item.run, 'source': item.source},
            ],
          },
    ],
    'glossary': glossary,
  });

  /// Validate full ordered coverage. The model supplies no source text or
  /// offsets, so every returned group is anchored to local snapshot ranges.
  Map<String, List<PromptTranslationGroup>> parseGroups(String raw) {
    final decoded = jsonDecode(raw.trim());
    if (decoded is! Map || decoded['fields'] is! List) {
      throw const FormatException('Translation response needs fields');
    }
    final output = decoded['fields'] as List;
    final expected = segments.entries.where((e) => e.value.isNotEmpty).toList();
    if (output.length != expected.length) {
      throw const FormatException('Translation fields are incomplete');
    }
    final result = <String, List<PromptTranslationGroup>>{};
    for (var fieldIndex = 0; fieldIndex < expected.length; fieldIndex++) {
      final entry = expected[fieldIndex];
      final response = output[fieldIndex];
      if (response is! Map ||
          response['id'] != entry.key ||
          response['groups'] is! List) {
        throw const FormatException('Translation field ID is invalid');
      }
      final items = entry.value;
      final groups = <PromptTranslationGroup>[];
      var cursor = 0;
      for (final rawGroup in response['groups'] as List) {
        if (rawGroup is! Map ||
            rawGroup['ids'] is! List ||
            rawGroup['zh'] is! String) {
          throw const FormatException('Translation group is invalid');
        }
        final ids = rawGroup['ids'] as List;
        final zh = (rawGroup['zh'] as String).trim();
        if (ids.isEmpty || zh.isEmpty || zh.length > 20000) {
          throw const FormatException('Translation group is empty or too long');
        }
        if (cursor >= items.length) {
          throw const FormatException('Translation contains extra groups');
        }
        final first = cursor;
        final run = items[cursor].run;
        for (final id in ids) {
          if (cursor >= items.length ||
              id != items[cursor].id ||
              items[cursor].run != run) {
            throw const FormatException('Translation IDs are out of order');
          }
          cursor++;
        }
        groups.add((
          start: items[first].start,
          end: items[cursor - 1].end,
          zh: zh,
        ));
      }
      if (cursor != items.length) {
        throw const FormatException('Translation segments are incomplete');
      }
      result[entry.key] = groups;
    }
    return result;
  }

  /// Apply validated groups from one request or multiple large-request parts.
  Map<String, PillDocument> buildFromGroups(
    Map<String, List<PromptTranslationGroup>> allGroups,
  ) {
    final result = <String, PillDocument>{};
    for (final entry in allGroups.entries) {
      final original = documents[entry.key]!;
      var text = original.text;
      final instances = Map<String, PillInstance>.of(original.instances);
      for (final group in entry.value.reversed) {
        final marker = PillDocumentEditor.allocateMarker(
          PillDocument(text: text, instances: instances),
        );
        instances[marker] = PillInstance(
          blockId: '',
          translation: TranslationPill(
            source: original.text.substring(group.start, group.end),
            zh: group.zh,
          ),
        );
        text = text.replaceRange(group.start, group.end, marker);
      }
      result[entry.key] = PillDocument(text: text, instances: instances);
    }
    return result;
  }

  /// Convenience for a single model response.
  Map<String, PillDocument> parseAndBuild(String raw) =>
      buildFromGroups(parseGroups(raw));
}
