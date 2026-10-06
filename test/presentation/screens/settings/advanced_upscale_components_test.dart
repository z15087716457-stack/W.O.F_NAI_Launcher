import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/advanced_upscale_components.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Install extends AdvancedUpscaleInstall {
  final installs = <String>[];
  final deletes = <String>[];
  @override
  AdvancedUpscaleInstallState build() => const AdvancedUpscaleInstallState();
  @override
  Future<void> install(String id) async {
    installs.add(id);
    state = AdvancedUpscaleInstallState(
      id: id,
      phase: 'weights',
      fraction: .42,
    );
  }

  @override
  Future<void> delete(String id) async => deletes.add(id);
  @override
  void cancel() => state = const AdvancedUpscaleInstallState();
}

List<LocalUpscaleModel> _models({bool seven = false}) => [
  for (final model in advancedUpscaleCatalog)
    model.withInstalled(
      model.id != 'seedvr2-7b' || seven,
      diskBytes: model.id == 'rtx-vsr' ? 18 * 1024 * 1024 : 3234 * 1024 * 1024,
    ),
];

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['CAPTURE_UI_FEEDBACK'] != '1') return;
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/ui-feedback-20261006/captures/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  GlobalKey boundary, {
  Locale locale = const Locale('zh'),
  bool dark = false,
  double scale = 1.1,
}) => tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: settingsUiTheme(dark ? GeistTheme.dark : GeistTheme.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: boundary,
          child: ColoredBox(
            color:
                (dark ? GeistTheme.dark : GeistTheme.light).colorScheme.surface,
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: AdvancedUpscaleComponents(blocked: false),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 560.0]) {
        final id =
            '${locale.toString()}-${dark ? 'dark' : 'light'}-${width.toInt()}';
        testWidgets(
          'SeedVR2 family switch preserves independent model actions $id',
          (tester) async {
            tester.view.physicalSize = Size(width, 750);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final install = _Install();
            final container = ProviderContainer(
              overrides: [
                localUpscaleModelsProvider.overrideWith((_) async => _models()),
                advancedUpscaleInstallProvider.overrideWith(() => install),
              ],
            );
            addTearDown(container.dispose);
            final boundary = GlobalKey();
            await _pump(
              tester,
              container,
              boundary,
              locale: locale,
              dark: dark,
            );
            await tester.pumpAndSettle();
            final dropdown = find.byKey(
              const ValueKey('seedvr2-management-model'),
            );
            final l = AppLocalizations.of(tester.element(dropdown))!;
            expect(
              find.byKey(const ValueKey('seedvr2-family-card')),
              findsOneWidget,
            );
            expect(find.text(l.localUpscale_seedvr2SharedHelp), findsOneWidget);
            expect(
              find.byKey(
                const ValueKey('upscale-management-delete-seedvr2-3b'),
              ),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('upscale-management-delete-rtx-vsr')),
              findsOneWidget,
            );
            await _capture(tester, boundary, '$id-3b');
            await tester.tap(dropdown);
            await tester.pumpAndSettle();
            await tester.tap(
              find.text('7B FP8 · ${l.localUpscale_notInstalledShort}').last,
            );
            await tester.pumpAndSettle();
            expect(
              find.text(l.localUpscale_seedvr2SevenSummary),
              findsOneWidget,
            );
            expect(
              find.byKey(
                const ValueKey('upscale-management-delete-seedvr2-3b'),
              ),
              findsNothing,
            );
            expect(
              find.byKey(
                const ValueKey('upscale-management-install-seedvr2-7b'),
              ),
              findsOneWidget,
            );
            expect(install.installs, isEmpty);
            expect(install.deletes, isEmpty);
            await _capture(tester, boundary, '$id-7b');
            expect(tester.takeException(), isNull);
          },
          variant: TargetPlatformVariant.only(TargetPlatform.windows),
        );
      }
    }
  }

  testWidgets(
    'Selected model install locks selection, exposes cancellation and refreshes its action',
    (tester) async {
      final install = _Install();
      var items = _models();
      final container = ProviderContainer(
        overrides: [
          localUpscaleModelsProvider.overrideWith((_) async => items),
          advancedUpscaleInstallProvider.overrideWith(() => install),
        ],
      );
      addTearDown(container.dispose);
      final boundary = GlobalKey();
      await _pump(tester, container, boundary, scale: 2);
      await tester.pumpAndSettle();
      final dropdown = find.byKey(const ValueKey('seedvr2-management-model'));
      final l = AppLocalizations.of(tester.element(dropdown))!;
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('7B FP8 · ${l.localUpscale_notInstalledShort}').last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('upscale-management-install-seedvr2-7b')),
      );
      await tester.pumpAndSettle();
      expect(install.installs, ['seedvr2-7b']);
      expect(
        tester.widget<DropdownButtonFormField<String>>(dropdown).onChanged,
        isNull,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .42,
      );
      await tester.tap(find.text(l.common_cancel));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(dropdown).onChanged,
        isNotNull,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      items = _models(seven: true);
      container.invalidate(localUpscaleModelsProvider);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('upscale-management-install-seedvr2-7b')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('upscale-management-delete-seedvr2-7b')),
      );
      await tester.pumpAndSettle();
      expect(install.deletes, ['seedvr2-7b']);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3B FP8 · ${l.localUpscale_installed}').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('upscale-management-delete-seedvr2-3b')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
