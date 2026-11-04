import 'dart:convert';
import 'dart:io';

class SettingsGpuInfo {
  const SettingsGpuInfo(this.name, this.vramMb, this.compute, this.cuda);
  final String name, cuda;
  final int vramMb;
  final double compute;
  bool get int8 => compute >= 7.5; // Same threshold as bundled native_int8.py.
  bool get rtxVideo => name.toUpperCase().contains('RTX');
}

typedef SettingsGpuCommand = Future<String> Function(List<String> arguments);

/// Reads the Mac's chip name (`machdep.cpu.brand_string`).
typedef SettingsChipName = Future<String> Function();

class SettingsGpuProbe {
  SettingsGpuProbe({
    SettingsGpuCommand? run,
    bool? macOS,
    SettingsChipName? chipName,
  }) : _run = run ?? _command,
       _macOS = macOS ?? Platform.isMacOS,
       _chipName = chipName ?? _sysctlChipName;
  final SettingsGpuCommand _run;
  final bool _macOS;
  final SettingsChipName _chipName;

  static Future<String> _sysctlChipName() async {
    final result = await Process.run('/usr/sbin/sysctl', [
      '-n',
      'machdep.cpu.brand_string',
    ]).timeout(const Duration(seconds: 5));
    if (result.exitCode != 0) {
      throw const FormatException('Chip query failed');
    }
    return result.stdout as String;
  }

  /// On Apple silicon the GPU is part of the chip, so the chip name (for
  /// example `Apple M2 Max`) names it; there is no separate video memory.
  /// Intel Macs report their CPU here, which is not a GPU name.
  static SettingsGpuInfo? parseMacChip(String brand) {
    final name = brand.trim();
    if (!name.startsWith('Apple ') || name.length > 64 || name.contains('\n')) {
      return null;
    }
    return SettingsGpuInfo(name, 0, 0, '');
  }

  static Future<String> _command(List<String> args) async {
    final process = await Process.start('nvidia-smi', args);
    final output = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    final errors = process.stderr.drain<void>();
    try {
      final code = await process.exitCode.timeout(const Duration(seconds: 5));
      await errors.timeout(const Duration(seconds: 2));
      final text = await output.timeout(const Duration(seconds: 2));
      if (code != 0 || text.length > 65536) {
        throw const FormatException('GPU query failed');
      }
      return text;
    } finally {
      process.kill();
    }
  }

  static SettingsGpuInfo? parse(String csv, String driver) {
    final candidates = <SettingsGpuInfo>[];
    final cuda =
        RegExp(r'CUDA Version:\s*([0-9.]+)').firstMatch(driver)?.group(1) ?? '';
    for (final line in csv.split('\n')) {
      final fields = line.split(',').map((part) => part.trim()).toList();
      if (fields.length != 3 || fields[0].isEmpty) continue;
      final memory = int.tryParse(fields[1]);
      final compute = double.tryParse(fields[2]);
      if (memory == null || memory < 0 || compute == null || !compute.isFinite) {
        continue;
      }
      candidates.add(SettingsGpuInfo(fields[0], memory, compute, cuda));
    }
    // Bundled inference uses CUDA device 0. Do not advertise another GPU's caps.
    return candidates.firstOrNull;
  }

  Future<SettingsGpuInfo?> inspect() async {
    if (_macOS) {
      try {
        return parseMacChip(await _chipName());
      } catch (_) {
        return null;
      }
    }
    try {
      final csv = await _run([
        '--query-gpu=name,memory.total,compute_cap',
        '--format=csv,noheader,nounits',
      ]);
      final driver = await _run([]);
      return parse(csv, driver);
    } catch (_) {
      return null;
    }
  }
}
