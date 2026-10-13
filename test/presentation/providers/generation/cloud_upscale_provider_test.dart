import 'dart:async';
import 'dart:typed_data';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import '../../wiring/generation_backend_test.dart' show SwitchingAuth;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

class _Api extends Mock implements NAIImageEnhancementApiService {}

class _Storage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(prompt: 'unrelated draft', seed: 999);
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

Uint8List _png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(CancelToken());
  });
  for (final scenario in [
    'direct',
    'account-restored',
    'new-draft-source',
    'selection-back',
    'cancel',
  ]) {
    test('direct cloud upscale: $scenario', () async {
      final api = _Api();
      final pending = Completer<Uint8List>();
      CancelToken? token;
      var requests = 0;
      when(
        () => api.upscaleImage(any(), cancelToken: any(named: 'cancelToken')),
      ).thenAnswer((call) {
        requests++;
        token = call.namedArguments[#cancelToken] as CancelToken;
        return pending.future;
      });
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(SwitchingAuth.new),
          localStorageServiceProvider.overrideWithValue(_Storage()),
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageGenerationNotifierProvider.overrideWith(_Generation.new),
          imageSaveSettingsNotifierProvider.overrideWith(_Save.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
          naiImageEnhancementApiServiceProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      final draft = container.read(generationParamsNotifierProvider);
      final image = GeneratedImage.create(_png(48, 32), width: 48, height: 32);
      container.read(authNotifierProvider);
      final task = container.read(cloudUpscaleTaskProvider.notifier);
      final work = task.start(image: image);
      final duplicate = task.start(image: image);
      expect(container.read(cloudUpscaleTaskProvider).running, isTrue);
      expect(container.read(generationParamsNotifierProvider), same(draft));
      if (scenario == 'account-restored') {
        final auth =
            container.read(authNotifierProvider.notifier) as SwitchingAuth;
        auth.changeAccount();
        auth.changeAccount('account-a');
      }
      if (scenario == 'selection-back') {
        final selection = container.read(
          generationPreviewSelectionProvider.notifier,
        );
        selection.select('another image');
        selection.clear();
      }
      if (scenario == 'new-draft-source') {
        container
            .read(generationParamsNotifierProvider.notifier)
            .setSourceImage(_png(32, 48));
      }
      final latestDraft = container.read(generationParamsNotifierProvider);
      if (scenario == 'cancel') task.cancel();
      pending.complete(_png(96, 64));
      await Future.wait([work, duplicate]);
      expect(requests, 1);
      expect(
        container.read(generationParamsNotifierProvider),
        same(latestDraft),
      );
      expect(
        container.read(imageWorkflowControllerProvider).isUpscale,
        isFalse,
      );
      expect(
        container.read(imageWorkflowControllerProvider).isToolRunning,
        isFalse,
      );
      final state = container.read(imageGenerationNotifierProvider);
      if ((scenario == 'cancel' || scenario == 'account-restored')) {
        expect(token!.isCancelled, isTrue);
        expect(state.history, isEmpty);
      } else {
        expect(state.history, hasLength(1));
        expect(state.history.single.originalBytes, orderedEquals(image.bytes));
        if (scenario == 'selection-back') {
          expect(state.displayImages, isEmpty);
          expect(container.read(generationPreviewSelectionProvider), isNull);
        } else {
          expect(state.displayImages.single.id, state.history.single.id);
        }
      }
    });
  }
}
