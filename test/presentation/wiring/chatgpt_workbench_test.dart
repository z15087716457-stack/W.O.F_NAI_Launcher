import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/auth/chatgpt_auth_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/model_request_history_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/provider_connection_health_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/wiring/settings/providers_workbench.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;

class _Auth extends ChatGptAuthService {
  _Auth()
    : super(
        dio: Dio(),
        read: (_) async => null,
        write: (_, _) async {},
        openBrowser: (_) async => false,
      );
  final accounts = <String, ChatGptAccount>{};
  int tokenReads = 0, signIns = 0;
  bool fail = false, waitForCancel = false;
  @override
  Future<ChatGptAccount?> account(String id) async => accounts[id];
  @override
  Future<String> accessToken(String id) async {
    tokenReads++;
    if (accounts[id]?.planEnabled != true) {
      throw const ChatGptAuthException('sign_in_required');
    }
    return 'synthetic-private-token';
  }

  @override
  Future<void> signIn(String id, CancelToken cancellation) async {
    signIns++;
    if (waitForCancel) {
      await cancellation.whenCancel;
      throw const ChatGptAuthException('cancelled');
    }
    if (fail) throw const ChatGptAuthException('authorization_denied');
    accounts[id] = ChatGptAccount(
      clientId: 'issued-$id',
      email: 'test@example.invalid',
      signedIn: true,
      planEnabled: true,
    );
  }

  @override
  Future<bool> signOut(String id) async {
    accounts[id] = ChatGptAccount(
      clientId: 'issued-$id',
      signedIn: false,
      planEnabled: false,
    );
    return true;
  }
}

