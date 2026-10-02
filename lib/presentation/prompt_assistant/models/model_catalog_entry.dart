enum ModelReasoningProtocol { standard, adaptive }

/// Immutable catalog facts. Kept separately from a user's request settings.
class ModelCatalogEntry {
  const ModelCatalogEntry({
    required this.id,
    required this.vendor,
    required this.name,
    this.contextLimit,
    this.outputLimit,
    this.reasoningEfforts,
    this.defaultReasoningEffort,
    this.reasoningFormat,
    this.reasoningProtocol = ModelReasoningProtocol.standard,
    this.supportsVision,
    this.supportsNativeSearch,
    this.supportsTemperature,
    this.updatedAt,
    this.budgetMin,
    this.budgetMax,
    this.canonicalId,
    this.inputLimit,
    this.inputModalities = const [],
    this.outputModalities = const [],
    this.reasoningOptions = const [],
    this.supportsReasoning,
    this.supportsToolCalling,
    this.supportsStructuredOutput,
    this.family,
    this.knowledgeCutoff,
    this.releasedAt,
    this.status,
    this.cost = const {},
  });
  final String id, vendor, name;
  final int? contextLimit, outputLimit;
  final int? budgetMin, budgetMax;
  final List<String>? reasoningEfforts;
  final String? defaultReasoningEffort, reasoningFormat, updatedAt;
  final ModelReasoningProtocol reasoningProtocol;
  final bool? supportsVision, supportsNativeSearch, supportsTemperature;
  final String? canonicalId, family, knowledgeCutoff, releasedAt, status;
  final int? inputLimit;
  final List<String> inputModalities, outputModalities;
  final List<Map<String, dynamic>> reasoningOptions;
  final bool? supportsReasoning, supportsToolCalling, supportsStructuredOutput;
  final Map<String, dynamic> cost;
  bool get supportsPdf => inputModalities.contains('pdf');

  factory ModelCatalogEntry.fromJson(Map<String, dynamic> json) =>
      ModelCatalogEntry(
        id: json['id'] as String,
        vendor: json['vendor'] as String,
        name: json['name'] as String,
        contextLimit: (json['context'] as num?)?.toInt(),
        outputLimit: (json['output'] as num?)?.toInt(),
        reasoningEfforts: json['efforts'] is List
            ? List<String>.unmodifiable(
                (json['efforts'] as List).cast<String>(),
              )
            : null,
        defaultReasoningEffort: json['defaultEffort'] as String?,
        reasoningFormat: json['reasoningFormat'] as String?,
        reasoningProtocol: json['reasoningProtocol'] == 'adaptive'
            ? ModelReasoningProtocol.adaptive
            : ModelReasoningProtocol.standard,
        supportsVision: json['vision'] as bool?,
        supportsNativeSearch: json['nativeSearch'] as bool?,
        supportsTemperature: json['temperature'] as bool?,
        updatedAt: json['updated'] as String?,
        budgetMin: (json['budgetMin'] as num?)?.toInt(),
        budgetMax: (json['budgetMax'] as num?)?.toInt(),
        canonicalId: json['canonicalId'] as String?,
        inputLimit: (json['input'] as num?)?.toInt(),
        inputModalities: List<String>.unmodifiable(
          (json['inputModalities'] as List? ?? const []).cast<String>(),
        ),
        outputModalities: List<String>.unmodifiable(
          (json['outputModalities'] as List? ?? const []).cast<String>(),
        ),
        reasoningOptions: List<Map<String, dynamic>>.unmodifiable([
          for (final option in json['reasoningOptions'] as List? ?? const [])
            Map<String, dynamic>.unmodifiable(
              (option as Map).cast<String, dynamic>(),
            ),
        ]),
        supportsReasoning: json['reasoning'] as bool?,
        supportsToolCalling: json['toolCall'] as bool?,
        supportsStructuredOutput: json['structuredOutput'] as bool?,
        family: json['family'] as String?,
        knowledgeCutoff: json['knowledge'] as String?,
        releasedAt: json['released'] as String?,
        status: json['status'] as String?,
        cost: Map<String, dynamic>.unmodifiable(
          (json['cost'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
      );
}

String modelTokenLabel(int? value) {
  if (value == null) return '—';
  if (value >= 1000000) {
    final label = (value / 1000000).toStringAsFixed(
      value % 1000000 == 0 ? 0 : 2,
    );
    return '${label.contains('.') ? label.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : label}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}
