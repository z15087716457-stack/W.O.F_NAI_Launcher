import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/workspace_text_settings_provider.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_prompt.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/atom_chip.dart';
import 'package:nai_launcher/presentation/widgets/common/workspace_text_scale_scope.dart';
import 'package:nai_launcher/presentation/widgets/common/workspace_typography_scope.dart';
import '../../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

void main() {
  testWidgets(
    'only creative regions scale and nested/inline scopes never double-scale',
    (tester) async {
      final storage = MemoryStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WorkspaceTextScaleHost(
                child: WorkspaceTypographyScope(
                  child: Column(
                    children: [
                      const Text('navigation'),
                      const WorkspaceTextScaleScope(
                        child: WorkspaceTextScaleScope(child: Text('creative')),
                      ),
                      const UiBlockPill(label: 'block', color: Colors.blue),
                      AtomChip(text: 'atom', theme: ThemeData()),
                      const ViewerPromptBox(spans: [TextSpan(text: 'viewer')]),
                      WorkspaceTextScaleScope(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                child: WorkspaceTextScaleScope.inline(
                                  const UiBlockPill(
                                    label: 'inline',
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      double scaleOf(Finder finder) =>
          MediaQuery.textScalerOf(tester.element(finder)).scale(10) / 10;
      expect(scaleOf(find.text('navigation')), 1);
      final inlineBefore = tester.getSize(find.text('inline'));
      await container
          .read(workspaceFontScaleProvider.notifier)
          .setFontScale(1.5);
      await tester.pump();
      expect(scaleOf(find.text('navigation')), 1);
      expect(scaleOf(find.text('creative')), 1.5);
      expect(scaleOf(find.text('block')), 1.5);
      expect(scaleOf(find.text('atom')), 1.5);
      expect(scaleOf(find.text('viewer', findRichText: true)), 1.5);
      expect(scaleOf(find.text('inline')), 1);
      expect(tester.getSize(find.text('inline')), inlineBefore);
      final inlineRect = tester.getRect(find.text('inline'));
      expect(inlineRect.height, closeTo(inlineBefore.height * 1.5, .001));
      expect(tester.takeException(), isNull);
    },
  );
}
