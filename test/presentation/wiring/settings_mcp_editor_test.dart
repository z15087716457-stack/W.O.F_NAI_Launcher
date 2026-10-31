import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_management.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/nai_agent_mcp_settings.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_kit.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/uiux_frontend_capture.dart';
import 'nai_agent/agent_wiring_harness.dart';

class _Probe extends NaiAgentManagement {
  _Probe(super.ref, this.results);
  final List<Completer<Map<String, dynamic>>> results;
  @override
  Future<Map<String, dynamic>> inspectMcp(
    String name,
    Map<String, dynamic> config,
    AgentWorkspace workspace, {
    String action = 'test',
    NaiAgentCancellation? cancellation,
  }) => results.removeAt(0).future;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  Future<AgentWiringHarness> open(
    WidgetTester t, {
    Locale locale = const Locale('zh'),
    Brightness brightness = Brightness.dark,
    List<Completer<Map<String, dynamic>>>? probes,
  }) async {
    final h = AgentWiringHarness();
    await t.runAsync(
      () => h.init(
        overrides: [
          if (probes != null)
            naiAgentManagementProvider.overrideWith(
              (ref) => _Probe(ref, probes),
            ),
        ],
        controller: (store) =>
            AgentTestController(AgentWorkspaceStore(store.root)),
      ),
    );
    await h.pump(
      t,
      width: 900,
      height: 900,
      locale: locale,
      brightness: brightness,
      child: Consumer(
        builder: (context, ref, _) => TextButton(
          key: const Key('open-mcp'),
          onPressed: () => const NaiAgentMcpSettings().edit(context, ref),
          child: const Text('Open'),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('open-mcp')));
    await t.pumpAndSettle();
    return h;
  }

  Future<void> save(WidgetTester t, AgentWiringHarness h) async {
    await t.tap(find.byKey(const Key('nai-mcp-save')));
    for (
      var i = 0;
      i < 100 &&
          h.container
              .read(naiAgentUiPreferencesProvider)
              .settings
              .mcpServers
              .isEmpty;
      i++
    ) {
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    await t.pumpAndSettle();
    expect(
      h.container.read(naiAgentUiPreferencesProvider).settings.mcpServers,
      hasLength(1),
    );
    expect(t.takeException(), isNull);
  }

  testWidgets(
    'editing connection fields clears success and ignores an older in-flight test',
    (t) async {
      final first = Completer<Map<String, dynamic>>(),
          second = Completer<Map<String, dynamic>>();
      final probes = [first, second];
      await open(t, probes: probes);
      await t.enterText(find.byKey(const Key('nai-mcp-name')), 'local');
      await t.enterText(
        find.byKey(const Key('nai-mcp-url')),
        'https://example.invalid/mcp',
      );
      await t.tap(find.byKey(const Key('nai-mcp-test')));
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(probes, hasLength(1));
      first.complete({'state': 'connected', 'tools': 2});
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pumpAndSettle();
      expect(find.text('已连接 · 2 个工具'), findsOneWidget);
      await t.enterText(
        find.byKey(const Key('nai-mcp-url')),
        'https://example.invalid/new',
      );
      await t.pump();
      expect(find.text('已连接 · 2 个工具'), findsNothing);
      await t.tap(find.byKey(const Key('nai-mcp-test')));
      await t.pump();
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(probes, isEmpty);
      await t.enterText(
        find.byKey(const Key('nai-mcp-url')),
        'https://example.invalid/newer',
      );
      second.complete({'state': 'connected', 'tools': 2});
      await t.pumpAndSettle();
      expect(find.text('已连接 · 2 个工具'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'JSON import and form share advanced fields and encrypted persistence',
    (t) async {
      final h = await open(t);
      expect(find.byKey(const Key('nai-mcp-url')), findsOneWidget);
      await t.tap(find.byKey(const Key('nai-mcp-json')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('nai-mcp-config')),
        jsonEncode({
          'mcpServers': {
            'web': {
              'url': 'https://example.invalid/mcp',
              'headers': {'x-api-key': 'fixture-key'},
              'timeout': 9,
              'oauth': {'clientId': 'fixture-client'},
            },
          },
        }),
      );
      await t.tap(find.byKey(const Key('nai-mcp-json')));
      await t.pumpAndSettle();
      expect(find.byType(ProviderKeyValues), findsOneWidget);
      await t.enterText(
        find.byKey(const Key('nai-mcp-url')),
        'https://example.invalid/new',
      );
      await t.pumpAndSettle();
      await captureUiuxRegion(
        t,
        find.byKey(const Key('agent-wiring-capture')),
        'mcp-http-zh-dark',
        const Rect.fromLTWH(0, 0, 900, 900),
      );
      await save(t, h);
      final server = h.container
          .read(naiAgentUiPreferencesProvider)
          .settings
          .mcpServers
          .single;
      expect(server.name, 'web');
      final secrets =
          h.container.read(secureStorageServiceProvider) as AgentTestSecrets;
      final config = jsonDecode(secrets.mcp[server.configId]!) as Map;
      expect(config['url'], 'https://example.invalid/new');
      expect(config['timeout'], 9);
      expect(config['headers']['x-api-key'], 'fixture-key');
      expect(config['oauth']['clientId'], 'fixture-client');
    },
  );

  for (final locale in [const Locale('en'), const Locale('ja')]) {
    testWidgets('local command form keeps spaced arguments and fits $locale', (
      t,
    ) async {
      final h = await open(t, locale: locale, brightness: Brightness.light);
      await t.enterText(find.byKey(const Key('nai-mcp-name')), 'local');
      await t.tap(find.byKey(const Key('nai-mcp-stdio')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('nai-mcp-command')), 'node');
      await t.enterText(
        find.byKey(const Key('nai-mcp-args')),
        'server with spaces.mjs\n--port\n9000',
      );
      await t.pumpAndSettle();
      await captureUiuxRegion(
        t,
        find.byKey(const Key('agent-wiring-capture')),
        'mcp-command-${locale.languageCode}-light',
        const Rect.fromLTWH(0, 0, 900, 900),
      );
      await save(t, h);
      final server = h.container
          .read(naiAgentUiPreferencesProvider)
          .settings
          .mcpServers
          .single;
      final secrets =
          h.container.read(secureStorageServiceProvider) as AgentTestSecrets;
      final config = jsonDecode(secrets.mcp[server.configId]!) as Map;
      expect(config['args'], ['server with spaces.mjs', '--port', '9000']);
      expect(config.containsKey('url'), isFalse);
    });
  }
}
