import '../../ui/agent/agent_contract.dart';

/// Pure read projection. Unknown catalog categories must not masquerade as
/// general; wiki pages without an explicit found flag are successful pages.
List<AgentTagHit> agentTagHits(String tool, Map<String, dynamic> details) {
  final raw = switch (tool) {
    'tag_query' => details['tags'],
    'studio_search' => details['items'],
    'tag_related' => details['items'],
    'wiki_query' => details['pages'],
    _ => null,
  };
  if (raw is! List) return const [];
  String? short(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final runes = value.trim().runes;
    return runes.length <= 200
        ? value.trim()
        : '${String.fromCharCodes(runes.take(200))}…';
  }

  final hits = <AgentTagHit>[];
  for (final row in raw.whereType<Map>()) {
    if (row['found'] == false) continue;
    if (tool == 'studio_search' && row['name'] is! String) continue;
    final tag = row[tool == 'studio_search' ? 'name' : 'tag'];
    if (tag is! String || tag.trim().isEmpty) continue;
    hits.add(
      AgentTagHit(
        tag: tag,
        category:
            AgentTagCategory.values
                .where((c) => c.name == row['category'])
                .firstOrNull ??
            AgentTagCategory.other,
        count: tool != 'wiki_query' && row['post_count'] is num
            ? (row['post_count'] as num).toInt()
            : null,
        translation: row['zh'] is String
            ? row['zh'] as String
            : row['translation'] as String?,
        summary: short(row[tool == 'wiki_query' ? 'body' : 'definition']),
      ),
    );
  }
  if (tool != 'tag_related') {
    hits.sort((a, b) {
      if (a.count == null) return b.count == null ? a.tag.compareTo(b.tag) : 1;
      if (b.count == null) return -1;
      final count = b.count!.compareTo(a.count!);
      return count == 0 ? a.tag.compareTo(b.tag) : count;
    });
  }
  return hits.take(24).toList();
}
