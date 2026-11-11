import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/advanced_upscale_component_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_model_manager.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_upscale.dart';

class _PendingInstall extends AdvancedUpscaleComponentManager {
  final cancelled = Completer<void>();
  final released = Completer<void>();
  @override
  Future<void> install(
    String id, {
    required LocalUpscaleCancellation cancellation,
    void Function(AdvancedUpscaleProgress)? onProgress,
  }) async {
    final remove = cancellation.listen(() => cancelled.complete());
    try {
      onProgress?.call(const AdvancedUpscaleProgress('runtime'));
      await released.future;
      cancellation.check();
    } finally {
      remove();
    }
  }
}

class _FailedInstall extends AdvancedUpscaleComponentManager {
  @override
  Future<void> install(
    String id, {
    required LocalUpscaleCancellation cancellation,
    void Function(AdvancedUpscaleProgress)? onProgress,
  }) async {
    onProgress?.call(const AdvancedUpscaleProgress('runtime'));
    throw const LocalUpscaleException(
      LocalUpscaleError.modelOperationFailed,
      details:
          'uv pip failed: https://user:private@example.test/wheel?token=private',
    );
  }
}

void main() {
  test(
    'failed installation keeps phase and sanitized details after releasing locks',
    () async {
      final manager = _FailedInstall();
      final base = LocalUpscaleModelManager();
      final container = ProviderContainer(
        overrides: [
          advancedUpscaleComponentManagerProvider.overrideWithValue(manager),
          localUpscaleModelManagerProvider.overrideWithValue(base),
        ],
      );
      addTearDown(() {
        container.dispose();
        manager.dispose();
        base.dispose();
      });
      await expectLater(
        container
            .read(settingsUpscaleOperationProvider.notifier)
            .install('seed3b'),
        throwsA(isA<LocalUpscaleException>()),
      );
      final state = container.read(advancedUpscaleInstallProvider);
      expect(state.running, isFalse);
      expect(state.phase, 'runtime');
      expect(state.error, LocalUpscaleError.modelOperationFailed);
      expect(
        state.details,
        allOf(contains('uv pip failed'), isNot(contains('private'))),
      );
      final settings = container.read(settingsUpscaleOperationProvider);
      expect(settings.failedId, 'seedvr2-3b');
      expect(settings.failedPhase, 'runtime');
      expect(settings.error?.details, state.details);
      base.claimInference('anime');
      base.releaseInference();
    },
  );

  test(
    'tray shutdown cancels component installation and waits for owned runtime cleanup',
    () async {
      final manager = _PendingInstall();
      final base = LocalUpscaleModelManager();
      final container = ProviderContainer(
        overrides: [
          advancedUpscaleComponentManagerProvider.overrideWithValue(manager),
          localUpscaleModelManagerProvider.overrideWithValue(base),
        ],
      );
      addTearDown(() {
        container.dispose();
        manager.dispose();
        base.dispose();
      });
      final task = container.read(advancedUpscaleInstallProvider.notifier);
      final work = task.install('seedvr2-3b');
      expect(container.read(advancedUpscaleInstallProvider).phase, 'runtime');
      expect(
        () => base.claimInference('anime'),
        throwsA(
          isA<LocalUpscaleException>().having(
            (e) => e.code,
            'code',
            LocalUpscaleError.busy,
          ),
        ),
      );
      var done = false;
      final shutdown = DesktopAppShutdownService.prepareBackgroundShutdown();
      unawaited(shutdown.then((_) => done = true));
      await manager.cancelled.future;
      expect(done, isFalse);
      expect(container.read(advancedUpscaleInstallProvider).running, isTrue);
      manager.released.complete();
      await work;
      await shutdown;
      expect(done, isTrue);
      expect(container.read(advancedUpscaleInstallProvider).running, isFalse);
      expect(
        container.read(advancedUpscaleInstallProvider).error,
        LocalUpscaleError.cancelled,
      );
      base.claimInference('anime');
      base.releaseInference();
    },
  );
}
