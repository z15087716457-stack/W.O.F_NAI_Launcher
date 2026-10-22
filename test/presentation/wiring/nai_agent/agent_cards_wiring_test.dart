import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/settings_tools.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_gallery_binding.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_gallery_undo.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_settings_undo.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';

import '../../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

class _Gallery extends Mock implements NaiAgentGalleryBinding {}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  late MemoryStorage storage;
  late _Gallery gallery;
  setUp(() async {
    h = AgentWiringHarness();
    storage = MemoryStorage();
    storage.values['font_scale'] = 1.1;
    gallery = _Gallery();
    when(() => gallery.undoManage(any(), any())).thenAnswer((_) async => true);
    await h.init(
      overrides: [
        agentPreferencesProvider.overrideWith((_) => {'font_scale': 1.1}),
        agentSettingsUndoProvider.overrideWith(
          (_, path) => AgentSettingsUndo(
            NaiAgentSettingsTools(
              SettingsPreferencesService(
                storage,
                backupDirectory: Directory('$path/settings-backups'),
              ),
              isAlive: () => true,
              refresh: () {},
            ),
          ),
        ),
        agentGalleryBindingProvider.overrideWith((_, __) => gallery),
      ],
    );
  });
  tearDown(() async => h.dispose());
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  for (final persistedCodeMode in [false, true]) {
    testWidgets(
      'settings and gallery ids route through both existing undo callbacks, CodeMode=$persistedCodeMode',
      (tester) async {
        h.c.selected!.messages = [
          {'role': 'user', 'content': 'cards'},
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'toolCall',
                'id': 's',
                'name': 'settings_update',
                'arguments': {},
              },
              {
                'type': 'toolCall',
                'id': 'g',
                'name': 'gallery_manage',
                'arguments': {
                  'action': 'delete',
                  'scope': 'library',
                  'image_id': 'history-non-gallery-test',
                },
              },
            ],
          },
          {
            'role': 'toolResult',
            'toolCallId': 's',
            'details': {
              'applied_fields': ['font_scale'],
              'before': {'font_scale': 1.0},
              'values': {'font_scale': 1.1},
              'version': 'v',
            },
          },
          {
            'role': 'toolResult',
            'toolCallId': 'g',
            'details': {
              'ok': true,
              'image_id': 'history-non-gallery-test',
              'scope': 'library',
              'image_version': 'iv',
            },
          },
        ];
        if (persistedCodeMode) {
          final messages = h.c.selected!.messages;
          final calls = (messages[1]['content'] as List)
              .cast<Map<String, dynamic>>();
          h.c.selected!.messages = [
            messages.first,
            {
              'role': 'assistant',
              'content': [
                {
                  'type': 'toolCall',
                  'id': 'code',
                  'name': 'codemode',
                  'arguments': {},
                },
              ],
            },
            {
              'role': 'toolResult',
              'toolCallId': 'code',
              'details': {
                'calls': [
                  for (final call in calls)
                    {
                      'id': call['id'],
                      'name': 'mcp__nai_studio__${call['name']}',
                      'status': 'ok',
                      'args': '{truncated',
                    },
                ],
                'studio_results': [
                  for (final call in calls)
                    {
                      'tool': 'mcp__nai_studio__${call['name']}',
                      'tool_call_id': call['id'],
                      'arguments': call['arguments'],
                      ...messages.singleWhere(
                            (m) => m['toolCallId'] == call['id'],
                          )['details']
                          as Map,
                    },
                ],
              },
            },
          ];
          expect(h.c.selected!.tools, isEmpty);
        }
        await h.pump(tester);
        final cards = h.panel(tester).data.thread.single.reply!.blocks;
        final settings = cards.whereType<AgentSettingsBlock>().single;
        final image = cards.whereType<AgentGalleryBlock>().single;
        var restored = false;
        await tester.runAsync(() async {
          restored = await h.panel(tester).actions.onUndoDiffs([settings.id]);
        });
        expect(restored, true);
        expect(storage.values['font_scale'], 1.0);
        await tester.pumpAndSettle();
        expect(
          h
              .panel(tester)
              .data
              .thread
              .single
              .reply!
              .blocks
              .whereType<AgentSettingsBlock>()
              .single
              .state,
          AgentDiffState.undone,
        );
        expect(await h.panel(tester).actions.onUndoDiff(settings.id), false);
        expect(await h.panel(tester).actions.onUndoDiff(image.id), true);
        verify(() => gallery.undoManage(any(), any())).called(1);
        await tester.pumpAndSettle();
        expect(
          h
              .panel(tester)
              .data
              .thread
              .single
              .reply!
              .blocks
              .whereType<AgentGalleryBlock>()
              .single
              .state,
          AgentDiffState.undone,
        );
      },
    );
  }

  for (final persisted in [false, true]) {
    testWidgets(
      'batch move card routes complete undo snapshots persisted=$persisted',
      (tester) async {
        final ids = ['gallery:1', 'gallery:2', 'gallery:3'];
        final args = <String, dynamic>{
          'action': 'move_file',
          'scope': 'library',
          'image_ids': ids,
          'target_folder': '/library/batch-target',
        };
        final details = <String, dynamic>{
          'ok': true,
          'action': 'move_file',
          'scope': 'library',
          'image_ids': ids,
          'count': 3,
          'target_folder': '/library/batch-target',
          'image_versions': {for (final id in ids) id: 'moved-version'},
          'source_paths': {
            for (final id in ids) id: '/library/original/$id.png',
          },
          'file_paths': {
            for (final id in ids) id: '/library/batch-target/$id.png',
          },
        };
        h.c.selected!.messages = [
          {'role': 'user', 'content': 'batch cards'},
          {
            'role': 'assistant',
            'content': [
              {
                'type': 'toolCall',
                'id': persisted ? 'code' : 'batch',
                'name': persisted ? 'codemode' : 'gallery_manage',
                'arguments': persisted ? <String, dynamic>{} : args,
              },
            ],
          },
          {
            'role': 'toolResult',
            'toolCallId': persisted ? 'code' : 'batch',
            'details': persisted
                ? {
                    'studio_results': [
                      {
                        'tool': 'mcp__nai_studio__gallery_manage',
                        'tool_call_id': 'batch',
                        'arguments': args,
                        ...details,
                      },
                    ],
                  }
                : details,
          },
        ];
        await h.pump(tester);
        final card = h
            .panel(tester)
            .data
            .thread
            .single
            .reply!
            .blocks
            .whereType<AgentGalleryBlock>()
            .single;
        expect(card.count, 3);
        expect(card.target, 'batch-target');
        expect(card.undoable, true);
        expect(await h.panel(tester).actions.onUndoDiff(card.id), true);
        final captured = verify(
          () => gallery.undoManage(captureAny(), captureAny()),
        ).captured;
        expect(captured[0], args);
        expect((captured[1] as Map)['source_paths'], details['source_paths']);
        expect(
          (captured[1] as Map)['image_versions'],
          details['image_versions'],
        );
        await tester.pumpAndSettle();
        expect(
          h
              .panel(tester)
              .data
              .thread
              .single
              .reply!
              .blocks
              .whereType<AgentGalleryBlock>()
              .single
              .state,
          AgentDiffState.undone,
        );
      },
    );
  }

  testWidgets('setting anchor callback keeps section and anchor in route', (
    tester,
  ) async {
    await h.pump(tester);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: AgentWiring()),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    h.panel(tester).actions.onOpenSettingAt('generation', 'wheelWeight');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters, {
      'section': 'generation',
      'anchor': 'wheelWeight',
    });
  });
}
