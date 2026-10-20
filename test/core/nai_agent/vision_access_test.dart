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
    test(
      'model vision reason and attachment count are localized for $locale',
      () {
        setCurrentL10nLocale(locale);
        final l = currentL10n;
        const model = NaiAgentVisionAccess(providerName: 'Synthetic Provider');
        expect(
          model.unavailableMessage,
          l.naiAgent_visionModelUnsupported('Synthetic Provider'),
        );
        expect(
          model.skippedAttachmentsNotice(3),
          l.naiAgent_visionAttachmentsSkipped(3, model.unavailableMessage),
        );
        expect(model.skippedAttachmentsNotice(3), contains('3'));
        expect(
          const NaiAgentVisionAccess(providerName: '  ').unavailableMessage,
          l.naiAgent_visionModelUnsupported(l.naiAgent_visionCurrentProvider),
        );
        expect(
          const NaiAgentVisionAccess().unavailableMessage,
          l.naiAgent_visionModelUnsupported(l.naiAgent_visionCurrentProvider),
        );
      },
    );
  }
}
