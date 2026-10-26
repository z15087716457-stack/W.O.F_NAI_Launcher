import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/comfyui/comfyui_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_tool_panel.dart';

class _Api extends Mock implements NAIImageEnhancementApiService {}

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(prompt: 'user draft', width: 832, height: 1216);
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Save extends ImageSaveSettingsNotifier {
  @override
  ImageSaveSettings build() => const ImageSaveSettings(autoSave: false);
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.initial();
  @override
  void schedulePostBillingRefresh({Duration delay = Duration.zero}) {}
}

class _Models extends ComfyUISeedvr2Models {
  @override
  List<String> build() => const [];
  @override
  Future<void> fetch({bool force = false}) async {}
}

class _ComfySettings extends ComfyUISettings {
  @override
  ComfyUISettingsState build() => const ComfyUISettingsState();
}

Uint8List _png(int width, int height) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: height)));

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(CancelToken());
  });
  for (final fail in [false, true]) {
    testWidgets(
      'cloud tool ${fail ? 'failure allows retry' : 'success registers an image'} and close restores the draft',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(920, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final api = _Api();
        final pending = Completer<Uint8List>();
        when(
          () => api.upscaleImage(
            any(),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) => pending.future);
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => _Storage()),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            naiImageEnhancementApiServiceProvider.overrideWithValue(api),
            imageSaveSettingsNotifierProvider.overrideWith(_Save.new),
            subscriptionNotifierProvider.overrideWith(_Subscription.new),
            comfyUISeedvr2ModelsProvider.overrideWith(_Models.new),
            comfyUISettingsProvider.overrideWith(_ComfySettings.new),
          ],
        );
        addTearDown(container.dispose);
        final original = container.read(generationParamsNotifierProvider);
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final source = _png(64, 96);
        controller.openTemporaryTool(source, ImageWorkflowMode.upscale);
        controller.updateUpscaleBackend(UpscaleBackend.novelai);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              locale: Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: GenerationToolPanel()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('开始超分'));
        await tester.pump();
        expect(
          container.read(imageWorkflowControllerProvider).isToolRunning,
          isTrue,
        );
        final close = find.descendant(
          of: find.byKey(const Key('generation-tool-surface')),
          matching: find.byTooltip('关闭'),
        );
        expect(
          tester
              .widget<IconButton>(
                find.ancestor(of: close, matching: find.byType(IconButton)),
              )
              .onPressed,
          isNull,
        );
        if (fail) {
          pending.completeError(StateError('fixture server unavailable'));
        } else {
          pending.complete(_png(128, 192));
        }
        // 结果登记会在后台 isolate 里算哈希/解析元数据（N03），给真实时间跑完。
        for (var i = 0; i < 50; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
          if (!container.read(imageWorkflowControllerProvider).isToolRunning) {
            break;
          }
        }
        await tester.pumpAndSettle();
        expect(
          container.read(imageWorkflowControllerProvider).isToolRunning,
          isFalse,
        );
        final result = container.read(imageGenerationNotifierProvider);
        if (fail) {
          expect(result.history, isEmpty);
          expect(
            find.textContaining('fixture server unavailable'),
            findsOneWidget,
          );
        } else {
          expect(result.history, hasLength(1));
          expect(result.currentImages.single.width, 128);
          expect(result.currentImages.single.height, 192);
          expect(result.currentImages.single.operation, ImageOperation.upscale);
          expect(
            result.currentImages.single.originalBytes,
            orderedEquals(source),
          );
        }
        verify(
          () => api.upscaleImage(
            any(that: orderedEquals(source)),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(
          container.read(generationParamsNotifierProvider).prompt,
          original.prompt,
        );
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        expect(
          container.read(generationParamsNotifierProvider).width,
          original.width,
        );
        expect(
          container.read(generationParamsNotifierProvider).height,
          original.height,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
