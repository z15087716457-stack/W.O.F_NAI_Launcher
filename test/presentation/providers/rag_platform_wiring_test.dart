import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/presentation/providers/rag_model_download_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag.dart';
import 'package:path/path.dart' as p;

class _Settings extends RagSettingsController {
  _Settings([this.device = RagDevice.auto]);
  final RagDevice device;
  @override
  RagSettings build() => RagSettings(
    enabled: true,
    tagsEnabled: false,
    wikiEnabled: true,
    embedding: 'embedding',
    reranker: 'reranker',
    device: device,
  );
}

/// A worker that only answers configure / status and records configure.
class _Worker implements Process {
  _Worker() {
    _output.add(
      utf8.encode('${jsonEncode({'event': 'ready', 'protocol': 1})}\n'),
    );
    _input.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final request = (jsonDecode(line) as Map).cast<String, dynamic>();
          switch (request['op']) {
            case 'configure':
              if (!configured.isCompleted) {
                configured.complete(
                  (request['params'] as Map).cast<String, dynamic>(),
                );
              }
              _reply(request['id']);
            case 'status':
              _reply(request['id']);
            case 'shutdown':
              _exit();
          }
        }, onDone: _exit);
  }
  final _input = StreamController<List<int>>();
  final _output = StreamController<List<int>>();
  final _exitCode = Completer<int>();
  final configured = Completer<Map<String, dynamic>>();
  late final IOSink _stdin = IOSink(_input.sink);
  void _reply(Object? id) => _output.add(
    utf8.encode(
      '${jsonEncode({
        'id': id,
        'result': {'sources': {}, 'jobs': []},
      })}\n',
    ),
  );
  void _exit() {
    if (_exitCode.isCompleted) return;
    _exitCode.complete(0);
    unawaited(_output.close());
  }

  @override
  IOSink get stdin => _stdin;
  @override
  Stream<List<int>> get stdout => _output.stream;
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => _exitCode.future;
  @override
  int get pid => 9;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _exit();
    return true;
  }
}

void main() {
  test('settings project the platform and whether it can install', () {
    SettingsRagData project(RagPlatform platform) => settingsRagData(
      const RagSettings(),
      const RagStatus(),
      const AsyncLoading(),
      const RagModelDownloadState(),
      const SettingsRagSessionState(),
      null,
      platform: platform,
    );
    final windows = project(RagPlatform.windows);
    expect(windows.platform, SettingsRagPlatform.windows);
    expect((windows.runtimeSupported, windows.cudaSupported), (true, true));
    final arm = project(RagPlatform.macOSArm64);
    expect(arm.platform, SettingsRagPlatform.macOS);
    expect((arm.runtimeSupported, arm.cudaSupported), (true, false));
    final intel = project(RagPlatform.macOSX64);
    expect(intel.platform, SettingsRagPlatform.macOS);
    expect((intel.runtimeSupported, intel.cudaSupported), (false, false));
  });

  for (final (platform, layout) in [
    (RagPlatform.windows, ['runtime', 'Scripts', 'python.exe']),
    (RagPlatform.macOSArm64, ['runtime', 'bin', 'python3']),
  ]) {
    test(
      '${platform.name} opens the managed interpreter of its venv',
      () async {
        final root = await Directory.systemTemp.createTemp('rag-platform-');
        addTearDown(() => root.delete(recursive: true));
        final managed = p.joinAll([root.path, ...layout]);
        File(managed).createSync(recursive: true);
        final started = <String>{};
        final container = ProviderContainer(
          overrides: [
            ragPlatformProvider.overrideWithValue(platform),
            ragSettingsProvider.overrideWith(_Settings.new),
            ragDirectoryProvider.overrideWithValue(() async => root),
            ragSourcePathsProvider.overrideWithValue(
              () async => (catalog: '', runtime: '', wiki: ''),
            ),
            ragClientStarterProvider.overrideWithValue(({
              required python,
              required directory,
            }) async {
              started.add(python);
              throw const RagException('fixture_stop');
            }),
          ],
        );
        addTearDown(container.dispose);
        expect(
          container.read(ragRuntimeProbeFactoryProvider)().platform,
          platform,
        );
        await container.read(ragControllerProvider.notifier).refresh();
        expect(started, {managed});
      },
    );
  }

  for (final (platform, memory, device, sent) in [
    (RagPlatform.macOSArm64, 16 << 30, RagDevice.auto, 'cpu'),
    (RagPlatform.macOSArm64, null, RagDevice.auto, 'cpu'),
    (RagPlatform.macOSArm64, 18 << 30, RagDevice.auto, 'auto'),
    (RagPlatform.macOSArm64, 96 << 30, RagDevice.cpu, 'cpu'),
    (RagPlatform.windows, 8 << 30, RagDevice.auto, 'auto'),
    (RagPlatform.windows, 8 << 30, RagDevice.cuda, 'cuda'),
  ]) {
    test(
      '${platform.name} with ${memory == null ? 'unknown' : '${memory >> 30} GB'} '
      'sends ${device.name} as $sent',
      () async {
        final root = await Directory.systemTemp.createTemp('rag-device-');
        addTearDown(() => root.delete(recursive: true));
        File(platform.managedPython(root.path)).createSync(recursive: true);
        final worker = _Worker();
        final container = ProviderContainer(
          overrides: [
            ragPlatformProvider.overrideWithValue(platform),
            ragPhysicalMemoryProvider.overrideWithValue(memory),
            ragSettingsProvider.overrideWith(() => _Settings(device)),
            ragDirectoryProvider.overrideWithValue(() async => root),
            ragSourcePathsProvider.overrideWithValue(
              () async => (catalog: '', runtime: '', wiki: ''),
            ),
            ragClientStarterProvider.overrideWithValue(
              ({required python, required directory}) async =>
                  RagClient(worker, shutdownTimeout: Duration.zero),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(ragControllerProvider.notifier).refresh();
        final params = await worker.configured.future.timeout(
          const Duration(seconds: 10),
        );
        expect(params['device'], sent);
      },
    );
  }
}
