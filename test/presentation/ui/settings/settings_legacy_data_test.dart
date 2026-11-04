import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import 'settings_test_harness.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('zh'));
  const app = 'Aaalice NAI Launcher';
  final copied = DateTime(2026, 10, 23, 14, 5);
  final synced = DateTime(2026, 10, 29, 14, 5);

  SettingsViewData data(SettingsLegacyData? legacy) {
    final fixture = SettingsFixture.view(page: SettingsPageId.backup);
    return fixture.copyWith(
      backup: SettingsBackupData(
        lastImportAt: fixture.backup.lastImportAt,
        backups: fixture.backup.backups,
        shortcutsCustomized: fixture.backup.shortcutsCustomized,
        legacy: legacy,
      ),
    );
  }

  testWidgets('the section sits on top and says where the data came from', (
    tester,
  ) async {
    final rec = await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(SettingsLegacyData(appName: app, copiedAt: copied)),
    );

    expect(find.byKey(const Key('legacy-data')), findsOneWidget);
    expect(find.text(l.set_bkLegacy), findsOneWidget);
    expect(find.text(l.set_bkLegacySub(app)), findsOneWidget);
    expect(find.text(l.set_bkLegacySyncCopied('10-23 14:05')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l.set_bkLegacy)).dy,
      lessThan(tester.getTopLeft(find.text(l.set_bkPrefs)).dy),
    );

    // Nothing to switch back to before the first sync.
    expect(find.text(l.set_bkLegacyUndo), findsOneWidget);
    expect(find.text(l.set_bkLegacyNoSync), findsOneWidget);
    await tester.tap(find.byKey(const Key('legacy-undo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-confirm')), findsNothing);
    expect(rec.has('legacyUndo'), isFalse);
  });

  testWidgets('sync asks first and warns while the old app is open', (
    tester,
  ) async {
    final rec = await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(
        SettingsLegacyData(appName: app, copiedAt: copied, running: true),
      ),
    );

    await tester.tap(find.byKey(const Key('legacy-sync')));
    await tester.pumpAndSettle();
    expect(find.text(l.set_bkLegacySyncTitle), findsOneWidget);
    expect(find.textContaining(l.set_bkLegacySyncRunning(app)), findsOneWidget);
    expect(rec.has('legacySync'), isFalse);

    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(rec.calls, contains('legacySync'));
  });

  testWidgets('undo is offered right after a sync', (tester) async {
    final rec = await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(
        SettingsLegacyData(
          appName: app,
          syncedAt: synced,
          switchBack: SettingsLegacySwitch(
            kind: SettingsLegacySwitchKind.undo,
            backup: 'backup-1',
            at: synced,
          ),
        ),
      ),
    );

    expect(find.text(l.set_bkLegacySyncSynced('10-29 14:05')), findsOneWidget);
    expect(find.text(l.set_bkLegacyUndoSub('10-29 14:05')), findsOneWidget);
    await tester.tap(find.byKey(const Key('legacy-undo')));
    await tester.pumpAndSettle();
    expect(find.text(l.set_bkLegacyUndoTitle), findsOneWidget);
    expect(find.text(l.set_bkLegacyUndoBody('10-29 14:05')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(rec.calls, contains('legacyUndo:backup-1'));
  });

  testWidgets('after an undo the row switches back to the synced data', (
    tester,
  ) async {
    // Same place and button as the undo; only the words change.
    await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(
        SettingsLegacyData(
          appName: app,
          copiedAt: copied,
          switchBack: SettingsLegacySwitch(
            kind: SettingsLegacySwitchKind.undo,
            backup: 'backup-1',
            at: synced,
          ),
        ),
      ),
    );
    final undoButton = tester.getRect(find.byKey(const Key('legacy-undo')));
    // The page keeps the data it was built with; start it afresh.
    await tester.pumpWidget(const SizedBox.shrink());

    final undone = DateTime(2026, 10, 29, 15, 30);
    final rec = await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(
        SettingsLegacyData(
          appName: app,
          copiedAt: copied,
          switchBack: SettingsLegacySwitch(
            kind: SettingsLegacySwitchKind.redo,
            backup: 'backup-2',
            at: undone,
          ),
        ),
      ),
    );

    expect(find.text(l.set_bkLegacyRedo), findsOneWidget);
    expect(find.text(l.set_bkLegacyUndo), findsNothing);
    expect(find.text(l.set_bkLegacyRedoSub('10-29 15:30')), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('legacy-undo'))), undoButton);

    await tester.tap(find.byKey(const Key('legacy-undo')));
    await tester.pumpAndSettle();
    expect(find.text(l.set_bkLegacyRedoTitle), findsOneWidget);
    expect(find.text(l.set_bkLegacyRedoBody('10-29 15:30')), findsOneWidget);
    expect(find.text(l.set_bkLegacyRedoConfirm), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(rec.calls, contains('legacyRedo:backup-2'));
    expect(rec.has('legacyUndo'), isFalse);
  });

  testWidgets('after switching back the sync can be undone again', (
    tester,
  ) async {
    final switched = DateTime(2026, 10, 29, 16);
    final rec = await pumpSettings(
      tester,
      page: SettingsPageId.backup,
      data: data(
        SettingsLegacyData(
          appName: app,
          syncedAt: synced,
          switchBack: SettingsLegacySwitch(
            kind: SettingsLegacySwitchKind.undoAgain,
            backup: 'backup-3',
            at: switched,
          ),
        ),
      ),
    );

    expect(find.text(l.set_bkLegacyUndo), findsOneWidget);
    expect(
      find.text(l.set_bkLegacyUndoAgainSub('10-29 16:00')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('legacy-undo')));
    await tester.pumpAndSettle();
    expect(find.text(l.set_bkLegacyUndoTitle), findsOneWidget);
    expect(
      find.text(l.set_bkLegacyUndoAgainBody('10-29 16:00')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pumpAndSettle();
    expect(rec.calls, contains('legacyUndo:backup-3'));
    expect(rec.has('legacyRedo'), isFalse);
  });

  testWidgets('no section without previous data, on Windows or in a sandbox', (
    tester,
  ) async {
    await pumpSettings(tester, page: SettingsPageId.backup, data: data(null));

    expect(find.byKey(const Key('legacy-data')), findsNothing);
    expect(find.text(l.set_bkPrefs), findsOneWidget);
  });
}
