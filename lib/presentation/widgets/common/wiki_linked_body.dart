import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../../core/wiki/wiki_tag_links.dart';
import '../autocomplete/tag_category_visuals.dart';

/// Shared selectable article renderer for the preview and the full Wiki.
class WikiLinkedBody extends ConsumerWidget {
  const WikiLinkedBody({
    super.key,
    required this.body,
    required this.onTagTap,
    this.style,
    this.headingStyle,
    this.headingAnchors,
    this.linkListsAsChips = false,
    this.exampleCards = false,
    this.initialSectionTitle,
    this.onTagAdd,
    this.onTagHover,
    this.onTagLeave,
  });
  final String body;
  final ValueChanged<CompletionCandidate> onTagTap;
  final TextStyle? style;

  /// Overrides the h1–h6 styles (used for the original side of a bilingual
  /// block, where headings render small and muted).
  final TextStyle? headingStyle;
  final List<GlobalKey>? headingAnchors;

  /// Bullet lists that are pure tag links (three items or more) render as a
  /// wrapping chip cloud. Other lists keep their default bullets.
  final bool linkListsAsChips;

  /// Top-level lists inside an example-named section ("示例"/"example"/…)
  /// render each item as a card. Checked before [linkListsAsChips].
  final bool exampleCards;

  /// Section title in effect before [body] starts. Bilingual blocks split the
  /// article so a list block does not see the heading that opened its
  /// section; the caller passes the running title in.
  final String? initialSectionTitle;

  /// Shift+click on a chip in a [linkListsAsChips] cloud.
  final ValueChanged<CompletionCandidate>? onTagAdd;

  /// Fires when the pointer hovers a tag link or chip, carrying the resolved
  /// candidate and the global pointer position for the preview overlay.
  final void Function(CompletionCandidate candidate, Offset position)?
  onTagHover;

