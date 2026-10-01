import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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
  });
  final String body;
  final ValueChanged<CompletionCandidate> onTagTap;
  final TextStyle? style;

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
        return MarkdownBody(
          data: document?.markdown ?? WikiTagLinks.withoutLocalLinks(body),
          selectable: true,
          fitContent: false,
          imageBuilder: (_, _, alt) => Text(alt ?? '', style: textStyle),
          softLineBreak: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: textStyle,
            listBullet: textStyle,
            a: textStyle?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.none,
            ),
            blockSpacing: 10,
            listIndent: 18,
          ),
          onTapLink: (_, href, _) {
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
          },
        );
      },
    );
  }
}
