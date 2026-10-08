import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_card.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/dashed_rounded_border.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_appearance.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_colors.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';

import '../../../../helpers/studio_capture_fonts.dart';

const _capture = Key('pill-specification-capture');

Finder _icon(IconData icon) => find.byWidgetPredicate(
  (widget) => widget is UiuxPrototypeIcon && widget.icon == icon,
);

Future<void> _pump(
  WidgetTester tester,
  WidgetBuilder builder, {
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  double width = 960,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: brightness == Brightness.light
          ? GeistTheme.light
          : GeistTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _capture,
            child: Material(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(PromptPill), matching: find.byType(Material))
      .first,
);

Future<void> _save(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/uiux-blocks-task01/captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Widget _inline(BuildContext context, {required bool pills, required Key key}) {
  final style = Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.55);
  return Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'tags, '),
        for (var index = 0; index < 4; index++) ...[
          if (pills)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: PromptPill(
                  title: 'tag',
                  color: promptBlockColorPalette[index],
                ),
              ),
            )
          else
            const TextSpan(text: 'tag'),
          const TextSpan(text: ', '),
        ],
        const TextSpan(text: 'tail'),
      ],
    ),
    key: key,
    style: style,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);

  testWidgets('regular/large keep fixed 20/24px frames and 12/13px labels', (
    tester,
  ) async {
    for (final size in PromptPillSize.values) {
      await _pump(
        tester,
        (context) => Align(
          alignment: Alignment.centerLeft,
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(
                context,
              ).textTheme.copyWith(bodyMedium: const TextStyle(fontSize: 22)),
            ),
            child: PromptPill(
              title: 'tag',
              color: promptBlockColorPalette.first,
              size: size,
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(PromptPill)).height,
        size == PromptPillSize.regular ? 20 : 24,
      );
      expect(
        tester.widget<Text>(find.text('tag')).style!.fontSize,
        size == PromptPillSize.regular ? 12 : 13,
      );
      expect(
        (_surface(tester).shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(size == PromptPillSize.regular ? 5 : 6),
      );
    }
  });

  testWidgets(
    'right badge priority is DNA then lock then random/sequential mode',
    (tester) async {
      for (final (evolution, allowed, locked, badge) in [
        (true, true, true, 'dna'),
        (true, false, true, 'lock'),
        (true, false, false, 'mode'),
        (false, true, true, 'lock'),
        (false, false, false, 'mode'),
      ]) {
        await _pump(
          tester,
          (_) => PromptPill(
            title: 'tag',
            color: promptBlockColorPalette.first,
            evolutionEnabled: evolution,
            allowEvolutionToggle: allowed,
            locked: locked,
            showRollBadge: true,
          ),
        );
        expect(
          find.byType(DnaIcon),
          badge == 'dna' ? findsOneWidget : findsNothing,
        );
        expect(
          _icon(Icons.lock_outline),
          badge == 'lock' ? findsOneWidget : findsNothing,
        );
        expect(
          _icon(Icons.casino_outlined),
          badge == 'mode' ? findsOneWidget : findsNothing,
        );
      }
      await _pump(
        tester,
        (_) => PromptPill(
          title: 'tag',
          color: promptBlockColorPalette.first,
          showRollBadge: true,
          rollBadgeIcon: Icons.arrow_right_alt,
        ),
      );
      expect(_icon(Icons.arrow_right_alt), findsOneWidget);
    },
  );

  testWidgets(
    'disabled uses a fully dashed outline, transparent fill and struck title',
    (tester) async {
      await _pump(
        tester,
        (_) => PromptPill(
          title: 'tag',
          color: promptBlockColorPalette.first,
          enabled: false,
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.foregroundPainter)
          .whereType<DashedRoundedBorderPainter>()
          .single;
      expect(painter.dashedAll, isTrue);
      expect(
        painter.dashedColor,
        GeistTheme.light.colorScheme.onSurfaceVariant.withValues(alpha: .7),
      );
      expect(_surface(tester).color, Colors.transparent);
      final style = tester.widget<Text>(find.text('tag')).style!;
      expect(style.decoration, TextDecoration.lineThrough);
      expect(style.color, GeistTheme.light.colorScheme.onSurfaceVariant);
    },
  );

  testWidgets(
    'missing and unknown use their diagnostic icon and theme colors',
    (tester) async {
      for (final variant in [
        PromptPillVariant.missing,
        PromptPillVariant.unknown,
      ]) {
        await _pump(
          tester,
          (_) => PromptPill(
            title: 'tag',
            color: promptBlockColorPalette.first,
            variant: variant,
            showRollBadge: true,
            locked: true,
          ),
        );
        final missing = variant == PromptPillVariant.missing;
        expect(
          _icon(missing ? Icons.error_outline : Icons.help_outline),
          findsOneWidget,
        );
        expect(_icon(Icons.lock_outline), findsNothing);
        expect(
          tester.widget<Text>(find.text('tag')).style!.color,
          missing
              ? GeistTheme.light.colorScheme.error
              : GeistTheme.light.colorScheme.onSurfaceVariant,
        );
        expect(
          _surface(tester).color,
          missing
              ? GeistTheme.light.colorScheme.error.withValues(alpha: .12)
              : Colors.transparent,
        );
      }
    },
  );

  testWidgets(
    'six styles keep their fill/ink contract and solid yellow has dark text',
    (tester) async {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.light
            ? GeistTheme.light
            : GeistTheme.dark;
        final color = promptBlockColorPalette[3];
        for (final appearance in PromptBlockAppearance.selectable) {
          await _pump(
            tester,
            (_) =>
                PromptPill(title: 'tag', color: color, appearance: appearance),
            brightness: brightness,
          );
          final expected = switch (appearance) {
            PromptBlockAppearance.solid => color,
            PromptBlockAppearance.translation =>
              theme.colorScheme.surfaceContainerHighest,
            PromptBlockAppearance.stripes ||
            PromptBlockAppearance.gradient => Colors.transparent,
            PromptBlockAppearance.dots => color.withValues(alpha: .05),
            _ => color.withValues(
              alpha: brightness == Brightness.light ? .08 : .15,
            ),
          };
          expect(_surface(tester).color, expected);
          final ink = tester.widget<Text>(find.text('tag')).style!;
          expect(
            ink.color,
            appearance == PromptBlockAppearance.solid
                ? Colors.black
                : appearance == PromptBlockAppearance.translation
                ? theme.colorScheme.onSurface
                : Color.lerp(
                    theme.colorScheme.onSurface,
                    color,
                    brightness == Brightness.light ? .72 : .62,
                  ),
          );
          if (appearance == PromptBlockAppearance.translation) {
            expect(find.byType(TranslationIcon), findsOneWidget);
            expect(ink.fontWeight, FontWeight.w500);
          }
        }
      }
      await _pump(
        tester,
        (_) => PromptPill(
          title: 'tag',
          color: promptBlockColorPalette.last,
          appearance: PromptBlockAppearance.solid,
        ),
      );
      expect(tester.widget<Text>(find.text('tag')).style!.color, Colors.white);
    },
  );

  testWidgets(
    'active/focused rings and UC do not change the inline frame height',
    (tester) async {
      await _pump(
        tester,
        (_) => PromptPill(
          title: 'tag',
          color: promptBlockColorPalette[8],
          active: true,
          focused: true,
          isAttachedUc: true,
        ),
      );
      expect(tester.getSize(find.byType(PromptPill)).height, 20);
      expect(find.text('UC'), findsOneWidget);
      expect(
        _surface(tester).color,
        promptBlockColorPalette[8].withValues(alpha: .16),
      );
      final ring = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<PromptPillShadowPainter>()
          .single;
      expect(ring.spreadRadius, 2);
      expect(ring.blurRadius, 0);
      expect(ring.color, promptBlockColorPalette[8].withValues(alpha: .3));
    },
  );

  testWidgets(
    'ordinary palette pills reuse 20px PromptPill and preserve tap/right-click',
    (tester) async {
      var taps = 0;
      var secondary = 0;
      final block = PromptBlock.create(
        title: 'tag',
        content: 'tag',
      ).copyWith(thumbnail: 'unused-thumbnail.png');
      await _pump(
        tester,
        (_) => Align(
          alignment: Alignment.centerLeft,
          child: PromptBlockPill(
            block: block,
            displayTitle: 'tag',
            maxWidth: 200,
            paletteStyle: true,
            selected: true,
            multiSelected: true,
            onTap: () => taps++,
            onSecondaryTap: (_) => secondary++,
          ),
        ),
      );
      expect(tester.getSize(find.byType(PromptBlockPill)).height, 20);
      expect(
        tester.widget<PromptPill>(find.byType(PromptPill)).focused,
        isTrue,
      );
      expect(find.byType(Image), findsNothing);
      expect(
        tester.widget<UiuxPrototypeIcon>(_icon(Icons.check_circle)).size,
        12,
      );
      await tester.tap(find.byType(PromptBlockPill));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PromptBlockPill)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      expect(taps, 1);
      expect(secondary, 1);
    },
  );

  testWidgets('active style combinations keep the prototype CSS surfaces', (
    tester,
  ) async {
    final color = promptBlockColorPalette.last;
    for (final appearance in PromptBlockAppearance.selectable) {
      await _pump(
        tester,
        (_) => PromptPill(
          title: 'tag',
          color: color,
          appearance: appearance,
          active: true,
        ),
      );
      final expected = switch (appearance) {
        PromptBlockAppearance.classic => color.withValues(alpha: .16),
        PromptBlockAppearance.solid => color,
        PromptBlockAppearance.translation =>
          GeistTheme.light.colorScheme.surfaceContainerHighest,
        PromptBlockAppearance.dots => color.withValues(alpha: .05),
        _ => Colors.transparent,
      };
      expect(_surface(tester).color, expected);
      expect(tester.getSize(find.byType(PromptPill)).height, 20);
    }
  });

  testWidgets(
    'four middle-aligned pills fit one 13px/1.55 line without raising it',
    (tester) async {
      await _pump(
        tester,
        (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inline(context, pills: false, key: const Key('plain-line')),
            _inline(context, pills: true, key: const Key('pill-line')),
          ],
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('pill-line'))).height,
        closeTo(
          tester.getSize(find.byKey(const Key('plain-line'))).height,
          .01,
        ),
      );
      expect(find.byType(PromptPill), findsNWidgets(4));
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'complete specification fits real fonts $locale ${brightness.name}',
        (tester) async {
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          try {
            await _pump(
              tester,
              (_) => const _Specification(),
              locale: Locale(locale),
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            await _save(tester, 'spec-$locale-${brightness.name}');
          } finally {
            debugDisableShadows = previousShadows;
          }
        },
      );
    }
  }
}