  /// Fires when the pointer leaves a tag link or chip.
  final VoidCallback? onTagLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodyMedium;
    return FutureBuilder<WikiLinkDocument>(
      future: ref.watch(wikiTagLinksProvider).resolve(body),
      builder: (context, snapshot) {
        final document = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        void onTapLink(String text, String? href, String title) {
          if (href == null) return;
          if (href.startsWith('wof-tag:')) {
            final candidate = document?.targets.values
                .where((item) => WikiTagLinks.href(item.canonicalTag) == href)
                .firstOrNull;
            if (candidate != null) onTagTap(candidate);
          } else {
            final uri = Uri.tryParse(href);
            if (uri != null &&
                (uri.scheme == 'https' || uri.scheme == 'http')) {
              launchUrl(uri);
            }
          }
        }

        final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: textStyle,
          listBullet: textStyle,
          a: textStyle?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.none,
          ),
          h1: headingStyle,
          h2: headingStyle,
          h3: headingStyle,
          h4: headingStyle,
          h5: headingStyle,
          h6: headingStyle,
          blockSpacing: headingAnchors == null ? 10 : 14,
          listIndent: 18,
        );
        final sectionTracker = _WikiSectionTracker()
          ..heading = initialSectionTitle ?? '';
        final MarkdownElementBuilder? headings;
        if (headingAnchors?.isNotEmpty == true) {
          headings = _WikiHeadingBuilder(
            headingAnchors!,
            sheet,
            onTapLink,
            sectionTracker,
          );
        } else if (exampleCards) {
          // Track section titles without replacing heading rendering so lists
          // can still tell whether they sit inside an example section.
          headings = _WikiSectionHeadingTracker(sectionTracker);
        } else {
          headings = null;
        }
        final byHref = {
          for (final item in (document?.targets ?? const {}).values)
            WikiTagLinks.href(item.canonicalTag): item,
        };
        final listBuilder = linkListsAsChips || exampleCards
            ? _WikiListBuilder(
                sectionTracker: sectionTracker,
                exampleCards: exampleCards,
                linkListsAsChips: linkListsAsChips,
                sheet: sheet,
                byHref: byHref,
                fontSize: (textStyle?.fontSize ?? 14) - 1.5,
                onTap: onTagTap,
                onAdd: onTagAdd,
                onHover: onTagHover,
                onLeave: onTagLeave,
                onTapLink: onTapLink,
                translationOf: (candidate) =>
                    candidate.translation ??
                    ref
                        .read(autoTagTranslationProvider)
                        .nameFor(candidate.canonicalTag),
              )
            : null;
        final builders = <String, MarkdownElementBuilder>{
          if (headings != null)
            for (var level = 1; level <= 6; level++) 'h$level': headings,
          if (listBuilder != null) 'ul': listBuilder,
          if (listBuilder != null) 'ol': listBuilder,
        };
        final rendered =
            document?.markdown ?? WikiTagLinks.withoutLocalLinks(body);
        Widget markdown = MarkdownBody(
          key: headingAnchors?.isNotEmpty == true
              ? ObjectKey(headingAnchors!.first)
              : null,
          data: rendered,
          selectable: true,
          fitContent: false,
          imageBuilder: (_, _, alt) => Text(alt ?? '', style: textStyle),
          softLineBreak: true,
          styleSheet: sheet,
          builders: builders,
          onTapLink: onTapLink,
        );
        if (onTagHover != null) {
          final textToHref = _linkHrefs(rendered);
          markdown = MouseRegion(
            onHover: (event) {
              final hit = _linkHitAt(
                context,
                event.position,
                textToHref,
                byHref,
              );
              if (hit.candidate != null) {
                onTagHover!(hit.candidate!, event.position);
              } else if (hit.onBodyText) {
                // Chips and example cards inside the body manage their own
                // hover and must not cancel the shared preview timer.
                onTagLeave?.call();
              }
            },
            onExit: (_) => onTagLeave?.call(),
            child: markdown,
          );
        }
        return markdown;
      },
    );
  }

  /// Resolves the tag link under [global] by hit-testing the render tree for
  /// the innermost text target, then matching its recognised span text
  /// against the link labels parsed from the rendered markdown. [onBodyText]
  /// is true when the pointer rests on the selectable markdown itself —
  /// chip labels and card content return false so they keep managing their
  /// own hover regions.
  ({CompletionCandidate? candidate, bool onBodyText}) _linkHitAt(
    BuildContext context,
    Offset global,
    Map<String, String> textToHref,
    Map<String, CompletionCandidate> byHref,
  ) {
    final view =
        View.maybeOf(context) ??
        WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return (candidate: null, onBodyText: false);
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, global, view.viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderEditable) {
        final position = target.getPositionForPoint(global);
        final span = target.text?.getSpanForPosition(position);
        if (span is TextSpan && span.recognizer != null) {
          final label = (span.text ?? span.toPlainText()).trim();
          return (candidate: byHref[textToHref[label]], onBodyText: true);
        }
        return (candidate: null, onBodyText: true);
      }
      if (target is RenderParagraph) {
        return (candidate: null, onBodyText: false);
      }
    }
    return (candidate: null, onBodyText: false);
  }

  /// Maps each link's label text to its href in the rendered markdown.
  /// Duplicate labels keep the first target.
  static Map<String, String> _linkHrefs(String markdown) {
    final map = <String, String>{};
    void visit(List<md.Node> nodes) {
      for (final node in nodes) {
        if (node is! md.Element) continue;
        if (node.tag == 'a') {
          map.putIfAbsent(
            node.textContent.trim(),
            () => node.attributes['href'] ?? '',
          );
        }
        visit(node.children ?? const <md.Node>[]);
      }
    }

    visit(
      md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
      ).parseLines(markdown.split('\n')),
    );
    return map;
  }
}

/// Shared mutable state between the heading builder and the list builders of
/// one markdown pass. Headings record their text as the visitor walks the
/// document, so a list can tell whether it sits inside an example section.
class _WikiSectionTracker {
  String heading = '';

  static final _keywords = [
    '示例',
    '例子',
    '范例',
    '範例',
    '示范',
    '示範',
    '用例',
    '使用例',
    '实例',
    '實例',
    'example',
    '예시',
    '예제',
  ];

  bool get inExampleSection {
    final title = heading.replaceAll(RegExp(r'\s'), '').toLowerCase();
    // 「例」 alone counts, but substring matching would also catch 「例外」.
    if (title == '例') return true;
    return _keywords.any(title.contains);
  }
}

/// Records the current section title for the example-cards check without
/// replacing the stock heading rendering (used when there are no outline
/// anchors to attach).
class _WikiSectionHeadingTracker extends MarkdownElementBuilder {
  _WikiSectionHeadingTracker(this.tracker);
  final _WikiSectionTracker tracker;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) {
    tracker.heading = element.textContent;
  }
}

