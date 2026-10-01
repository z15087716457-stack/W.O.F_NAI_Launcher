import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tag_expansion/tag_expansion_providers.dart';
import '../../core/autocomplete/tag_translation_lookup.dart';
import '../../core/autocomplete/chinese_term_matcher.dart';
import '../../core/utils/prompt_translation_document.dart';
import '../../core/utils/prompt_translation_edit.dart';
import '../../core/utils/prompt_translation_language.dart';
import '../../core/utils/tag_normalizer.dart';
import '../../core/utils/nai_prompt_syntax.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../prompt_assistant/services/prompt_assistant_service.dart';
import 'character_prompt_provider.dart';
import 'image_generation_provider.dart';
import 'pill_workspace_provider.dart';
import 'locale_provider.dart';

/// Only verified, unambiguous category metadata becomes an editor decoration.
final promptTranslationAnnotationProvider =
    Provider<Future<List<TranslationTagMark>> Function(String, bool)>((ref) {
      final tags = ref.read(unifiedTagRepositoryProvider);
      final chineseLookup = ref.read(chinesePromptTermLookupProvider);
      return (text, chinese) async {
        if (chinese) {
          final hits = await chineseLookup(text);
          return [
            for (final hit in hits)
              if (hits
                      .where(
                        (other) =>
                            other.start == hit.start && other.end == hit.end,
                      )
                      .length ==
                  1)
                TranslationTagMark(
                  start: hit.start,
                  end: hit.end,
                  tag: hit.candidate.canonicalTag,
                  iconId: hit.candidate.category.name,
                ),
          ];
        }
        final candidates = await tags.byNames(_editorTagCandidates(text));
        final marks = <TranslationTagMark>[];
        final boundary = RegExp(r'[a-zA-Z0-9_@]');
        for (final candidate in candidates) {
          final pattern = RegExp(
            candidate.canonicalTag.split('_').map(RegExp.escape).join(r'[ _]+'),
            caseSensitive: false,
          );
          for (final match in pattern.allMatches(text)) {
            if ((match.start > 0 && boundary.hasMatch(text[match.start - 1])) ||
                (match.end < text.length &&
                    boundary.hasMatch(text[match.end]))) {
              continue;
            }
            marks.add(
              TranslationTagMark(
                start: match.start,
                end: match.end,
                tag: candidate.canonicalTag,
                iconId: candidate.category.name,
              ),
            );
          }
        }
        marks.sort((a, b) => a.start.compareTo(b.start));
        return marks;
      };
    });

Set<String> _editorTagCandidates(String text) {
  final result = PromptTranslationBatch.prepare({
    'draft': PillDocument(text: text, instances: const {}),
  }).tagCandidates;
  void collect(String value) {
    for (final token in NaiPromptSyntax.scan(value)) {
      if (token.kind != NaiPromptTokenKind.group ||
          (token.start > 0 &&
              !RegExp(r'[\s,，:{}\[\]]').hasMatch(value[token.start - 1]))) {
        continue;
      }
      final inner = token
          .source(value)
          .substring(1, token.end - token.start - 1);
      result.addAll(
        PromptTranslationBatch.prepare({
          'draft': PillDocument(text: inner, instances: const {}),
        }).tagCandidates,
      );
      if (result.length >= 160) return;
      collect(inner);
    }
  }

  collect(text);
  return result.take(160).toSet();
}

final promptTranslationBusyProvider = StateProvider<bool>((ref) => false);

final promptTranslationCoordinatorProvider =
    Provider<PromptTranslationCoordinator>(
      (ref) => PromptTranslationCoordinator(ref),
    );

class PromptTranslationResult {
  const PromptTranslationResult(
    this.convertedFields,
    this.skippedChangedFields,
  );
  final int convertedFields;
  final int skippedChangedFields;
}

class PromptTranslationCoordinator {
  PromptTranslationCoordinator(this._ref);
  final Ref _ref;
  final Map<String, bool> _draftRequests = {};

  void cancelDraft(String sessionId) {
    if (_draftRequests.containsKey(sessionId)) _draftRequests[sessionId] = true;
  }

