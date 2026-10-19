import '../utils/localization_extension.dart';

/// Request-scoped explanation of the provider/model image-input gate.
/// A null reason means an older or synthetic client supplied no capability data.
class NaiAgentVisionAccess {
  const NaiAgentVisionAccess({this.blockedByProvider, this.providerName});

  final bool? blockedByProvider;
  final String? providerName;

  String get unavailableMessage {
    final l = currentL10n;
    final provider = providerName?.trim();
    final name = provider == null || provider.isEmpty
        ? l.naiAgent_visionCurrentProvider
        : provider;
    return switch (blockedByProvider) {
      true => l.naiAgent_visionProviderBlocked(name),
      false => l.naiAgent_visionModelUnsupported(name),
      null => l.naiAgent_visionDisabled,
    };
  }

  String skippedAttachmentsNotice(int count) =>
      currentL10n.naiAgent_visionAttachmentsSkipped(count, unavailableMessage);
}
