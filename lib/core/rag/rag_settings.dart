import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';
import 'rag_platform.dart';

enum RagDevice { auto, cpu, cuda }

enum RagSource { tags, wiki, blocks, gallery }

class RagSettings {
  const RagSettings({
    this.enabled = false,
    this.embedding = '',
    this.python = '',
    this.device = RagDevice.auto,
  });
  final bool enabled;
  final String embedding, python;
  final RagDevice device;
  RagDevice deviceOn(RagPlatform platform, {int? memoryBytes}) {
    if (platform.isMacOS) {
      if (device == RagDevice.cpu || (memoryBytes ?? 0) <= (17 << 30)) {
        return RagDevice.cpu;
      }
      return RagDevice.auto;
    }
    return device == RagDevice.cuda && !platform.supportsCuda
        ? RagDevice.auto
        : device;
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'enabled': enabled,
    'embedding': embedding,
    'python': python,
    'device': device.name,
  };
  factory RagSettings.fromJson(Map<String, dynamic> json) => RagSettings(
    enabled: json['version'] == 1 && json['enabled'] == true,
    embedding: json['embedding'] is String ? json['embedding'] : '',
    python: json['python'] is String ? json['python'] : '',
    device:
        RagDevice.values.where((e) => e.name == json['device']).firstOrNull ??
        RagDevice.auto,
  );
  RagSettings copyWith({
    bool? enabled,
    String? embedding,
    String? python,
    RagDevice? device,
  }) => RagSettings(
    enabled: enabled ?? this.enabled,
    embedding: embedding ?? this.embedding,
    python: python ?? this.python,
    device: device ?? this.device,
  );
  String get connectionKey =>
      jsonEncode([enabled, embedding, python, device.name]);
}

final ragSettingsProvider =
    NotifierProvider<RagSettingsController, RagSettings>(
      RagSettingsController.new,
    );

class RagSettingsController extends Notifier<RagSettings> {
  static const storageKey = 'rag_preferences_v1';
  Future<void> _writes = Future.value();
  @override
  RagSettings build() {
    try {
      final value = ref
          .read(localStorageServiceProvider)
          .getSetting<String>(storageKey);
      return value == null
          ? const RagSettings()
          : RagSettings.fromJson(
              (jsonDecode(value) as Map).cast<String, dynamic>(),
            );
    } catch (_) {
      return const RagSettings();
    }
  }

  Future<void> update(RagSettings value) {
    state = value;
    final raw = jsonEncode(value.toJson());
    final next = _writes
        .catchError((Object _) {})
        .then(
          (_) =>
              ref.read(localStorageServiceProvider).setSetting(storageKey, raw),
        );
    _writes = next;
    return next;
  }
}
