import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../settings/settings_test_harness.dart';

/// 设置页“模型与接口”，服务商标签换成新工作台。数据由 [ProvidersHost] 本地模拟（即时操作立刻反映）。
Future<ProvidersRecorder> pumpProviders(
  WidgetTester tester, {
  ProvidersViewData? data,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
  ProvidersRecorder? recorder,
}) async {
  final rec = recorder ?? ProvidersRecorder();
  rec.data = data ?? ProvidersFixture.view;
  final base = SettingsFixture.view(page: SettingsPageId.models, dark: dark);
  await pumpSettings(
    tester,
    window: window,
    height: height,
    locale: locale,
    dark: dark,
    data: base.copyWith(
      models: SettingsModelsData(
        providers: base.models.providers,
        assignments: base.models.assignments,
        presets: base.models.presets,
        requests: base.models.requests,
        requestTotal: base.models.requestTotal,
        workbench: rec.data,
      ),
    ),
    providers: rec.actions,
    onHost: (host) => rec.host = host,
  );
  return rec;
}

/// 记录回调；即时操作（启用、增删模型、排序、删除）直接改本地数据并刷新宿主。
class ProvidersRecorder {
  final calls = <String>[];
  late ProvidersViewData data;
  SettingsHostState? host;
  ProvidersSaveResult saveResult = ProvidersSaveResult.saved;

  /// 非 null 时 onSave 等它完成（测“保存中继续编辑”）。
  Future<void>? saveGate;
  ProviderSettings? lastSaved;
  String? lastKey;

  /// 保存成功的明文 Key（显示 Key 时返回它，模拟后端已更新）。
  final savedKeys = <String, String>{};

  bool has(String prefix) => calls.any((c) => c.startsWith(prefix));

  void replace(ProvidersViewData next) {
    data = next;
    final h = host;
    if (h == null) return;
    final d = h.data;
    h.updateData(
      d.copyWith(
        models: SettingsModelsData(
          providers: d.models.providers,
          assignments: d.models.assignments,
          presets: d.models.presets,
          requests: d.models.requests,
          requestTotal: d.models.requestTotal,
          workbench: next,
        ),
      ),
    );
  }

  void updateProvider(String id, ProviderItem Function(ProviderItem) f) =>
      replace(
        ProvidersViewData(
          providers: [for (final p in data.providers) p.id == id ? f(p) : p],
          protocols: data.protocols,
          presets: data.presets,
          catalogs: data.catalogs,
        ),
      );

  ProviderItem _with(
    ProviderItem p, {
    ProviderSettings? settings,
    bool? enabled,
  }) => ProviderItem(
    id: p.id,
    settings: settings ?? p.settings,
    presetId: p.presetId,
    group: p.group,
    logoAsset: p.logoAsset,
    mark: p.mark,
    color: p.color,
    enabled: enabled ?? p.enabled,
    local: p.local,
    apiKeyMasked: p.apiKeyMasked,
    status: p.status,
    latencyMs: p.latencyMs,
    checkedAt: p.checkedAt,
    error: p.error,
    testing: p.testing,
    hint: p.hint,
    models: p.models,
  );

  /// 模拟别处改了已保存配置。
  void externalEdit(String id, ProviderSettings Function(ProviderSettings) f) =>
      updateProvider(id, (p) => _with(p, settings: f(p.settings)));

  ProvidersActions get actions => ProvidersActions(
    onCreate: (preset) async {
      calls.add('create:$preset');
      return null;
    },
    onEnabled: (id, v) {
      calls.add('enabled:$id:$v');
      updateProvider(id, (p) => _with(p, enabled: v));
    },
    onTest: (id, edited, key) => calls.add('test:$id:${edited.baseUrl}:$key'),
    onTestModel: (id, m, edited, key) =>
        calls.add('testModel:$id:$m:${edited.model(m)?.maxOutput}:$key'),
    onSave:
        ({required providerId, required base, required edited, apiKey}) async {
          calls.add('save:$providerId');
          if (saveGate != null) await saveGate;
          lastSaved = edited;
          lastKey = apiKey;
          if (saveResult == ProvidersSaveResult.saved) {
            if (apiKey != null) savedKeys[providerId] = apiKey;
            externalEdit(providerId, (_) => edited);
          }
          return saveResult;
        },
    onRevealApiKey: (id) async {
      calls.add('reveal:$id');
      return savedKeys[id] ?? 'sk-plain-$id';
    },
    onFetchCatalog: (id) => calls.add('fetch:$id'),
    onAddModels: (id, ids, {manual = false}) {
      calls.add('add:$id:${ids.join(',')}:$manual');
      externalEdit(
        id,
        (s) => s.copyWith(
          models: [
            ...s.models,
            for (final m in ids) ProviderModelSettings(id: m),
          ],
        ),
      );
    },
    onRemoveModel: (id, m) {
      calls.add('remove:$id:$m');
      externalEdit(
        id,
        (s) => s.copyWith(models: [...s.models]..removeWhere((x) => x.id == m)),
      );
    },
    onReorderModels: (id, ids) {
      calls.add('reorder:$id:${ids.join(',')}');
      externalEdit(
        id,
        (s) => s.copyWith(models: [for (final m in ids) s.model(m)!]),
      );
    },
    onDelete: (id) {
      calls.add('delete:$id');
      replace(
        ProvidersViewData(
          providers: [...data.providers]..removeWhere((p) => p.id == id),
          protocols: data.protocols,
          presets: data.presets,
          catalogs: data.catalogs,
        ),
      );
    },
  );
}
