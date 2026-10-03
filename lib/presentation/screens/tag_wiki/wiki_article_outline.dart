import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

class WikiArticleHeading {
  WikiArticleHeading({required this.label, required this.level});

  final String label;
  final int level;
  final GlobalKey anchor = GlobalKey();
}

/// Use the Markdown parser so fenced code and setext headings behave correctly.
List<WikiArticleHeading> wikiArticleHeadings(String body) {
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
  ).parseLines(body.split('\n'));
  final headings = <WikiArticleHeading>[];
  void visit(List<md.Node> nodes) {
    for (final node in nodes) {
      if (node is! md.Element) continue;
      if (RegExp(r'^h[1-6]$').hasMatch(node.tag)) {
        headings.add(
          WikiArticleHeading(
            label: node.textContent.trim(),
            level: int.parse(node.tag.substring(1)),
          ),
        );
      } else {
        visit(node.children ?? []);
      }
    }
  }

  visit(nodes);
  return headings;
}
