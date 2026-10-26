import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/krita/bridge_session.dart';
import '../../../core/network/nai_api_endpoint_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/comfyui/comfyui_provider.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/proxy_settings_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../widgets/bridge/agent_bridge_indicator.dart';

/// Connectivity probes are deliberately separate from authenticated API clients.
/// They never load account credentials, provider headers or request bodies.
typedef SettingsEndpointProbe = Future<int> Function(Uri uri, String? proxy);
final settingsEndpointProbeProvider = Provider<SettingsEndpointProbe>(
  (ref) => (uri, proxy) async {
    if (!const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid endpoint');
    }
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    client.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final http = HttpClient();
        http.findProxy = (_) =>
            proxy == null || proxy.isEmpty ? 'DIRECT' : 'PROXY $proxy';
        return http;
      },
    );
    final watch = Stopwatch()..start();
    try {
      // Query parameters can contain API keys. Probe the origin only.
      await client.headUri(
        Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.hasPort ? uri.port : null,
          path: '/',
        ),
      );
      return watch.elapsedMilliseconds;
    } finally {
      client.close(force: true);
    }
  },
);

final settingsNetworkProvider =
    NotifierProvider<SettingsNetwork, SettingsNetworkData>(SettingsNetwork.new);

class SettingsNetwork extends Notifier<SettingsNetworkData> {
  bool _disposed = false;
  int _revision = 0;
  @override
  SettingsNetworkData build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _revision++;
    });
    return const SettingsNetworkData();
  }

  Future<void> check() async {
    if (state.checking) return;
    final revision = ++_revision;
    final providers = ref
        .read(promptAssistantConfigProvider)
        .providers
        .where((p) => p.enabled)
        .toList();
    final proxy = ref.read(currentProxyAddressProvider);
    final targets = <(SettingsEndpointKind, String, String)>[
      (SettingsEndpointKind.naiImage, 'https://image.novelai.net', ''),
      (
        SettingsEndpointKind.naiApi,
        ref.read(naiApiEndpointServiceProvider).current.userUrl('/user/login'),
        '',
      ),
      (SettingsEndpointKind.danbooru, 'https://danbooru.donmai.us', ''),
      (SettingsEndpointKind.update, 'https://api.github.com', ''),
      for (final provider in providers)
        (SettingsEndpointKind.provider, provider.baseUrl, provider.name),
    ];
    state = const SettingsNetworkData(checking: true);
    final probe = ref.read(settingsEndpointProbeProvider);
    final endpoints = await Future.wait(
      targets.map((target) async {
        final uri = Uri.tryParse(target.$2);
        try {
          if (uri == null) throw const FormatException();
          final latency = await probe(uri, proxy);
          return SettingsEndpoint(
            kind: target.$1,
            host: uri.host,
            name: target.$3,
            latencyMs: latency,
            tone: SettingsTone.ok,
          );
        } catch (_) {
          return SettingsEndpoint(
            kind: target.$1,
            host: uri?.host ?? '',
            name: target.$3,
            tone: SettingsTone.error,
          );
        }
      }),
    );
    if (_disposed || revision != _revision) return;
    // An old probe must not describe a newly selected proxy/configuration.
    if (proxy != ref.read(currentProxyAddressProvider) ||
        providers.map((p) => '${p.id}:${p.baseUrl}').join('|') !=
            ref
                .read(promptAssistantConfigProvider)
                .providers
                .where((p) => p.enabled)
                .map((p) => '${p.id}:${p.baseUrl}')
                .join('|')) {
      state = const SettingsNetworkData();
      return;
    }
    state = SettingsNetworkData(
      endpoints: endpoints,
      checkedAt: DateTime.now(),
    );
  }
}

final settingsComfyTestProvider =
    StateProvider<({bool testing, bool? ok, DateTime? at})>(
      (ref) => (testing: false, ok: null, at: null),
    );

SettingsBridgesData settingsBridgesData(BuildContext context, WidgetRef ref) {
  final bridge = ref.watch(kritaBridgeNotifierProvider);
  final test = ref.watch(settingsComfyTestProvider);
  return SettingsBridgesData(
    kritaConnected: bridge.status == KritaBridgeStatus.connected,
    kritaClient: bridge.connectedClientLabel ?? '',
    kritaEndpoint: bridge.port == null ? '' : 'ws://127.0.0.1:${bridge.port}',
    kritaDiscovery: bridge.discoveryFilePath ?? '',
    agentClients: bridge.session.agents.length,
    activity: [
      for (final activity in bridge.session.activities.take(20))
        SettingsBridgeActivity(
          client: activity.client.name,
          action: bridgeOperationLabel(context.l10n, activity.operation),
          at: activity.at,
          tone: switch (activity.status) {
            BridgeActivityStatus.failed => SettingsTone.error,
            BridgeActivityStatus.running => SettingsTone.warn,
            BridgeActivityStatus.disconnected => SettingsTone.idle,
            _ => SettingsTone.ok,
          },
        ),
    ],
    comfyTone: test.ok == null
        ? SettingsTone.idle
        : test.ok!
        ? SettingsTone.ok
        : SettingsTone.error,
    comfyCheckedAt: test.at,
    comfyTesting: test.testing,
  );
}

class SettingsConnectionActions {
  SettingsConnectionActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;
  Future<void> copyEndpoint() async {
    final bridge = ref.read(kritaBridgeNotifierProvider);
    if (!bridge.isActive || bridge.port == null) {
      throw StateError('Bridge is not active');
    }
    await Clipboard.setData(
      ClipboardData(text: 'ws://127.0.0.1:${bridge.port}'),
    );
  }

  Future<void> openDiscovery() async {
    final path = ref.read(kritaBridgeNotifierProvider).discoveryFilePath;
    if (path == null) throw StateError('Bridge is not active');
    if (!await launchUrl(Uri.file(path))) {
      throw StateError('Unable to open discovery file');
    }
  }

  Future<void> copyTakeover() async {
    final bundle = await ref.read(bridgeClientBundleProvider.future);
    if (!bundle.available || !context.mounted) {
      throw StateError('Bridge client is unavailable');
    }
    await Clipboard.setData(
      ClipboardData(text: context.l10n.bridge_guide(bundle.path)),
    );
  }

  Future<void> testComfy() async {
    final state = ref.read(settingsComfyTestProvider.notifier);
    if (state.state.testing) return;
    final before = ref.read(comfyUISettingsProvider);
    state.state = (testing: true, ok: null, at: null);
    bool ok;
    try {
      ok = await ref.read(comfyUIConnectionProvider.notifier).testConnection();
    } catch (_) {
      ok = false;
    }
    if (!state.mounted) return;
    final latest = ref.read(comfyUISettingsProvider);
    state.state = before.serverUrl == latest.serverUrl
        ? (testing: false, ok: ok, at: DateTime.now())
        : (testing: false, ok: null, at: null);
  }
}
