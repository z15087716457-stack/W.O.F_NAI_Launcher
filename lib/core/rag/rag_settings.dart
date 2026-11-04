import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';
import 'rag_platform.dart';

enum RagContextMode { before, around }

enum RagDevice { auto, cpu, cuda }

enum RagSource { tags, wiki, blocks, gallery }

class RagSettings {
  const RagSettings({
    this.enabled = false,
    this.tagsEnabled = true,
    this.wikiEnabled = false,
    this.blocksEnabled = false,
    this.galleryEnabled = false,
    this.embedding = '',
    this.reranker = '',
    this.python = '',
    this.mode = RagContextMode.around,
    this.device = RagDevice.auto,
  });
  final bool enabled, tagsEnabled, wikiEnabled, blocksEnabled, galleryEnabled;
  bool enabledFor(RagSource source) =>
      enabled &&
      switch (source) {
        RagSource.tags => tagsEnabled,
        RagSource.wiki => wikiEnabled,
        RagSource.blocks => blocksEnabled,
        RagSource.gallery => galleryEnabled,
      };
  final String embedding, reranker, python;
  final RagContextMode mode;
  final RagDevice device;

  /// Macs with more memory than this run "auto" on the GPU (MPS), so 18 GB
  /// and up; the cut sits between the two sizes Apple sells. The GPU path
  /// peaks at about 1.5 times the memory of the CPU path.
  static const macGpuMemory = 17 << 30;

  /// The device sent to the worker. Windows sends the choice as it is. On a
  /// Mac "auto" means the GPU only with more than [macGpuMemory]; with 16 GB
  /// or less, or when [memoryBytes] is unknown, it means the CPU. A Mac has
  /// no CUDA, so a saved "cuda" counts as auto there.
  RagDevice deviceOn(RagPlatform platform, {int? memoryBytes}) {
    if (!platform.isMacOS) {
      return device == RagDevice.cuda && !platform.supportsCuda
          ? RagDevice.auto
          : device;
    }
    if (device == RagDevice.cpu) return RagDevice.cpu;
    return (memoryBytes ?? 0) > macGpuMemory ? RagDevice.auto : RagDevice.cpu;
  }

  static const tokenBudget = 120;
  Map<String, Object> toJson() => {
    'version': 1,
    'enabled': enabled,
    'tagsEnabled': tagsEnabled,
    'wikiEnabled': wikiEnabled,
    'blocksEnabled': blocksEnabled,
    'galleryEnabled': galleryEnabled,
    'embedding': embedding,
    'reranker': reranker,
    'python': python,
    'mode': mode.name,
    'device': device.name,
  };
  factory RagSettings.fromJson(Map<String, dynamic> json) => RagSettings(
    enabled: json['version'] == 1 && json['enabled'] == true,
    tagsEnabled: json['tagsEnabled'] != false,
    wikiEnabled: json['wikiEnabled'] == true,
    blocksEnabled: json['blocksEnabled'] == true,
    galleryEnabled: json['galleryEnabled'] == true,
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
    bool? wikiEnabled,
    bool? blocksEnabled,
    bool? galleryEnabled,
    String? embedding,
    String? reranker,
    String? python,
    RagContextMode? mode,
    RagDevice? device,
  }) => RagSettings(
    enabled: enabled ?? this.enabled,
    tagsEnabled: tagsEnabled ?? this.tagsEnabled,
    wikiEnabled: wikiEnabled ?? this.wikiEnabled,
    blocksEnabled: blocksEnabled ?? this.blocksEnabled,
    galleryEnabled: galleryEnabled ?? this.galleryEnabled,
    embedding: embedding ?? this.embedding,
    reranker: reranker ?? this.reranker,
    python: python ?? this.python,
    mode: mode ?? this.mode,
    device: device ?? this.device,
  );
  String get connectionKey => jsonEncode([
    enabled,
    tagsEnabled,
    wikiEnabled,
    blocksEnabled,
    galleryEnabled,
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
