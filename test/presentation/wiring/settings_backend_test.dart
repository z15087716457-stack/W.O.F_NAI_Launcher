import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_maintenance.dart';
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/services/settings_gpu_probe.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/anlas_usage_metrics.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_model_download_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_accounts.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_connections.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_models.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_rag.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_system.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_upscale.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

class _SystemBrightness extends StudioSystemBrightness {
  @override
  Brightness build() => Brightness.light;
  void set(Brightness value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'fresh theme follows system brightness without writing a preference',
    () async {
      final storage = MemoryStorage();
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          studioSystemBrightnessProvider.overrideWith(_SystemBrightness.new),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(themeNotifierProvider), Brightness.light);
      (container.read(studioSystemBrightnessProvider.notifier)
              as _SystemBrightness)
          .set(Brightness.dark);
      expect(container.read(themeNotifierProvider), Brightness.dark);
      expect(storage.values[StorageKeys.studioThemeMode], isNull);
      await container.read(themeNotifierProvider.notifier).setMode('light');
      expect(container.read(themeNotifierProvider), Brightness.light);
      expect(storage.values[StorageKeys.studioThemeMode], 'light');
      (container.read(studioSystemBrightnessProvider.notifier)
              as _SystemBrightness)
          .set(Brightness.light);
      (container.read(studioSystemBrightnessProvider.notifier)
              as _SystemBrightness)
          .set(Brightness.dark);
      expect(container.read(themeNotifierProvider), Brightness.light);
      expect(storage.values[StorageKeys.studioThemeMode], 'light');
      await container.read(themeNotifierProvider.notifier).setMode('system');
      expect(container.read(themeNotifierProvider), Brightness.dark);
      expect(storage.values[StorageKeys.studioThemeMode], 'system');
    },
  );
  test('unread account facts stay null and known zero stays zero', () {
    final account = SavedAccount(
      id: 'fixture',
      email: 'name@example.invalid',
      accountType: AccountType.credentials,
      createdAt: DateTime(2026),
    );
    expect(
      settingsAccountsData([
        SettingsAccountFact(
          account: account,
          current: false,
          credentialExpired: false,
        ),
      ]),
      isA<SettingsAccountData>()
          .having((value) => value.accounts.single.anlas, 'balance', isNull)
          .having((value) => value.accounts.single.tier, 'tier', isNull),
    );
    final data = settingsAccountsData([
      SettingsAccountFact(
        account: account,
        current: true,
        credentialExpired: false,
        balance: 0,
        tier: 0,
      ),
    ]);
    expect(data.accounts.single.anlas, 0);
    expect(data.accounts.single.maskedId, isNot(contains('example.invalid')));
    expect(data.accounts.single.expired, isFalse);
    expect(
      settingsAccountsData([
        SettingsAccountFact(
          account: account.copyWith(accountType: AccountType.token),
          current: true,
          credentialExpired: false,
          balance: 8,
          tier: 3,
        ),
      ]).accounts.single.maskedId,
      isEmpty,
    );
  });

  test('all stored request languages map to the same stable task', () {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final task in LauncherInterface.values) {
        expect(
          settingsHistoryTask(task.titleIn(lookupAppLocalizations(locale))),
          task,
        );
      }
    }
    expect(settingsHistoryTask('synthetic connection test'), isNull);
  });

  test(
    'GPU capabilities use the actual first CUDA device and known threshold',
    () async {
      final info = SettingsGpuProbe.parse(
        'NVIDIA RTX A, 8192, 7.5\nNVIDIA RTX B, 24576, 8.9',
        'CUDA Version: 12.6',
      )!;
      expect(info.name, 'NVIDIA RTX A');
      expect(info.vramMb, 8192);
      expect(info.int8, isTrue);
      expect(SettingsGpuProbe.parse('old GPU, 4096, 6.1', '')!.int8, isFalse);
      expect(SettingsGpuProbe.parse('N/A,N/A,N/A', ''), isNull);
      expect(
        await SettingsGpuProbe(
          run: (_) => Future.error(StateError('no driver')),
        ).inspect(),
        isNull,
      );
    },
  );

  test(
    'RAG projection keeps disabled sources, paused jobs and unread runtime honest',
    () {
      final data = settingsRagData(
        const RagSettings(enabled: true, galleryEnabled: true),
        const RagStatus(
          indexed: 2,
          total: 8,
          phase: 'paused',
          sources: {
            RagSource.gallery: RagStatus(
              indexed: 9,
              total: 12,
              phase: 'building',
              busy: true,
              details: {
                'images': 5,
                'visual_indexed': 3,
                'parameters_indexed': 6,
                'skipped': 1,
              },
            ),
          },
        ),
        const AsyncData(RagRuntimeInfo(python: 'fixture-python', ready: false)),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
        indexBytes: 123,
      );
      expect(data.runtimeReady, isFalse);
      expect(data.runtime.tone, SettingsTone.idle);
      expect(data.sources.first.state, SettingsRagState.paused);
      expect(data.sources[1].state, SettingsRagState.off);
      expect(data.sources.last.done, 3);
      expect(data.sources.last.secondary, 6);
      expect(data.sources.last.skipped, 1);
      expect(data.indexBytes, 123);
      expect(data.busy, isTrue);
    },
  );

  test(
    'RAG verification is ready at full progress, real writes stay building',
    () {
      SettingsRagState project(RagStatus status) => settingsRagData(
        const RagSettings(enabled: true),
        status,
        const AsyncData(RagRuntimeInfo(python: 'fixture', ready: true)),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
      ).sources.first.state;
      expect(
        project(
          const RagStatus(busy: true, phase: 'checking', indexed: 8, total: 8),
        ),
        SettingsRagState.ready,
      );
      final writing = settingsRagData(
        const RagSettings(enabled: true),
        const RagStatus(
          busy: true,
          phase: 'building',
          indexed: 8,
          total: 8,
          processed: 3,
        ),
        const AsyncData(RagRuntimeInfo(python: 'fixture', ready: true)),
        const RagModelDownloadState(),
        const SettingsRagSessionState(),
        null,
      );
      expect(writing.sources.first.done, 3);
      expect(writing.indexBusy, true);
      expect(writing.busy, true);
      expect(
        project(
          const RagStatus(busy: true, phase: 'checking', indexed: 4, total: 8),
        ),
        SettingsRagState.loading,
      );
      // A same-count digest change is still a real incremental write.
      expect(
        project(
          const RagStatus(busy: true, phase: 'building', indexed: 8, total: 8),
        ),
        SettingsRagState.building,
      );
      expect(
        project(const RagStatus(phase: 'ready', indexed: 8, total: 8)),
        SettingsRagState.ready,
      );
    },
  );

  test(
    'all upscale variants retain manager IDs and per-model offload bounds',
    () {
      const workflow = UpscaleWorkflowSettings(localModel: 'seedvr2-7b-int8');
      final data = settingsUpscaleData(
        [...localUpscaleCatalog, ...advancedUpscaleCatalog],
        const SettingsUpscaleOperation(
          id: 'anime-fast',
          received: 20,
          total: 100,
        ),
        const AdvancedUpscaleInstallState(),
        workflow,
      );
      expect(data.seed, hasLength(6));
      expect(data.seedOffloadMaxBlocks, 36);
      expect(
        data.seed.where((model) => model.isDefault).single.id,
        'seedvr2-7b-int8',
      );
      expect(
        data.esrgan.firstWhere((model) => model.id == 'animeFast').received,
        20,
      );
      expect(settingsUpscaleId('seed7bSharp'), 'seedvr2-7b-sharp');
      expect(settingsUpscaleId('custom-fixture'), 'custom-fixture');
    },
  );

  test('model sizes stay fixed independently of transfer totals and state', () {
    const model = LocalUpscaleModel(
      id: 'general',
      name: 'General',
      engineName: 'general',
      scales: [4],
      modelBytes: 33540549,
    );
    for (final installed in [false, true]) {
      for (final total in [0, -1, 75000000]) {
        for (final failed in [false, true]) {
          final data = settingsUpscaleData(
            [
              model.withInstalled(
                installed,
                diskBytes: installed ? 40000000 : 0,
              ),
            ],
            SettingsUpscaleOperation(
              id: failed ? null : model.id,
              received: 37500000,
              total: total,
              failedId: failed ? model.id : null,
            ),
            const AdvancedUpscaleInstallState(),
            const UpscaleWorkflowSettings(),
          ).esrgan.single;
          expect(data.bytes, 33540549);
          expect(data.total, failed ? 0 : total);
          expect(data.received, failed ? 0 : 37500000);
        }
      }
    }
  });

  test(
    'directory measurement reads bytes without following external links',
    () async {
      final root = await Directory.systemTemp.createTemp('settings-measure-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/image.png').writeAsBytes([1, 2, 3]);
      await File('${root.path}/secret.txt').writeAsBytes([1, 2, 3, 4]);
      await Directory('${root.path}/.thumbs').create();
      await File('${root.path}/.thumbs/test.thumb.jpg').writeAsBytes([1, 2]);
      try {
        await Link('${root.path}/loop').create(root.path);
      } on FileSystemException {
        /* Windows may disallow symlinks. */
      }
      final measured = settingsMeasureDirectory(root.path, gallery: true);
      expect(measured.bytes, 3);
      expect(measured.thumbs, 2);
      expect(measured.images, 1);
      expect(await File('${root.path}/secret.txt').length(), 4);
    },
  );

  test(
    'endpoint check strips query keys and sends no account authorization',
    () async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seen = Completer<HttpRequest>();
      final subscription = server.listen((request) async {
        seen.complete(request);
        request.response.statusCode =
            HttpStatus.forbidden; // Reachable, authentication is not tested.
        await request.response.close();
      });
      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await subscription.cancel();
        await server.close(force: true);
      });
      final probe = container.read(settingsEndpointProbeProvider);
      final latency = await probe(
        Uri.parse('http://127.0.0.1:${server.port}/api?key=synthetic-secret'),
        null,
      );
      final request = await seen.future.timeout(const Duration(seconds: 3));
      expect(latency, greaterThanOrEqualTo(0));
      expect(request.method, 'HEAD');
      expect(request.uri.toString(), '/');
      expect(request.headers.value(HttpHeaders.authorizationHeader), isNull);
      await expectLater(
        probe(Uri.parse('https://secret:secret@example.invalid'), null),
        throwsFormatException,
      );
    },
  );

  test('diagnostics are an explicit factual allowlist', () {
    final decoded =
        jsonDecode(
              settingsDiagnostics(
                version: 'fixture',
                os: 'Windows',
                runtime: 'Dart',
                ragEnabled: true,
                indexed: 2,
                runtimeReady: false,
                providers: 3,
              ),
            )
            as Map;
    expect(decoded.keys.toSet(), {
      'version',
      'os',
      'runtime',
      'rag',
      'providers',
    });
    expect((decoded['rag'] as Map).keys.toSet(), {
      'enabled',
      'indexed',
      'runtimeReady',
    });
  });

  test(
    'maintenance claims are synchronous and old releases cannot unlock a new owner',
    () {
      final gate = RagMaintenance();
      final release = gate.claim();
      expect(() => gate.claim(), throwsA(isA<Exception>()));
      release();
      final second = gate.claim();
      release();
      expect(gate.busy, isTrue);
      second();
      expect(gate.busy, isFalse);
      expect(() => gate.claim(indexBusy: true), throwsA(isA<Exception>()));
    },
  );

  test(
    'usage details serialize concurrent records without inventing old hours',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(anlasUsageMetricsProvider.notifier);
      expect(
        (await container.read(anlasUsageMetricsProvider.future)).hourly,
        isEmpty,
      );
      await Future.wait([
        store.record(cost: 5),
        store.record(cost: 8),
        store.record(warning: true),
      ]);
      final metrics = container.read(anlasUsageMetricsProvider).requireValue;
      expect(metrics.hourly.reduce((a, b) => a + b), 13);
      expect(metrics.maxDeduction, 8);
      expect(metrics.warnings, 1);
      expect(
        AnlasUsageMetrics.decode(jsonEncode(metrics.toJson())).hourly,
        metrics.hourly,
      );
      expect(
        metrics.at(DateTime.now().add(const Duration(days: 1))).hourly,
        isEmpty,
      );
    },
  );
}