  /// Produces an editor draft only. Saving remains the host editor's job.
  Future<PromptTranslationEditResult> convertDraft(
    PromptTranslationEditRequest request, {
    required String sessionId,
  }) async {
    _draftRequests[sessionId] = false;
    try {
      if (request.input.trim().isEmpty) {
        throw const FormatException('请先输入需要转换的内容');
      }
      final batch = PromptTranslationBatch.prepare({
        'draft': PillDocument(text: request.source, instances: const {}),
      });
      final glossary = await _glossaryFor(batch);
      final byTag = {for (final item in glossary) item['tag']!: item};
      final activeTerms = request.selectedTerms
          .where(
            (term) =>
                term.start >= 0 &&
                term.end <= request.zh.length &&
                request.zh.substring(term.start, term.end) == term.text,
          )
          .toList();
      try {
        final picked = await _ref
            .read(unifiedTagRepositoryProvider)
            .byNames(activeTerms.map((term) => term.tag).toList());
        for (final candidate in picked) {
          final term = activeTerms.firstWhere(
            (term) => term.tag == candidate.canonicalTag,
          );
          byTag[candidate.canonicalTag] = {
            'tag': candidate.canonicalTag,
            'title': TagNormalizer.toDisplay(candidate.canonicalTag),
            if (request.languageCode == 'zh') 'zh': term.text,
            'matched_text': term.text,
            'icon_id': candidate.category.name,
          };
        }
        final hits = request.languageCode == 'zh'
            ? await _ref.read(chinesePromptTermLookupProvider)(request.zh)
            : const <ChineseTermHit>[];
        for (final hit in hits) {
          final candidate = hit.candidate;
          byTag.putIfAbsent(
            candidate.canonicalTag,
            () => {
              'tag': candidate.canonicalTag,
              'title': TagNormalizer.toDisplay(candidate.canonicalTag),
              'zh':
                  candidate.translation ??
                  request.zh.substring(hit.start, hit.end),
              'matched_text': request.zh.substring(hit.start, hit.end),
              'icon_id': candidate.category.name,
              'match': 'candidate',
            },
          );
        }
      } catch (_) {
        // Optional local terminology never blocks natural-language conversion.
      }
      if (_draftRequests[sessionId] == true) throw StateError('转换已取消');
      final pickedTags = activeTerms.map((term) => term.tag).toSet();
      final terms = [
        for (final tag in pickedTags)
          if (byTag[tag] != null) byTag[tag]!,
        for (final item in byTag.values)
          if (!pickedTags.contains(item['tag'])) item,
      ].take(64).toList(growable: false);
      final raw = await _ref
          .read(promptAssistantServiceProvider)
          .translatePromptEdit(
            request.requestJson(terms),
            sessionId: sessionId,
          );
      if (_draftRequests[sessionId] == true) throw StateError('转换已取消');
      return PromptTranslationEditResult.parse(raw, request, terms);
    } finally {
      _draftRequests.remove(sessionId);
    }
  }

  Map<String, ({PillDocument before, PillDocument after})> _lastUndo = {};
  final Map<bool, Map<String, ({PillDocument before, PillDocument after})>>
  _plainTextUndo = {};

  List<String> _scopes(bool negative, {bool includeDisabled = false}) {
    final characters = _ref.read(characterPromptNotifierProvider).characters;
    return [
      negative ? PillScopes.negative : PillScopes.main,
      for (final character in characters)
        if (includeDisabled || character.enabled)
          negative
              ? PillScopes.charNeg(character.id)
              : PillScopes.charPos(character.id),
    ];
  }

  void _seedIfNeeded(String scope) {
    final provider = pillWorkspaceProvider(scope);
    final document = _ref.read(provider).document;
    if (document.text.isNotEmpty || document.instances.isNotEmpty) return;
    String plain;
    if (scope == PillScopes.main || scope == PillScopes.negative) {
      final params = _ref.read(generationParamsNotifierProvider);
      plain = scope == PillScopes.main ? params.prompt : params.negativePrompt;
    } else {
      final id = scope.split(':')[1];
      final character = _ref
          .read(characterPromptNotifierProvider)
          .characters
          .where((item) => item.id == id)
          .firstOrNull;
      plain = scope.endsWith(':neg')
          ? character?.negativePrompt ?? ''
          : character?.prompt ?? '';
    }
    if (plain.isNotEmpty) {
      _ref.read(provider.notifier).replaceWithPlainText(plain);
    }
  }

  bool hasTranslations(bool negative) => _scopes(negative).any((scope) {
    return _ref
        .read(pillWorkspaceProvider(scope))
        .document
        .instances
        .values
        .any((instance) => instance.translation != null);
  });

  bool hasAnyTranslations(bool negative) =>
      _scopes(negative, includeDisabled: true).any((scope) {
        return _ref
            .read(pillWorkspaceProvider(scope))
            .document
            .instances
            .values
            .any((instance) => instance.translation != null);
      });

  int clearTranslations(bool negative) {
    if (_ref.read(promptTranslationBusyProvider)) return 0;
    var cleared = 0;
    final undo = <String, ({PillDocument before, PillDocument after})>{};
    final scopes = _scopes(negative, includeDisabled: true);
    for (final scope in scopes) {
      final lane = pillWorkspaceProvider(scope);
      final before = _ref.read(lane).document;
      final count = _ref.read(lane.notifier).unwrapAllTranslations();
      if (count == 0) continue;
      undo[scope] = (before: before, after: _ref.read(lane).document);
      cleared += count;
    }
    if (cleared > 0) {
      _plainTextUndo[negative] = undo;
    }
    return cleared;
  }

