import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/common/prompt_translation_guide.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_menu.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'lightweight menu $locale dark=$dark keeps mode and plain actions',
        (t) async {
          final calls = <String>[];
          final data = GenFixture.view().copyWith(
            prompt: const GenPromptData(
              translate: GenTranslate(
                mode: PromptTranslationMode.inline,
                hasTranslations: true,
                showing: true,
                route: 'Model',
              ),
              tools: GenPromptTools(translatePinned: true),
            ),
          );
          await pumpGen(
            t,
            data: data,
            actions: GenActions.logging(calls.add),
            slots: GenSlots(
              editor: GenFixtureEditor.builder,
              translationGuide: (_, back) =>
                  PromptTranslationGuide(onBack: back),
            ),
            window: 760,
            height: 760,
            locale: locale,
            dark: dark,
          );
          await t.tap(find.byKey(const Key('gen-translate-menu')));
          await t.pumpAndSettle();
          final l = AppLocalizations.of(t.element(find.byType(UiMenu)))!;
          final menu = t.widget<UiMenu>(find.byType(UiMenu));
          expect(menu.items[0].label, l.promptReading_mode);
          expect(menu.items[0].checked, isTrue);
          expect(menu.items[1].label, l.promptReading_blocks);
          expect(menu.items[1].checked, isFalse);
          expect(menu.items[2].label, l.promptReading_automatic);
          expect(menu.items[2].divider, isTrue);
          expect(menu.items[2].checked, isFalse);
          expect(menu.items[2].trailing, l.promptReading_automaticOff);
          expect(menu.items[3].divider, isFalse);
          expect(
            t.getSize(find.byKey(const Key('gen-translate-auto'))).height,
            48,
          );
          expect(
            t.getTopLeft(find.byKey(const Key('gen-translate-auto'))).dx,
            t.getTopLeft(find.byKey(const Key('gen-translate-new'))).dx,
          );
          expect(find.byKey(const Key('gen-translate-adjust')), findsNothing);
          expect(find.text(l.promptReading_update), findsOneWidget);
          expect(find.text(l.promptReading_hide), findsOneWidget);
          expect(find.text(l.promptReading_clear), findsOneWidget);
          await t.tap(find.byKey(const Key('gen-translation-tutorial')));
          await t.pumpAndSettle();
          expect(find.text(l.promptReading_guide), findsOneWidget);
          await t.tap(find.byKey(const Key('translation-guide-back')));
          await t.pumpAndSettle();
          await t.tap(find.text(l.promptReading_blocks));
          await t.pumpAndSettle();
          expect(
            calls,
            contains('onTranslationMode(PromptTranslationMode.blocks)'),
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  for (final mode in PromptTranslationMode.values) {
    for (final automatic in [false, true]) {
      testWidgets(
        'automatic=$automatic in $mode uses an independent menu action',
        (t) async {
          final calls = <String>[];
          await pumpGen(
            t,
            data: GenFixture.view().copyWith(
              prompt: GenPromptData(
                translate: GenTranslate(
                  mode: mode,
                  automatic: automatic,
                  route: 'Model',
                ),
                tools: const GenPromptTools(translatePinned: true),
              ),
            ),
            actions: GenActions.logging(calls.add),
            window: 760,
            height: 760,
            dark: true,
          );
          await t.tap(find.byKey(const Key('gen-translate-menu')));
          await t.pumpAndSettle();
          final item = t.widget<UiMenu>(find.byType(UiMenu)).items[2];
          expect(item.checked, automatic);
          expect(item.enabled, mode == PromptTranslationMode.inline);
          if (mode == PromptTranslationMode.inline) {
            await t.tap(find.byKey(const Key('gen-translate-auto')));
            await t.pumpAndSettle();
            expect(calls, contains('onAutomaticTranslation(${!automatic})'));
          } else {
            await t.tap(find.byKey(const Key('gen-translate-auto')));
            await t.pump();
            expect(
              calls.where((call) => call.startsWith('onAutomaticTranslation')),
              isEmpty,
            );
          }
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('automatic toggle keeps a live menu open dark=$dark', (
      t,
    ) async {
      final automatic = ValueNotifier(false);
      addTearDown(automatic.dispose);
      final calls = <String>[];
      final actions = GenActions.logging((call) {
        calls.add(call);
        if (call == 'onAutomaticTranslation(true)') automatic.value = true;
        if (call == 'onAutomaticTranslation(false)') automatic.value = false;
      });
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(760, 760);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        genApp(
          ValueListenableBuilder<bool>(
            valueListenable: automatic,
            builder: (context, enabled, child) => GenerationPage(
              data: GenFixture.view().copyWith(
                prompt: GenPromptData(
                  translate: GenTranslate(
                    mode: PromptTranslationMode.inline,
                    automatic: enabled,
                    route: 'Model',
                  ),
                  tools: const GenPromptTools(translatePinned: true),
                ),
              ),
              actions: actions,
              slots: const GenSlots(editor: GenFixtureEditor.builder),
            ),
          ),
          dark: dark,
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gen-translate-menu')));
      await t.pumpAndSettle();
      final menu = t.element(find.byType(UiMenu));
      final bounds = t.getRect(find.byType(UiMenu));
      final l = AppLocalizations.of(menu)!;
      for (final enabled in [true, false]) {
        await t.tap(find.byKey(const Key('gen-translate-auto')));
        await t.pumpAndSettle();
        expect(find.byType(UiMenu), findsOneWidget);
        expect(t.element(find.byType(UiMenu)), same(menu));
        expect(t.getRect(find.byType(UiMenu)), bounds);
        final item = t.widget<UiMenu>(find.byType(UiMenu)).items[2];
        expect(item.checked, enabled);
        expect(item.trailing, enabled ? null : l.promptReading_automaticOff);
      }
      expect(calls, [
        'onAutomaticTranslation(true)',
        'onAutomaticTranslation(false)',
      ]);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(UiMenu), findsNothing);
      await t.tap(find.byKey(const Key('gen-translate-menu')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gen-translate-new')));
      await t.pumpAndSettle();
      expect(find.byType(UiMenu), findsNothing);
      expect(calls.last, 'onTranslate');
      await t.tap(find.byKey(const Key('gen-translate-menu')));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(700, 700));
      await t.pumpAndSettle();
      expect(find.byType(UiMenu), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'automatic translation can be turned off while a request is busy',
    (t) async {
      final calls = <String>[];
      await pumpGen(
        t,
        data: GenFixture.view().copyWith(
          prompt: const GenPromptData(
            translate: GenTranslate(
              mode: PromptTranslationMode.inline,
              automatic: true,
              busy: true,
            ),
            tools: GenPromptTools(translatePinned: true),
          ),
        ),
        actions: GenActions.logging(calls.add),
      );
      await t.tap(find.byKey(const Key('gen-translate-menu')));
      await t.pump(const Duration(milliseconds: 200));
      final auto = t.widget<UiMenu>(find.byType(UiMenu)).items[2];
      expect(auto.enabled, isTrue);
      await t.tap(find.byKey(const Key('gen-translate-auto')));
      await t.pump(const Duration(milliseconds: 200));
      expect(calls, contains('onAutomaticTranslation(false)'));
    },
  );

  for (final dark in [false, true]) {
    testWidgets('automatic translation native menu capture dark=$dark', (
      t,
    ) async {
      await pumpGen(
        t,
        data: GenFixture.view().copyWith(
          prompt: const GenPromptData(
            translate: GenTranslate(
              mode: PromptTranslationMode.inline,
              route: 'Model',
            ),
            tools: GenPromptTools(translatePinned: true),
          ),
        ),
        window: 760,
        height: 760,
        dark: dark,
      );
      await t.tap(find.byKey(const Key('gen-translate-menu')));
      await t.pumpAndSettle();
      final menu = t.getRect(find.byType(UiMenu));
      expect(menu.width, 280);
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.right, lessThanOrEqualTo(712));
      final directory = Platform.environment['AUTO_TRANSLATION_CAPTURES'];
      if (directory != null) {
        debugDisableShadows = false;
        await t.pump();
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('gen-capture')),
        );
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File(
            '$directory/menu-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        debugDisableShadows = true;
      }
      expect(t.takeException(), isNull);
    });
  }
}
