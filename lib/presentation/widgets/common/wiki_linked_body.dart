import 'package:flutter/material.dart';
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
    this.headingAnchors,
    this.linkListsAsChips = false,
    this.onTagAdd,
  });
  final String body;
  final ValueChanged<CompletionCandidate> onTagTap;
  final TextStyle? style;
  final List<GlobalKey>? headingAnchors;

  /// Bullet lists that are pure tag links (three items or more) render as a
  /// wrapping chip cloud. Other lists keep their default bullets.
  final bool linkListsAsChips;

  /// Shift+click on a chip in a [linkListsAsChips] cloud.
  final ValueChanged<CompletionCandidate>? onTagAdd;

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
          blockSpacing: headingAnchors == null ? 10 : 14,
          listIndent: 18,
        );
        final headings = headingAnchors == null
            ? null
            : _WikiHeadingBuilder(headingAnchors!, sheet, onTapLink);
        final builders = <String, MarkdownElementBuilder>{
          if (headings != null)
            for (var level = 1; level <= 6; level++) 'h$level': headings,
          if (linkListsAsChips)
            'ul': _WikiLinkListBuilder(
              byHref: {
                for (final item in (document?.targets ?? const {}).values)
                  WikiTagLinks.href(item.canonicalTag): item,
              },
              fontSize: (textStyle?.fontSize ?? 14) - 1.5,
              onTap: onTagTap,
              onAdd: onTagAdd,
              translationOf: (candidate) =>
                  candidate.translation ??
                  ref
                      .read(autoTagTranslationProvider)
                      .nameFor(candidate.canonicalTag),
            ),
        };
        return MarkdownBody(
          key: headingAnchors?.isNotEmpty == true
              ? ObjectKey(headingAnchors!.first)
              : null,
          data: document?.markdown ?? WikiTagLinks.withoutLocalLinks(body),
          selectable: true,
          fitContent: false,
          imageBuilder: (_, _, alt) => Text(alt ?? '', style: textStyle),
          softLineBreak: true,
          styleSheet: sheet,
          builders: builders,
          onTapLink: onTapLink,
        );
      },
    );
  }
}

class _WikiHeadingBuilder extends MarkdownElementBuilder {
  _WikiHeadingBuilder(this.anchors, this.sheet, this.onTapLink);
  final List<GlobalKey> anchors;
  final MarkdownStyleSheet sheet;
  final MarkdownTapLinkCallback onTapLink;
  int index = 0;

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
/// or an external link keeps the stock bullet rendering.
class _WikiLinkListBuilder extends MarkdownElementBuilder {
  _WikiLinkListBuilder({
    required this.byHref,
    required this.fontSize,
    required this.onTap,
    required this.onAdd,
    required this.translationOf,
  });

  /// Candidates keyed by the full `wof-tag:` URI, matching [WikiTagLinks.href].
  final Map<String, CompletionCandidate> byHref;
  final double fontSize;
  final ValueChanged<CompletionCandidate> onTap;
  final ValueChanged<CompletionCandidate>? onAdd;
  final String? Function(CompletionCandidate) translationOf;

  static final _separators = RegExp(r'^[\s/,、，|&]*$');

  @override
  bool isBlockElement() => true;

  CompletionCandidate? _targetOf(String? href) =>
      href == null ? null : byHref[href];

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
    final links = _linkItems(element);
    if (links == null) return null;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final link in links) _chip(context, link)],
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
    return Tooltip(
      message: tooltip,
      child: Material(
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
                    style: TextStyle(
                      fontSize: fontSize,
                      color: scheme.onSurface,
                    ),
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
      ),
    );
  }

  static String _compactCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
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
