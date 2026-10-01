import 'completion_models.dart';

class ChineseTermHit {
  const ChineseTermHit(this.start, this.end, this.candidate);
  final int start;
  final int end;
  final CompletionCandidate candidate;
}

/// A local phrase index. Matches remain suggestions, including in negated text.
class ChineseTermMatcher {
  ChineseTermMatcher(Iterable<Map<String, Object?>> rows) {
    for (final row in rows) {
      final label = row['cn_name'] as String?;
      if (label == null) continue;
      final candidate = CompletionCandidate(
        canonicalTag: row['name'] as String,
        category:
            TagCategory.fromDanbooru((row['category'] as num?)?.toInt() ?? 0) ??
            TagCategory.general,
        postCount: (row['post_count'] as num?)?.toInt() ?? 0,
        translation: label,
        matchKind: CompletionMatchKind.chineseExact,
        sources: const {CompletionSourceKind.zhDictionary},
      );
      for (final alias
          in label.split(RegExp(r'[；;,，/、|]')).map((s) => s.trim()).toSet()) {
        if (alias.isEmpty || alias.length > 48 || !_chinese.hasMatch(alias)) {
          continue;
        }
        var node = _root;
        for (final unit in alias.codeUnits) {
          node = node.children.putIfAbsent(unit, _Node.new);
        }
        node.candidates.add(candidate);
      }
    }
  }
  static final _chinese = RegExp(r'[\u3400-\u9fff]');
  final _Node _root = _Node();

  List<ChineseTermHit> match(String text, {int limit = 64}) {
    if (limit <= 0) return const [];
    final spans =
        <({int start, int end, List<CompletionCandidate> candidates})>[];
    for (var start = 0; start < text.length; start++) {
      var node = _root;
      for (var end = start; end < text.length && end < start + 48; end++) {
        final next = node.children[text.codeUnitAt(end)];
        if (next == null) break;
        node = next;
        if (node.candidates.isEmpty) continue;
        // A one-character definition is useful as a separate tag, but too
        // ambiguous as a substring inside another Chinese word.
        if (end == start &&
            ((start > 0 && _chinese.hasMatch(text[start - 1])) ||
                (end + 1 < text.length && _chinese.hasMatch(text[end + 1])))) {
          continue;
        }
        spans.add((start: start, end: end + 1, candidates: node.candidates));
      }
    }
    spans.sort((a, b) {
      final length = (b.end - b.start).compareTo(a.end - a.start);
      return length != 0 ? length : a.start.compareTo(b.start);
    });
    final accepted =
        <({int start, int end, List<CompletionCandidate> candidates})>[];
    for (final span in spans) {
      if (accepted.any((hit) => span.start < hit.end && span.end > hit.start)) {
        continue;
      }
      accepted.add(span);
      if (accepted.length >= limit) break;
    }
    accepted.sort((a, b) => a.start.compareTo(b.start));
    final hits = <ChineseTermHit>[];
    for (final span in accepted) {
      final candidates = span.candidates.toList()
        ..sort((a, b) {
          final count = b.postCount.compareTo(a.postCount);
          return count != 0 ? count : a.canonicalTag.compareTo(b.canonicalTag);
        });
      for (final candidate in candidates.take(3)) {
        hits.add(ChineseTermHit(span.start, span.end, candidate));
        if (hits.length == limit) return hits;
      }
    }
    return hits;
  }
}

class _Node {
  final Map<int, _Node> children = {};
  final List<CompletionCandidate> candidates = [];
}

ChineseTermMatcher buildChineseTermMatcher(List<Map<String, Object?>> rows) =>
    ChineseTermMatcher(rows);
