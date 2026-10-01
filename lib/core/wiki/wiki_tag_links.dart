import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autocomplete/autocomplete_providers.dart';
import '../autocomplete/chinese_term_matcher.dart';
import '../autocomplete/completion_models.dart';
import '../tag_expansion/tag_expansion_providers.dart';

class WikiTagLink {
  const WikiTagLink(this.start, this.end, this.candidate);
  final int start;
  final int end;
  final CompletionCandidate candidate;
}

class WikiLinkDocument {
  const WikiLinkDocument(this.markdown, this.links, this.targets);
  final String markdown;
  final List<WikiTagLink> links;
  final Map<String, CompletionCandidate> targets;
}

final wikiTagLinksProvider = Provider<WikiTagLinks>((ref) {
  final catalog = ref.watch(unifiedTagRepositoryProvider);
  final dictionary = ref.watch(zhDictionaryServiceProvider);
  return WikiTagLinks(
    exactLookup: catalog.resolveExact,
    chineseLookup: (text) =>
        dictionary.matchInText(text, limit: text.length * 3 + 3),
  );
});

/// Resolve complete phrases in indexed batches, never fuzzy search or model
/// guesses. A small session cache avoids rescanning on translation progress.
class WikiTagLinks {
  WikiTagLinks({required this.exactLookup, required this.chineseLookup});
  final Future<Map<String, CompletionCandidate>> Function(Iterable<String>)
  exactLookup;
  final Future<List<ChineseTermHit>> Function(String) chineseLookup;
  final _cache = <String, Future<WikiLinkDocument>>{};

  Future<WikiLinkDocument> resolve(String body) {
    if (_cache[body] case final cached?) return cached;
    if (_cache.length >= 32) _cache.remove(_cache.keys.first);
    final future = _resolve(body);
    _cache[body] = future;
    return future;
  }

  static String href(String tag) => 'wof-tag:${Uri.encodeComponent(tag)}';
  static String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  static final _tokens = RegExp(r"[A-Za-z0-9_:][A-Za-z0-9_:'./+!?()\-]*");
  static final _protected = RegExp(
    r'```[\s\S]*?```|`[^`\n]+`|!?\[[^\]\n]*\]\([^\n]*?\)|https?://[^\s<>]+',
  );

  Future<WikiLinkDocument> _resolve(String body) async {
    final protected = _protected.allMatches(body).toList();
    bool overlaps(int start, int end) =>
        protected.any((m) => start < m.end && end > m.start);
    final spans = <({int start, int end, String name})>[];
    final tokens = _tokens
        .allMatches(body)
        .where((m) => !overlaps(m.start, m.end))
        .toList();
    for (var i = 0; i < tokens.length; i++) {
      for (var j = i; j < tokens.length && j < i + 40; j++) {
        if (j > i &&
            !RegExp(
              r'^[ \t]+$',
            ).hasMatch(body.substring(tokens[j - 1].end, tokens[j].start))) {
          break;
        }
        final start = tokens[i].start;
        var end = tokens[j].end;
        if (end - start > 256) break;
        final raw = body.substring(start, end);
        spans.add((start: start, end: end, name: _normalize(raw)));
        while (end > start && '.!?'.contains(body[end - 1])) {
          end--;
        }
        var trimmed = body.substring(start, end);
        while (trimmed.endsWith(')') &&
            ')'.allMatches(trimmed).length > '('.allMatches(trimmed).length) {
          end--;
          trimmed = body.substring(start, end);
        }
        if (end != tokens[j].end && end > start) {
          spans.add((start: start, end: end, name: _normalize(trimmed)));
        }
      }
    }
    List<ChineseTermHit> chinese = const [];
    try {
      chinese = await chineseLookup(body);
    } catch (_) {
      /* optional dictionary */
    }
    final terms = {
      for (final span in spans) span.name,
      for (final hit in chinese) hit.candidate.canonicalTag,
    };
    final sourceLinks = <RegExpMatch, String>{};
    for (final link in RegExp(
      r'\[([^\]\n]+)\]\((https?://[^\s]+)\)',
    ).allMatches(body)) {
      final uri = Uri.tryParse(link[2]!);
      if (uri == null ||
          !uri.host.endsWith('.donmai.us') ||
          uri.pathSegments.length != 2 ||
          uri.pathSegments.first != 'wiki_pages') {
        continue;
      }
      final tag = _normalize(uri.pathSegments.last);
      sourceLinks[link] = tag;
      terms.add(tag);
    }
    Map<String, CompletionCandidate> exact;
    try {
      exact = await exactLookup(terms);
    } catch (_) {
      return WikiLinkDocument(body, const [], const {});
    }
    final candidates = <WikiTagLink>[
      for (final span in spans)
        if (exact[span.name] case final item?)
          WikiTagLink(span.start, span.end, item),
    ];
    final chineseBySpan = <(int, int), Map<String, CompletionCandidate>>{};
    for (final hit in chinese) {
      if (overlaps(hit.start, hit.end)) continue;
      (chineseBySpan[(hit.start, hit.end)] ??= {})[hit.candidate.canonicalTag] =
          hit.candidate;
    }
    for (final entry in chineseBySpan.entries) {
      if (entry.value.length == 1 &&
          exact.containsKey(entry.value.keys.single)) {
        candidates.add(
          WikiTagLink(entry.key.$1, entry.key.$2, entry.value.values.single),
        );
      }
    }
    candidates.sort((a, b) {
      final length = (b.end - b.start).compareTo(a.end - a.start);
      return length != 0 ? length : a.start.compareTo(b.start);
    });
    final accepted = <WikiTagLink>[];
    for (final link in candidates) {
      if (!accepted.any((a) => link.start < a.end && link.end > a.start)) {
        accepted.add(link);
      }
    }
    accepted.sort((a, b) => a.start.compareTo(b.start));
    final edits = <({int start, int end, String markdown})>[
      for (final link in accepted)
        (
          start: link.start,
          end: link.end,
          markdown:
              '[${body.substring(link.start, link.end).replaceAllMapped(RegExp(r'[\\\[\]_*]'), (m) => '\\${m[0]}')}](${href(link.candidate.canonicalTag)})',
        ),
      for (final entry in sourceLinks.entries)
        if (exact[entry.value] case final item?)
          (
            start: entry.key.start,
            end: entry.key.end,
            markdown: '[${entry.key[1]}](${href(item.canonicalTag)})',
          ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final output = StringBuffer();
    var cursor = 0;
    for (final edit in edits) {
      output.write(body.substring(cursor, edit.start));
      output.write(edit.markdown);
      cursor = edit.end;
    }
    output.write(body.substring(cursor));
    return WikiLinkDocument(output.toString(), accepted, {
      for (final link in accepted) link.candidate.canonicalTag: link.candidate,
      for (final tag in sourceLinks.values)
        if (exact[tag] case final item?) item.canonicalTag: item,
    });
  }
}
