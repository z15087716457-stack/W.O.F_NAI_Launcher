import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/integrations_settings_section.dart';

const _comfyUiPanelKey = ValueKey<String>('panel-comfyui');
const _kritaPanelKey = ValueKey<String>('panel-krita');
const _panelKeys = [_comfyUiPanelKey, _kritaPanelKey];

class _PanelProbe extends StatefulWidget {
  const _PanelProbe({
    required super.key,
    required this.label,
    required this.onDispose,
  });

  final String label;
  final VoidCallback onDispose;

  @override
  State<_PanelProbe> createState() => _PanelProbeState();
}

class _PanelProbeState extends State<_PanelProbe> {
  @override
  Widget build(BuildContext context) => Text(widget.label);

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }
}

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    List<String> disposedPanels, {
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IntegrationsSettingsSection(
            panelBuilders: [
              (_) => _PanelProbe(
                key: _comfyUiPanelKey,
                label: 'panel-comfyui',
                onDispose: () => disposedPanels.add('comfyui'),
              ),
              (_) => _PanelProbe(
                key: _kritaPanelKey,
                label: 'panel-krita',
                onDispose: () => disposedPanels.add('krita'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectOnlyPanel(ValueKey<String> expectedKey) {
    for (final panelKey in _panelKeys) {
      expect(
        find.byKey(panelKey, skipOffstage: false),
        panelKey == expectedKey ? findsOneWidget : findsNothing,
      );
    }
  }

  test('测试注入面板数量必须恰好为两项', () {
    Widget buildPanel(BuildContext _) => const SizedBox.shrink();

    for (final invalidLength in [0, 1, 3, 4]) {
      expect(
        () => IntegrationsSettingsSection(
          panelBuilders: List<WidgetBuilder>.filled(invalidLength, buildPanel),
        ),
        throwsAssertionError,
        reason: 'panelBuilders length $invalidLength should be rejected',
      );
    }

    expect(
      () => IntegrationsSettingsSection(
        panelBuilders: List<WidgetBuilder>.filled(2, buildPanel),
      ),
      returnsNormally,
    );
    expect(() => const IntegrationsSettingsSection(), returnsNormally);
  });

  testWidgets('默认显示第一个面板且两段可切换', (tester) async {
    final disposedPanels = <String>[];
    await pumpSection(tester, disposedPanels);

    expect(find.text('模型与接口'), findsNothing);
    expect(find.text('ComfyUI'), findsOneWidget);
    expect(find.text('Krita'), findsOneWidget);
    expectOnlyPanel(_comfyUiPanelKey);
    expect(disposedPanels, isEmpty);

    await tester.tap(find.text('Krita'));
    await tester.pumpAndSettle();
    expectOnlyPanel(_kritaPanelKey);
    expect(disposedPanels, ['comfyui']);
  });

  testWidgets('英文环境切换集成面板时分段导航总宽度保持不变', (tester) async {
    final disposedPanels = <String>[];
    await pumpSection(tester, disposedPanels, locale: const Locale('en'));

    final segmentedButton = find.byType(ManagementTabs);
    final promptAssistantWidth = tester.getSize(segmentedButton).width;

    await tester.tap(find.text('ComfyUI'));
    await tester.pumpAndSettle();
    final comfyUiWidth = tester.getSize(segmentedButton).width;

    await tester.tap(find.text('Krita'));
    await tester.pumpAndSettle();
    final kritaWidth = tester.getSize(segmentedButton).width;

    expect(
      [promptAssistantWidth, comfyUiWidth, kritaWidth],
      everyElement(promptAssistantWidth),
      reason:
          'Prompt Assistant=$promptAssistantWidth, '
          'ComfyUI=$comfyUiWidth, Krita=$kritaWidth',
    );
  });

  const expectedLabels = <String, List<String>>{
    'en': ['ComfyUI', 'Krita'],
    'zh': ['ComfyUI', 'Krita'],
    'ja': ['ComfyUI', 'Krita'],
  };

  for (final entry in expectedLabels.entries) {
    testWidgets('分段导航按 ${entry.key} 显示精确文案', (tester) async {
      await pumpSection(tester, <String>[], locale: Locale(entry.key));

      final segmentedButton = tester.widget<ManagementTabs>(
        find.byType(ManagementTabs),
      );
      final labels = segmentedButton.labels;

      expect(labels, entry.value, reason: 'locale=${entry.key}');
    });
  }
}
