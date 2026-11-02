import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/database_providers.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/warmup_provider.dart';
import 'package:nai_launcher/presentation/screens/splash/app_bootstrap.dart';
import 'package:nai_launcher/presentation/screens/splash/splash_screen.dart';

import 'krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String> getApplicationSupportPath() async => '$root/app';
  @override
  Future<String> getApplicationDocumentsPath() async => '$root/documents';
  @override
  Future<String> getTemporaryPath() async => '$root/temp';
}

class _Auth extends AuthNotifier {
  static int starts = 0;
  @override
  AuthState build() {
    starts++;
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _Client extends Fake implements HttpClient {
  final gate = Completer<HttpClientRequest>();
  int requests = 0;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    requests++;
    return gate.future;
  }

  @override
  set connectionTimeout(Duration? value) {}
  @override
  Duration? get connectionTimeout => const Duration(seconds: 3);
  @override
  set idleTimeout(Duration value) {}
  @override
  set findProxy(String Function(Uri url)? callback) {}
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Studio',
      packageName: 'studio.test',
      version: '2.2.4',
      buildNumber: '78',
      buildSignature: '',
    );
    await AppVersion.initialize();
  });
  late Directory directory;
  late ProviderContainer container;
  late ProviderSubscription<WarmupState> subscription;
  late Completer<void> services;
  late _Client network;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('startup-warmup-');
    await Directory('${directory.path}/documents').create();
    PathProviderPlatform.instance = _Paths(directory.path);
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    services = Completer<void>();
    network = _Client();
    _Auth.starts = 0;
    container = ProviderContainer(
      overrides: [
        appStartupReadyProvider.overrideWithValue(services.future),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
    );
  });
  tearDown(() async {
    subscription.close();
    container.dispose();
    if (!services.isCompleted) services.complete();
    if (network.requests > 0 && !network.gate.isCompleted) {
      network.gate.completeError(const SocketException('isolated test'));
    }
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'auto-login starts while services are pending and no second database init begins',
    () async {
      subscription = container.listen(warmupNotifierProvider, (_, _) {});
      await container.pump();
      expect(_Auth.starts, 1);
      expect(container.read(warmupNotifierProvider).isComplete, isFalse);
      expect(container.exists(databaseManagerProvider), isFalse);
    },
  );

  test(
    'completed warmup does not wait for a slow background network probe',
    () async {
      await HttpOverrides.runZoned(() async {
        subscription = container.listen(warmupNotifierProvider, (_, _) {});
        final completion = container
            .read(warmupNotifierProvider.notifier)
            .whenComplete;
        services.complete();
        await completion;
        for (var i = 0; i < 10 && network.requests == 0; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(network.requests, 1);
        expect(network.gate.isCompleted, isFalse);
        expect(container.read(warmupNotifierProvider).isComplete, isTrue);
        expect(container.read(warmupNotifierProvider).subTaskMessage, isNull);
        expect(container.exists(databaseManagerProvider), isFalse);
      }, createHttpClient: (_) => network);
    },
  );

  test(
    'service preparation failure stays on the existing loading error state',
    () async {
      subscription = container.listen(warmupNotifierProvider, (_, _) {});
      final completion = expectLater(
        container.read(warmupNotifierProvider.notifier).whenComplete,
        throwsStateError,
      );
      services.completeError(StateError('isolated preparation failure'));
      await completion;
      final state = container.read(warmupNotifierProvider);
      expect(state.isComplete, isFalse);
      expect(state.error, contains('isolated preparation failure'));
      expect(network.requests, 0);
    },
  );

  test(
    'disposing during service preparation does not resume warmup later',
    () async {
      subscription = container.listen(warmupNotifierProvider, (_, _) {});
      subscription.close();
      await container.pump();
      services.complete();
      await Future<void>.delayed(Duration.zero);
      expect(network.requests, 0);
    },
  );

  test('retry uses a fresh completion after readiness is restored', () async {
    await HttpOverrides.runZoned(() async {
      subscription = container.listen(warmupNotifierProvider, (_, _) {});
      final notifier = container.read(warmupNotifierProvider.notifier);
      final first = expectLater(notifier.whenComplete, throwsStateError);
      services.completeError(StateError('temporary preparation failure'));
      await first;
      container.updateOverrides([
        appStartupReadyProvider.overrideWithValue(Future<void>.value()),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        authNotifierProvider.overrideWith(_Auth.new),
      ]);
      notifier.retry();
      await notifier.whenComplete;
      expect(container.read(warmupNotifierProvider).isComplete, isTrue);
      expect(container.read(warmupNotifierProvider).error, isNull);
    }, createHttpClient: (_) => network);
  });

  testWidgets('the original loading page renders before service readiness', (
    tester,
  ) async {
    subscription = container.listen(warmupNotifierProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AppBootstrap(),
      ),
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(container.read(warmupNotifierProvider).isComplete, isFalse);
    expect(services.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
