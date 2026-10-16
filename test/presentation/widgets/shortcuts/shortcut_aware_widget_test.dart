import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_help_dialog.dart';

class _DefaultConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _LoadingConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() => Completer<ShortcutConfig>().future;
}

class _ErrorConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async =>
      throw StateError('test config failure');
}

class _DisabledConfig extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async =>
      ShortcutConfig.createDefault().copyWith(enableShortcuts: false);
}

void main() {
  for (final factory in [
    _DefaultConfig.new,
    _LoadingConfig.new,
    _ErrorConfig.new,
  ]) {
    for (final page in [
      ShortcutContext.generation,
      ShortcutContext.vibeDetail,
    ]) {
      testWidgets(
        'default local/global key dispatch stays separate: $factory $page',
        (tester) async {
          var local = 0, global = 0;
          final generation = page == ShortcutContext.generation;
          final focus = FocusNode();
          addTearDown(focus.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [shortcutConfigNotifierProvider.overrideWith(factory)],
              child: MaterialApp(
                home: GlobalShortcuts(
                  shortcuts: {
                    generation
                        ? ShortcutIds.minimizeToTray
                        : ShortcutIds.vibeExport: () =>
                        global++,
                  },
                  child: PageShortcuts(
                    contextType: page,
                    shortcuts: {
                      generation
                          ? ShortcutIds.togglePromptMode
                          : ShortcutIds.vibeDetailExport: () =>
                          local++,
                    },
                    child: Focus(
                      focusNode: focus,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          focus.requestFocus();
          await tester.pump();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(
            generation ? LogicalKeyboardKey.keyM : LogicalKeyboardKey.keyE,
          );
          expect(local, 1);
          expect(global, 0);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(
            generation ? LogicalKeyboardKey.keyM : LogicalKeyboardKey.keyE,
          );
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          expect(local, 1);
          expect(global, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final nested in [false, true]) {
    testWidgets('F1 opens real help with page shortcuts: $nested', (
      tester,
    ) async {
      var helpCalls = 0;
      var generationCalls = 0;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new),
          ],
          child: GlobalShortcuts(
            shortcuts: {
              ShortcutIds.showShortcutHelp: () {
                helpCalls++;
                ShortcutHelpDialog.show(navigator.currentContext!);
              },
            },
            child: MaterialApp(
              navigatorKey: navigator,
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: nested
                    ? PageShortcuts(
                        contextType: ShortcutContext.generation,
                        shortcuts: {
                          ShortcutIds.generateImage: () => generationCalls++,
                        },
                        child: const Material(
                          child: TextField(autofocus: true),
                        ),
                      )
                    : const Material(child: TextField(autofocus: true)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(helpCalls, 1);
      expect(find.byType(ShortcutHelpDialog), findsOneWidget);
      Navigator.of(tester.element(find.byType(ShortcutHelpDialog))).pop();
      await tester.pumpAndSettle();
      if (nested) {
        await tester.tap(find.byType(TextField));
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        expect(generationCalls, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final entry in <String, ShortcutConfigNotifier Function()>{
    'loading': _LoadingConfig.new,
    'error': _ErrorConfig.new,
    'disabled': _DisabledConfig.new,
  }.entries) {
    testWidgets('nested dispatch when config is ${entry.key}', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shortcutConfigNotifierProvider.overrideWith(entry.value)],
          child: MaterialApp(
            home: GlobalShortcuts(
              shortcuts: {ShortcutIds.showShortcutHelp: () => calls++},
              child: PageShortcuts(
                contextType: ShortcutContext.generation,
                shortcuts: {ShortcutIds.generateImage: () {}},
                child: const Material(child: TextField(autofocus: true)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pump();
      expect(calls, entry.key == 'disabled' ? 0 : 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('all ten navigation bindings dispatch with an input focused', (
    tester,
  ) async {
    final opened = <AppBranch>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new),
        ],
        child: MaterialApp(
          home: GlobalShortcuts(
            shortcuts: {
              for (final entry in globalNavigationShortcutBranches.entries)
                entry.key: () => opened.add(entry.value),
            },
            child: const Material(child: TextField(autofocus: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    const keys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.comma,
    ];
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    for (final key in keys) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(opened, [
      AppBranch.generation,
      AppBranch.styleExplore,
      AppBranch.localGallery,
      AppBranch.onlineGallery,
      AppBranch.promptBlockLibrary,
      AppBranch.vibeLibrary,
      AppBranch.preciseRefLibrary,
      AppBranch.tagWiki,
      AppBranch.statistics,
      AppBranch.settings,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nearest registered global binding wins without duplicate calls',
    (tester) async {
      var rootCalls = 0;
      var shellCalls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shortcutConfigNotifierProvider.overrideWith(_DefaultConfig.new),
          ],
          child: MaterialApp(
            home: GlobalShortcuts(
              shortcuts: {ShortcutIds.showShortcutHelp: () => rootCalls++},
              child: GlobalShortcuts(
                shortcuts: {ShortcutIds.showShortcutHelp: () => shellCalls++},
                child: PageShortcuts(
                  contextType: ShortcutContext.generation,
                  shortcuts: {ShortcutIds.generateImage: () {}},
                  child: const Material(child: TextField(autofocus: true)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pump();
      expect(rootCalls, 0);
      expect(shellCalls, 1);
    },
  );
}
