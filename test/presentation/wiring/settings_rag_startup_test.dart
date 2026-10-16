import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag_startup.dart';

import '../../helpers/studio_capture_fonts.dart';

Future<void> _capture(WidgetTester t, String name) async {
  final folder = Platform.environment['RAG_STARTUP_CAPTURES'];
  if (folder == null) return;
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('startup-capture')),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$folder/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    if (name == 'notice-zh-light') {
      final content = find.descendant(
        of: find.byKey(const Key('rag-startup-notice')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxWidth == 480,
        ),
      );
      final rect = t
          .getRect(content)
          .inflate(8)
          .intersect(Offset.zero & boundary.size);
      final detail = await (boundary.debugLayer! as OffsetLayer).toImage(rect);
      final png = await detail.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$folder/preview-zh-light.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      detail.dispose();
    }
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  test(
    'notice gates the action and blocks duplicate clicks until completion',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final startup = c.read(settingsRagStartupProvider.notifier);
      final notice = Completer<bool>();
      final work = Completer<void>();
      var notices = 0, actions = 0;
      final first = startup.run(
        source: SettingsRagSourceKind.tags,
        notify: () {
          notices++;
          return notice.future;
        },
        action: () {
          actions++;
          return work.future;
        },
      );
      await startup.run(
        source: SettingsRagSourceKind.gallery,
        notify: () async {
          notices++;
          return true;
        },
        action: () async {
          actions++;
        },
      );
      expect(notices, 1);
      expect(actions, 0);
      notice.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(actions, 1);
      expect(
        c.read(settingsRagStartupProvider).preparing,
        SettingsRagSourceKind.tags,
      );
      work.complete();
      await first;
      expect(c.read(settingsRagStartupProvider).preparing, isNull);
      await startup.run(
        source: SettingsRagSourceKind.gallery,
        notify: () async {
          notices++;
          return true;
        },
        action: () async {
          actions++;
        },
      );
      expect(notices, 1);
      expect(actions, 2);
    },
  );

  test(
    'dismissing the notice does not start work or keep controls locked',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      var actions = 0;
      await c
          .read(settingsRagStartupProvider.notifier)
          .run(
            source: SettingsRagSourceKind.gallery,
            notify: () async => false,
            action: () async {
              actions++;
            },
          );
      expect(actions, 0);
      expect(c.read(settingsRagStartupProvider).preparing, isNull);
    },
  );

  test(
    'failure clears the pending state and retry does not show another notice',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final startup = c.read(settingsRagStartupProvider.notifier);
      await expectLater(
        startup.run(
          source: SettingsRagSourceKind.gallery,
          notify: () async => true,
          action: () async => throw StateError('fixture failure'),
        ),
        throwsStateError,
      );
      expect(c.read(settingsRagStartupProvider).preparing, isNull);
      var retried = false;
      await startup.run(
        source: SettingsRagSourceKind.gallery,
        notify: () async => throw StateError('notice repeated'),
        action: () async {
          retried = true;
        },
      );
      expect(retried, isTrue);
    },
  );

  test(
    'disposing the app while the notice is open never starts work',
    () async {
      final c = ProviderContainer();
      final notice = Completer<bool>();
      var actions = 0;
      final pending = c
          .read(settingsRagStartupProvider.notifier)
          .run(
            source: SettingsRagSourceKind.gallery,
            notify: () => notice.future,
            action: () async {
              actions++;
            },
          );
      c.dispose();
      notice.complete(true);
      await pending;
      expect(actions, 0);
    },
  );

  test('a new application session shows its own first-use notice', () async {
    var notices = 0;
    for (var session = 0; session < 2; session++) {
      final c = ProviderContainer();
      await c
          .read(settingsRagStartupProvider.notifier)
          .run(
            source: SettingsRagSourceKind.gallery,
            notify: () async {
              notices++;
              return true;
            },
            action: () async {},
          );
      c.dispose();
    }
    expect(notices, 2);
  });

  testWidgets('localized notice and pending state survive page remounts', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(520, 620);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    for (final locale in AppLocalizations.supportedLocales) {
      for (final dark in [false, true]) {
        for (final width in [320.0, 520.0]) {
          for (final scale in [1.0, 1.35]) {
            t.view.physicalSize = Size(width, 620);
            await t.pumpWidget(const SizedBox.shrink());
            final c = ProviderContainer();
            final work = Completer<void>();
            Future<void>? pending;
            var actions = 0;
            Widget app(String page) => UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: const Key('startup-capture'),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: dark ? GeistTheme.dark : GeistTheme.light,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Consumer(
                      key: ValueKey(page),
                      builder: (context, ref, _) => Column(
                        children: [
                          for (final source in [
                            SettingsRagSourceKind.tags,
                            SettingsRagSourceKind.gallery,
                          ])
                            TextButton(
                              key: ValueKey(source.name),
                              onPressed: () {
                                pending = runSettingsRagStartup(
                                  ref,
                                  context,
                                  source,
                                  () {
                                    actions++;
                                    return work.future;
                                  },
                                );
                              },
                              child: Text(source.name),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pumpWidget(app('first'));
            await t.pumpAndSettle();
            await t.tap(find.byKey(const ValueKey('tags')));
            await t.pumpAndSettle();
            expect(find.byKey(const Key('rag-startup-notice')), findsOneWidget);
            expect(actions, 0);
            await _capture(
              t,
              'notice-${locale.toString()}-${dark ? 'dark' : 'light'}${width == 520 && scale == 1 ? '' : '-w${width.toInt()}-s$scale'}',
            );
            await t.tap(find.byKey(const Key('rag-startup-notice-ok')));
            await t.pumpAndSettle();
            expect(actions, 1);
            expect(
              c.read(settingsRagStartupProvider).preparing,
              SettingsRagSourceKind.tags,
            );
            work.complete();
            await pending;
            await t.pumpAndSettle();
            await t.pumpWidget(app('reopened-settings'));
            await t.pumpAndSettle();
            await t.tap(find.byKey(const ValueKey('gallery')));
            await t.pumpAndSettle();
            await pending;
            expect(find.byKey(const Key('rag-startup-notice')), findsNothing);
            expect(actions, 2);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
            c.dispose();
          }
        }
      }
    }
  });

  testWidgets('the close control dismisses without confirming the action', (
    t,
  ) async {
    Future<bool>? result;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                result = showSettingsRagStartupNotice(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('rag-startup-notice-close')));
    await t.pumpAndSettle();
    expect(await result, isFalse);
    expect(find.byKey(const Key('rag-startup-notice')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
