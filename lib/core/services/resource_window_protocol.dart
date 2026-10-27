import 'dart:convert';

import '../../data/models/resources/floating_window_data.dart';

/// Versioned, storage-free launch contract. Empty arguments mean main engine.
class ResourceWindowArguments {
  const ResourceWindowArguments({
    required this.kind,
    this.scope = const FloatingResourceScope(),
    this.brightness = 'dark',
    this.style = 'geist',
    this.locale = 'zh',
    this.fontKey = 'bundled:HarmonyOS Sans SC',
    this.rect,
    this.alwaysOnTop = false,
  });

  final FloatingResourceKind kind;
  final FloatingResourceScope scope;
  final String brightness, style, locale, fontKey;
  final Map<String, Object?>? rect;
  final bool alwaysOnTop;

  String encode() => jsonEncode({
    'type': 'resource',
    'version': 1,
    'kind': kind.name,
    'scope': scope.toJson(),
    'brightness': brightness,
    'style': style,
    'locale': locale,
    'fontKey': fontKey,
    'rect': rect,
    'alwaysOnTop': alwaysOnTop,
  });

  static ResourceWindowArguments? parse(String arguments) {
    if (arguments.isEmpty) return null;
    final json = jsonDecode(arguments);
    if (json is! Map<String, dynamic> ||
        json['type'] != 'resource' ||
        json['version'] != 1 ||
        !FloatingResourceKind.values.any((kind) => kind.name == json['kind']) ||
        json['brightness'] != null &&
            !const ['light', 'dark'].contains(json['brightness']) ||
        json['style'] != null && json['style'] != 'geist' ||
        json['scope'] is! Map) {
      throw const FormatException('Unsupported resource window arguments');
    }
    return ResourceWindowArguments(
      kind: FloatingResourceKind.values.byName(json['kind'] as String),
      brightness: json['brightness'] as String? ?? 'dark',
      style: json['style'] as String? ?? 'geist',
      locale: json['locale'] as String? ?? 'zh',
      fontKey: json['fontKey'] as String? ?? 'bundled:HarmonyOS Sans SC',
      rect: json['rect'] == null
          ? null
          : Map<String, Object?>.from(json['rect'] as Map),
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? false,
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
