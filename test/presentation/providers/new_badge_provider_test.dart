import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/new_badge_provider.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_new_badge.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import '../../helpers/studio_capture_fonts.dart';

class _MemoryStorage extends LocalStorageService {
  final settings = <String, Object?>{};
  var writes = 0;

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      settings[key] as T? ?? defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    writes++;
    settings[key] = value;
  }
}

ProviderContainer _launch(_MemoryStorage storage) => ProviderContainer(
  overrides: [localStorageServiceProvider.overrideWithValue(storage)],
);

void main() {
  for (final blocks in [false, true]) {
    testWidgets(
      'existing badge call sites persist only when shown, blocks=$blocks',
      (tester) async {
        await tester.runAsync(loadStudioCaptureFonts);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1600, 1200);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final storage = _MemoryStorage();
        var launch = _launch(storage);
        Widget page() => UncontrolledProviderScope(
          container: launch,
          child: NewBadgeScope(
            child: MaterialApp(
              theme: GeistTheme.light,
              locale: const Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: blocks
                    ? Center(
                        child: BlockEditDialog(
                          data: BlocksFixture.edit(),
                          actions: BlockEditActions(
                            onSave: (_) {},
                            onCancel: () {},
                            onPickThumbnail: () async => null,
                            onCaptureParams: () async => null,
                          ),
                        ),
                      )
                    : GenerationPage(
                        data: GenFixture.view(),
                        actions: GenActions.logging((_) {}),
                        slots: const GenSlots(editor: GenFixtureEditor.builder),
                      ),
              ),
            ),
          ),
        );
        Future<void> open() async {
          final entry = find.byKey(
            Key(blocks ? 'block-edit-params' : 'gen-translate-menu'),
          );
          await tester.ensureVisible(entry);
          await tester.tap(entry);
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(storage.writes, 0);
        await open();
        expect(find.text('新'), findsNWidgets(2));
        expect(
          (storage.settings[NewBadgeService.storageKey] as List).toSet(),
          blocks
              ? {'presets.quality', 'presets.uc'}
              : {'translate.adjust', 'translate.clearRestore'},
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        await open();
        expect(find.text('新'), findsNWidgets(2));
        await tester.pumpWidget(const SizedBox.shrink());
        launch.dispose();
        launch = _launch(storage);
        addTearDown(launch.dispose);
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        await open();
        expect(find.text('新'), findsNothing);
      },
    );
  }
  test(
    'first launch stays new; only actually seen ids disappear on restart',
    () {
      final storage = _MemoryStorage();
      final first = _launch(storage);
      final service = first.read(newBadgeServiceProvider);
      expect(service.showNewBadge('translate.adjust'), true);
      expect(service.showNewBadge('not.rendered'), true);
      expect(storage.writes, 0);
      service.markNewBadgeSeen('translate.adjust');
      service.markNewBadgeSeen('translate.adjust');
      expect(service.showNewBadge('translate.adjust'), true);
      service.markNewBadgeSeen('presets.quality');
      expect(service.showNewBadge('presets.quality'), true);
      expect(storage.writes, 2);
      expect(storage.settings[NewBadgeService.storageKey], [
        'translate.adjust',
        'presets.quality',
      ]);
      first.dispose();

      final second = _launch(storage);
      addTearDown(second.dispose);
      final restarted = second.read(newBadgeServiceProvider);
      expect(restarted.showNewBadge('translate.adjust'), false);
      expect(restarted.showNewBadge('presets.quality'), false);
      expect(restarted.showNewBadge('not.rendered'), true);
      restarted.markNewBadgeSeen('translate.adjust');
      expect(storage.writes, 2);
      restarted.markNewBadgeSeen('presets.uc');
      expect(restarted.showNewBadge('presets.uc'), true);
      final third = _launch(storage);
      addTearDown(third.dispose);
      expect(
        third.read(newBadgeServiceProvider).showNewBadge('presets.uc'),
        false,
      );
      expect(
        third.read(newBadgeServiceProvider).showNewBadge('translate.adjust'),
        false,
      );
    },
  );

  testWidgets('string adapter marks after presentation, reopening stays new', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    final first = _launch(storage);
    addTearDown(first.dispose);
    Widget entry(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: NewBadgeScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => Text(
              uiNewBadge(context, 'translate.adjust', 'NEW') ?? 'hidden',
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(entry(first));
    expect(find.text('NEW'), findsOneWidget);
    expect(storage.writes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(entry(first));
    expect(find.text('NEW'), findsOneWidget);
    expect(storage.writes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    final second = _launch(storage);
    addTearDown(second.dispose);
    await tester.pumpWidget(entry(second));
    expect(find.text('hidden'), findsOneWidget);
    expect(storage.writes, 1);
  });
}
