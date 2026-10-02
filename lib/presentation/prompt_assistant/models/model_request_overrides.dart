import 'dart:convert';

/// Model-specific HTTP options. Values are stored in secure storage, not in
/// the ordinary settings JSON or configuration exports.
class ModelRequestOverrides {
  const ModelRequestOverrides({this.headers = const {}, this.body = const {}});

  static const empty = ModelRequestOverrides();
  final Map<String, String> headers;
  final Map<String, dynamic> body;
  bool get isEmpty => headers.isEmpty && body.isEmpty;

  Map<String, dynamic> toJson() => {'headers': headers, 'body': body};
  String encode() => jsonEncode(toJson());

  factory ModelRequestOverrides.decode(String raw) {
    final json = jsonDecode(raw) as Map;
    return ModelRequestOverrides(
      headers: Map.unmodifiable(
        (json['headers'] as Map).cast<String, String>(),
      ),
      body: Map.unmodifiable((json['body'] as Map).cast<String, dynamic>()),
    );
  }

  static String? headerError(String name, String value) {
    if (!RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$").hasMatch(name)) {
      return '请输入有效的请求头名称';
    }
    if (RegExp(r'[\x00-\x08\x0A-\x1F\x7F]').hasMatch(value)) {
      return '请求头值不能包含换行或控制字符';
    }
    return null;
  }

  String? validate(String model) {
    for (final entry in headers.entries) {
      final error = headerError(entry.key, entry.value);
      if (error != null) return error;
    }
    if (body.keys.any((key) => key.trim().isEmpty)) return '请求体字段名不能为空';
    if (body.containsKey('model') && body['model'] != model) {
      return '模型 ID 请通过模型列表设置';
    }
    if (body.containsKey('stream') && body['stream'] != false) {
      return '当前接口使用非流式请求，stream 应为 false';
    }
    return null;
  }

  /// Objects are patched recursively, so a custom generationConfig or
  /// reasoning field keeps unrelated options. Arrays/scalars replace values.
  Map<String, dynamic> applyBody(Map<String, dynamic> defaults) {
    Map<String, dynamic> merge(Map base, Map patch) => {
      for (final key in {...base.keys, ...patch.keys})
        '$key': !patch.containsKey(key)
            ? base[key]
            : base[key] is Map && patch[key] is Map
            ? merge(base[key] as Map, patch[key] as Map)
            : patch[key],
    };
    return merge(defaults, body);
  }
}
