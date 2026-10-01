import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../autocomplete/autocomplete_providers.dart';
import '../autocomplete/chinese_term_matcher.dart';
import '../autocomplete/completion_models.dart';
import '../tag_expansion/tag_expansion_providers.dart';
import '../utils/tag_normalizer.dart';

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
    chineseLookup: (text) => dictionary.matchInText(text, limit: 256),
    readingsLookup: (tags) => dictionary.resolve(tags, locale: 'zh-CN'),
  );
});

/// Matching supplies model context; rendering validates explicit links only.
class WikiTagLinks {
  WikiTagLinks({
    required this.exactLookup,
    required this.chineseLookup,
    this.readingsLookup,
  });
  final Future<Map<String, CompletionCandidate>> Function(Iterable<String>)
  exactLookup;
  final Future<List<ChineseTermHit>> Function(String) chineseLookup;
  final Future<Map<String, String>> Function(List<String>)? readingsLookup;
  final _cache = <String, Future<WikiLinkDocument>>{};

  Future<WikiLinkDocument> resolve(String body) {
    if (_cache[body] case final cached?) return cached;
    if (_cache.length >= 32) _cache.remove(_cache.keys.first);
    final future = _resolve(body);
    _cache[body] = future;
    return future;
  }

  static String href(String tag) =>
      'wof-tag:${Uri.encodeComponent(tag).replaceAll('(', '%28').replaceAll(')', '%29')}';
  static String _normalize(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  static final _tokens = RegExp(r"[A-Za-z0-9_:][A-Za-z0-9_:'./+!?()\-]*");
  static final _code = RegExp(r'```[\s\S]*?```|~~~[\s\S]*?~~~|`[^`\n]+`');
  // Escapes and balanced parentheses cover the canonical names used by tags.
  static final _inlineLinks = RegExp(
    r'(!?)\[((?:\\.|[^\]\\\n])*)\]\((<[^>\n]+>|(?:\\.|[^()\s\\]|\([^()\s]*\))*)(?:\s+"[^"\n]*")?\)',
  );
  static List<({int start, int end, String label, String url})> _links(
    String body,
  ) {
    final code = _code.allMatches(body).toList();
    final inline = _inlineLinks.allMatches(body).toList();
    final result = <({int start, int end, String label, String url})>[
      for (final match in inline)
        if (match[1]!.isEmpty &&
            !code.any((m) => match.start < m.end && match.end > m.start))
          (
            start: match.start,
            end: match.end,
            label: match[2]!,
            url: match[3]!.startsWith('<')
                ? match[3]!.substring(1, match[3]!.length - 1)
                : match[3]!,
          ),
    ];
    // Official articles can use reference links. Validate those destinations too.
    final definitions = RegExp(
      r'^ {0,3}\[([^\]\n]+)\]:[ \t]*<?([^\s>]+)>?',
      multiLine: true,
    ).allMatches(body).toList();
    final refs = {
      for (final m in definitions) m[1]!.trim().toLowerCase(): m[2]!,
    };
    bool protected(int start, int end) =>
        [
          ...code,
          ...inline,
          ...definitions,
        ].any((m) => start < m.end && end > m.start) ||
        result.any((m) => start < m.end && end > m.start);
    void add(int start, int end, String label, String url) {
      if ((start > 0 && body[start - 1] == '!') || protected(start, end)) {
        return;
      }
      result.add((start: start, end: end, label: label, url: url));
    }

    for (final match in RegExp(
      r'\[([^\]\n]+)\]\[([^\]\n]*)\]',
    ).allMatches(body)) {
      final key = (match[2]!.isEmpty ? match[1]! : match[2]!)
          .trim()
          .toLowerCase();
      if (refs[key] case final url?) {
        add(match.start, match.end, match[1]!, url);
      }
    }
    for (final match in RegExp(r'\[([^\]\n]+)\]').allMatches(body)) {
      if (refs[match[1]!.trim().toLowerCase()] case final url?) {
        add(match.start, match.end, match[1]!, url);
      }
    }
    for (final match in RegExp(r'<(wof-tag:[^<>\n]+)>').allMatches(body)) {
      add(match.start, match.end, match[1]!, match[1]!);
    }
    return result..sort((a, b) => a.start.compareTo(b.start));
  }

  static String? _target(String url) {
    try {
      if (url.startsWith('wof-tag:')) {
        return _normalize(Uri.decodeComponent(url.substring(8)));
      }
      final uri = Uri.tryParse(url);
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.endsWith('.donmai.us') &&
          uri.pathSegments.length == 2 &&
          uri.pathSegments.first == 'wiki_pages') {
        return _normalize(uri.pathSegments.last);
      }
    } on FormatException {
      /* invalid target becomes plain text */
    } on ArgumentError {
      /* invalid percent encoding becomes plain text */
    }
    return null;
  }

