import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

void main() {
  tearDown(() => setCurrentL10nLocale(const Locale('zh')));

  for (final locale in [
    const Locale('en'),
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    test('vision reasons and attachment count are localized for $locale', () {
      setCurrentL10nLocale(locale);
      final l = currentL10n;
      const provider = NaiAgentVisionAccess(
        blockedByProvider: true,
        providerName: 'Synthetic Provider',
      );
      const model = NaiAgentVisionAccess(
        blockedByProvider: false,
        providerName: 'Synthetic Provider',
      );
      expect(
        provider.unavailableMessage,
        l.naiAgent_visionProviderBlocked('Synthetic Provider'),
      );
      expect(
        model.unavailableMessage,
        l.naiAgent_visionModelUnsupported('Synthetic Provider'),
      );
      expect(provider.unavailableMessage, isNot(model.unavailableMessage));
      expect(
        provider.skippedAttachmentsNotice(3),
        l.naiAgent_visionAttachmentsSkipped(3, provider.unavailableMessage),
      );
      expect(provider.skippedAttachmentsNotice(3), contains('3'));
      expect(
        const NaiAgentVisionAccess(
          blockedByProvider: true,
          providerName: '  ',
        ).unavailableMessage,
        l.naiAgent_visionProviderBlocked(l.naiAgent_visionCurrentProvider),
      );
      expect(
        const NaiAgentVisionAccess().unavailableMessage,
        l.naiAgent_visionDisabled,
      );
    });
  }
}
