import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../presentation/ui/kit/ui_resource_kind.dart';

export '../../../presentation/ui/kit/ui_resource_kind.dart';

@immutable
class FloatingResourceScope {
  const FloatingResourceScope({
    this.folderPath,
    this.categoryId,
    this.collectionId,
    this.folderId,
    this.favoritesOnly = false,
  });
  final String? folderPath;
  final String? categoryId;
  final String? collectionId;
  final String? folderId;
  final bool favoritesOnly;

  Map<String, dynamic> toJson() => {
    'folderPath': folderPath,
    'categoryId': categoryId,
    'collectionId': collectionId,
    'folderId': folderId,
    'favoritesOnly': favoritesOnly,
  };

  factory FloatingResourceScope.fromJson(Map<String, dynamic> json) =>
      FloatingResourceScope(
        folderPath: json['folderPath'] as String?,
        categoryId: json['categoryId'] as String?,
        collectionId: json['collectionId'] as String?,
        folderId: json['folderId'] as String?,
        favoritesOnly: json['favoritesOnly'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is FloatingResourceScope &&
      folderPath == other.folderPath &&
      categoryId == other.categoryId &&
      collectionId == other.collectionId &&
      folderId == other.folderId &&
      favoritesOnly == other.favoritesOnly;
  @override
  int get hashCode => Object.hash(
    folderPath,
    categoryId,
    collectionId,
    folderId,
    favoritesOnly,
  );
}

@immutable
class FloatingWindowData {
  const FloatingWindowData({
    required this.id,
    required this.kind,
    required this.rect,
    required this.z,
    this.query = '',
    this.scope = const FloatingResourceScope(),
    this.minimized = false,
  });
  final String id;
  final FloatingResourceKind kind;
  final Rect rect;
  final int z;
  final String query;
  final FloatingResourceScope scope;
  final bool minimized;

  FloatingWindowData copyWith({
    Rect? rect,
    int? z,
    String? query,
    FloatingResourceScope? scope,
    bool? minimized,
  }) => FloatingWindowData(
    id: id,
    kind: kind,
    rect: rect ?? this.rect,
    z: z ?? this.z,
    query: query ?? this.query,
    scope: scope ?? this.scope,
    minimized: minimized ?? this.minimized,
  );

  /// Queries are deliberately session-only. Layout and scope survive restart.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'rect': [rect.left, rect.top, rect.width, rect.height],
    'z': z,
    'scope': scope.toJson(),
    'minimized': minimized,
  };

  factory FloatingWindowData.fromJson(Map<String, dynamic> json) {
    final rect = (json['rect'] as List).cast<num>();
    return FloatingWindowData(
      id: json['id'] as String,
      kind: FloatingResourceKind.values.byName(json['kind'] as String),
      rect: Rect.fromLTWH(
        rect[0].toDouble(),
        rect[1].toDouble(),
        rect[2].toDouble(),
        rect[3].toDouble(),
      ),
      z: json['z'] as int,
      scope: FloatingResourceScope.fromJson(
        Map<String, dynamic>.from(json['scope'] as Map),
      ),
      minimized: json['minimized'] as bool,
    );
  }
}
