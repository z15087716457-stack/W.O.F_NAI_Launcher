import 'package:collection/collection.dart';
import 'rag_settings.dart';

class RagSearchHit {
  const RagSearchHit({
    required this.id,
    required this.title,
    required this.snippet,
    required this.section,
  });
  final String id, title, snippet, section;
  factory RagSearchHit.fromJson(Map<String, dynamic> value) => RagSearchHit(
    id: value['id'] as String,
    title: value['title'] as String,
    snippet: value['snippet'] as String,
    section: value['section'] as String,
  );
}

/// Stable provider key: a folder/filter with unchanged IDs reuses its request.
class RagTextQuery {
  RagTextQuery({
    required this.source,
    required this.query,
    Iterable<String>? allowed,
    Iterable<int>? categories,
  }) : allowed = allowed == null ? null : (allowed.toSet().toList()..sort()),
       categories = categories == null
           ? null
           : (categories.toSet().toList()..sort());
  final RagSource source;
  final String query;
  final List<String>? allowed;
  final List<int>? categories;
  static const _equal = ListEquality<Object>();
  @override
  bool operator ==(Object other) =>
      other is RagTextQuery &&
      other.source == source &&
      other.query == query &&
      _equal.equals(other.allowed, allowed) &&
      _equal.equals(other.categories, categories);
  @override
  int get hashCode =>
      Object.hash(source, query, _equal.hash(allowed), _equal.hash(categories));
}
