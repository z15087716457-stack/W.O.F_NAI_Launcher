import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_wiring.dart';

void main() {
  test(
    'new settings card sections resolve the correct page and keep anchor',
    () {
      for (final page in [
        SettingsPageId.generation,
        SettingsPageId.canvas,
        SettingsPageId.dictionaries,
        SettingsPageId.about,
      ]) {
        final uri = Uri(
          path: '/settings',
          queryParameters: {'section': page.name, 'anchor': 'row'},
        );
        expect(settingsPageFromUri(uri), page);
        expect(uri.queryParameters['anchor'], 'row');
      }
    },
  );
}