  static String _rewrite(
    String body,
    List<({int start, int end, String text})> edits,
  ) {
    final output = StringBuffer();
    var cursor = 0;
    for (final edit in edits) {
      output.write(body.substring(cursor, edit.start));
      output.write(edit.text);
      cursor = edit.end;
    }
    output.write(body.substring(cursor));
    return output.toString();
  }

  static String withoutLocalLinks(String body) => _rewrite(body, [
    for (final link in _links(body))
      if (link.url.startsWith('wof-tag:'))
        (start: link.start, end: link.end, text: link.label),
  ]);
  Future<WikiLinkDocument> _resolve(String body) async {
    final links = _links(body);
    final names = {
      for (final link in links)
        if (_target(link.url) case final name?) name,
    };
    Map<String, CompletionCandidate> exact = const {};
    if (names.isNotEmpty) {
      try {
        exact = await exactLookup(names);
      } catch (_) {
        /* readable fallback */
      }
    }
    final accepted = <WikiTagLink>[];
    final edits = <({int start, int end, String text})>[];
    for (final link in links) {
      if (exact[_target(link.url)] case final item?) {
        accepted.add(WikiTagLink(link.start, link.end, item));
        edits.add((
          start: link.start,
          end: link.end,
          text: '[${link.label}](${href(item.canonicalTag)})',
        ));
      } else if (link.url.startsWith('wof-tag:')) {
        edits.add((start: link.start, end: link.end, text: link.label));
      }
    }
    return WikiLinkDocument(_rewrite(body, edits), accepted, {
      for (final link in accepted) link.candidate.canonicalTag: link.candidate,
    });
  }

  static final _protected = RegExp(
    r'```[\s\S]*?```|`[^`\n]+`|!?\[[^\]\n]*\]\([^\n]*?\)|https?://[^\s<>]+',
  );

  Future<List<Map<String, Object>>> glossaryFor(
    String body, {
    int limit = 64,
    String? currentTag,
  }) async {
    if (limit <= 0 || body.isEmpty) return const [];
    final protected = [
      ..._protected.allMatches(body),
      ..._code.allMatches(body),
    ];
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
    final sourceLinks = {
      for (final link in _links(body))
        if (_target(link.url) case final tag?) link: tag,
    };
    terms.addAll(sourceLinks.values);
    if (currentTag != null) terms.add(_normalize(currentTag));
    Map<String, CompletionCandidate> exact;
    try {
      exact = await exactLookup(terms);
    } catch (_) {
      return const [];
    }
    final chosen = <String, CompletionCandidate>{};
    final matches = <String, Set<String>>{};
    final readings = <String, String>{};
    void add(String name, String text, [String? reading]) {
      final item = exact[name];
      if (item == null ||
          (!chosen.containsKey(item.canonicalTag) && chosen.length >= limit)) {
        return;
      }
      chosen[item.canonicalTag] = item;
      final fragments = matches.putIfAbsent(item.canonicalTag, () => {});
      if (fragments.length < 4) fragments.add(text);
      if (reading != null) readings[item.canonicalTag] = reading;
    }

    if (currentTag != null) {
      add(_normalize(currentTag), currentTag);
    }
    for (final entry in sourceLinks.entries) {
      add(entry.value, entry.key.label);
    }
    spans.sort((a, b) => (b.end - b.start).compareTo(a.end - a.start));
    for (final span in spans) {
      add(span.name, body.substring(span.start, span.end));
    }
    for (final hit in chinese) {
      if (hit.start >= 0 &&
          hit.end <= body.length &&
          hit.end > hit.start &&
          !overlaps(hit.start, hit.end)) {
        add(
          hit.candidate.canonicalTag,
          body.substring(hit.start, hit.end),
          hit.candidate.translation,
        );
      }
    }
    try {
      readings.addAll(
        await readingsLookup?.call(chosen.keys.toList()) ?? const {},
      );
    } catch (_) {
      /* optional */
    }
    return [
      for (final item in chosen.values)
        {
          'tag': item.canonicalTag,
          'title': TagNormalizer.toDisplay(item.canonicalTag),
          'category': item.category.name,
          if (item.canonicalTag == _normalize(currentTag ?? ''))
            'current_article': true,
          if (readings[item.canonicalTag] ?? item.translation
              case final reading?)
            'zh': reading,
          if (item.aliases.isNotEmpty) 'aliases': item.aliases.take(6).toList(),
          'matched_texts': matches[item.canonicalTag]!.toList(),
        },
    ];
  }
}