class _WikiHeadingBuilder extends MarkdownElementBuilder {
  _WikiHeadingBuilder(this.anchors, this.sheet, this.onTapLink, [this.tracker]);
  final List<GlobalKey> anchors;
  final MarkdownStyleSheet sheet;
  final MarkdownTapLinkCallback onTapLink;
  final _WikiSectionTracker? tracker;
  int index = 0;

  @override
  void visitElementBefore(md.Element element) {
    tracker?.heading = element.textContent;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (anchors.isEmpty) return null;
    // Markdown may reparse with the same builder after dependencies change.
    // Each complete traversal starts a new sequence of the same headings.
    if (index == anchors.length) index = 0;
    final anchor = anchors[index++];
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: MarkdownBody(
        key: anchor,
        data:
            '${'#' * int.parse(element.tag.substring(1))} ${_inlineMarkdown(element.children ?? [])}',
        selectable: true,
        fitContent: false,
        styleSheet: sheet,
        onTapLink: onTapLink,
      ),
    );
  }
}

/// Turns a bullet list made only of local tag links into a wrapping chip
/// cloud. Any li without a link, nested lists, meaningful text between links
/// or an external link keeps the stock bullet rendering. Inside an
/// example-named section a top-level list renders as cards instead — the
/// section check wins over the chip conversion.
class _WikiListBuilder extends MarkdownElementBuilder {
  _WikiListBuilder({
    required this.sectionTracker,
    required this.exampleCards,
    required this.linkListsAsChips,
    required this.sheet,
    required this.byHref,
    required this.fontSize,
    required this.onTap,
    required this.onAdd,
    required this.onHover,
    required this.onLeave,
    required this.onTapLink,
    required this.translationOf,
  });

  final _WikiSectionTracker sectionTracker;
  final bool exampleCards;
  final bool linkListsAsChips;
  final MarkdownStyleSheet sheet;

  /// Candidates keyed by the full `wof-tag:` URI, matching [WikiTagLinks.href].
  final Map<String, CompletionCandidate> byHref;
  final double fontSize;
  final ValueChanged<CompletionCandidate> onTap;
  final ValueChanged<CompletionCandidate>? onAdd;
  final void Function(CompletionCandidate candidate, Offset position)? onHover;
  final VoidCallback? onLeave;
  final MarkdownTapLinkCallback onTapLink;
  final String? Function(CompletionCandidate) translationOf;

  static final _separators = RegExp(r'^[\s/,、，|&]*$');