  bool canRestoreTranslations(bool negative) {
    final scopes = _scopes(negative, includeDisabled: true).toSet();
    return _plainTextUndo[negative]?.entries.any((entry) {
          return scopes.contains(entry.key) &&
              _ref.read(pillWorkspaceProvider(entry.key)).document ==
                  entry.value.after;
        }) ??
        false;
  }

  /// Restore only untouched fields; never replace newer edits or deleted roles.
  bool restoreTranslations(bool negative) {
    if (_ref.read(promptTranslationBusyProvider)) return false;
    final undo = _plainTextUndo.remove(negative);
    if (undo == null) return false;
    final scopes = _scopes(negative, includeDisabled: true).toSet();
    var restored = false;
    for (final entry in undo.entries) {
      if (!scopes.contains(entry.key)) continue;
      restored =
          _ref
              .read(pillWorkspaceProvider(entry.key).notifier)
              .replaceIfCurrent(entry.value.after, entry.value.before) ||
          restored;
    }
    return restored;
  }

  void toggleAll(bool negative) {
    final scopes = _scopes(negative);
    final translations = [
      for (final scope in scopes)
        ..._ref
            .read(pillWorkspaceProvider(scope))
            .document
            .instances
            .values
            .map((instance) => instance.translation)
            .whereType<TranslationPill>(),
    ];
    if (translations.isEmpty) return;
    final original = translations.every((pill) => !pill.showOriginal);
    for (final scope in scopes) {
      _ref
          .read(pillWorkspaceProvider(scope).notifier)
          .showAllTranslations(original: original);
    }
  }

  Future<PromptTranslationResult> translate(bool negative) async {
    if (_ref.read(promptTranslationBusyProvider)) {
      return const PromptTranslationResult(0, 0);
    }
    _ref.read(promptTranslationBusyProvider.notifier).state = true;
    try {
      final snapshots = <String, PillDocument>{};
      for (final scope in _scopes(negative)) {
        _seedIfNeeded(scope);
        snapshots[scope] = _ref.read(pillWorkspaceProvider(scope)).document;
      }
      final batch = PromptTranslationBatch.prepare(snapshots);
      if (batch.isEmpty) return const PromptTranslationResult(0, 0);
      final languageCode = PromptTranslationLanguage.fromCode(
        _ref.read(localeNotifierProvider).languageCode,
      ).code;

      final groups = <String, List<PromptTranslationGroup>>{};
      for (final part in batch.partitions()) {
        final glossary = await _glossaryFor(part);
        final raw = await _ref
            .read(promptAssistantServiceProvider)
            .translatePromptGroup(
              part.requestJson(glossary, languageCode: languageCode),
              sessionId: 'prompt-translation-${negative ? 'neg' : 'pos'}',
            );
        final parsed = part.parseGroups(
          raw,
          glossary: glossary,
          verifiedTags: await _verifyProposedTags(part, raw, glossary),
        );
        for (final entry in parsed.entries) {
          groups.putIfAbsent(entry.key, () => []).addAll(entry.value);
        }
      }
      final replacements = batch.buildFromGroups(
        groups,
        autoFormat: _ref.read(autoFormatPromptSettingsProvider),
        languageCode: languageCode,
      );
      var converted = 0;
      var changed = 0;
      final undo = <String, ({PillDocument before, PillDocument after})>{};
      final validScopes = _scopes(negative).toSet();
      for (final entry in replacements.entries) {
        final scope = entry.key;
        if (!validScopes.contains(scope)) {
          changed++;
          continue;
        }
        final before = snapshots[scope]!;
        if (_ref
            .read(pillWorkspaceProvider(scope).notifier)
            .replaceIfCurrent(before, entry.value)) {
          undo[scope] = (before: before, after: entry.value);
          converted++;
        } else {
          changed++;
        }
      }
      _lastUndo = undo;
      return PromptTranslationResult(converted, changed);
    } finally {
      _ref.read(promptTranslationBusyProvider.notifier).state = false;
    }
  }

