import '../utils/tag_normalizer.dart';

bool isWikiExampleHeading(String title) => RegExp(
  r'^(examples?|示例|范例|範例|例子|示范|示範|用例|使用例|实例|實例|事例|作例|サンプル|例|예시|예제)(?:\s|[:：]|$)',
  caseSensitive: false,
).hasMatch(title.trim());

enum WikiImageKind { post, asset }

class WikiExampleReference {
  const WikiExampleReference(
    this.id,
    this.caption, {
    this.kind = WikiImageKind.post,
    this.section = const [],
    this.sectionId = 0,
    this.occurrence = 0,
  });

  final int id;
  final String caption;
  final WikiImageKind kind;
  final List<String> section;
  final int sectionId, occurrence;
  int get postId => id;
  String get key => '${kind.name}:$id';
  String get occurrenceKey => '$key:$occurrence';
  String get sourceUrl => kind == WikiImageKind.post
      ? 'https://danbooru.donmai.us/posts/$id'
      : 'https://danbooru.donmai.us/media_assets/$id';
  String get captionMarkdown => wikiImageCaptionMarkdown(caption);
  String get captionText => wikiImageCaptionText(caption);
  String get sectionText => section.map(wikiImageCaptionText).join(' / ');

  /// The full article's existing inline gallery requests positive examples.
  /// The small article uses [WikiImageDocument] to include all source sections.
  static List<WikiExampleReference> parse(String body) {
    final unique = <String, WikiExampleReference>{};
    for (final ref in WikiImageDocument.parse(body).references) {
      final example = ref.section.lastIndexWhere(isWikiExampleHeading);
      if (ref.kind != WikiImageKind.post || example < 0) continue;
      if (ref.section
          .skip(example + 1)
          .any(
            (title) => RegExp(
              r'^(non[- ]?examples?|counter[- ]?examples?|反例|非示例|非範例|非范例)',
              caseSensitive: false,
            ).hasMatch(title.trim()),
          )) {
        continue;
      }
      unique.putIfAbsent(ref.key, () => ref);
    }
    return unique.values.toList(growable: false);
  }
}

String wikiImageCaptionMarkdown(String text) => text
    .replaceAllMapped(RegExp(r'\[\[([^\]\r\n]+)\]\]'), (match) {
      final parts = match[1]!.split('|');
      final tag = TagNormalizer.normalize(parts.first);
      final label = parts.length > 1 && parts.last.isNotEmpty
          ? parts.last
          : TagNormalizer.toDisplay(tag);
      final safe = label.replaceAll('[', r'\[').replaceAll(']', r'\]');
      final encoded = Uri.encodeComponent(
        tag,
      ).replaceAll('(', '%28').replaceAll(')', '%29');
      return '[$safe](https://danbooru.donmai.us/wiki_pages/$encoded)';
    })
    .replaceAll(RegExp(r'\[/?b\]', caseSensitive: false), '**')
    .replaceAll(RegExp(r'\[/?i\]', caseSensitive: false), '*')
    .replaceAll(RegExp(r'\[/?s\]', caseSensitive: false), '~~')
    .replaceAll(RegExp(r'\[br\]', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'\[/?(?:u|small)\]', caseSensitive: false), '');

