import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/core/constants/brand.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icon_registry.dart';

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final file = File('.dart_tool/studio-captures/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes.buffer.asUint8List());
  image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadStudioCaptureFonts);

  test(
    'default keys adopt bundled fonts while explicit choices are preserved',
    () {
      for (final key in ['', 'system', 'system:', 'bundled:Geist']) {
        expect(FontConfig.fromKey(key), FontConfig.defaultFont);
      }
      final custom = FontConfig.fromKey('system:LXGW ZhenKai GB');
      expect(custom.fontFamily, 'LXGW ZhenKai GB');
      expect(custom.source, FontSource.system);
    },
  );

  test('all color themes use offline typography and keep CJK fallback', () {
    for (final style in AppStyle.values) {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.getTheme(
          style,
          brightness,
          fontConfig: FontConfig.defaultFont,
        );
        expect(theme.textTheme.bodyMedium!.fontFamily, StudioTypography.sans);
        expect(
          theme.textTheme.bodyMedium!.fontFamilyFallback,
          contains(StudioTypography.cjk),
        );
        expect(
          theme.primaryTextTheme.bodyMedium!.fontFamilyFallback,
          contains(StudioTypography.cjk),
        );
        expect(
          theme.tooltipTheme.textStyle!.fontFamilyFallback,
          contains(StudioTypography.cjk),
        );
        expect(
          theme.chipTheme.labelStyle?.fontFamilyFallback,
          anyOf(isNull, contains(StudioTypography.cjk)),
        );
      }
    }
  });

  testWidgets('SVG inherits color, opacity, size, direction and spoken label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: IconTheme(
            data: IconThemeData(
              size: 20,
              color: Colors.red,
              opacity: 0.5,
              applyTextScaling: true,
            ),
            child: Center(
              child: StudioIcon(Icons.arrow_back, semanticLabel: '返回'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.width, 30);
    expect(
      svg.colorFilter,
      ColorFilter.mode(Colors.red.withValues(alpha: 0.5), BlendMode.srcIn),
    );
    expect(svg.matchTextDirection, isTrue);
    expect(find.bySemanticsLabel('返回'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(tester.getSize(find.byType(StudioIcon)), const Size(30, 30));
    semantics.dispose();
  });

  testWidgets('specialist and null icons retain the original renderer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            StudioIcon(Icons.female),
            StudioIcon(null, size: 18),
            StudioIcon(Icons.check, shadows: [Shadow(blurRadius: 2)]),
          ],
        ),
      ),
    );
    expect(find.byType(SvgPicture), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all imported artwork loads and paints in the icon catalog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final icons = <String, IconData>{};
    for (final entry in StudioIconRegistry.assets.entries) {
      icons.putIfAbsent(entry.value, () => entry.key);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppStyle.grungeCollage, Brightness.dark),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (final entry in icons.entries)
                    SizedBox(
                      width: 112,
                      height: 68,
                      child: Column(
                        children: [
                          StudioIcon(entry.value, size: 22),
                          const SizedBox(height: 8),
                          Text(
                            entry.key.split('/').last.replaceAll('.svg', ''),
                            style: const TextStyle(fontSize: 10),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNWidgets(icons.length));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => _capture(tester, key, 'geist-icon-catalog'));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'mixed text and controls fit at real interface sizes: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(760, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        final theme = AppTheme.getTheme(AppStyle.grungeCollage, brightness);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/wof_icon.svg',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Brand.name,
                            style: StudioTypography.wordmark.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          const StudioIcon(Icons.remove, size: 16),
                          const SizedBox(width: 20),
                          const StudioIcon(Icons.close, size: 16),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        '角色提示词 Character Prompts',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '为场景中的角色创建独立提示词。中文 / English / 日本語',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: '提示词 Prompt',
                          hintText: '夜空、城市灯光 · city lights, pixel art',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const StudioIcon(Icons.add, size: 18),
                            label: const Text('添加角色'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const StudioIcon(Icons.tune, size: 18),
                            label: const Text('图像设置'),
                          ),
                          const SizedBox(width: 12),
                          const IconButton(
                            onPressed: null,
                            icon: StudioIcon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '832 × 1216   28 steps   CFG 5.0',
                        style: StudioTypography.data.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seed 3829104 · 已完成 12 张',
                        style: StudioTypography.data.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        children: [
                          for (final size in [16.0, 20.0, 24.0, 32.0])
                            Text(
                              'W.O.F',
                              style: StudioTypography.wordmark.copyWith(
                                fontSize: size,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(
          () => _capture(tester, key, 'studio-typography-${brightness.name}'),
        );
      },
    );
  }
}
