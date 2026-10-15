import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/panel_layout.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  test('sidebar budget reserves history and canvas across window widths', () {
    for (final available in [728.0, 752.0, 1000.0, 1448.0, 2560.0]) {
      for (final preferred in [320.0, 520.0, 900.0, 1280.0]) {
        final width = AgentPanelLayout.resolve(preferred, available);
        expect(width, greaterThanOrEqualTo(320));
        expect(width, lessThanOrEqualTo(1280));
        expect(
          available - width - AgentPanelLayout.handle,
          greaterThanOrEqualTo(AgentPanelLayout.minimumPage),
        );
      }
    }
  });
  test(
    'legacy narrow panes migrate once; explicit new sizes survive reload',
    () {
      final legacy = AgentSettings.fromJson({'panelWidth': 440});
      expect(legacy.panelWidth, 520);
      expect(
        AgentSettings.fromJson({
          ...legacy.toJson(),
          'panelWidth': 340,
        }).panelWidth,
        340,
      );
      expect(AgentSettings.fromJson({'panelWidth': 900}).panelWidth, 900);
      expect(
        AgentSettings.fromJson({'panelWidth': double.nan}).panelWidth,
        520,
      );
      expect(AgentSettings.fromJson({'panelWidth': 3000}).panelWidth, 1280);
    },
  );
}
