/// Non-secret, exact single-turn input/output retained only for this app session.
class TranslationExchange {
  const TranslationExchange({
    required this.system,
    required this.request,
    required this.raw,
    required this.providerId,
    required this.modelId,
  });
  final String system, request, raw, providerId, modelId;
}

class TranslationContext {
  TranslationContext(this.exchanges, this.blocks);
  final List<TranslationExchange> exchanges;
  final List<Map<String, dynamic>> blocks;
  TranslationExchange get route => exchanges.last;
  List<Map<String, dynamic>> get seedMessages => [
    for (final exchange in exchanges) ...[
      {'role': 'user', 'content': exchange.request},
      {'role': 'assistant', 'content': exchange.raw},
    ],
  ];
}
