import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_configuration_card.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_square_checkbox.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

const _id = 'deepseek-flash';
const _model = ModelConfig(
  providerId: 'deepseek',
  name: _id,
  displayName: _id,
  customFields: {},
);
PromptAssistantConfigState get _config => harness.sampleConfig.copyWith(
  models: [
    _model,
    _model.copyWith(name: 'deepseek-v4-pro', displayName: 'deepseek-v4-pro'),
  ],
);

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(target),
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectWholeCard(WidgetTester tester) {
  final viewport = tester.getRect(
    find.byKey(const Key('service-selected-list')),
  );
  final card = tester.getRect(find.byType(ModelConfigurationCard));
  final page = tester.getRect(find.byKey(const Key('service-overview-scroll')));
  expect(
    card.top,
    greaterThanOrEqualTo(page.top - .5),
    reason: 'card=$card, list=$viewport, page=$page',
  );
  expect(card.bottom, lessThanOrEqualTo(page.bottom + .5));
  expect(card.top, greaterThanOrEqualTo(viewport.top - .5));
  expect(
    card.bottom,
    lessThanOrEqualTo(viewport.bottom + .5),
    reason: 'All base model options must fit in the selected-model viewport.',
  );
  for (final key in [
    'context-presets',
    'output-presets',
    'reasoning-presets',
    'model-thinking-controls',
    'model-custom-headers',
    'model-custom-body',
  ]) {
    final bounds = tester.getRect(find.byKey(Key(key)));
    expect(bounds.top, greaterThanOrEqualTo(viewport.top));
    expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + .5));
  }
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] == '1') {
      await loadStudioCaptureFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final entry in [
    (const Size(1200, 820), 1.1, 'regular'),
    (const Size(1600, 1000), 1.0, 'wide'),
    (const Size(960, 820), 1.3, 'compact'),
  ]) {
    testWidgets(
      '${entry.$3} advanced model opens with every base option visible',
      (tester) async {
        final container = await harness.pumpManagement(
          tester,
          size: entry.$1,
          scale: entry.$2,
          config: _config,
        );
        final before = container.read(promptAssistantConfigProvider).encode();
        final selectedPanel = find
            .ancestor(
              of: find.byKey(const Key('service-selected-list')),
              matching: find.byType(Material),
            )
            .first;
        final catalogPanel = find
            .ancestor(
              of: find.byKey(const Key('service-catalog-search')),
              matching: find.byType(Material),
            )
            .first;
        final selectedHeight = tester.getSize(selectedPanel).height;
        final catalogHeight = tester.getSize(catalogPanel).height;
        expect(selectedHeight, lessThanOrEqualTo(460));
        expect(selectedHeight, greaterThanOrEqualTo(320));
        await harness.capture(tester, 'restored-height-${entry.$3}-collapsed');
        await _tap(tester, 'service-model-parameters-$_id');
        expect(tester.getSize(selectedPanel).height, selectedHeight);
        expect(tester.getSize(catalogPanel).height, catalogHeight);
        _expectWholeCard(tester);
        expect(find.text('思考设置'), findsNothing);
        expect(find.text('支持的等级'), findsNothing);
        expect(find.text('自定义 Headers'), findsOneWidget);
        expect(find.text('自定义 Body'), findsOneWidget);
        expect(
          find.byKey(const Key('model-capability-divider')),
          findsOneWidget,
        );
        final header = tester.widget(
          find.byKey(const Key('model-thinking-controls')),
        );
        expect(header, isA<Row>());
        final segments = find.descendant(
          of: find.byKey(const Key('context-presets')),
          matching: find.byType(TextButton),
        );
        expect(tester.getSize(segments.first).height, greaterThanOrEqualTo(28));
        final advanced = tester.widget<TextButton>(
          find.byKey(const Key('service-model-parameters-$_id')),
        );
        final colors = Theme.of(
          tester.element(find.byType(ModelConfigurationCard)),
        ).colorScheme;
        final advancedInk = advanced.style!.foregroundColor!.resolve({})!;
        final luminance = advancedInk.computeLuminance();
        final mainLuminance = colors.onSurface.computeLuminance();
        final mutedLuminance = colors.onSurfaceVariant.computeLuminance();
        expect(
          luminance,
          greaterThan(
            mainLuminance < mutedLuminance ? mainLuminance : mutedLuminance,
          ),
        );
        expect(
          luminance,
          lessThan(
            mainLuminance > mutedLuminance ? mainLuminance : mutedLuminance,
          ),
        );
        expect(container.read(promptAssistantConfigProvider).encode(), before);
        await harness.capture(tester, 'restored-height-${entry.$3}-advanced');
        if (entry.$3 == 'regular') {
          final square = find.byKey(const ValueKey('capability-box-原生网络搜索'));
          final mouse = await tester.createGesture(
            kind: ui.PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(square));
          await tester.pump();
          await harness.capture(tester, 'restored-height-capability-hover');
          await tester.tap(square);
          await tester.pumpAndSettle();
          await harness.capture(tester, 'restored-height-capability-selected');
          await mouse.removePointer();
        }
        await _tap(tester, 'service-model-parameters-$_id');
        expect(tester.getSize(selectedPanel).height, selectedHeight);
        expect(tester.getSize(catalogPanel).height, catalogHeight);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'visible advanced options keep the outer page and panel geometry unchanged',
    (tester) async {
      await harness.pumpManagement(
        tester,
        size: const Size(1600, 1000),
        config: _config,
      );
      final selectedPanel = find
          .ancestor(
            of: find.byKey(const Key('service-selected-list')),
            matching: find.byType(Material),
          )
          .first;
      final catalogPanel = find
          .ancestor(
            of: find.byKey(const Key('service-catalog-search')),
            matching: find.byType(Material),
          )
          .first;
      final selectedBefore = tester.getRect(selectedPanel);
      final catalogBefore = tester.getRect(catalogPanel);
      final outer = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('service-overview-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final pageBefore = outer.pixels;
      await tester.tap(find.byKey(const Key('service-model-parameters-$_id')));
      await tester.pumpAndSettle();
      _expectWholeCard(tester);
      expect(tester.getRect(selectedPanel), selectedBefore);
      expect(tester.getRect(catalogPanel), catalogBefore);
      expect(outer.pixels, pageBefore);
      expect(
        tester.getRect(find.byType(ModelConfigurationCard)).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const Key('service-overview-scroll')))
              .bottom,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advanced focus reveals a model below many preceding rows without changing their order',
    (tester) async {
      final config = _config.copyWith(
        models: [
          for (var i = 0; i < 18; i++)
            ModelConfig(
              providerId: 'deepseek',
              name: 'studio-$i',
              displayName: 'studio-$i',
            ),
          _model,
        ],
      );
      final container = await harness.pumpManagement(tester, config: config);
      final target = find.byKey(const Key('service-model-parameters-$_id'));
      final scrollable = find
          .descendant(
            of: find.byKey(const Key('service-selected-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(target, 220, scrollable: scrollable);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await harness.capture(tester, 'restored-height-later-model');
      _expectWholeCard(tester);
      final viewport = tester.getRect(
        find.byKey(const Key('service-selected-list')),
      );
      expect(tester.getRect(target).top, greaterThanOrEqualTo(viewport.top));
      expect(
        container.read(promptAssistantConfigProvider).models.map((m) => m.name),
        config.models.map((m) => m.name),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Headers and Body indicators follow nonempty content independently of expansion',
    (tester) async {
      await harness.pumpManagement(tester, config: _config);
      await _tap(tester, 'service-model-parameters-$_id');
      final colors = Theme.of(
        tester.element(find.byType(ModelConfigurationCard)),
      ).colorScheme;
      Color? background(String key) => tester
          .widget<TextButton>(find.byKey(Key(key)))
          .style!
          .backgroundColor!
          .resolve({});
      expect(background('model-custom-headers'), isNot(colors.onSurface));
      await _tap(tester, 'model-custom-headers');
      await _tap(tester, 'model-add-header');
      expect(background('model-custom-headers'), isNot(colors.onSurface));
      await tester.enterText(find.byKey(const Key('header-key-0')), 'X-Client');
      await tester.enterText(find.byKey(const Key('header-value-0')), 'Studio');
      await tester.pumpAndSettle();
      expect(background('model-custom-headers'), colors.onSurface);
      await _tap(tester, 'model-custom-headers');
      expect(find.byKey(const Key('model-headers-editor')), findsNothing);
      expect(background('model-custom-headers'), colors.onSurface);
      expect(background('model-custom-body'), isNot(colors.onSurface));
      await harness.capture(tester, 'restored-height-headers-configured');
      await _tap(tester, 'model-custom-body');
      await _tap(tester, 'model-add-body-field');
      await tester.enterText(find.byKey(const Key('body-key-0')), 'metadata');
      await tester.enterText(
        find.byKey(const Key('body-value-0')),
        '{"source":"studio"}',
      );
      await tester.pumpAndSettle();
      expect(background('model-custom-body'), colors.onSurface);
      await _tap(tester, 'model-custom-body');
      _expectWholeCard(tester);
      await harness.capture(tester, 'restored-height-both-configured');
      await _tap(tester, 'model-custom-body');
      await _tap(tester, 'body-remove-0');
      expect(background('model-custom-body'), isNot(colors.onSurface));
      expect(background('model-custom-headers'), colors.onSurface);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'square checkbox keeps hover pixels inside its icon and supports keyboard and disabled states',
    (tester) async {
      final boundaryKey = GlobalKey();
      var value = false, changes = 0, enabled = true;
      Widget host() => MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, update) => RepaintBoundary(
                key: boundaryKey,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: ModelSquareCheckbox(
                        value: value,
                        semanticLabel: '测试能力',
                        onChanged: enabled
                            ? (next) => update(() {
                                value = next;
                                changes++;
                              })
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      Future<Uint8List> pixels() async => (await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes!.buffer.asUint8List();
      }))!;
      final before = await pixels();
      final square = find.byKey(const ValueKey('capability-box-测试能力'));
      final origin = tester.getTopLeft(find.byKey(boundaryKey));
      final icon = tester.getRect(square).shift(-origin);
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(square));
      await tester.pump();
      final hovered = await pixels();
      var changedInside = 0;
      for (var y = 0; y < 80; y++) {
        for (var x = 0; x < 80; x++) {
          final index = (y * 80 + x) * 4;
          final changed = List.generate(
            4,
            (i) => before[index + i] != hovered[index + i],
          ).any((v) => v);
          if (icon.contains(Offset(x + .5, y + .5))) {
            if (changed) changedInside++;
          } else {
            expect(
              changed,
              isFalse,
              reason: 'Hover feedback escaped the square at $x,$y',
            );
          }
        }
      }
      expect(changedInside, greaterThan(0));
      expect(tester.getSize(square), const Size(18, 18));
      await tester.tap(square);
      await tester.pump();
      expect(value, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(value, isFalse);
      expect(changes, 2);
      enabled = false;
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.tap(square);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, 2);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'provider picker shows compact four-column tiles in the requested order and works in a narrow window',
    (tester) async {
      await harness.pumpManagement(tester, size: const Size(1600, 1000));
      await _tap(tester, 'service-edit-connection');
      await _tap(tester, 'service-provider-picker');
      final grid = tester.widget<SliverGrid>(
        find.byKey(const Key('provider-card-grid')),
      );
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        4,
      );
      final custom = find.byKey(
        const Key('choose-provider-openaiCompatibleChat'),
      );
      final openai = find.byKey(const Key('choose-provider-openaiResponses'));
      final anthropic = find.byKey(const Key('choose-provider-anthropic'));
      final google = find.byKey(const Key('choose-provider-gemini'));
      expect(tester.getRect(custom).top, tester.getRect(openai).top);
      expect(
        tester.getRect(openai).left,
        greaterThan(tester.getRect(custom).left),
      );
      expect(
        tester.getRect(anthropic).left,
        greaterThan(tester.getRect(openai).left),
      );
      expect(
        tester.getRect(google).left,
        greaterThan(tester.getRect(anthropic).left),
      );
      expect(
        tester.getRect(find.byKey(const Key('choose-provider-deepseek'))).top,
        greaterThan(tester.getRect(google).top),
      );
      final material = tester.widget<Material>(
        find.ancestor(of: custom, matching: find.byType(Material)).first,
      );
      expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
      expect(find.text('自定义端点'), findsOneWidget);
      expect(tester.getSize(custom).height, lessThan(75));
      await harness.capture(tester, 'restored-height-provider-picker');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.pumpManagement(
        tester,
        size: const Size(420, 680),
        scale: 1.3,
      );
      await _tap(tester, 'service-edit-connection');
      await _tap(tester, 'service-provider-picker');
      await tester.enterText(
        find.byKey(const Key('provider-search')),
        'Ollama',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('choose-provider-ollama')), findsOneWidget);
      await harness.capture(tester, 'restored-height-provider-picker-compact');
      await tester.tap(find.byKey(const Key('choose-provider-ollama')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('provider-search')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
