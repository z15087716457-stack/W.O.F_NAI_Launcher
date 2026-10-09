import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/prototype_typography_scope.dart';

import '../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);

  for (final brightness in Brightness.values) {
    testWidgets(
      'root, controls, gallery and viewer typography ${brightness.name}',
      (tester) async {
        final root = AppTheme.getTheme(
          AppStyle.geist,
          brightness,
          fontConfig: FontConfig.defaultFont,
        );
        final themes = <String, ThemeData>{};
        Widget probe(String name) => Builder(
          builder: (context) {
            themes[name] = Theme.of(context);
            return Text(name);
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: root,
            home: Scaffold(
              body: Column(
                children: [
                  probe('root'),
                  FilledButton(onPressed: () {}, child: const Text('Mixed 角色')),
                  PrototypeTypographyScope(
                    family: StudioTypography.sans,
                    child: Column(
                      children: [
                        probe('gallery'),
                        PrototypeTypographyScope(
                          family: StudioTypography.cjk,
                          child: probe('viewer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          themes['root']!.textTheme.bodyMedium!.fontFamily,
          StudioTypography.cjk,
        );
        expect(
          themes['gallery']!.textTheme.bodyMedium!.fontFamily,
          StudioTypography.sans,
        );
        expect(
          themes['viewer']!.textTheme.bodyMedium!.fontFamily,
          StudioTypography.cjk,
        );
        for (final theme in themes.values) {
          final body = theme.textTheme.bodyMedium!;
          expect(body.fontSize, 13);
          expect(body.fontWeight, FontWeight.w400);
          expect(body.height, 1.45);
          expect(body.leadingDistribution, TextLeadingDistribution.even);
          expect(body.letterSpacing, 0);
          expect(body.wordSpacing, 0);
          expect(
            body.fontFamilyFallback,
            containsAllInOrder([StudioTypography.cjk, StudioTypography.korean]),
          );
          for (final style in [
            theme.filledButtonTheme.style!.textStyle!.resolve({}),
            theme.filledButtonTheme.style!.textStyle!.resolve({
              WidgetState.disabled,
            }),
            theme.outlinedButtonTheme.style!.textStyle!.resolve({}),
            theme.textButtonTheme.style!.textStyle!.resolve({}),
            theme.segmentedButtonTheme.style!.textStyle!.resolve({}),
            theme.chipTheme.labelStyle,
            theme.popupMenuTheme.textStyle,
            theme.dropdownMenuTheme.textStyle,
            theme.tabBarTheme.labelStyle,
            theme.appBarTheme.titleTextStyle,
            theme.tooltipTheme.textStyle,
          ]) {
            expect(style!.fontFamily, body.fontFamily);
            expect(style.fontFamilyFallback, body.fontFamilyFallback);
            expect(style.letterSpacing, 0);
          }
        }
        final button =
            tester
                    .widget<RichText>(
                      find.descendant(
                        of: find.byType(FilledButton),
                        matching: find.byType(RichText),
                      ),
                    )
                    .text
                as TextSpan;
        expect(button.style!.fontFamily, StudioTypography.cjk);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('explicit font selection survives nested prototype scopes', (
    tester,
  ) async {
    for (final font in [
      bundledPresets.first,
      const FontConfig(
        displayName: 'Custom',
        fontFamily: 'Custom Font',
        source: FontSource.system,
      ),
    ]) {
      ThemeData? scoped;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(
            AppStyle.geist,
            Brightness.light,
            fontConfig: font,
          ),
          home: PrototypeTypographyScope(
            family: StudioTypography.cjk,
            child: Builder(
              builder: (context) {
                scoped = Theme.of(context);
                return const Text('Choice');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scoped!.textTheme.bodyMedium!.fontFamily, font.fontFamily);
      expect(
        scoped!.filledButtonTheme.style!.textStyle!.resolve({})!.fontFamily,
        font.fontFamily,
      );
    }
  });

  testWidgets('native Mono 500-700 uses identical prototype Medium glyphs', (
    tester,
  ) async {
    // Rendering catches native synthetic bold; manifest declarations alone do
    // not test the actual face selected by the desktop engine.
    Future<Uint8List> pixels(FontWeight weight) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: const SizedBox(width: 400, height: 48).copyWithText(weight),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final result = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            image.dispose();
            return result;
          })
          .then((value) => value!);
    }

    final medium = await pixels(FontWeight.w500);
    expect(await pixels(FontWeight.w600), orderedEquals(medium));
    expect(await pixels(FontWeight.w700), orderedEquals(medium));
    expect(await pixels(FontWeight.w400), isNot(orderedEquals(medium)));
  });
}

extension on SizedBox {
  Widget copyWithText(FontWeight weight) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          '0123456789 832 × 1216 5.0 NovelAI',
          style: StudioTypography.data.copyWith(
            fontSize: 13,
            fontWeight: weight,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}
