import 'dart:convert';

/// Logical retained payload size, excluding allocator and database overhead.
class CacheFootprint {
  const CacheFootprint(this.entries, this.bytes);
  final int entries;
  final int bytes;

  factory CacheFootprint.json(Iterable<Object?> payloads) {
    var entries = 0, bytes = 0;
    for (final payload in payloads) {
      entries++;
      bytes += utf8.encode(jsonEncode(payload)).length;
    }
    return CacheFootprint(entries, bytes);
  }

  CacheFootprint operator +(CacheFootprint other) =>
      CacheFootprint(entries + other.entries, bytes + other.bytes);
}