String wikiImageCaptionText(String text) => wikiImageCaptionMarkdown(text)
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^\r\n]*?\)'), (m) => m[1]!)
    .replaceAll(RegExp(r'[*~`]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class WikiImageProjection {
  const WikiImageProjection(this.body, this.references);
  final String body;
  final List<WikiExampleReference> references;
}

/// Source identities and safe display-only removals. A source image's ordinary
/// prose neighbours, tables and code examples are never removed as captions.
class WikiImageDocument {
  WikiImageDocument._(this.body, this._scan);
  factory WikiImageDocument.parse(String body) =>
      WikiImageDocument._(body, _scanWikiImages(body));

  final String body;
  final _ImageScan _scan;
  List<WikiExampleReference> get references => _scan.references;

  WikiImageProjection project(String displayedBody) {
    if (displayedBody == body) {
      return WikiImageProjection(_scan.withoutImageRows(), references);
    }
    if (references.isEmpty) return WikiImageProjection(displayedBody, const []);
    // Translations may retain a source image as plain `post #ID`. Only safe
    // standalone items with a known identity and unambiguous count can move.
    final shown = _scanWikiImages(displayedBody, allowPlain: true);
    final sourceByKey = <String, List<WikiExampleReference>>{};
    final shownByKey = <String, List<WikiExampleReference>>{};
    for (final ref in references) {
      sourceByKey.putIfAbsent(ref.key, () => []).add(ref);
    }
    for (final ref in shown.references) {
      if (shown.safeRows.containsKey(ref.occurrence)) {
        shownByKey.putIfAbsent(ref.key, () => []).add(ref);
      }
    }
    final removed = <int>{};
    final localized = <int, WikiExampleReference>{};
    for (final MapEntry(key: key, value: source) in sourceByKey.entries) {
      final targets = shownByKey[key];
      if (targets == null || targets.length != source.length) continue;
      for (var i = 0; i < source.length; i++) {
        final original = source[i], target = targets[i];
        removed.add(shown.safeRows[target.occurrence]!);
        localized[original.occurrence] = WikiExampleReference(
          original.id,
          target.caption.isNotEmpty ? target.caption : original.caption,
          kind: original.kind,
          section: target.section.isNotEmpty
              ? target.section
              : original.section,
          sectionId: original.sectionId,
          occurrence: original.occurrence,
        );
      }
    }
    return WikiImageProjection(shown.withoutImageRows(removed), [
      for (final ref in references) localized[ref.occurrence] ?? ref,
    ]);
  }
}

typedef _WikiHeading = ({int line, int level, String title});

class _ImageScan {
  const _ImageScan(this.lines, this.headings, this.references, this.safeRows);
  final List<String> lines;
  final List<_WikiHeading> headings;
  final List<WikiExampleReference> references;
  final Map<int, int> safeRows;

  String withoutImageRows([Set<int>? selected]) {
    final removed = selected ?? safeRows.values.toSet();
    if (removed.isEmpty) return lines.join('\n');
    // Work from nested headings outwards, removing only sections whose entire
    // content was moved. An unrelated empty heading remains untouched.
    for (final h in headings.reversed) {
      final end =
          headings
              .where((other) => other.line > h.line && other.level <= h.level)
              .map((other) => other.line)
              .firstOrNull ??
          lines.length;
      var moved = false, remaining = false;
      for (var i = h.line + 1; i < end; i++) {
        moved |= removed.contains(i);
        remaining |= !removed.contains(i) && lines[i].trim().isNotEmpty;
      }
      if (moved && !remaining) removed.add(h.line);
    }
    return [
      for (var i = 0; i < lines.length; i++)
        if (!removed.contains(i)) lines[i],
    ].join('\n').trim();
  }
}

final _wikiCode = RegExp(
  r'\[(code|pre)(?:=[^\]]*)?\][\s\S]*?\[/\1\]|```[\s\S]*?```|~~~[\s\S]*?~~~|`[^`\r\n]+`',
  caseSensitive: false,
);
final _wikiEmbed = RegExp(r'!(post|asset)\s*#\s*(\d+)\b', caseSensitive: false);
final _wikiPlainReference = RegExp(
  r'!?(post|asset)\s*#\s*(\d+)\b',
  caseSensitive: false,
);

_ImageScan _scanWikiImages(String body, {bool allowPlain = false}) {
  final lines = body.split('\n');
  final code = _wikiCode.allMatches(body).toList();
  final headings = <_WikiHeading>[], stack = <_WikiHeading>[];
  final refs = <WikiExampleReference>[];
  final safeRows = <int, int>{};
  var offset = 0;
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    bool protected(int position) =>
        code.any((m) => position >= m.start && position < m.end);
    final trimmed = line.trim();
    final dtext = RegExp(r'^h([1-6])\.\s*(.+)$').firstMatch(trimmed);
    final markdown = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(trimmed);
    if ((dtext != null || markdown != null) &&
        !protected(offset + line.indexOf(trimmed))) {
      final h = (
        line: lineIndex,
        level: dtext != null ? int.parse(dtext[1]!) : markdown![1]!.length,
        title: (dtext?[2] ?? markdown![2]!).trim(),
      );
      while (stack.isNotEmpty && stack.last.level >= h.level) {
        stack.removeLast();
      }
      stack.add(h);
      headings.add(h);
    }
    final matches = (allowPlain ? _wikiPlainReference : _wikiEmbed)
        .allMatches(line)
        .where((m) => !protected(offset + m.start))
        .toList();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final id = int.tryParse(match[2]!);
      if (id == null || id <= 0) continue;
      final end = i + 1 < matches.length ? matches[i + 1].start : line.length;
      final tail = line.substring(match.end, end).trim();
      // Only an explicit colon starts a caption. Other trailing prose stays
      // in the article rather than being silently relabelled as image text.
      final caption = tail.startsWith(':') || tail.startsWith('：')
          ? tail.substring(1).trim()
          : '';
      final prefix = line.substring(0, match.start);
      final safe =
          matches.length == 1 &&
          RegExp(r'^\s*(?:[-*+]\s+|\d+[.)]\s+)?$').hasMatch(prefix) &&
          (tail.isEmpty || tail.startsWith(':') || tail.startsWith('：')) &&
          !RegExp(
            r'<[/]?(?:table|tr|td|th)\b|\[/?(?:table|tr|td|th|quote|expand|spoiler)\b',
            caseSensitive: false,
          ).hasMatch(line);
      final ref = WikiExampleReference(
        id,
        caption,
        kind: match[1]!.toLowerCase() == 'asset'
            ? WikiImageKind.asset
            : WikiImageKind.post,
        section: List.unmodifiable(stack.map((h) => h.title)),
        sectionId: stack.isEmpty ? -1 : stack.last.line,
        occurrence: refs.length,
      );
      refs.add(ref);
      if (safe) safeRows[ref.occurrence] = lineIndex;
    }
    offset += line.length + 1;
  }
  return _ImageScan(lines, headings, List.unmodifiable(refs), safeRows);
}
