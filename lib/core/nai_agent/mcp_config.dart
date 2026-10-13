import 'dart:convert';

const naiAgentMcpExposures = ['codemode', 'deferred', 'direct', 'hidden'];

/// Public metadata only. Commands, environment and authentication stay in the
/// existing encrypted credential store, then travel through private host stdin.
class AgentMcpServer {
  const AgentMcpServer({
    required this.name,
    required this.configId,
    required this.transport,
    this.enabled = true,
    this.exposure = 'codemode',
  });
  final String name, configId, transport, exposure;
  final bool enabled;
  Map<String, dynamic> toJson() => {
    'name': name,
    'configId': configId,
    'transport': transport,
    'enabled': enabled,
    'exposure': exposure,
  };
  factory AgentMcpServer.fromJson(Map<String, dynamic> json) => AgentMcpServer(
    name: json['name'] as String,
    configId: json['configId'] as String,
    transport: json['transport'] as String,
    enabled: json['enabled'] != false,
    exposure: json['exposure'] as String? ?? 'codemode',
  );
}

Map<String, dynamic> parseAgentMcpConfig(String name, String text) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(name) ||
      name.replaceAll('-', '_') == 'nai_studio') {
    throw const FormatException('Invalid or reserved MCP server name');
  }
  dynamic value;
  try {
    value = jsonDecode(text);
  } on FormatException {
    throw const FormatException('Invalid MCP JSON');
  }
  if (value is! Map) {
    throw const FormatException('MCP configuration must be an object');
  }
  final config = Map<String, dynamic>.from(value);
  final type = config['type'];
  if (type != null && type != 'stdio' && type != 'http') {
    throw const FormatException(
      'MCP supports stdio and Streamable HTTP; legacy SSE is unsupported',
    );
  }
  if (config['url'] != null) {
    final uri = Uri.tryParse('${config['url']}');
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        config.containsKey('command') ||
        type == 'stdio') {
      throw const FormatException('Invalid MCP HTTP URL');
    }
  } else if (config['command'] is! String ||
      (config['command'] as String).trim().isEmpty ||
      type == 'http') {
    throw const FormatException('MCP command must name one executable');
  }
  if (config['args'] != null &&
      (config['args'] is! List ||
          (config['args'] as List).any((arg) => arg is! String))) {
    throw const FormatException('MCP args must be an array of strings');
  }
  for (final field in ['env', 'headers']) {
    final map = config[field];
    if (map != null &&
        (map is! Map || map.values.any((value) => value is! String))) {
      throw FormatException('MCP $field must contain string values');
    }
  }
  if (config.containsKey('auth')) {
    throw const FormatException(
      'Use MCP headers or OAuth instead of Studio provider credentials',
    );
  }
  if (config['exposure'] != null &&
      !naiAgentMcpExposures.contains(config['exposure'])) {
    throw const FormatException('Invalid MCP exposure');
  }
  return config;
}