  /// ul/ol nesting depth while the visitor walks the document. Cards and
  /// chip clouds only apply to top-level lists.
  int _depth = 0;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) => _depth++;

  CompletionCandidate? _targetOf(String? href) =>
      href == null ? null : byHref[href];

  static bool _containsNestedList(md.Node node) {
    if (node is! md.Element) return false;
    if (node.tag == 'ul' || node.tag == 'ol') return true;
    return (node.children ?? const <md.Node>[]).any(_containsNestedList);
  }

  /// Example cards accept every li, as long as none nests another list.
  bool _cardable(md.Element list) {
    final children = list.children ?? const <md.Node>[];
    if (children.isEmpty) return false;
    for (final node in children) {
      if (node is! md.Element || node.tag != 'li') return false;
      if ((node.children ?? const <md.Node>[]).any(_containsNestedList)) {
        return false;
      }
    }
    return true;
  }

  List<md.Element>? _linkItems(md.Element list) {
    final children = list.children ?? const <md.Node>[];
    if (children.length < 3) return null;
    final links = <md.Element>[];
    for (final node in children) {
      if (node is! md.Element || node.tag != 'li') return null;
      final liLinks = <md.Element>[];
      var valid = true;
      void scan(md.Node child, {bool inLink = false}) {
        if (!valid) return;
        if (child is md.Text) {
          if (!inLink && !_separators.hasMatch(child.text)) valid = false;
          return;
        }
        if (child is! md.Element) {
          valid = false;
          return;
        }
        if (child.tag == 'ul' || child.tag == 'ol') {
          valid = false;
          return;
        }
        final link = child.tag == 'a';
        if (link) liLinks.add(child);
        for (final nested in child.children ?? const <md.Node>[]) {
          scan(nested, inLink: inLink || link);
        }
      }

      for (final nested in node.children ?? const <md.Node>[]) {
        scan(nested);
      }
      if (!valid || liLinks.isEmpty) return null;
      links.addAll(liLinks);
    }
    for (final link in links) {
      if (_targetOf(link.attributes['href']) == null) return null;
    }
    return links;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final topLevel = _depth == 1;
    _depth--;
    if (!topLevel) return null;
    if (exampleCards && sectionTracker.inExampleSection && _cardable(element)) {
      return _cards(context, element);
    }
    if (linkListsAsChips) {
      final links = _linkItems(element);
      if (links != null) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final link in links) _chip(context, link)],
        );
      }
    }
    return null;
  }

  Widget _cards(BuildContext context, md.Element list) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final width = twoColumns
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;
        final items = list.children ?? const <md.Node>[];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < items.length; index++)
              Container(
                key: ValueKey('wiki-example-card-$index'),
                width: width,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: MarkdownBody(
                  data: _cardItemMarkdown(
                    (items[index] as md.Element).children ?? const <md.Node>[],
                  ),
                  selectable: true,
                  fitContent: false,
                  softLineBreak: true,
                  styleSheet: sheet.copyWith(blockSpacing: 4),
                  onTapLink: onTapLink,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(BuildContext context, md.Element link) {
    final candidate = _targetOf(link.attributes['href'])!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final translation = translationOf(candidate);
    final tooltip = [
      TagCategoryVisuals.label(context, candidate.category),
      _compactCount(candidate.postCount),
      if (translation != null) translation,
    ].join(' · ');
    final chip = Material(
      color: scheme.onSurface.withValues(alpha: .045),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        key: ValueKey('wiki-chip-${candidate.canonicalTag}'),
        borderRadius: BorderRadius.circular(7),
        onTap: () {
          if (onAdd != null && HardwareKeyboard.instance.isShiftPressed) {
            onAdd!(candidate);
          } else {
            onTap(candidate);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: TagNormalizer.toDisplay(candidate.canonicalTag),
                  style: TextStyle(fontSize: fontSize, color: scheme.onSurface),
                ),
                if (translation != null)
                  TextSpan(
                    text: ' $translation',
                    style: TextStyle(
                      fontSize: fontSize - .5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    // The shared preview card replaces the tooltip when hover previews are on.
    if (onHover != null) {
      return MouseRegion(
        onEnter: (event) => onHover!(candidate, event.position),
        onHover: (event) => onHover!(candidate, event.position),
        onExit: (_) => onLeave?.call(),
        child: chip,
      );
    }
    return Tooltip(message: tooltip, child: chip);
  }

  static String _compactCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

/// Serializes one li's children back to markdown for an example card. Inline
/// siblings concatenate onto the same line; block children (loose lists wrap
/// item content in `p`) keep their paragraph breaks.
String _cardItemMarkdown(List<md.Node> children) {
  const blockTags = {
    'p',
    'ul',
    'ol',
    'blockquote',
    'pre',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
  };
  final blocks = <String>[];
  final inline = StringBuffer();
  void flush() {
    final text = inline.toString();
    inline.clear();
    if (text.trim().isNotEmpty) blocks.add(text);
  }

  for (final node in children) {
    if (node is md.Element && blockTags.contains(node.tag)) {
      flush();
      final block = _inlineMarkdown(node.children ?? []);
      if (block.trim().isNotEmpty) blocks.add(block);
    } else {
      inline.write(_inlineMarkdown([node]));
    }
  }
  flush();
  return blocks.join('\n\n');
}

String _inlineMarkdown(List<md.Node> nodes) => nodes.map((node) {
  if (node is md.Text) {
    return node.text.replaceAllMapped(
      RegExp(r'[\\`*_\[\]]'),
      (match) => '\\${match[0]}',
    );
  }
  final element = node as md.Element;
  final text = _inlineMarkdown(element.children ?? []);
  return switch (element.tag) {
    'a' => '[$text](${element.attributes['href'] ?? ''})',
    'strong' => '**$text**',
    'em' => '*$text*',
    'del' => '~~$text~~',
    'code' => '`${element.textContent}`',
    'br' => '  \n',
    _ => text,
  };
}).join();
