import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_tool_panel.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _Storage extends LocalStorageService {
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

void main() {
  for (final size in [const Size(920, 640), const Size(320, 480)]) {
    testWidgets(
      'enhance floating controls fit $size and close restores the draft',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Storage()),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            generationParamsNotifierProvider.overrideWith(_Params.new),
          ],
        );
        addTearDown(container.dispose);
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        controller.openTemporaryTool(
          Uint8List.fromList(
            img.encodePng(img.Image(width: 832, height: 1216)),
          ),
          ImageWorkflowMode.enhance,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              locale: Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: GenerationToolPanel()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1.5x'), findsOneWidget);
        await tester.tap(find.text('显示高级设置'));
        await tester.pumpAndSettle();
        expect(find.byType(Slider), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('关闭'));
        await tester.pumpAndSettle();
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        expect(find.byType(Slider), findsNothing);
      },
    );
  }
}
