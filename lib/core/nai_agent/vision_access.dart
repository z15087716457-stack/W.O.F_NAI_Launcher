import '../utils/localization_extension.dart';

/// Request-scoped explanation of unavailable model image input.
/// A null provider name means an older/synthetic client supplied no model context.
class NaiAgentVisionAccess {
  const NaiAgentVisionAccess({this.providerName});
  final String? providerName;

  String get unavailableMessage {
    final l = currentL10n;
    final provider = providerName?.trim();
    final name = provider == null || provider.isEmpty
        ? l.naiAgent_visionCurrentProvider
        : provider;
    return l.naiAgent_visionModelUnsupported(name);
  }

  String skippedAttachmentsNotice(int count) =>
      currentL10n.naiAgent_visionAttachmentsSkipped(count, unavailableMessage);
}
