import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';

const _worker = r'''
import sys,json,time
print(json.dumps({'event':'ready','protocol':1}),flush=True)
for line in sys.stdin:
 r=json.loads(line);op=r['op'];p=r.get('params',{})
 if op=='shutdown' or op=='exit':break
 if op=='cancel':continue
 if op=='configure':
  for step in range(8):
   if p['embedding']!='silent':
    print(json.dumps({'event':'initialization','request_id':r['id'],'phase':'restoring','processed':step,'total':8}),flush=True)
   time.sleep(.04)
  sources={s:{'indexed':8 if s=='tags' else 0,'total':8 if s=='tags' else 0,'complete':s=='tags','building':False} for s in p['sources']}
 print(json.dumps({'id':r['id'],'result':{'sources':sources,'jobs':[]}}),flush=True)
''';

class _Settings extends RagSettingsController {
  @override
  RagSettings build() => RagSettings(
    enabled: true,
    wikiEnabled: true,
    embedding: 'fixture',
    reranker: 'fixture',
    python: Platform.environment['RAG_TEST_PYTHON']!,
  );
  @override
  Future<void> update(RagSettings value) async {
    state = value;
  }
}

class _SilentSettings extends _Settings {
  @override
  RagSettings build() => super.build().copyWith(embedding: 'silent');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final python = Platform.environment['RAG_TEST_PYTHON'];
  late Directory root;
  ProviderContainer? container;
  final clients = <RagClient>[];
  Future<void> waitFor(bool Function() ready) async {
    for (var i = 0; i < 200; i++) {
      if (ready()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('fixture did not reach the expected state');
  }

  Future<void> open({bool silent = false}) async {
    container = ProviderContainer(
      overrides: [
        ragSettingsProvider.overrideWith(
          silent ? _SilentSettings.new : _Settings.new,
        ),
        ragDirectoryProvider.overrideWithValue(() async => root),
        ragSourcePathsProvider.overrideWithValue(
          () async => (catalog: 'fixture', runtime: '', wiki: 'fixture'),
        ),
        ragWikiTranslationsPathProvider.overrideWithValue(() async => ''),
        ragInitializationTimeoutProvider.overrideWithValue(
          const Duration(seconds: 3),
        ),
        ragInitializationIdleTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 200),
        ),
        ragStatusTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
        ragClientStarterProvider.overrideWithValue(({
          required python,
          required directory,
        }) async {
          final client = await RagClient.start(
            python: python,
            directory: directory,
            loadAsset: (name) async =>
                name.endsWith('worker.py') ? _worker : '',
          );
          clients.add(client);
          return client;
        }),
      ],
    );
    container!.read(ragControllerProvider);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rag-startup-');
    clients.clear();
  });
  tearDown(() async {
    await DesktopAppShutdownService.prepareBackgroundShutdown();
    container?.dispose();
    for (final client in clients) {
      await client.close();
    }
    await root.delete(recursive: true);
  });
  group('startup with isolated JSON worker', () {
    test(
      'progress survives short command budgets and publishes authoritative empty state only after configure',
      () async {
        await open();
        final c = container!;
        await waitFor(
          () => c.read(ragControllerProvider).initializationProcessed >= 1,
        );
        final loading = c.read(ragControllerProvider);
        expect(loading.initializing, isTrue);
        expect(loading.hasIndexStatus, isFalse);
        expect(loading.forSource(RagSource.wiki).hasIndexStatus, isFalse);
        final refresh = c.read(ragControllerProvider.notifier).refresh();
        await waitFor(() => c.read(ragControllerProvider).runtimeReady);
        await refresh;
        final ready = c.read(ragControllerProvider);
        expect(ready.initializing, isFalse);
        expect(ready.indexed, 8);
        expect(ready.indexKnown, isTrue);
        expect(ready.forSource(RagSource.wiki).indexed, 0);
        expect(ready.forSource(RagSource.wiki).indexKnown, isTrue);
        expect(clients, hasLength(1));
      },
    );
    test(
      'an idle initialization fails honestly without claiming an empty index',
      () async {
        await open(silent: true);
        final c = container!;
        await waitFor(() => c.read(ragControllerProvider).error != null);
        final failed = c.read(ragControllerProvider);
        expect(failed.initializing, isFalse);
        expect(failed.error, 'initialization_timeout');
        expect(failed.indexKnown, isFalse);
        expect(
          failed.forSource(RagSource.wiki).error,
          'initialization_timeout',
        );
        expect(clients.single.isClosed, isTrue);
      },
    );
    test(
      'disabling while restoring closes the opening worker and ignores late state',
      () async {
        await open();
        final c = container!;
        await waitFor(
          () => c.read(ragControllerProvider).initializationProcessed >= 1,
        );
        await c
            .read(ragSettingsProvider.notifier)
            .update(c.read(ragSettingsProvider).copyWith(enabled: false));
        await waitFor(() => clients.single.isClosed);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(c.read(ragControllerProvider).runtimeReady, isFalse);
        expect(c.read(ragControllerProvider).initializing, isFalse);
        expect(c.read(ragControllerProvider).error, isNull);
      },
    );
    test(
      'reconnect keeps previously known counts during restoration',
      () async {
        await open();
        final c = container!;
        await waitFor(() => c.read(ragControllerProvider).runtimeReady);
        await expectLater(
          clients.single.request('exit'),
          throwsA(isA<RagException>()),
        );
        final refresh = c.read(ragControllerProvider.notifier).refresh();
        await waitFor(() => c.read(ragControllerProvider).initializing);
        expect(c.read(ragControllerProvider).indexed, 8);
        expect(c.read(ragControllerProvider).indexKnown, isTrue);
        await refresh;
        expect(c.read(ragControllerProvider).error, isNull);
        expect(c.read(ragControllerProvider).indexed, 8);
      },
    );
  }, skip: python == null ? 'Set RAG_TEST_PYTHON for isolated IPC' : false);
}
