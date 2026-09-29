import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tag_expansion/tag_expansion_providers.dart';
import '../../core/autocomplete/tag_translation_lookup.dart';
import '../../core/utils/prompt_translation_document.dart';
import '../../core/utils/tag_normalizer.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../prompt_assistant/services/prompt_assistant_service.dart';
import 'character_prompt_provider.dart';
import 'generation/generation_params_notifier.dart';
import 'image_generation_provider.dart';
import 'pill_workspace_provider.dart';

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
  Map<String, ({PillDocument before, PillDocument after})> _lastUndo = {};

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
    final scopes = _scopes(negative, includeDisabled: true);
    for (final scope in scopes) {
      cleared += _ref
          .read(pillWorkspaceProvider(scope).notifier)
          .unwrapAllTranslations();
    }
    if (cleared > 0) {
      _lastUndo.removeWhere((scope, _) => scopes.contains(scope));
    }
    return cleared;
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

      final groups = <String, List<PromptTranslationGroup>>{};
      for (final part in batch.partitions()) {
        final glossary = await _glossaryFor(part);
        final raw = await _ref
            .read(promptAssistantServiceProvider)
            .translatePromptGroup(
              part.requestJson(glossary),
              sessionId: 'prompt-translation-${negative ? 'neg' : 'pos'}',
            );
        final parsed = part.parseGroups(raw, glossary: glossary);
        for (final entry in parsed.entries) {
          groups.putIfAbsent(entry.key, () => []).addAll(entry.value);
        }
      }
      final replacements = batch.buildFromGroups(groups);
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
      final batch = PromptTranslationBatch.prepare({
        'single': PillDocument(text: initial.source, instances: const {}),
      });
      if (batch.isEmpty) return false;
      final glossary = await _glossaryFor(batch);
      final raw = await _ref
          .read(promptAssistantServiceProvider)
          .translatePromptGroup(
            batch.requestJson(glossary),
            sessionId: 'prompt-translation-single',
          );
      final rebuilt = batch.parseAndBuild(raw, glossary: glossary)['single']!;
      final reading = StringBuffer();
      final marks = <TranslationTagMark>[];
      for (final marker in rebuilt.text.split('')) {
        final part = rebuilt.instances[marker]?.translation;
        if (part == null) continue;
        if (reading.isNotEmpty) reading.write('，');
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
      if (current != initial) return false;
      _ref
          .read(pillWorkspaceProvider(scope).notifier)
          .updateTranslation(
            marker,
            initial.copyWith(
              zh: zh,
              marks: List.unmodifiable(marks),
              showOriginal: false,
              needsReview: false,
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
