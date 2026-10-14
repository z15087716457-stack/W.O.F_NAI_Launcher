import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_sidebar_style.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../helpers/studio_capture_fonts.dart';

const _captureKey = Key('module-sample-capture');

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder builder, {
  double width = 420,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width + 24, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: brightness == Brightness.light
          ? GeistTheme.light
          : GeistTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _captureKey,
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: width,
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final capture = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await capture.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/uiux-task01/captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      capture.dispose();
    }
  });
}

Finder _segment(int value) => find.ancestor(
  of: find.text('$value'),
  matching: find.byType(SidebarSegmentButton),
);

Material _segmentMaterial(WidgetTester tester, Finder segment) =>
    tester.widget<Material>(
      find.descendant(of: segment, matching: find.byType(Material)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'header keeps title, badge and action geometry; tooltip and tap work',
    (tester) async {
      var taps = 0;
      late String title;
      late String hint;
      await _pump(tester, (context) {
        final l10n = AppLocalizations.of(context)!;
        title = l10n.gen_refs;
        hint = l10n.img2img_subtitle;
        return GenerationModuleCard(
          title: title,
          titleTooltip: hint,
          count: 3,
          headerKey: const Key('module-header'),
          actions: [
            ModuleHeaderIconButton(
              icon: Icons.add,
              tooltip: l10n.vibe_addReference,
              onPressed: () => taps++,
              primary: true,
            ),
          ],
        );
      });
      expect(find.text(title), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('module-header'))).height, 38);
      final badge = find.ancestor(
        of: find.text('3'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(badge).height, 18);
      expect(tester.getSize(find.byType(IconButton)), const Size(28, 28));
      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(GenerationModuleCard),
              matching: find.byType(Material),
            )
            .first,
      );
      final shape = surface.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(6));
      expect(shape.side.width, 1);
      expect(shape.side.color, GenSidebarStyle.border(GeistTheme.light));
      expect(surface.clipBehavior, Clip.antiAlias);
      expect(surface.color, GenSidebarStyle.promptSurface(GeistTheme.light));

      await tester.tap(find.byType(IconButton));
      expect(taps, 1);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(title)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(hint), findsOneWidget);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('absent, zero and negative counts leave only the title', (
    tester,
  ) async {
    for (final count in <int?>[null, 0, -1]) {
      await _pump(
        tester,
        (context) => GenerationModuleCard(
          title: AppLocalizations.of(context)!.gen_refs,
          count: count,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(GenerationModuleCard),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(GenerationModuleCard)).height, 40);
    }
  });

  testWidgets(
    'hidden model panels leave adjacent 46px rows with one separator',
    (tester) async {
      await _pump(
        tester,
        (context) => GenerationModuleCard(
          title: AppLocalizations.of(context)!.gen_refs,
          headerKey: const Key('row-header'),
          children: [
            GenerationModuleRow(
              key: const Key('first-row'),
              child: Text(AppLocalizations.of(context)!.img2img_title),
            ),
            const SizedBox.shrink(),
            GenerationModuleRow(
              key: const Key('last-row'),
              child: Text(AppLocalizations.of(context)!.preciseRef_title),
            ),
          ],
        ),
      );
      final first = tester.getRect(find.byKey(const Key('first-row')));
      final last = tester.getRect(find.byKey(const Key('last-row')));
      expect(first.height, 46);
      expect(last.height, 46);
      expect(
        first.top,
        tester.getRect(find.byKey(const Key('row-header'))).bottom,
      );
      expect(first.bottom, last.top);
      // HTML's 38px header + two 46px rows + the outer 1px border on each edge.
      expect(tester.getSize(find.byType(GenerationModuleCard)).height, 132);
      final dividers = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(GenerationModuleRow),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((widget) => widget.decoration is BoxDecoration)
          .map((widget) => (widget.decoration as BoxDecoration).border)
          .whereType<Border>()
          .toList();
      expect(dividers, hasLength(2));
      expect(dividers.every((border) => border.top.width == 1), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'row background fills its frame and lets growing content receive taps',
    (tester) async {
      var taps = 0;
      await _pump(
        tester,
        (context) => GenerationModuleCard(
          title: AppLocalizations.of(context)!.gen_refs,
          children: [
            GenerationModuleRow(
              key: const Key('growing-row'),
              background: const ColoredBox(
                key: Key('row-background'),
                color: Colors.black,
              ),
              child: GestureDetector(
                key: const Key('row-action'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: SizedBox(
                  height: 80,
                  child: Text(AppLocalizations.of(context)!.img2img_subtitle),
                ),
              ),
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('growing-row'))).height, 81);
      expect(
        tester.getRect(find.byKey(const Key('row-background'))),
        tester.getRect(find.byKey(const Key('growing-row'))),
      );
      await tester.tap(find.byKey(const Key('row-action')));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'track switches selection and disabled segments cannot call back',
    (tester) async {
      var selected = 1;
      final calls = <int>[];
      await _pump(
        tester,
        (_) => StatefulBuilder(
          builder: (context, setState) => SidebarSegmentTrack<int>(
            selected: selected,
            expand: true,
            segments: const [
              SidebarSegment(value: 1, child: Text('1'), numeric: true),
              SidebarSegment(value: 2, child: Text('2'), numeric: true),
              SidebarSegment(
                value: 3,
                child: Text('3'),
                enabled: false,
                numeric: true,
              ),
            ],
            onSelected: (value) => setState(() {
              selected = value;
              calls.add(value);
            }),
          ),
        ),
      );
      await tester.tap(find.text('3'));
      expect(calls, isEmpty);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(calls, [2]);
      expect(tester.widget<SidebarSegmentButton>(_segment(2)).selected, isTrue);
      expect(
        tester.widget<SidebarSegmentButton>(_segment(1)).selected,
        isFalse,
      );
      expect(
        tester.widget<SidebarSegmentButton>(_segment(3)).onPressed,
        isNull,
      );
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('2')),
        matchesSemantics(
          label: '2',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'dense and normal tracks have 22/28px segments and support equal widths',
    (tester) async {
      for (final dense in [false, true]) {
        for (final expand in [false, true]) {
          await _pump(
            tester,
            (_) => Align(
              alignment: Alignment.centerLeft,
              child: SidebarSegmentTrack<int>(
                key: const Key('track'),
                selected: null,
                onSelected: (_) {},
                dense: dense,
                expand: expand,
                segments: const [
                  SidebarSegment(value: 1, child: Text('1')),
                  SidebarSegment(value: 2, child: Text('2')),
                ],
              ),
            ),
            width: 280,
          );
          final first = tester.getRect(_segment(1));
          final second = tester.getRect(_segment(2));
          final track = tester.getSize(find.byKey(const Key('track')));
          expect(first.height, dense ? 22 : 28);
          expect(track.height, dense ? 26 : 32);
          expect(second.left - first.right, 2);
          expect(
            tester.widget<SidebarSegmentButton>(_segment(1)).selected,
            isFalse,
          );
          if (expand) {
            expect(track.width, 280);
            expect(first.width, second.width);
          } else {
            expect(track.width, lessThan(280));
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'light/dark selected surfaces, disabled ink and tabular Mono match the spec',
    (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = brightness == Brightness.light
            ? GeistTheme.light
            : GeistTheme.dark;
        await _pump(
          tester,
          (_) => SidebarSegmentTrack<int>(
            selected: 1,
            onSelected: (_) {},
            segments: const [
              SidebarSegment(value: 1, child: Text('1'), numeric: true),
              SidebarSegment(value: 2, child: Text('2'), enabled: false),
            ],
          ),
          brightness: brightness,
        );
        expect(
          _segmentMaterial(tester, _segment(1)).color,
          brightness == Brightness.light
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surfaceContainerHigh,
        );
        final text = DefaultTextStyle.of(tester.element(find.text('1'))).style;
        expect(text.fontFamily, 'Geist Mono');
        expect(
          text.fontFeatures,
          contains(const ui.FontFeature.tabularFigures()),
        );
        expect(text.color, theme.colorScheme.onSurface);
        expect(
          DefaultTextStyle.of(tester.element(find.text('2'))).style.color,
          theme.colorScheme.onSurface.withValues(alpha: .3),
        );
        final shadows = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(SidebarSegmentTrack<int>),
                matching: find.byType(DecoratedBox),
              ),
            )
            .where(
              (box) => (box.decoration as BoxDecoration).boxShadow != null,
            );
        expect(
          shadows,
          brightness == Brightness.light ? hasLength(1) : isEmpty,
        );
      }
    },
  );

  testWidgets(
    'legacy SidebarSegmentButton retains old geometry and selected color',
    (tester) async {
      await _pump(
        tester,
        (_) => SidebarSegmentButton(
          selected: true,
          onPressed: () {},
          child: const Text('1'),
        ),
      );
      final button = find.byType(SidebarSegmentButton);
      expect(tester.getSize(button).height, 28);
      final surface = _segmentMaterial(tester, button);
      expect(surface.borderRadius, BorderRadius.circular(3));
      expect(surface.color, GenSidebarStyle.selectedSurface(GeistTheme.light));
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'real-font samples fit $locale ${brightness.name} at 280/352/420/560',
        (tester) async {
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          try {
            for (final width in [280.0, 352.0, 420.0, 560.0]) {
              await _pump(
                tester,
                (_) => const _SampleModules(),
                width: width,
                locale: Locale(locale),
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
              for (final header in [
                'character-header',
                'reference-header',
                'image-header',
              ]) {
                expect(tester.getSize(find.byKey(Key(header))).height, 38);
              }
              final card = tester.getRect(
                find.byKey(const Key('character-module')),
              );
              final action = tester.getRect(
                find.byKey(const Key('character-add')),
              );
              expect(card.contains(action.topLeft), isTrue);
              expect(card.contains(action.bottomRight), isTrue);
              expect(action.size, const Size(28, 28));
              final title = tester.widget<Text>(
                find
                    .descendant(
                      of: find.byType(GenerationModuleCard).last,
                      matching: find.byType(Text),
                    )
                    .first,
              );
              expect(title.maxLines, 1);
              expect(title.overflow, TextOverflow.ellipsis);
              await _capture(
                tester,
                '$locale-${brightness.name}-${width.toInt()}',
              );
            }
          } finally {
            debugDisableShadows = previousShadows;
          }
        },
      );
    }
  }
}

class _SampleModules extends StatelessWidget {
  const _SampleModules();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GenerationModuleCard(
          key: const Key('character-module'),
          headerKey: const Key('character-header'),
          title: l10n.generation_sectionCharacters,
          titleTooltip: l10n.generation_sectionCharactersSub,
          count: 32,
          actions: [
            SidebarSegmentTrack<bool>(
              selected: false,
              dense: true,
              onSelected: (_) {},
              segments: [
                SidebarSegment(
                  value: false,
                  child: Text(l10n.characterCanvas_aiChoice),
                ),
                SidebarSegment(
                  value: true,
                  child: Text(l10n.characterCanvas_custom),
                ),
              ],
            ),
            ModuleHeaderIconButton(
              key: const Key('character-add'),
              icon: Icons.add,
              tooltip: l10n.character_addCharacter,
              onPressed: () {},
              primary: true,
            ),
          ],
          children: [
            GenerationModuleRow(child: Text(l10n.character_number(1))),
          ],
        ),
        const SizedBox(height: GenSidebarStyle.sectionGap),
        GenerationModuleCard(
          headerKey: const Key('reference-header'),
          title: l10n.gen_refs,
          count: 3,
          actions: [
            ModuleHeaderIconButton(
              icon: Icons.add,
              tooltip: l10n.vibe_addReference,
              onPressed: () {},
            ),
          ],
          children: [
            GenerationModuleRow(
              background: ColoredBox(
                color: GenSidebarStyle.selectedSurface(theme),
              ),
              child: _referenceRow(
                context,
                l10n.img2img_title,
                StudioIcons.imageToImage,
              ),
            ),
            const SizedBox.shrink(),
            GenerationModuleRow(
              child: _referenceRow(
                context,
                l10n.vibe_title,
                StudioIcons.styleTransfer,
              ),
            ),
            GenerationModuleRow(
              child: _referenceRow(
                context,
                l10n.preciseRef_title,
                StudioIcons.referenceFocus,
              ),
            ),
          ],
        ),
        const SizedBox(height: GenSidebarStyle.sectionGap),
        GenerationModuleCard(
          headerKey: const Key('image-header'),
          title: l10n.generation_imageSize,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: [
                  SidebarSegmentTrack<int>(
                    selected: 2,
                    expand: true,
                    onSelected: (_) {},
                    segments: const [
                      SidebarSegment(
                        value: 1,
                        child: UiuxPrototypeIcon(
                          Icons.crop_landscape,
                          source: UiuxPrototypeIconSource.generation,
                        ),
                      ),
                      SidebarSegment(
                        value: 2,
                        child: UiuxPrototypeIcon(
                          Icons.crop_portrait,
                          source: UiuxPrototypeIconSource.generation,
                        ),
                      ),
                      SidebarSegment(
                        value: 3,
                        child: UiuxPrototypeIcon(
                          Icons.crop_square,
                          source: UiuxPrototypeIconSource.generation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SidebarSegmentTrack<int>(
                    selected: 1,
                    expand: true,
                    onSelected: (_) {},
                    segments: const [
                      SidebarSegment(value: 1, child: Text('1'), numeric: true),
                      SidebarSegment(value: 2, child: Text('2'), numeric: true),
                      SidebarSegment(value: 3, child: Text('3'), numeric: true),
                      SidebarSegment(
                        value: 4,
                        child: Text('4'),
                        numeric: true,
                        enabled: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: GenSidebarStyle.sectionGap),
        GenerationModuleCard(
          title: l10n.generation_sectionCharactersSub,
          actions: [
            ModuleHeaderIconButton(
              icon: Icons.add,
              tooltip: l10n.character_addCharacter,
              onPressed: () {},
            ),
          ],
          children: [
            GenerationModuleRow(
              child: Text(
                l10n.generation_sectionCharactersSub,
                key: const Key('long-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _referenceRow(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GenSidebarStyle.moduleFieldLabel(theme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ModuleHeaderIconButton(
          icon: Icons.upload_outlined,
          tooltip: AppLocalizations.of(context)!.img2img_uploadImage,
          onPressed: () {},
        ),
        ModuleHeaderIconButton(
          icon: Icons.expand_more,
          tooltip: title,
          onPressed: () {},
        ),
      ],
    );
  }
}
