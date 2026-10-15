enum RagGalleryMode { mixed, visual, parameters }

class RagGalleryHit {
  const RagGalleryHit({
    required this.id,
    required this.path,
    required this.channel,
  });
  final String id, path, channel;
  factory RagGalleryHit.fromJson(Map<String, dynamic> json) => RagGalleryHit(
    id: json['id'] as String,
    path: json['path'] as String,
    channel: json['channel'] as String,
  );
}

class RagGalleryQueryOptions {
  const RagGalleryQueryOptions({
    this.mode = RagGalleryMode.mixed,
    this.image = '',
  });
  final RagGalleryMode mode;
  final String image;
}
