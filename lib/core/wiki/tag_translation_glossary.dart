import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/tag_normalizer.dart';
import 'tag_wiki_repository.dart';
import 'visible_tag_translation_cache.dart';

final tagTranslationGlossaryProvider = Provider<TagTranslationGlossary>(
  (ref) => TagTranslationGlossary(
    wiki: ref.read(tagWikiRepositoryProvider),
    cache: ref.read(visibleTagTranslationCacheProvider),
  ),
);

/// Shared, local-only semantic context for all translation request glossaries.
class TagTranslationGlossary {
  TagTranslationGlossary({required this.wiki, required this.cache});
  final TagWikiRepository wiki;
  final VisibleTagTranslationCache cache;

  Future<Map<String, Map<String, String>>> termsFor(
    Iterable<String> tags,
  ) async {
    final names = tags
        .map(TagNormalizer.normalize)
        .where((tag) => tag.isNotEmpty)
        .toSet();
    if (names.isEmpty) return const {};
    final cachedFuture = _cached(names);
    Map<String, TagWikiEntry> pages = const {};
    try {
      pages = await wiki.findAll(names);
    } catch (_) {
      // An optional wiki index never blocks translation.
    }
    final cached = await cachedFuture;
    return {for (final tag in names) tag: _term(cached[tag], pages[tag]?.body)};
  }

  Future<Map<String, CachedVisibleTagTranslation>> _cached(
    Set<String> names,
  ) async {
    try {
      return await cache.chineseTerms(names);
    } catch (_) {
      return const {};
    }
  }

  Map<String, String> _term(CachedVisibleTagTranslation? saved, String? body) {
    final sameSource =
        body != null &&
        saved?.wikiHash == sha256.convert(utf8.encode(body)).toString();
    final chineseDefinition =
        sameSource &&
            (saved?.definitionLanguage == 'zh' ||
                saved?.definitionLanguage == 'zh-TW')
        ? saved?.definition
        : null;
    final definition = chineseDefinition ?? sourceDefinition(body ?? '');
    return {
      if (saved?.nameZh.trim().isNotEmpty == true) 'zh': saved!.nameZh,
      if (definition != null) 'definition': definition,
      if (definition != null)
        'definition_language': chineseDefinition == null
            ? 'source'
            : saved!.definitionLanguage!,
    };
  }

  static bool hasWikiContext(String body) =>
      body.trim().isNotEmpty &&
      !RegExp(
        r'^(?:none\s*\(404\)|404|not found|null)$',
        caseSensitive: false,
      ).hasMatch(body.trim());

  /// A truthful source fallback until a Chinese definition has been cached.
  /// Do not fabricate either a Chinese label or a definition from the tag name.
  static String? sourceDefinition(String body) {
    if (!hasWikiContext(body)) return null;
    var text = body
        .split(
          RegExp(
            r'\b(?:See also|Examples|The following tags|Related tags)\b',
            caseSensitive: false,
          ),
        )
        .first
        .replaceAll(RegExp(r'^\s*#{1,6}\s+[^\n]+\n', multiLine: true), '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[*`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;
    final end = RegExp(r'[。！？]|[.!?](?:\s|$)').firstMatch(text);
    if (end != null) text = text.substring(0, end.start + 1);
    if (text.runes.length > 320) {
      text = '${String.fromCharCodes(text.runes.take(319))}…';
    }
    return text;
  }
}