class _Harness {
  final auth = _Auth();
  final local = MemorySettings();
  final secure = MemorySecrets();
  final requests = <RequestOptions>[];
  late ProviderContainer container;
  late ProvidersWorkbench backend;
  PromptAssistantConfigState get config =>
      container.read(promptAssistantConfigProvider);
  ProvidersWorkbenchState get state =>
      container.read(providersWorkbenchProvider);
  Future<void> init({bool existing = false}) async {
    local.values[StorageKeys.promptAssistantConfigJson] =
        PromptAssistantConfigState(
          providers: existing
              ? [ProviderPreset.chatgpt.createConfig(id: 'chatgpt')]
              : [],
          models: const [],
          interfaces: const {},
          providerHasApiKey: const {},
        ).encode();
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            if (request.method == 'POST') {
              expect(
                request.uri.toString(),
                'https://api.openai.com/v1/responses',
              );
              expect(
                (request.data as Map).containsKey('max_output_tokens'),
                false,
              );
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: ResponseBody.fromString(
                    'data: {"type":"response.output_text.delta","delta":"OK"}\n\ndata: {"type":"response.completed"}\n\n',
                    200,
                  ),
                ),
              );
              return;
            }
            expect(request.method, 'GET');
            expect(request.uri.toString(), 'https://api.openai.com/v1/models');
            expect(
              request.headers['Authorization'],
              'Bearer synthetic-private-token',
            );
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'models': [
                    {
                      'slug': 'account-model-b',
                      'display_name': 'Account Model B',
                      'visibility': 'list',
                    },
                    {
                      'slug': 'hidden',
                      'display_name': 'Hidden',
                      'visibility': 'hide',
                    },
                    {
                      'slug': 'account-model-a',
                      'display_name': 'Account Model A',
                      'visibility': 'list',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(local),
        secureStorageServiceProvider.overrideWithValue(secure),
        chatGptAuthServiceProvider.overrideWithValue(auth),
        promptAssistantDioProvider.overrideWithValue(dio),
      ],
    );
    container.read(promptAssistantConfigProvider);
    await Future<void>.delayed(Duration.zero);
    backend = container.read(providersWorkbenchProvider.notifier);
    await backend.refresh();
    addTearDown(() {
      container.dispose();
      dio.close();
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  setUp(() {
    final old = ModelCatalogRepository.cached;
    ModelCatalogRepository.cached = ModelCatalogRepository.empty;
    addTearDown(() => ModelCatalogRepository.cached = old);
  });

  test(
    'signed-in workbench model test completes and creates a visible diagnostic record',
    () async {
      final h = _Harness();
      await h.init(existing: true);
      await h.backend.signIn('chatgpt');
      await h.backend.addModels('chatgpt', ['account-model-b']);
      await h.backend.test(
        'chatgpt',
        h.state.settings['chatgpt']!,
        null,
        modelId: 'account-model-b',
      );
      expect(
        h.state.models[('chatgpt', 'account-model-b')]!.lastTest!.ok,
        true,
      );
      expect(
        h.container.read(modelRequestHistoryProvider).records.single.status,
        ModelRequestStatus.success,
      );
    },
  );

  test(
    'signed-out saved services and creation never request or expose an OAuth token',
    () async {
      final h = _Harness();
      await h.init(existing: true);
      expect(await h.backend.create('chatgpt'), 'chatgpt_2');
      expect(h.state.accounts.keys, ['chatgpt', 'chatgpt_2']);
      expect(h.auth.tokenReads, 0);
      expect(h.requests, isEmpty);
      final actions = workbenchActions(h.backend, (action) => action());
      expect(await actions.onRevealApiKey('chatgpt'), isNull);
      expect(h.state.masked.values, everyElement(isEmpty));
    },
  );

  test(
    'authorization failures and cancellation keep the saved connection usable',
    () async {
      final h = _Harness();
      await h.init(existing: true);
      h.auth.fail = true;
      await h.backend.signIn('chatgpt');
      expect(
        h.state.accounts['chatgpt']!.error,
        contains('authorization_denied'),
      );
      expect(h.state.accounts['chatgpt']!.busy, false);
      h.auth.waitForCancel = true;
      final pending = h.backend.signIn('chatgpt');
      expect(h.state.accounts['chatgpt']!.canCancel, true);
      h.backend.cancelSignIn('chatgpt');
      await pending;
      expect(h.state.accounts['chatgpt']!.busy, false);
      expect(h.config.providers.single.id, 'chatgpt');
      expect(h.requests, isEmpty);
    },
  );

  for (final language in ['zh', 'en']) {
    testWidgets(
      'actual settings page: add ChatGPT, authorize, list/add models and sign out ($language)',
      (tester) async {
        final h = _Harness();
        await tester.runAsync(h.init);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1600, 1100);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final errors = <Object>[];
        Future<void>? pending;
        final actions = workbenchActions(h.backend, (action) {
          pending = Future<void>.sync(action).catchError((Object e) {
            errors.add(e);
          });
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: h.container,
            child: MaterialApp(
              theme: GeistTheme.light,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: WindowChromeScope(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final data = providersViewData(
                        ref.watch(promptAssistantConfigProvider),
                        ref.watch(providersWorkbenchProvider),
                        ref.watch(providerConnectionHealthProvider),
                        AppLocalizations.of(context)!,
                      );
                      return RepaintBoundary(
                        key: const Key('chatgpt-full-page'),
                        child: SettingsPage(
                          data:
                              SettingsFixture.view(
                                page: SettingsPageId.models,
                              ).copyWith(
                                models: SettingsModelsData(workbench: data),
                              ),
                          actions: SettingsActions(providers: actions),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        await tester.tap(find.byKey(const Key('mp-empty-add')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('mp-preset-chatgpt')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mp-preset-chatgpt')));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(find.text(l.chatGpt_addService), findsOneWidget);
        expect(find.text(l.mp_pickerNext), findsNothing);
        await tester.tap(find.byKey(const Key('mp-picker-next')));
        await tester.pumpAndSettle();
        expect(h.config.providers.single.preset, ProviderPreset.chatgpt);
        expect(errors, isEmpty);
        expect(h.auth.tokenReads, 0);
        expect(find.byKey(const Key('mp-key')), findsNothing);
        expect(find.byKey(const Key('mp-url')), findsNothing);
        expect(find.byKey(const Key('mp-protocol')), findsNothing);
        expect(find.byKey(const Key('mp-add-header')), findsNothing);
        expect(find.text('Continue with ChatGPT'), findsOneWidget);
        final output = Platform.environment['CHATGPT_UI_CAPTURES'];
        if (output != null) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('chatgpt-full-page')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            await Directory(output).create(recursive: true);
            await File(
              '$output/workbench-$language.png',
            ).writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byKey(const Key('mp-chatgpt-sign-in')));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(h.auth.signIns, 1);
        expect(find.text(l.chatGpt_usingPlan), findsOneWidget);
        expect(h.state.catalogs['chatgpt']!.entries.map((e) => e.id), [
          'account-model-b',
          'account-model-a',
        ]);
        expect(h.requests, hasLength(1));
        expect(errors, isEmpty);
        expect(h.state.masked['chatgpt'], isEmpty);
        pending = h.backend.addModels('chatgpt', ['account-model-b']);
        await tester.pumpAndSettle();
        await pending;
        expect(h.config.models.single.displayName, 'Account Model B');
        await tester.tap(find.byKey(const Key('mp-chatgpt-sign-out')));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(find.text(l.chatGpt_signedOut), findsOneWidget);
        expect(h.state.catalogs.containsKey('chatgpt'), false);
        expect(h.requests, hasLength(1));
        expect(tester.takeException(), isNull);
        expect(h.config.encode(), isNot(contains('synthetic-private-token')));
      },
    );
  }
}
