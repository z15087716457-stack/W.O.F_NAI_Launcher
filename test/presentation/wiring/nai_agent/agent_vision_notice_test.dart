import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('run image notice is projected alongside extension notices', (
    tester,
  ) async {
    final h = AgentWiringHarness();
    await tester.runAsync(h.init);
    addTearDown(h.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final runtime = h.c.selected!;
    runtime.visionNotice = 'Synthetic image notice';
    runtime.extensionNotices.add('Synthetic extension notice');
    await h.pump(tester);
    expect(
      h.panel(tester).data.notices,
      containsAll(['Synthetic image notice', 'Synthetic extension notice']),
    );
    h.panel(tester).actions.onDismissNotices();
    await tester.pump();
    expect(runtime.visionNotice, isNull);
    expect(runtime.extensionNotices, isEmpty);
    expect(h.panel(tester).data.notices, isEmpty);
  });
}
