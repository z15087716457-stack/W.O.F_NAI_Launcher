import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_legacy_data_import.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/l10n/app_localizations_en.dart';
import 'package:nai_launcher/presentation/screens/splash/legacy_data_import_gate.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<void> pumpView(
    WidgetTester tester,
    LegacyDataImportView view, {
    Locale locale = const Locale('en'),
    Size size = const Size(800, 600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The background field and busy dots stand still, so the page settles.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      LegacyDataImportApp(
        appName: 'Aaalice NAI Launcher',
        view: ValueNotifier(view),
        locale: locale,
        themeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  final en = AppLocalizationsEn();

  test('the window opens once and then follows the import', () {
    final shown = <Widget>[];
    final gate = LegacyDataImportGate(appName: 'Old app', show: shown.add)
      ..showLegacyRunning(MacLegacyDataTask.import, onSkip: () {})
      ..showCopying(MacLegacyDataTask.import)
      ..showStarting();
    expect(shown, hasLength(1));
    final app = shown.single as LegacyDataImportApp;
    expect(app.appName, 'Old app');
    expect(app.view.value.step, LegacyDataImportStep.starting);
    expect(gate.appName, 'Old app');
  });

  testWidgets('waiting for the old app offers to start without copying', (
    tester,
  ) async {
    var skipped = 0;
    await pumpView(
      tester,
      LegacyDataImportView(
        LegacyDataImportStep.waiting,
        onSkip: () => skipped++,
      ),
    );

    expect(
      find.text(en.legacyImport_runningTitle('Aaalice NAI Launcher')),
      findsOneWidget,
    );
    expect(
      find.text(en.legacyImport_waiting('Aaalice NAI Launcher')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('legacy_import_retry')), findsNothing);
    await tester.tap(find.byKey(const Key('legacy_import_skip')));
    expect(skipped, 1);
  });

  testWidgets('a failed copy names the reason and offers both ways on', (
    tester,
  ) async {
    var retried = 0;
    var skipped = 0;
    await pumpView(
      tester,
      LegacyDataImportView(
        LegacyDataImportStep.failed,
        error: const FileSystemException(
          'Application data copy verification failed',
          '/synthetic/hive/settings.hive',
          OSError('No space left on device', 28),
        ),
        onRetry: () => retried++,
        onSkip: () => skipped++,
      ),
    );

    expect(
      find.text(en.legacyImport_failedTitle('Aaalice NAI Launcher')),
      findsOneWidget,
    );
    expect(find.text('No space left on device'), findsOneWidget);
    await tester.tap(find.byKey(const Key('legacy_import_retry')));
    await tester.tap(find.byKey(const Key('legacy_import_skip')));
    expect((retried, skipped), (1, 1));
  });

  testWidgets('copying has no buttons to press', (tester) async {
    await pumpView(
      tester,
      const LegacyDataImportView(LegacyDataImportStep.copying),
    );

    expect(
      find.text(en.legacyImport_copyingTitle('Aaalice NAI Launcher')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('legacy_import_skip')), findsNothing);
    expect(find.byKey(const Key('legacy_import_retry')), findsNothing);
  });

  testWidgets('every step fits the first window in every language', (
    tester,
  ) async {
    final views = [
      for (final task in MacLegacyDataTask.values) ...[
        LegacyDataImportView(LegacyDataImportStep.copying, task: task),
        LegacyDataImportView(
          LegacyDataImportStep.waiting,
          task: task,
          onSkip: () {},
        ),
        LegacyDataImportView(
          LegacyDataImportStep.failed,
          task: task,
          error: const FileSystemException('Synthetic failure'),
          onRetry: () {},
          onSkip: () {},
        ),
        LegacyDataImportView(LegacyDataImportStep.starting, task: task),
      ],
    ];
    for (final locale in AppLocalizations.supportedLocales) {
      for (final view in views) {
        await pumpView(tester, view, locale: locale);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale ${view.task} ${view.step}',
        );
        final card = tester.getRect(
          find.byKey(const Key('legacy_import_card')),
        );
        expect(card.bottom, lessThanOrEqualTo(600), reason: '$locale');
      }
    }
  });

  testWidgets('a sync, undo or redo from Settings says so', (tester) async {
    var skipped = 0;
    await pumpView(
      tester,
      LegacyDataImportView(
        LegacyDataImportStep.failed,
        task: MacLegacyDataTask.sync,
        error: const FileSystemException('Synthetic failure'),
        onRetry: () {},
        onSkip: () => skipped++,
      ),
    );
    expect(
      find.text(en.legacySync_failedTitle('Aaalice NAI Launcher')),
      findsOneWidget,
    );
    expect(find.text(en.legacySync_failedBody), findsOneWidget);
    await tester.tap(find.text(en.legacySync_startWithout));
    expect(skipped, 1);

    await pumpView(
      tester,
      LegacyDataImportView(
        LegacyDataImportStep.waiting,
        task: MacLegacyDataTask.sync,
        onSkip: () {},
      ),
    );
    expect(find.text(en.legacySync_runningBody), findsOneWidget);

    await pumpView(
      tester,
      const LegacyDataImportView(
        LegacyDataImportStep.copying,
        task: MacLegacyDataTask.undo,
      ),
    );
    expect(find.text(en.legacyUndo_title), findsOneWidget);

    await pumpView(
      tester,
      const LegacyDataImportView(
        LegacyDataImportStep.copying,
        task: MacLegacyDataTask.redo,
      ),
    );
    expect(find.text(en.legacyRedo_title), findsOneWidget);
    expect(find.text(en.legacyRedo_body), findsOneWidget);

    await pumpView(
      tester,
      LegacyDataImportView(
        LegacyDataImportStep.failed,
        task: MacLegacyDataTask.redo,
        error: const FileSystemException('Synthetic failure'),
        onRetry: () {},
        onSkip: () => skipped++,
      ),
    );
    expect(find.text(en.legacyRedo_failedTitle), findsOneWidget);
    expect(find.text(en.legacyUndo_failedBody), findsOneWidget);
    await tester.tap(find.text(en.legacyRedo_startWithout));
    expect(skipped, 2);
  });

  test('the window keeps the task while the app takes over', () {
    final shown = <Widget>[];
    LegacyDataImportGate(appName: 'Old app', show: shown.add)
      ..showCopying(MacLegacyDataTask.sync)
      ..showStarting();
    final view = (shown.single as LegacyDataImportApp).view.value;
    expect(view.step, LegacyDataImportStep.starting);
    expect(view.task, MacLegacyDataTask.sync);
  });

  test('errors show the system reason first', () {
    expect(
      describeImportError(
        const FileSystemException(
          'Copy failed',
          '/a/b',
          OSError('Permission denied', 13),
        ),
      ),
      'Permission denied',
    );
    expect(
      describeImportError(const FileSystemException('Copy failed', '/a/b')),
      'Copy failed: /a/b',
    );
    expect(
      describeImportError(const FileSystemException('Copy failed')),
      'Copy failed',
    );
    expect(describeImportError(StateError('x')), 'Bad state: x');
  });
}
