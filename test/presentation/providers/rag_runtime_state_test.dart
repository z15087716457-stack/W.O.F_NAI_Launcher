import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_model_download_provider.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag.dart';

class _Settings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(python: 'selected-python.exe');
}

class _Probe extends RagRuntimeProbe {
  int calls = 0;
  @override
  Future<RagRuntimeInfo> inspect(Directory root, String preferred) async {
    calls++;
    return RagRuntimeInfo(python: preferred, ready: true);
  }
}

void main() {
  test(
    'leaving and reopening settings reuses the interpreter probe; explicit recheck still runs',
    () async {
      final probe = _Probe();
      final container = ProviderContainer(
        overrides: [
          ragSettingsProvider.overrideWith(_Settings.new),
          ragRuntimeProbeFactoryProvider.overrideWithValue(() => probe),
          ragDirectoryProvider.overrideWithValue(
            () async => Directory.systemTemp,
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(ragRuntimeInfoProvider, (_, __) {});
      expect(
        (await container.read(ragRuntimeInfoProvider.future)).ready,
        isTrue,
      );
      subscription.close();
      await container.pump();
      expect(
        (await container.read(ragRuntimeInfoProvider.future)).ready,
        isTrue,
      );
      expect(probe.calls, 1);
      container.invalidate(ragRuntimeInfoProvider);
      await container.read(ragRuntimeInfoProvider.future);
      expect(probe.calls, 2);
    },
  );

  test(
    'pending probe preserves an active worker and selected path, but an explicit failed probe stays failed',
    () {
      const settings = RagSettings(python: 'selected-python.exe');
      const status = RagStatus(runtimeReady: true);
      final pending = settingsRagData(
        settings,
        status,
        const AsyncLoading(),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
      );
      expect(pending.checking, isTrue);
      expect(pending.runtimeReady, isTrue);
      expect(pending.runtime.value, 'selected-python.exe');
      final failed = settingsRagData(
        settings,
        status,
        const AsyncData(
          RagRuntimeInfo(python: 'selected-python.exe', ready: false),
        ),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
      );
      expect(failed.runtimeReady, isFalse);
    },
  );
  test(
    'startup projection distinguishes unread, empty, reconnecting and failed indexes',
    () {
      const settings = RagSettings(enabled: true, wikiEnabled: true);
      SettingsRagData project(RagStatus status) => settingsRagData(
        settings,
        status,
        const AsyncData(RagRuntimeInfo(python: 'fixture', ready: true)),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
      );
      final unread = project(const RagStatus());
      expect(unread.initializing, isTrue);
      expect(unread.progressKnown, isFalse);
      expect(unread.sources.first.state, SettingsRagState.loading);
      expect(unread.sources.first.known, isFalse);
      final empty = project(
        const RagStatus(
          indexKnown: true,
          sources: {RagSource.wiki: RagStatus(indexKnown: true)},
        ),
      );
      expect(empty.initializing, isFalse);
      expect(empty.progressKnown, isTrue);
      expect(empty.sources.first.state, SettingsRagState.empty);
      final reconnect = project(
        const RagStatus(
          initializing: true,
          indexKnown: true,
          indexed: 12,
          total: 20,
        ),
      );
      expect(reconnect.sources.first.state, SettingsRagState.loading);
      expect(reconnect.sources.first.done, 12);
      expect(reconnect.sources.first.known, isTrue);
      final failed = project(
        const RagStatus(
          phase: 'error',
          error: 'initialization_timeout',
          sources: {
            RagSource.wiki: RagStatus(
              phase: 'error',
              error: 'initialization_timeout',
            ),
          },
        ),
      );
      expect(failed.initializing, isFalse);
      expect(failed.sources.first.state, SettingsRagState.error);
      expect(failed.progressKnown, isFalse);
    },
  );
}
