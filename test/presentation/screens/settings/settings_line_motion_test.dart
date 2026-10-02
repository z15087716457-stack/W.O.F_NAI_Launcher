import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/provider_logo.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

ThemeData get _theme => settingsUiTheme(
  AppTheme.getTheme(
    AppStyle.geist,
    Platform.environment['STUDIO_APPEARANCE'] == 'dark'
        ? Brightness.dark
        : Brightness.light,
  ),
);

class _TestSurface extends StatelessWidget {
  const _TestSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    ),
  );
}

class _Pixels {
  _Pixels(this.data, this.width, this.origin);
  final List<int> data;
  final int width;
  final Offset origin;

  List<int> at(Offset point) {
    final local = point - origin;
    final index = (local.dy.floor() * width + local.dx.floor()) * 4;
    return data.sublist(index, index + 4);
  }

  int blueLine(Rect rect) {
    var count = 0;
    for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
      final p = at(Offset(x.toDouble(), rect.bottom - 1));
      if (p[2] > p[0] + 4 && p[2] > p[1] + 4) count++;
    }
    return count;
  }
}

Future<_Pixels> _pixels(
  WidgetTester tester,
  GlobalKey key, [
  String? capture,
]) async => (await tester.runAsync(() async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = _Pixels(
    rgba!.buffer.asUint8List(),
    image.width,
    boundary.localToGlobal(Offset.zero),
  );
  if (capture != null &&
      Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/model-management-captures')
      ..createSync(recursive: true);
    File(
      '${folder.path}/settings-line-$capture-${Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
  }
  image.dispose();
  return pixels;
}))!;

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1, 1));
  addTearDown(mouse.removePointer);
  return mouse;
}

void main() {
  setUpAll(() async {
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'hover extends only a short separator segment and restores without moving or stealing clicks',
    (tester) async {
      final key = GlobalKey();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme,
          home: Scaffold(
            body: _TestSurface(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SettingsTile(
                      key: const Key('first-row'),
                      title: const Text('字体'),
                      subtitle: const Text('HarmonyOS Sans SC'),
                      onTap: () => taps++,
                    ),
                    SettingsSwitchTile(
                      key: const Key('second-row'),
                      title: const Text('完成音效'),
                      value: true,
                      onChanged: (_) => taps++,
                    ),
                    const SettingsTile(
                      title: Text('说明'),
                      subtitle: Text('设置会自动保存'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester.getRect(find.byKey(const Key('first-row')));
      final second = tester.getRect(find.byKey(const Key('second-row')));
      final before = await _pixels(tester, key, 'rows-idle');
      final bodyPoint = Offset(first.right - 70, first.center.dy);
      final mouse = await _mouse(tester);
      await mouse.moveTo(first.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final early = await _pixels(tester, key);
      expect(early.blueLine(first), greaterThan(0));
      await tester.pump(const Duration(milliseconds: 180));
      final active = await _pixels(tester, key, 'rows-hover');
      expect(active.blueLine(first), greaterThan(early.blueLine(first)));
      expect(active.blueLine(first), lessThanOrEqualTo(144));
      expect(active.at(bodyPoint), before.at(bodyPoint));
      expect(tester.getRect(find.byKey(const Key('first-row'))), first);
      await tester.tap(find.text('字体'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      await mouse.moveTo(second.center);
      await tester.pumpAndSettle();
      final moved = await _pixels(tester, key);
      expect(moved.blueLine(first), 0);
      expect(moved.blueLine(second), greaterThan(0));
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect((await _pixels(tester, key, 'rows-restored')).blueLine(second), 0);
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'informational and disabled rows stay still; a narrow RTL row keeps feedback at the start edge',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme,
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: _TestSurface(
                key: key,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      const SettingsTile(
                        key: Key('informational'),
                        hoverFeedback: false,
                        title: Text('订阅有效期'),
                        trailing: Text('2026-12-01'),
                      ),
                      const SettingsTile(
                        key: Key('disabled'),
                        enabled: false,
                        title: Text('加载中'),
                        trailing: Icon(Icons.more_horiz),
                      ),
                      SettingsTile(
                        key: const Key('rtl-active'),
                        title: const Text('语言'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await _mouse(tester);
      for (final name in ['informational', 'disabled']) {
        final rect = tester.getRect(find.byKey(Key(name)));
        await mouse.moveTo(rect.center);
        await tester.pumpAndSettle();
        expect((await _pixels(tester, key)).blueLine(rect), 0);
      }
      final rect = tester.getRect(find.byKey(const Key('rtl-active')));
      await mouse.moveTo(rect.center);
      await tester.pumpAndSettle();
      final pixels = await _pixels(tester, key, 'rtl');
      expect(pixels.blueLine(rect), greaterThan(0));
      final start = pixels.at(Offset(rect.right - 8, rect.bottom - 1));
      final end = pixels.at(Offset(rect.left + 8, rect.bottom - 1));
      expect(start[2], greaterThan(start[0] + 20));
      expect(end[2], closeTo(end[0], 1));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the saved reduced-motion preference settles mid-hover and is captured into dialogs',
    (tester) async {
      final key = GlobalKey();
      final storage = harness.MemorySettings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp(
            theme: _theme,
            home: SettingsTypographyScope(
              child: Builder(
                builder: (context) => Scaffold(
                  body: _TestSurface(
                    key: key,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SettingsTile(
                            key: const Key('motion-row'),
                            title: const Text('风格'),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (_) => const AlertDialog(
                                content: Text(
                                  '设置弹窗',
                                  key: Key('motion-dialog'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsTypographyScope)),
      );
      final rect = tester.getRect(find.byKey(const Key('motion-row')));
      final mouse = await _mouse(tester);
      await mouse.moveTo(rect.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final moving = (await _pixels(tester, key)).blueLine(rect);
      await container
          .read(canvasReducedMotionNotifierProvider.notifier)
          .setReduced(true);
      await tester.pump();
      await tester.pump();
      final still = (await _pixels(tester, key, 'reduced')).blueLine(rect);
      expect(still, greaterThan(moving));
      await tester.pump(const Duration(milliseconds: 20));
      expect((await _pixels(tester, key)).blueLine(rect), still);
      expect(storage.values[StorageKeys.canvasReducedMotion], isTrue);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      // Mouse tracking commits the exit after paint; flush without elapsed time.
      await tester.pump();
      expect((await _pixels(tester, key)).blueLine(rect), 0);
      await tester.tap(find.text('风格'));
      await tester.pumpAndSettle();
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.byKey(const Key('motion-dialog'))),
        ),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('motion-dialog')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every provider logo renders in neutral tones with its existing silhouette',
    (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme,
          home: Scaffold(
            body: _TestSurface(
              key: key,
              child: SizedBox(
                width: 600,
                height: 320,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in ProviderPresetDefaults.selectable)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(child: ProviderLogo(preset, size: 28)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pixels = await _pixels(tester, key, 'provider-logos');
      final background = pixels.at(pixels.origin + const Offset(599, 319));
      var drawn = 0;
      var colored = 0;
      for (var i = 0; i < pixels.data.length; i += 4) {
        if ((pixels.data[i] - pixels.data[i + 1]).abs() > 1 ||
            (pixels.data[i] - pixels.data[i + 2]).abs() > 1) {
          colored++;
        }
        if (pixels.data[i] != background[0]) drawn++;
      }
      expect(colored, 0);
      expect(drawn, greaterThan(1000));
      expect(find.byType(ProviderLogo), findsNWidgets(40));
      expect(tester.takeException(), isNull);
    },
  );
}