class _Specification extends StatelessWidget {
  const _Specification();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = l10n.generation_sectionReferenceImages;
    final color = promptBlockColorPalette[8];
    Widget pill({
      bool locked = false,
      bool roll = false,
      IconData rollIcon = Icons.casino_outlined,
      bool active = false,
      bool enabled = true,
      bool uc = false,
      bool dna = false,
      bool focused = false,
      PromptPillVariant variant = PromptPillVariant.normal,
    }) => PromptPill(
      title: title,
      color: color,
      locked: locked,
      showRollBadge: roll,
      rollBadgeIcon: rollIcon,
      active: active,
      enabled: enabled,
      isAttachedUc: uc,
      evolutionEnabled: dna,
      allowEvolutionToggle: dna,
      focused: focused,
      variant: variant,
    );
    Widget cells(List<(String, Widget)> entries) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final entry in entries)
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: entry.$2,
                  ),
                ),
                Text(entry.$1, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
    Widget section(String text, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    final ordinary = PromptBlock.create(title: title, content: 'tag');
    final reading = '$title, $title, $title, $title, $title';
    final translated = PromptBlock.create(
      title: title,
      content: 'tag',
      appearance: PromptBlockAppearance.translation,
      readingTranslationZh: reading,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section(
          '20 / 24',
          cells([
            ('regular', pill()),
            (
              'large',
              PromptPill(
                title: title,
                color: color,
                size: PromptPillSize.large,
              ),
            ),
          ]),
        ),
        section(
          'Mode',
          cells([
            ('fixed', pill()),
            ('random', pill(roll: true)),
            ('sequential', pill(roll: true, rollIcon: Icons.arrow_right_alt)),
            ('random locked', pill(roll: true, locked: true)),
            (
              'sequential locked',
              pill(roll: true, rollIcon: Icons.arrow_right_alt, locked: true),
            ),
          ]),
        ),
        section(
          'State',
          cells([
            ('active', pill(active: true)),
            ('disabled', pill(enabled: false)),
            ('UC', pill(uc: true)),
            ('DNA > lock > mode', pill(locked: true, roll: true, dna: true)),
            ('drag -2 degrees', PromptPillDragFeedback(child: pill())),
            ('focused', pill(focused: true)),
            ('missing', pill(variant: PromptPillVariant.missing)),
            ('unknown', pill(variant: PromptPillVariant.unknown)),
          ]),
        ),
        section(
          'Appearance',
          cells([
            for (final appearance in PromptBlockAppearance.selectable)
              (
                PromptBlockAppearance.label(appearance, l10n),
                PromptPill(
                  title: title,
                  color: promptBlockColorPalette[5],
                  appearance: appearance,
                ),
              ),
          ]),
        ),
        section(
          '10 colors',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < promptBlockColorPalette.length; i++)
                PromptPill(
                  title: '${i + 1}',
                  color: promptBlockColorPalette[i],
                ),
            ],
          ),
        ),
        section(
          'Inline: control / 4 pills',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inline(context, pills: false, key: const Key('sample-plain')),
              const SizedBox(height: 5),
              _inline(context, pills: true, key: const Key('sample-pills')),
            ],
          ),
        ),
        section(
          'Palette components',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PromptBlockPill(
                block: ordinary,
                displayTitle: title,
                maxWidth: 260,
                paletteStyle: true,
                onTap: () {},
              ),
              PromptBlockPill(
                block: translated,
                displayTitle: reading,
                maxWidth: 260,
                paletteStyle: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
