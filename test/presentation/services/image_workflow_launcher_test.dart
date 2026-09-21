import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/services/image_workflow_launcher.dart';

class _Generation extends ImageGenerationNotifier {
  _Generation(this.busy);
  final bool busy;
  @override
  ImageGenerationState build() => ImageGenerationState(
    status: busy ? GenerationStatus.generating : GenerationStatus.idle,
    generationRunId: 12,
  );
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(prompt: 'user draft', seed: 42);
}

class _Bridge extends KritaBridgeNotifier {
  _Bridge(bool busy) {
    state = KritaBridgeState(activeRequestId: busy ? 'request' : null);
  }
}

class _Cooldown extends GenerationCooldownNotifier {
  _Cooldown(this.active);
  final bool active;
  @override
  GenerationCooldownState build() =>
      GenerationCooldownState(remainingSeconds: active ? 5 : 0);
}

void main() {
  for (final gate in ['generation', 'bridge', 'cooldown']) {
    testWidgets(
      '$gate blocks variations before changing any draft or workflow',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(
              () => _Generation(gate == 'generation'),
            ),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => _Bridge(gate == 'bridge'),
            ),
            generationCooldownProvider.overrideWith(
              () => _Cooldown(gate == 'cooldown'),
            ),
          ],
        );
        addTearDown(container.dispose);
        final params = container.read(generationParamsNotifierProvider);
        final workflow = container.read(imageWorkflowControllerProvider);
        final generation = container.read(imageGenerationNotifierProvider);
        late Future<void> Function() invoke;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    invoke = () => ImageWorkflowLauncher.generateVariations(
                      context,
                      ref,
                      Uint8List(0),
                    );
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
        await invoke();
        await invoke();
        expect(container.read(generationParamsNotifierProvider), same(params));
        expect(container.read(imageWorkflowControllerProvider), same(workflow));
        expect(
          container.read(imageGenerationNotifierProvider),
          same(generation),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }
}
