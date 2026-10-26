import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/nai_agent/translation_context.dart';
import '../../core/nai_agent/agent_tool.dart';
import '../../core/utils/translation_block_edit.dart';

import '../../core/tag_expansion/tag_expansion_providers.dart';
import '../../core/utils/prompt_translation_document.dart';
import '../../core/utils/prompt_translation_edit.dart';
import '../../core/utils/prompt_translation_language.dart';
import '../../core/utils/tag_normalizer.dart';
import '../../core/wiki/tag_translation_glossary.dart';
import '../../core/utils/nai_prompt_syntax.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../prompt_assistant/services/prompt_assistant_service.dart';
import 'character_prompt_provider.dart';
import 'image_generation_provider.dart';
import 'pill_workspace_provider.dart';
import 'locale_provider.dart';
import '../../core/utils/localization_extension.dart';

/// Only verified, unambiguous category metadata becomes an editor decoration.
final promptTranslationAnnotationProvider =
    Provider<Future<List<TranslationTagMark>> Function(String, bool)>((ref) {
      final tags = ref.read(unifiedTagRepositoryProvider);
      return (text, chinese) async {
        // Reading text has no local term index; its marks come from the
        // model and from terms the user picked.
        if (chinese) return const [];
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

final promptTranslationContextsProvider =
    StateProvider<Map<bool, TranslationContext>>((ref) => {});

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
        throw FormatException(currentL10n.promptTranslation_inputRequired);
      }
      final batch = PromptTranslationBatch.prepare({
        'draft': PillDocument(text: request.source, instances: const {}),
      });
      final reading = PromptTranslationLanguage.fromCode(request.languageCode);
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
        final definitions = await _ref
            .read(tagTranslationGlossaryProvider)
            .termsFor(picked.map((candidate) => candidate.canonicalTag));
        for (final candidate in picked) {
          final term = activeTerms.firstWhere(
            (term) => term.tag == candidate.canonicalTag,
          );
          byTag[candidate.canonicalTag] = {
            ...?byTag[candidate.canonicalTag],
            'tag': candidate.canonicalTag,
            'title': TagNormalizer.toDisplay(candidate.canonicalTag),
            ...?definitions[candidate.canonicalTag],
            if (reading.isChinese) 'zh': term.text,
            'matched_text': term.text,
            'icon_id': candidate.category.name,
          };
        }
      } catch (_) {
        // Optional local terminology never blocks natural-language conversion.
      }
      if (_draftRequests[sessionId] == true) {
        throw StateError(currentL10n.modelService_conversionCancelled);
      }
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
      if (_draftRequests[sessionId] == true) {
        throw StateError(currentL10n.modelService_conversionCancelled);
      }
      return PromptTranslationEditResult.parse(raw, request, terms);
    } finally {
      _draftRequests.remove(sessionId);
    }
  }

  Map<String, ({PillDocument before, PillDocument after})> _lastUndo = {};
  final Map<
    bool,
    List<Map<String, ({PillDocument before, PillDocument after})>>
  >
  _adjustmentUndo = {};
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

  Map<String, PillDocument> adjustmentDocuments(bool negative) => {
    for (final scope in _scopes(negative, includeDisabled: true))
      scope: _ref.read(pillWorkspaceProvider(scope)).document,
  };

  static List<Map<String, dynamic>> blockMap(
    Map<String, PillDocument> documents,
  ) => [
    for (final entry in documents.entries)
      for (final item
          in entry.value.text
              .split('')
              .toSet()
              .where(
                (marker) => entry.value.instances[marker]?.translation != null,
              )
              .indexed)
        if (entry.value.instances[item.$2]?.translation case final pill?)
          {
            'scope': entry.key,
            'marker': item.$2,
            'index': item.$1 + 1,
            'offset': entry.value.text.indexOf(item.$2),
            'source': pill.source,
            'translation': pill.zh,
            'enabled': entry.value.instances[item.$2]!.enabled,
          },
  ];

  String adjustmentVersion(bool negative) => sha256
      .convert(
        utf8.encode(
          jsonEncode({
            for (final entry in adjustmentDocuments(negative).entries)
              entry.key: entry.value.toJson(),
          }),
        ),
      )
      .toString();

  Map<String, dynamic> readAdjustment(bool negative) => {
    'version': adjustmentVersion(negative),
    'blocks': blockMap(adjustmentDocuments(negative)),
  };

  Map<String, dynamic> editAdjustment(
    bool negative,
    String expectedVersion,
    List<Map<String, dynamic>> operations,
  ) {
    if (_ref.read(promptTranslationBusyProvider) ||
        adjustmentVersion(negative) != expectedVersion) {
      throw const NaiAgentToolError(
        'translation_conflict',
        'Document changed; read blocks again',
      );
    }
    final before = adjustmentDocuments(negative);
    final after = TranslationBlockEdit.apply(before, operations);
    // No await between validation, in-memory backup and writes. The coordinator
    // groups all lanes in one conflict-safe undo entry before replacing them.
    final undo = <String, ({PillDocument before, PillDocument after})>{};
    for (final entry in after.entries) {
      if (entry.value == before[entry.key]) continue;
      undo[entry.key] = (before: before[entry.key]!, after: entry.value);
    }
    if (undo.isNotEmpty) {
      _adjustmentUndo.putIfAbsent(negative, () => []).add(undo);
    }
    for (final entry in undo.entries) {
      _ref
          .read(pillWorkspaceProvider(entry.key).notifier)
          .replaceIfCurrent(entry.value.before, entry.value.after);
    }
    return readAdjustment(negative);
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
    final scopes = _scopes(negative, includeDisabled: true);
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
    // Match the button/tooltip: any visible reading means show all originals.
    // A second press then shows all readings, including an initially mixed face.
    final original = translations.any((pill) => !pill.showOriginal);
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
      final language = _interfaceReadingLanguage();

      final groups = <String, List<PromptTranslationGroup>>{};
      final languageCode = language.code;
      final exchanges = <TranslationExchange>[];
      for (final part in batch.partitions()) {
        final glossary = await _glossaryFor(part);
        final raw = await _ref
            .read(promptAssistantServiceProvider)
            .translatePromptGroup(
              part.requestJson(glossary, languageCode: languageCode),
              sessionId: 'prompt-translation-${negative ? 'neg' : 'pos'}',
            );
        final exchange = _ref
            .read(promptAssistantServiceProvider)
            .takeTranslationExchange(
              'prompt-translation-${negative ? 'neg' : 'pos'}',
            );
        if (exchange != null) exchanges.add(exchange);
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
      if (converted > 0 && exchanges.isNotEmpty) {
        _ref.read(promptTranslationContextsProvider.notifier).state = {
          ..._ref.read(promptTranslationContextsProvider),
          negative: TranslationContext(
            List.unmodifiable(exchanges),
            blockMap(adjustmentDocuments(negative)),
          ),
        };
      }
      return PromptTranslationResult(converted, changed);
    } finally {
      _ref.read(promptTranslationBusyProvider.notifier).state = false;
    }
  }

  /// Translate an isolated, read-only image detail snapshot. No generation
  /// lane, persisted workspace or global undo history is read or changed.
  Future<PillDocument> translateDocument(
    PillDocument document, {
    required String sessionId,
  }) async {
    final batch = PromptTranslationBatch.prepare({'detail': document});
    if (batch.isEmpty) return document;
    final language = _interfaceReadingLanguage().code;
    final groups = <String, List<PromptTranslationGroup>>{};
    for (final part in batch.partitions()) {
      final glossary = await _glossaryFor(part);
      final raw = await _ref
          .read(promptAssistantServiceProvider)
          .translatePromptGroup(
            part.requestJson(glossary, languageCode: language),
            sessionId: sessionId,
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
    return batch.buildFromGroups(
          groups,
          autoFormat: false,
          languageCode: language,
        )['detail'] ??
        document;
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
      final language = _interfaceReadingLanguage();
      final languageCode = language.code;
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

  /// Prompt conversion reads in the interface language (block metadata keeps
  /// it afterwards); Traditional Chinese has its own code.
  PromptTranslationLanguage _interfaceReadingLanguage() =>
      PromptTranslationLanguage.forLocale(_ref.read(localeNotifierProvider));

  /// Verified local tags with their icons; the model writes the readings.
  Future<List<Map<String, String>>> _glossaryFor(
    PromptTranslationBatch batch,
  ) async {
    try {
      final candidates = await _ref
          .read(unifiedTagRepositoryProvider)
          .byNames(batch.tagCandidates);
      final terms = await _ref
          .read(tagTranslationGlossaryProvider)
          .termsFor(candidates.map((candidate) => candidate.canonicalTag));
      return [
        for (final candidate in candidates)
          {
            'tag': candidate.canonicalTag,
            ...?terms[candidate.canonicalTag],
            'title': TagNormalizer.toDisplay(candidate.canonicalTag),
            'icon_id': candidate.category.name,
          },
      ];
    } catch (_) {
      // The optional catalog lookup must not prevent ordinary translation.
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

  bool canUndoAdjustment(bool negative) {
    final history = _adjustmentUndo[negative];
    if (history == null || history.isEmpty) return false;
    final scopes = _scopes(negative, includeDisabled: true).toSet();
    final undo = history.last;
    return undo.keys.every(scopes.contains) &&
        undo.entries.every(
          (entry) => _sameExceptDisplay(
            entry.value.after,
            _ref.read(pillWorkspaceProvider(entry.key)).document,
          ),
        );
  }

  bool undoAdjustment(bool negative) {
    if (!canUndoAdjustment(negative)) return false;
    final undo = _adjustmentUndo[negative]!.removeLast();
    for (final entry in undo.entries) {
      final lane = pillWorkspaceProvider(entry.key);
      _ref
          .read(lane.notifier)
          .replaceIfCurrent(_ref.read(lane).document, entry.value.before);
    }
    return true;
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
