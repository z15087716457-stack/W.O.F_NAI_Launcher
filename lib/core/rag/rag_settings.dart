import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';

enum RagContextMode { before, around }

enum RagDevice { auto, cpu, cuda }

class RagSettings {
  const RagSettings({
    this.enabled = false,
    this.tagsEnabled = true,
    this.embedding = '',
    this.reranker = '',
    this.python = '',
    this.mode = RagContextMode.around,
    this.device = RagDevice.auto,
  });
  final bool enabled, tagsEnabled;
  final String embedding, reranker, python;
  final RagContextMode mode;
  final RagDevice device;
  static const tokenBudget = 120;
  Map<String, Object> toJson() => {
    'version': 1,
    'enabled': enabled,
    'tagsEnabled': tagsEnabled,
    'embedding': embedding,
    'reranker': reranker,
    'python': python,
    'mode': mode.name,
    'device': device.name,
  };
  factory RagSettings.fromJson(Map<String, dynamic> json) => RagSettings(
    enabled: json['version'] == 1 && json['enabled'] == true,
    tagsEnabled: json['tagsEnabled'] != false,
    embedding: json['embedding'] is String ? json['embedding'] : '',
    reranker: json['reranker'] is String ? json['reranker'] : '',
    python: json['python'] is String ? json['python'] : '',
    mode:
        RagContextMode.values
            .where((e) => e.name == json['mode'])
            .firstOrNull ??
        RagContextMode.around,
    device:
        RagDevice.values.where((e) => e.name == json['device']).firstOrNull ??
        RagDevice.auto,
  );
  RagSettings copyWith({
    bool? enabled,
    bool? tagsEnabled,
    String? embedding,
    String? reranker,
    String? python,
    RagContextMode? mode,
    RagDevice? device,
  }) => RagSettings(
    enabled: enabled ?? this.enabled,
    tagsEnabled: tagsEnabled ?? this.tagsEnabled,
    embedding: embedding ?? this.embedding,
    reranker: reranker ?? this.reranker,
    python: python ?? this.python,
    mode: mode ?? this.mode,
    device: device ?? this.device,
  );
  String get connectionKey => jsonEncode([
    enabled,
    tagsEnabled,
    embedding,
    reranker,
    python,
    device.name,
  ]);
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
