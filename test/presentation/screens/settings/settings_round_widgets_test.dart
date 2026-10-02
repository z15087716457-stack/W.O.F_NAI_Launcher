import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_storage.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_configuration_card.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/provider_picker.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_number_dialog.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/shortcut_settings_panel.dart';
import '../../../helpers/studio_capture_fonts.dart';

class MemoryShortcuts extends ShortcutStorage {
  MemoryShortcuts()
    : super.forTesting(readConfig: () async => null, writeConfig: (_) async {});
  @override
  Future<void> init() async {}
}

void main() {
  final capture = GlobalKey();
  final captures = Platform.environment['CAPTURE_SETTINGS_ROUND'] == '1';
  final dark = Platform.environment['STUDIO_APPEARANCE'] == 'dark';
  setUpAll(() async {
    if (!captures) return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    Size size = const Size(960, 820),
    double scale = 1.1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shortcutStorageProvider.overrideWithValue(MemoryShortcuts()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: settingsUiTheme(
            AppTheme.getTheme(
              AppStyle.geist,
              dark ? Brightness.dark : Brightness.light,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: capture, child: child!),
          ),
          home: Scaffold(body: body),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!captures) return;
    debugDisableShadows = false;
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('.dart_tool/settings-round-captures')
        ..createSync(recursive: true);
      File(
        '${folder.path}/$name-${dark ? 'dark' : 'light'}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    debugDisableShadows = true;
  }

  testWidgets('Anlas help wraps and invalid values cannot close the dialog', (
    tester,
  ) async {
    int? saved;
    const description = '当单次生成预计消耗达到或超过该阈值时，生成前会要求确认。';
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => saved = await showDialog<int>(
            context: context,
            builder: (_) => const SettingsNumberDialog(
              title: '设置 Anlas 警告阈值',
              label: '阈值',
              suffix: 'Anlas',
              value: 50,
              description: description,
            ),
          ),
          child: const Text('打开'),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    final help = tester.widget<Text>(find.text(description));
    expect(help.maxLines, isNull);
    expect(help.overflow, isNot(TextOverflow.ellipsis));
    await snap(tester, 'anlas');
    await tester.enterText(
      find.byKey(const Key('settings-positive-number')),
      '-1',
    );
    await tester.tap(find.byKey(const Key('settings-save-number')));
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的整数'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(
      find.byKey(const Key('settings-positive-number')),
      '60',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(saved, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vendor picker filters vendors without protocol duplication', (
    tester,
  ) async {
    ProviderPreset? selected;
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => selected = await showProviderPicker(
            context,
            ProviderPreset.deepseek,
          ),
          child: const Text('打开'),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await snap(tester, 'providers');
    await tester.enterText(find.byKey(const Key('provider-search')), 'OpenAI');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('OpenAI Responses'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('choose-provider-openaiResponses')),
    );
    await tester.pumpAndSettle();
    expect(selected, ProviderPreset.openaiResponses);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard panel keeps rounded clipping and working search and preferences',
    (tester) async {
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ShortcutSettingsPanel.show(context),
            child: const Text('打开'),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Dialog>(find.byType(Dialog)).clipBehavior,
        Clip.antiAlias,
      );
      await snap(tester, 'shortcuts');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShortcutSettingsPanel)),
      );
      final before = container
          .read(shortcutConfigNotifierProvider)
          .requireValue
          .showInMenus;
      await tester.tap(find.byType(FilterChip).last);
      await tester.pumpAndSettle();
      expect(
        container.read(shortcutConfigNotifierProvider).requireValue.showInMenus,
        !before,
      );
      await tester.enterText(find.byType(TextField), '生成页面');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);
      await tester.enterText(find.byType(TextField), '无法匹配的快捷键');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ShortcutSettingsPanel), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'model numbers validate and clearing keeps unknown capabilities',
    (tester) async {
      var value = const ModelConfig(
        providerId: 'test',
        name: 'custom',
        displayName: 'Custom',
        maxOutputTokens: 8192,
      );
      String? error;
      await pump(
        tester,
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ModelConfigurationCard(
              value: value,
              protocol: ProviderProtocol.openaiChatCompletions,
              onChanged: (next) => value = next,
              onValidationChanged: (next) => error = next,
            ),
          ),
        ),
        size: const Size(360, 780),
        scale: 1.5,
      );
      await tester.enterText(find.byKey(const Key('context-custom')), 'bad');
      await tester.pumpAndSettle();
      expect(error, isNotNull);
      await tester.enterText(find.byKey(const Key('context-custom')), '128000');
      await tester.pumpAndSettle();
      expect(error, isNull);
      expect(value.contextWindow, 128000);
      await tester.enterText(find.byKey(const Key('parameter-max-tokens')), '');
      await tester.pumpAndSettle();
      expect(value.maxOutputTokens, isNull);
      expect(value.supportsTools, isNull);
      await snap(tester, 'model-narrow');
      expect(tester.takeException(), isNull);
    },
  );
}