  Future<bool> retranslateSingle(String scope, String marker) async {
    if (_ref.read(promptTranslationBusyProvider)) return false;
    final initial = _ref
        .read(pillWorkspaceProvider(scope))
        .document
        .instances[marker]
        ?.translation;
    if (initial == null) return false;
    _ref.read(promptTranslationBusyProvider.notifier).state = true;
    try {
      final languageCode = PromptTranslationLanguage.fromCode(
        _ref.read(localeNotifierProvider).languageCode,
      ).code;
      final batch = PromptTranslationBatch.prepare({
        'single': PillDocument(text: initial.source, instances: const {}),
      });
      if (batch.isEmpty) return false;
      final glossary = await _glossaryFor(batch);
      final raw = await _ref
          .read(promptAssistantServiceProvider)
          .translatePromptGroup(
            batch.requestJson(glossary, languageCode: languageCode),
            sessionId: 'prompt-translation-single',
          );
      final rebuilt = batch.parseAndBuild(
        raw,
        glossary: glossary,
        verifiedTags: await _verifyProposedTags(batch, raw, glossary),
        languageCode: languageCode,
      )['single']!;
      final reading = StringBuffer();
      final marks = <TranslationTagMark>[];
      for (final marker in rebuilt.text.split('')) {
        final part = rebuilt.instances[marker]?.translation;
        if (part == null) continue;
        if (reading.isNotEmpty) {
          reading.write(languageCode == 'en' ? ', ' : '，');
        }
        final offset = reading.length;
        reading.write(part.zh);
        marks.addAll([
          for (final mark in part.marks)
            TranslationTagMark(
              start: offset + mark.start,
              end: offset + mark.end,
              tag: mark.tag,
              iconId: mark.iconId,
            ),
        ]);
      }
      final zh = reading.toString();
      if (zh.isEmpty) return false;
      final current = _ref
          .read(pillWorkspaceProvider(scope))
          .document
          .instances[marker]
          ?.translation;
      if (current == null ||
          current.copyWith(showOriginal: initial.showOriginal) != initial) {
        return false;
      }
      _ref
          .read(pillWorkspaceProvider(scope).notifier)
          .updateTranslation(
            marker,
            initial.copyWith(
              zh: zh,
              marks: List.unmodifiable(marks),
              showOriginal: false,
              needsReview: false,
              languageCode: languageCode,
              translationEdited: false,
            ),
          );
      return true;
    } finally {
      _ref.read(promptTranslationBusyProvider.notifier).state = false;
    }
  }

  Future<List<Map<String, String>>> _glossaryFor(
    PromptTranslationBatch batch,
  ) async {
    try {
      final candidates = await _ref
          .read(unifiedTagRepositoryProvider)
          .byNames(batch.tagCandidates);
      final names = candidates.map((item) => item.canonicalTag).toList();
      Map<String, String> translations = const {};
      try {
        translations = await _ref
            .read(tagTranslationLookupProvider)
            .translateBatch(names);
      } catch (_) {
        // Missing optional Chinese readings must not hide verified tag icons.
      }
      return [
        for (final candidate in candidates)
          {
            'tag': candidate.canonicalTag,
            'title': TagNormalizer.toDisplay(candidate.canonicalTag),
            if (translations[candidate.canonicalTag] case final zh?) 'zh': zh,
            'icon_id': candidate.category.name,
          },
      ];
    } catch (_) {
      // The optional dictionary must not prevent ordinary translation.
      return const [];
    }
  }

  Future<Map<String, String>> _verifyProposedTags(
    PromptTranslationBatch batch,
    String raw,
    List<Map<String, String>> glossary,
  ) async {
    final proposed = batch.proposedTags(raw, glossary: glossary);
    if (proposed.isEmpty) return const {};
    try {
      final candidates = await _ref
          .read(unifiedTagRepositoryProvider)
          .byNames(proposed);
      return {
        for (final candidate in candidates)
          candidate.canonicalTag: candidate.category.name,
      };
    } catch (_) {
      // Optional marks must never prevent a successful text translation.
      return const {};
    }
  }

  bool get canUndoLast => _lastUndo.entries.any((entry) {
    final current = _ref.read(pillWorkspaceProvider(entry.key)).document;
    return _sameExceptDisplay(entry.value.after, current);
  });

  bool undoLast() {
    var restored = false;
    for (final entry in _lastUndo.entries) {
      final lane = pillWorkspaceProvider(entry.key);
      final current = _ref.read(lane).document;
      if (!_sameExceptDisplay(entry.value.after, current)) continue;
      restored =
          _ref
              .read(lane.notifier)
              .replaceIfCurrent(current, entry.value.before) ||
          restored;
    }
    _lastUndo = {};
    return restored;
  }

  static bool _sameExceptDisplay(PillDocument expected, PillDocument current) {
    if (expected.text != current.text ||
        expected.instances.length != current.instances.length) {
      return false;
    }
    for (final entry in expected.instances.entries) {
      final actual = current.instances[entry.key];
      if (actual == entry.value) continue;
      final original = entry.value.translation;
      final edited = actual?.translation;
      if (original == null || edited == null) return false;
      if (actual!.copyWith(
            translation: edited.copyWith(showOriginal: original.showOriginal),
          ) !=
          entry.value) {
        return false;
      }
    }
    return true;
  }
}
