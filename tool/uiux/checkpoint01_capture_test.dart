import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_sidebar_style.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon_paths.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_appearance.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';

import '../../test/helpers/studio_capture_fonts.dart';

// Temporary visual evidence fixture: input is read from the selected HTML DOM.
// Production widgets are rendered directly; this does not repaint their shape.
void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('capture selected HTML pill cases with production widgets', (
    tester,
  ) async {
    final root = Directory('.dart_tool/uiux-checkpoint01');
    final cases =
        (jsonDecode(
                  File(
                    '${root.path}/prototype-pill-cases.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final output = Directory('${root.path}/same-scene-captures');
    output.createSync(recursive: true);
    final measurements = <Map<String, Object?>>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(260, 64);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final entry in cases.where((entry) => entry['index'] < 29)) {
        final theme = entry['theme'] == 'dark'
            ? GeistTheme.dark
            : GeistTheme.light;
        final classes = (entry['classes'] as String).split(' ');
        final index = entry['index'] as int;
        final path = (entry['icon'] as Map)['path'] as String;
        final iconName = blocksPrototypeIconPaths.entries
            .where((value) => value.value == path)
            .firstOrNull
            ?.key;
        final appearance = classes.contains('stripes')
            ? PromptBlockAppearance.stripes
            : classes.contains('dots')
            ? PromptBlockAppearance.dots
            : classes.contains('solid')
            ? PromptBlockAppearance.solid
            : classes.contains('grad')
            ? PromptBlockAppearance.gradient
            : classes.contains('tr')
            ? PromptBlockAppearance.translation
            : PromptBlockAppearance.classic;
        final rawColor = (entry['blockColor'] as String).replaceFirst('#', '');
        Widget pill = PromptPill(
          key: const Key('pill'),
          title: entry['title'] as String,
          color: Color(int.parse('ff$rawColor', radix: 16)),
          appearance: appearance,
          enabled: !classes.contains('off'),
          active: classes.contains('open'),
          focused: classes.contains('kf'),
          isAttachedUc: entry['uc'] as bool,
          locked:
              (entry['badgePath'] as String) ==
              blocksPrototypeIconPaths['lock'],
          showRollBadge: [
            'dice',
            'seq',
          ].any((name) => entry['badgePath'] == blocksPrototypeIconPaths[name]),
          rollBadgeIcon: entry['badgePath'] == blocksPrototypeIconPaths['seq']
              ? Icons.arrow_right_alt
              : Icons.casino_outlined,
          evolutionEnabled:
              entry['badgePath'] == blocksPrototypeIconPaths['evo'],
          allowEvolutionToggle:
              entry['badgePath'] == blocksPrototypeIconPaths['evo'],
          variant: classes.contains('miss')
              ? PromptPillVariant.missing
              : classes.contains('unk')
              ? PromptPillVariant.unknown
              : PromptPillVariant.normal,
          leading: iconName == null || classes.contains('tr')
              ? null
              : UiuxPrototypeIcon(
                  StudioIcons.promptBlocks,
                  prototypeName: iconName,
                  strokeWidth: 2,
                  size: 12,
                ),
        );
        if (classes.contains('drag')) {
          pill = PromptPillDragFeedback(child: pill);
        }
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: theme,
            home: RepaintBoundary(
              key: const Key('capture'),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Align(alignment: Alignment.topLeft, child: pill),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final pillBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('pill')),
        );
        // A rotated pill needs the bounds of all four transformed corners;
        // tester.getRect uses only opposite corners and underreports its height.
        final rect = MatrixUtils.transformRect(
          pillBox.getTransformTo(null),
          Offset.zero & pillBox.size,
        );
        final name =
            'pill-${entry['theme']}-${index.toString().padLeft(2, '0')}';
        measurements.add({
          'name': name,
          'x': rect.left,
          'y': rect.top,
          'title': entry['title'],
          'label': entry['label'],
          'theme': entry['theme'],
          'prototypeWidth': (entry['rect'] as Map)['width'],
          'prototypeHeight': (entry['rect'] as Map)['height'],
          'flutterWidth': rect.width,
          'flutterHeight': rect.height,
          'transformed': classes.contains('drag'),
        });
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${output.path}/$name.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      File('${root.path}/same-scene-measurements.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(measurements),
      );
    } finally {
      debugDisableShadows = shadows;
    }
  });
  testWidgets('capture production module headers and segment tracks', (
    tester,
  ) async {
    final root = Directory('.dart_tool/uiux-checkpoint01');
    final output = Directory('${root.path}/same-scene-captures');
    output.createSync(recursive: true);
    final records = <Map<String, Object?>>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final dark in [false, true]) {
        final theme = dark ? GeistTheme.dark : GeistTheme.light;
        final key = dark ? 'dark' : 'light';
        Widget position() => SidebarSegmentTrack<bool>(
          selected: false,
          dense: true,
          onSelected: (_) {},
          segments: const [
            SidebarSegment(value: false, child: Text('AI 选择')),
            SidebarSegment(value: true, child: Text('自定义')),
          ],
        );
        final scenes = <String, Widget>{
          'header-character': GenerationModuleCard(
            title: '角色提示词',
            count: 1,
            headerKey: const Key('geometry'),
            actions: [
              Text('定位', style: GenSidebarStyle.moduleFieldLabel(theme)),
              position(),
              ModuleHeaderIconButton(
                icon: Icons.grid_view,
                tooltip: '定位',
                onPressed: () {},
              ),
              ModuleHeaderIconButton(
                icon: Icons.add,
                tooltip: '添加',
                primary: true,
                onPressed: () {},
              ),
            ],
          ),
          'header-reference': const GenerationModuleCard(
            title: '参考图',
            headerKey: Key('geometry'),
          ),
          'header-image': const GenerationModuleCard(
            title: '图像',
            headerKey: Key('geometry'),
          ),
          'position': KeyedSubtree(
            key: const Key('geometry'),
            child: position(),
          ),
          'orientation': KeyedSubtree(
            key: const Key('geometry'),
            child: SidebarSegmentTrack<int>(
              selected: 1,
              onSelected: (_) {},
              segments: const [
                SidebarSegment(
                  value: 0,
                  child: UiuxPrototypeIcon(
                    Icons.crop_landscape,
                    source: UiuxPrototypeIconSource.generation,
                  ),
                ),
                SidebarSegment(
                  value: 1,
                  child: UiuxPrototypeIcon(
                    Icons.crop_portrait,
                    source: UiuxPrototypeIconSource.generation,
                  ),
                ),
                SidebarSegment(
                  value: 2,
                  child: UiuxPrototypeIcon(
                    Icons.crop_square,
                    source: UiuxPrototypeIconSource.generation,
                  ),
                ),
              ],
            ),
          ),
          'count': SizedBox(
            width: 215,
            child: SidebarSegmentTrack<int>(
              key: const Key('geometry'),
              selected: 1,
              expand: true,
              onSelected: (_) {},
              segments: const [
                SidebarSegment(value: 1, child: Text('1'), numeric: true),
                SidebarSegment(value: 2, child: Text('2'), numeric: true),
                SidebarSegment(value: 3, child: Text('3'), numeric: true),
                SidebarSegment(value: 4, child: Text('4'), numeric: true),
              ],
            ),
          ),
        };
        for (final scene in scenes.entries) {
          final header = scene.key.startsWith('header-');
          tester.view.physicalSize = const Size(411, 64);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: RepaintBoundary(
                key: const Key('capture'),
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: header
                          ? SizedBox(width: 395, child: scene.value)
                          : scene.value,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final rect = tester.getRect(find.byKey(const Key('geometry')));
          final name = 'generation-$key-${scene.key}';
          records.add({
            'name': name,
            'x': rect.left,
            'y': rect.top,
            'width': rect.width,
            'height': rect.height,
          });
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '${output.path}/$name.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      }
      File(
        '${root.path}/same-scene-generation-measurements.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(records));
    } finally {
      debugDisableShadows = shadows;
    }
  });
}
