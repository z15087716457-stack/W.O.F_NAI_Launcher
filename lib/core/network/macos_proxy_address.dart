/// The scutil HTTP and HTTPS settings both describe forward-proxy endpoints.
String? macOSProxyAddress(String output) {
  final values = <String, String>{};
  for (final match in RegExp(
    r'^\s*(HTTPS?(?:Enable|Proxy|Port))\s*:\s*([^\s]+)\s*$',
    multiLine: true,
  ).allMatches(output)) {
    values.putIfAbsent(match[1]!, () => match[2]!);
  }
  for (final scheme in ['HTTP', 'HTTPS']) {
    final host = values['${scheme}Proxy'];
    final port = int.tryParse(values['${scheme}Port'] ?? '');
    if (values['${scheme}Enable'] == '1' &&
        host != null &&
        port != null &&
        port >= 1 &&
        port <= 65535) {
      final address = host.contains(':') && !host.startsWith('[')
          ? '[$host]'
          : host;
      return '$address:$port';
    }
  }
  return null;
}
