import 'dart:io';

/// 不走代理的地址。
///
/// W.O.F 读到系统代理后给所有请求套上代理，连本机的也不例外；开着 Clash 这类系统代理时，
/// 本机的 LM Studio、Ollama、ComfyUI 都连不上（代理不会把 localhost 转回本机）。
/// 本机地址一律直连；macOS 上再照系统代理设置里的「不走代理」名单（`scutil --proxy` 的
/// `ExceptionsList`，网段、`*.xxx` 通配、精确域名）和「不对简单主机名使用代理」。
class ProxyBypassList {
  const ProxyBypassList({
    this.entries = const [],
    this.excludeSimpleHostnames = false,
  });

  /// 只放本机。
  static const loopbackOnly = ProxyBypassList();

  final List<String> entries;

  /// 没有点的主机名（例如局域网里的 `nas`）直连。
  final bool excludeSimpleHostnames;

  bool matches(String rawHost) {
    final host = _normalize(rawHost);
    if (host.isEmpty) return false;
    if (_isLoopback(host)) return true;
    if (excludeSimpleHostnames && !host.contains('.') && !host.contains(':')) {
      return true;
    }
    return entries.any((entry) => _matchesEntry(host, entry));
  }

  /// 解析 `scutil --proxy` 的输出。
  static ProxyBypassList fromScutil(String output) {
    final entries = <String>[];
    final list = RegExp(
      r'ExceptionsList\s*:\s*<array>\s*\{([^}]*)\}',
    ).firstMatch(output);
    if (list != null) {
      for (final line in list.group(1)!.split('\n')) {
        final item = RegExp(r'^\s*\d+\s*:\s*(\S+)\s*$').firstMatch(line);
        if (item != null) entries.add(item.group(1)!.toLowerCase());
      }
    }
    final simple = RegExp(r'ExcludeSimpleHostnames\s*:\s*1').hasMatch(output);
    return ProxyBypassList(entries: entries, excludeSimpleHostnames: simple);
  }

  /// macOS 上读系统代理设置的名单；读不到或不是 macOS 时只放本机。
  static ProxyBypassList readMacSystem() {
    if (!Platform.isMacOS) return loopbackOnly;
    try {
      final result = Process.runSync('scutil', ['--proxy']);
      if (result.exitCode != 0) return loopbackOnly;
      return fromScutil(result.stdout as String);
    } catch (_) {
      return loopbackOnly;
    }
  }

  static String _normalize(String host) {
    var h = host.trim().toLowerCase();
    if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
    return h;
  }

  static bool _isLoopback(String host) {
    if (host == 'localhost' || host.endsWith('.localhost')) return true;
    if (host == '::1') return true;
    final ip = InternetAddress.tryParse(host);
    return ip != null && ip.isLoopback;
  }

  static bool _matchesEntry(String host, String entry) {
    if (entry.startsWith('*.')) {
      final suffix = entry.substring(1); // ".local"
      return host.endsWith(suffix) || host == entry.substring(2);
    }
    if (entry.contains('/')) return _inCidr(host, entry);
    return host == entry;
  }

  static bool _inCidr(String host, String cidr) {
    final parts = cidr.split('/');
    final network = _ipv4(parts[0]);
    final bits = int.tryParse(parts.length > 1 ? parts[1] : '');
    final address = _ipv4(host);
    if (network == null || address == null || bits == null) return false;
    if (bits <= 0) return true;
    if (bits > 32) return false;
    final mask = (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF;
    return (network & mask) == (address & mask);
  }

  static int? _ipv4(String text) {
    final ip = InternetAddress.tryParse(text);
    if (ip == null || ip.type != InternetAddressType.IPv4) return null;
    return ip.rawAddress.fold<int>(0, (value, byte) => (value << 8) | byte);
  }
}
