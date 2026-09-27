import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/precise_reference_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/decoded_memory_image.dart';
import 'package:nai_launcher/presentation/widgets/common/hover_image_preview.dart';

class _ReferenceParams extends GenerationParamsNotifier {
  _ReferenceParams(this.image);

  final Uint8List image;

  @override
  ImageParams build() => ImageParams(
    model: 'nai-diffusion-4-5-full',
    preciseReferences: [
      PreciseReference(image: image, type: PreciseRefType.character),
    ],
  );
}

void main() {
  group('PreciseReferencePanel', () {
    testWidgets('small reference image decodes for square cover', (
      tester,
    ) async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 300, height: 500)),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            generationParamsNotifierProvider.overrideWith(
              () => _ReferenceParams(bytes),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(width: 320, child: PreciseReferencePanel()),
            ),
          ),
        ),
      );
      tester
          .widget<CollapsibleImagePanel>(find.byType(CollapsibleImagePanel))
          .onToggle();
      await tester.pumpAndSettle();

      final image = tester.widget<DecodedMemoryImage>(
        find.descendant(
          of: find.byType(HoverImagePreview),
          matching: find.byType(DecodedMemoryImage),
        ),
      );
      expect(identical(image.bytes, bytes), isTrue);
      expect(image.decodeForCover, isTrue);
      expect(image.filterQuality, FilterQuality.medium);
      expect(image.maxLogicalWidth, 56);
      expect(image.maxLogicalHeight, 56);
    });

    for (final top in [0.0, 310.0]) {
      testWidgets('头部 + 菜单锚定并在边缘避让，overlay 内 top=$top', (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.binding.setSurfaceSize(const Size(800, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // 内层 Navigator 产生一个相对窗口有 (140, 120) 偏移的 Overlay。
        // 回归场景：showMenu 的 position 必须在该 overlay 坐标系内，
        // 否则菜单会按全局坐标被解释而整体向右下方漂移。
        // Overlay 留足右缘空间，避免菜单触边回弹掩盖坐标系错误。
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.only(left: 140, top: 120),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 500,
                      height: 400,
                      child: Navigator(
                        onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (_) => Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: top),
                              child: const SizedBox(
                                width: 320,
                                child: PreciseReferencePanel(),
                              ),
                            ),
                          ),
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

        final addButton = find.byKey(const Key('precise-ref-panel-add-menu'));
        expect(addButton, findsOneWidget);
        final buttonRight = tester.getTopRight(addButton).dx;
        final buttonBottomLeft = tester.getBottomLeft(addButton);

        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // 两个菜单项都存在
        final libraryItem = find.byKey(
          const Key('precise-ref-panel-from-library'),
        );
        expect(libraryItem, findsOneWidget);
        final addItem = find.widgetWithText(PopupMenuItem<String>, '添加参考图');
        expect(addItem, findsOneWidget);

        // 菜单右缘与按钮右缘对齐、顶部位于按钮正下方，
        // 而不是被 overlay 偏移量 (140, 120) 带跑
        final itemTopLeft = tester.getTopLeft(addItem);
        expect(
          (tester.getTopRight(addItem).dx - buttonRight).abs(),
          lessThan(2),
          reason: '菜单应水平锚定在 + 按钮处',
        );
        if (top == 0) {
          expect(itemTopLeft.dy, greaterThanOrEqualTo(buttonBottomLeft.dy));
          expect(itemTopLeft.dy, lessThan(buttonBottomLeft.dy + 20));
        } else {
          expect(
            tester.getBottomRight(libraryItem).dy,
            lessThanOrEqualTo(520 - 8),
          );
          expect((itemTopLeft.dy - buttonBottomLeft.dy).abs(), lessThan(112));
        }

        // 菜单项可点击：点“添加参考图”应打开类型选择对话框
        await tester.tap(addItem);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(libraryItem, findsNothing);

        // 关掉类型选择对话框
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
