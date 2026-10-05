import 'dart:convert';

import 'package:flutter/services.dart';

import '../utils/tag_normalizer.dart';

class WikiDirectoryNode {
  const WikiDirectoryNode({
    required this.label,
    required this.children,
    this.group,
  });

  final String label;
  final String? group;
  final List<WikiDirectoryNode> children;

  factory WikiDirectoryNode.fromJson(Map<String, dynamic> json) =>
      WikiDirectoryNode(
        label: json['label'] as String,
        group: json['group'] as String?,
        children: (json['children'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  WikiDirectoryNode.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class WikiDirectoryGroup {
  const WikiDirectoryGroup({
    required this.title,
    required this.members,
    required this.children,
    required this.sourceUrl,
  });

  final String title;
  final List<String> members;
  final List<String> children;
  final String sourceUrl;

  factory WikiDirectoryGroup.fromJson(Map<String, dynamic> json) =>
      WikiDirectoryGroup(
        title: json['title'] as String,
        members: List<String>.from(json['members'] as List<dynamic>),
        children: List<String>.from(json['children'] as List<dynamic>),
        sourceUrl: json['source_url'] as String,
      );
}

/// Bundled snapshot of the official subject directory. Entries are references
/// to tags, and one tag may legitimately belong to several groups.
class WikiDirectory {
  const WikiDirectory({required this.roots, required this.groups});

  final List<WikiDirectoryNode> roots;
  final Map<String, WikiDirectoryGroup> groups;

  static Future<WikiDirectory> load() async {
    final data =
        jsonDecode(
              await rootBundle.loadString(
                'assets/databases/wiki_directory.json',
              ),
            )
            as Map<String, dynamic>;
    final rawGroups = data['groups'] as Map<String, dynamic>;
    return WikiDirectory(
      roots: (data['roots'] as List<dynamic>)
          .map(
            (item) => WikiDirectoryNode.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      groups: {
        for (final entry in rawGroups.entries)
          entry.key: WikiDirectoryGroup.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  Set<String> tagsForGroup(String group, {bool includeChildren = true}) {
    final result = <String>{};
    final visited = <String>{};

    void collect(String id) {
      if (!visited.add(id)) return;
      final entry = groups[id];
      if (entry == null) return;
      result.addAll(entry.members);
      if (includeChildren) {
        for (final child in entry.children) {
          collect(child);
        }
      }
    }

    collect(group);
    return result;
  }

  Set<String> tagsForNode(WikiDirectoryNode node) {
    final tags = <String>{};
    if (node.group case final group?) {
      tags.addAll(tagsForGroup(group));
    }
    for (final child in node.children) {
      tags.addAll(tagsForNode(child));
    }
    return tags;
  }

  /// Weakly-keyed per-instance reverse index, built lazily on the first
  /// [pathsForTag] call so the constructor can stay const.
  static final _tagPaths =
      Expando<Map<String, List<List<WikiDirectoryNode>>>>();

  /// Root-to-node paths where [tag] belongs, keeping only the deepest nodes:
  /// a containing node is reported only when none of its children contain the
  /// tag. At most four paths, in tree order. The reverse index is built lazily
  /// on the first call.
  List<List<WikiDirectoryNode>> pathsForTag(String tag) {
    final normalized = TagNormalizer.normalize(tag);
    if (normalized.isEmpty) return const [];
    final index = _tagPaths[this] ??= _buildTagPaths();
    return index[normalized] ?? const [];
  }

  Map<String, List<List<WikiDirectoryNode>>> _buildTagPaths() {
    final paths = <String, List<List<WikiDirectoryNode>>>{};
    final nodeTags = <WikiDirectoryNode, Set<String>>{};
    Set<String> tagsOf(WikiDirectoryNode node) =>
        nodeTags.putIfAbsent(node, () => tagsForNode(node));
    void visit(WikiDirectoryNode node, List<WikiDirectoryNode> trail) {
      final tags = tagsOf(node);
      if (tags.isEmpty) return;
      final path = [...trail, node];
      final childTags = [for (final child in node.children) tagsOf(child)];
      for (final tag in tags) {
        if (childTags.any((children) => children.contains(tag))) continue;
        final list = paths.putIfAbsent(tag, () => []);
        if (list.length < 4) list.add(path);
      }
      for (final child in node.children) {
        visit(child, path);
      }
    }

    for (final root in roots) {
      visit(root, const []);
    }
    return paths;
  }
}
