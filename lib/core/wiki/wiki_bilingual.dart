/// Pairs a translated wiki article with its original for the bilingual
/// reading mode. The translation contract keeps headings, paragraphs and
/// lists structurally parallel, so blocks align positionally.
library;

/// One paragraph/heading/list pair in the bilingual reading mode.
typedef WikiBilingualBlock = ({
  String translated,
  String original,
  bool heading,
});

enum _BlockKind { paragraph, list, heading }

class _Block {
  const _Block(this.kind, this.level, this.lines);
  final _BlockKind kind;

  /// Heading level (1-6) for heading blocks, otherwise 0.
  final int level;
  final List<String> lines;

  String get text => lines.join('\n');
  bool get isHeading => kind == _BlockKind.heading;
}

final _headingLine = RegExp(r'^(#{1,6})\s');
final _listLine = RegExp(r'^\s{0,3}(?:[-*+]|\d{1,9}\.)\s');

/// Split markdown into structural blocks: an ATX heading is its own block,
/// blank lines are block boundaries, consecutive list lines plus their
/// indented continuations merge into one block, and any other run of
/// non-empty lines merges into a paragraph.
List<_Block> _blocks(String body) {
  final blocks = <_Block>[];
  _BlockKind? kind;
  var level = 0;
  final buffer = <String>[];
  void flush() {
    if (buffer.isNotEmpty) {
      blocks.add(_Block(kind!, level, List.of(buffer)));
      buffer.clear();
    }
  }

  for (final line in body.split('\n')) {
    if (line.trim().isEmpty) {
      flush();
      kind = null;
      continue;
    }
    final heading = _headingLine.firstMatch(line);
    if (heading != null) {
      flush();
      kind = null;
      blocks.add(_Block(_BlockKind.heading, heading[1]!.length, [line]));
      continue;
    }
    final isListItem = _listLine.hasMatch(line);
    final isIndented = line.startsWith(' ') || line.startsWith('\t');
    if (kind == _BlockKind.list && (isListItem || isIndented)) {
      buffer.add(line);
      continue;
    }
    if (isListItem) {
      flush();
      kind = _BlockKind.list;
      level = 0;
      buffer.add(line);
      continue;
    }
    if (kind != _BlockKind.paragraph) {
      flush();
      kind = _BlockKind.paragraph;
      level = 0;
    }
    buffer.add(line);
  }
  flush();
  return blocks;
}

class _Section {
  const _Section(this.level, this.blocks);

  /// Leading heading level, or null for the preamble before the first heading.
  final int? level;
  final List<_Block> blocks;

  String get text => blocks.map((block) => block.text).join('\n\n');
}

/// Sections are bounded by headings; content before the first heading forms
/// the (level-less) first section.
List<_Section> _sections(List<_Block> blocks) {
  final sections = <_Section>[];
  var current = <_Block>[];
  int? currentLevel;
  for (final block in blocks) {
    if (block.isHeading) {
      if (current.isNotEmpty) sections.add(_Section(currentLevel, current));
      current = [block];
      currentLevel = block.level;
    } else {
      current.add(block);
    }
  }
  if (current.isNotEmpty) sections.add(_Section(currentLevel, current));
  return sections;
}

/// Aligns a translated body with its original block by block. Returns null
/// when neither exact block matching nor the section fallback lines up.
List<WikiBilingualBlock>? alignWikiBlocks(String translated, String original) {
  final translatedBlocks = _blocks(translated);
  final originalBlocks = _blocks(original);
  if (translatedBlocks.isEmpty || originalBlocks.isEmpty) return null;
  if (translatedBlocks.length == originalBlocks.length) {
    var matches = true;
    for (var i = 0; i < translatedBlocks.length; i++) {
      final a = translatedBlocks[i];
      final b = originalBlocks[i];
      if (a.isHeading != b.isHeading || a.level != b.level) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return [
        for (var i = 0; i < translatedBlocks.length; i++)
          (
            translated: translatedBlocks[i].text,
            original: originalBlocks[i].text,
            heading: translatedBlocks[i].isHeading,
          ),
      ];
    }
  }
  final translatedSections = _sections(translatedBlocks);
  final originalSections = _sections(originalBlocks);
  if (translatedSections.isNotEmpty &&
      translatedSections.length == originalSections.length) {
    var matches = true;
    for (var i = 0; i < translatedSections.length; i++) {
      if (translatedSections[i].level != originalSections[i].level) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return [
        for (var i = 0; i < translatedSections.length; i++)
          (
            translated: translatedSections[i].text,
            original: originalSections[i].text,
            heading: false,
          ),
      ];
    }
  }
  return null;
}
