import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/wiki/wiki_tag_links.dart';

/// Shared selectable article renderer for the preview and the full Wiki.
class WikiLinkedBody extends ConsumerWidget {
  const WikiLinkedBody({
    super.key,
    required this.body,
    required this.onTagTap,
    this.style,
    this.headingAnchors,
  });
  final String body;
  final ValueChanged<CompletionCandidate> onTagTap;
  final TextStyle? style;
  final List<GlobalKey>? headingAnchors;

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
        return MarkdownBody(
          data: document?.markdown ?? WikiTagLinks.withoutLocalLinks(body),
          selectable: true,
          fitContent: false,
          imageBuilder: (_, _, alt) => Text(alt ?? '', style: textStyle),
          softLineBreak: true,
          styleSheet: sheet,
          builders: headings == null
              ? const {}
              : {for (var level = 1; level <= 6; level++) 'h$level': headings},
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
    if (index >= anchors.length) return null;
    final anchor = anchors[index++];
    return Padding(
      key: anchor,
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: MarkdownBody(
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
