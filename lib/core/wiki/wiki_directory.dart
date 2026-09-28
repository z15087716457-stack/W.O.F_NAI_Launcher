import 'dart:convert';

import 'package:flutter/services.dart';

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
}
