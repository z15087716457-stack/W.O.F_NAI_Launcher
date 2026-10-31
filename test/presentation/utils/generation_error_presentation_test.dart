import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations_en.dart';
import 'package:nai_launcher/l10n/app_localizations_zh.dart';
import 'package:nai_launcher/presentation/utils/generation_error_presentation.dart';

void main() {
  for (final l in [AppLocalizationsZh(), AppLocalizationsEn()]) {
    test(
      'HTTP codes and actual server reasons stay visible: ${l.localeName}',
      () {
        for (final code in [
          '400',
          '401',
          '402',
          '429',
          '500',
          '503',
          'HTTP_504',
        ]) {
          final (title, hint) = generationErrorPresentation(
            'API_ERROR_$code|server reason | extra detail',
            l,
          );
          expect(title, contains(code.replaceFirst('HTTP_', '')));
          expect(hint, contains('server reason | extra detail'));
        }
      },
    );
    test('network hints and cancellation stay localized: ${l.localeName}', () {
      final (title, hint) = generationErrorPresentation(
        'API_ERROR_NETWORK|connection refused',
        l,
      );
      expect(title, l.api_error_network);
      expect(hint, contains(l.api_error_network_hint));
      expect(hint, contains('connection refused'));
      expect(generationErrorPresentation('Cancelled', l), (
        l.generation_cancelGeneration,
        null,
      ));
      expect(generationErrorPresentation(null, l), (
        l.generation_generationFailed,
        null,
      ));
      expect(generationErrorPresentation('plain failure', l), (
        l.generation_generationFailed,
        'plain failure',
      ));
    });
  }
}
