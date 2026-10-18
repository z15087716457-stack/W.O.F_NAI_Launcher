import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent_generation_host.dart';
import 'package:nai_launcher/presentation/widgets/common/update_capsule.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';

import '../../helpers/studio_capture_fonts.dart';

class _Window extends NaiAgentWindowHost {
  Rect rect = const Rect.fromLTWH(100, 40, 1100, 800);
  final writes = <Rect>[];
  @override
  Future<Rect> bounds() async => rect;
  @override
  Future<bool> locked() async => false;
  @override
  Future<List<Rect>> workAreas() async => [
    const Rect.fromLTWH(0, 0, 2200, 1200),
  ];
  @override
  Future<void> setBounds(Rect value) async {
    rect = value;
    writes.add(value);
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          (call) async => call.method == 'isMaximized' ? false : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  testWidgets(
    'standalone generation adapter never initializes an Agent store',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            naiAgentWorkspaceStoreProvider.overrideWith((ref) {
              throw StateError('Personal storage must not be initialized');
            }),
          ],
          child: const MaterialApp(
            home: NaiAgentGenerationHost(child: Text('generation')),
          ),
        ),
      );
      expect(find.text('generation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'application runtime with a closed Agent preserves generation content',
    (tester) async {
      final preferences = NaiAgentUiPreferences();
      final window = NaiAgentWindowController(
        host: _Window(),
        readSettings: () async => preferences.settings,
        saveExpanded: (expanded) async => preferences.replace(
          AgentSettings.fromJson({
            ...preferences.settings.toJson(),
            'panelExpanded': expanded,
          }),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            naiAgentUiPreferencesProvider.overrideWith((ref) => preferences),
            naiAgentWindowControllerProvider.overrideWith((ref) => window),
          ],
          child: const MaterialApp(
            home: NaiAgentIntegrationScope(
              child: NaiAgentGenerationHost(child: Text('generation')),
            ),
          ),
        ),
      );
      expect(find.text('generation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new caption toggle reuses Agent opening and exact window restoration',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = NaiAgentUiPreferences();
      final host = _Window();
      final original = host.rect;
      final window = NaiAgentWindowController(
        host: host,
        readSettings: () async => preferences.settings,
        saveExpanded: (expanded) async => preferences.replace(
          AgentSettings.fromJson({
            ...preferences.settings.toJson(),
            'panelExpanded': expanded,
          }),
        ),
      );
      double? reserved;
      var updateTaps = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            naiAgentUiPreferencesProvider.overrideWith((ref) => preferences),
            naiAgentWindowControllerProvider.overrideWith((ref) => window),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: IntegratedTitleBarShell(
              deferToRoute: true,
              captionHeight: 61,
              accessoryWidth: UpdateCapsule.width,
              accessory: UpdateCapsule(onPressed: () => updateTaps++),
              child: WindowChromePage(
                showNaiAgent: true,
                child: Builder(
                  builder: (context) {
                    reserved = WindowChromeScope.reservedWidthOf(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        reserved,
        WindowChromeScope.controlsWidth + 28 + UpdateCapsule.width,
      );
      expect(
        tester.getSize(find.byKey(const Key('window-caption-controls'))).height,
        61,
      );
      final toggle = find.byKey(const Key('nai-agent-toggle'));
      expect(toggle, findsOneWidget);
      expect(find.byType(AgentToggleButton), findsOneWidget);
      expect(
        tester
            .widget<AgentToggleButton>(find.byType(AgentToggleButton))
            .expanded,
        false,
      );
      final capsule = find.byKey(const Key('window-update-capsule'));
      expect(
        tester.getRect(capsule).right,
        lessThanOrEqualTo(tester.getRect(toggle).left),
      );
      await tester.tap(capsule);
      expect(updateTaps, 1);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(preferences.settings.panelExpanded, isTrue);
      expect(
        tester
            .widget<AgentToggleButton>(find.byType(AgentToggleButton))
            .expanded,
        true,
      );
      expect(window.docked, isTrue);
      expect(
        host.rect.width,
        original.width + preferences.settings.panelWidth + 8,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(preferences.settings.panelExpanded, isFalse);
      expect(host.rect, original);
      expect(tester.takeException(), isNull);
    },
  );

  for (final hidden in [true, false]) {
    testWidgets(
      'fullscreen disables caption reservation through ${hidden ? 'generation' : 'gallery'} host',
      (tester) async {
        bool? active;
        await tester.pumpWidget(
          MaterialApp(
            home: IntegratedTitleBarShell(
              deferToRoute: true,
              child: WindowChromePage(
                hidden: hidden,
                hideCaptions: !hidden,
                child: Builder(
                  builder: (context) {
                    active = WindowChromeScope.activeOf(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        );
        expect(active, isFalse);
        expect(find.byKey(const Key('window-caption-controls')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
