import 'dart:convert';

import '../../data/models/resources/floating_window_data.dart';

/// Versioned, storage-free launch contract. Empty arguments mean main engine.
class ResourceWindowArguments {
  const ResourceWindowArguments({
    required this.kind,
    this.scope = const FloatingResourceScope(),
  });

  final FloatingResourceKind kind;
  final FloatingResourceScope scope;

  String encode() => jsonEncode({
    'type': 'resource',
    'version': 1,
    'kind': kind.name,
    'scope': scope.toJson(),
  });

  static ResourceWindowArguments? parse(String arguments) {
    if (arguments.isEmpty) return null;
    final json = jsonDecode(arguments);
    if (json is! Map<String, dynamic> ||
        json['type'] != 'resource' ||
        json['version'] != 1 ||
        !FloatingResourceKind.values.any((kind) => kind.name == json['kind'])) {
      throw const FormatException('Unsupported resource window arguments');
    }
    return ResourceWindowArguments(
      kind: FloatingResourceKind.values.byName(json['kind'] as String),
      scope: FloatingResourceScope.fromJson(
        Map<String, dynamic>.from(json['scope'] as Map),
      ),
    );
  }
}

/// Injectable dispatch keeps child engines out of the primary startup pipeline.
Future<void> dispatchResourceWindow({
  required String arguments,
  required Future<void> Function() startMain,
  required Future<void> Function(ResourceWindowArguments) startResource,
}) async {
  final resource = ResourceWindowArguments.parse(arguments);
  if (resource == null) {
    await startMain();
  } else {
    await startResource(resource);
  }
}
