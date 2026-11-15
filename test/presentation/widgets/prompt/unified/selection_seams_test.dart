import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';
import 'package:nai_launcher/presentation/widgets/common/continuous_text_selection.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';

import '../../../../helpers/studio_capture_fonts.dart';

class _Settings extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
}

const _source =
    'A gameplay screenshot from a beautiful Japanese post-apocalyptic fantasy RPG '
    'about a lonely journey through a vast ancient world of colossal ruins '
    'reclaimed by nature. The girl is tiny against the enormous landscape. '
    'The game HUD is clean and minimal: thin white lines, small sans-serif '
    'labels, semi-transparent dark navy panels. Persistent HUD in the corners: '
    'a small circular radar minimap in the top left with a white arrow at its center.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 1.3, 1.5]) {
      for (final annotated in [false, true]) {
        testWidgets(
          'long source selection has no seams $brightness scale=$scale annotated=$annotated',
          (t) async {
            final source = TextEditingController(text: _source),
                focus = FocusNode();
            final capture = GlobalKey();
            await t.binding.setSurfaceSize(const Size(320, 1600));
            addTearDown(() => t.binding.setSurfaceSize(null));
            addTearDown(source.dispose);
            addTearDown(focus.dispose);
            await t.pumpWidget(
              ProviderScope(
                overrides: [
                  localStorageServiceProvider.overrideWithValue(_Settings()),
                ],
                child: MaterialApp(
                  theme: AppTheme.getTheme(AppStyle.geist, brightness),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (_, child) => RepaintBoundary(
                    key: capture,
                    child: UiScale(scale: scale, child: child!),
                  ),
                  home: Scaffold(
                    body: UnifiedPromptInput(
                      controller: source,
                      focusNode: focus,
                      fitContent: true,
                      readings: [
                        if (annotated)
                          const PromptReading(
                            start: 0,
                            end: _source.length,
                            source: _source,
                            translation: '完整译文位于原文下方，不进入蓝色选区。',
                            perSegment: true,
                          ),
                      ],
                      textStyle: const TextStyle(fontSize: 14, height: 1.55),
                      config: UnifiedPromptConfig(
                        embedded: true,
                        enableAutoFormat: false,
                        // Main/character editors always supply a pill builder, even
                        // when the current document only contains plain source text.
                        pillBuilder: (_, __, ___) => null,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pump();
            focus.requestFocus();
            source.selection = const TextSelection(
              baseOffset: 0,
              extentOffset: _source.length,
            );
            await t.pump();
            await t.pump();
            final editable = t
                .state<EditableTextState>(find.byType(EditableText))
                .renderEditable;
            final bounds = <double, Rect>{};
            for (final box in editable.getBoxesForSelection(
              editable.selection!,
            )) {
              bounds.update(
                box.top,
                (r) => r.expandToInclude(box.toRect()),
                ifAbsent: () => box.toRect(),
              );
            }
            final lines = bounds.values.toList()
              ..sort((a, b) => a.top.compareTo(b.top));
            expect(lines.length, greaterThanOrEqualTo(10));
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final transform = editable.getTransformTo(boundary);
            final context = t.element(find.byType(ContinuousTextSelection));
            final expected = Color.alphaBlend(
              DefaultSelectionStyle.of(context).selectionColor!,
              Theme.of(context).scaffoldBackgroundColor,
            );
            final channels = [
              (expected.r * 255).round(),
              (expected.g * 255).round(),
              (expected.b * 255).round(),
            ];
            await t.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              final bytes = data!.buffer.asUint8List();
              for (var i = 1; i < lines.length - 1; i++) {
                final point = MatrixUtils.transformPoint(
                  transform,
                  Offset(
                    math.max(lines[i - 1].left, lines[i].left) + 3,
                    (lines[i - 1].bottom + lines[i].top) / 2,
                  ),
                );
                final at =
                    (point.dy.floor() * image.width + point.dx.floor()) * 4;
                for (var channel = 0; channel < 3; channel++) {
                  expect(
                    bytes[at + channel],
                    closeTo(channels[channel], 1),
                    reason:
                        'Solid selection fill across source rows ${i - 1} and $i',
                  );
                }
              }
              if (annotated) {
                final caption = t.getRect(
                  find.byKey(const ValueKey('prompt-reading-0')),
                );
                final local = boundary.globalToLocal(caption.center);
                final at = (local.dy.floor() * image.width + 1) * 4;
                final background = Theme.of(context).scaffoldBackgroundColor;
                expect(bytes[at], closeTo((background.r * 255).round(), 1));
                expect(bytes[at + 1], closeTo((background.g * 255).round(), 1));
                expect(bytes[at + 2], closeTo((background.b * 255).round(), 1));
              }
              image.dispose();
            });
            expect(source.text, _source);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
