// 服务商工作台预览：本地模拟器，按契约回调改假数据（启用、测试、保存、目录、增删模型、排序、新建）。
// 只给 settings_preview.dart 用，不进应用。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart'
    show SettingsTone;

class ModelProvidersPreviewSim extends ChangeNotifier {
  ModelProvidersPreviewSim({required this.log});

  final ValueChanged<String> log;
  ProvidersViewData data = ProvidersFixture.view;
  var _n = 0;

  /// 下一次保存的结果（预览里可以演示冲突 / 失败）：保存 3 次中第 3 次冲突。
  var _saves = 0;

  void _set(ProvidersViewData d) {
    data = d;
    notifyListeners();
  }

  void _provider(String id, ProviderItem Function(ProviderItem) f) => _set(
    ProvidersViewData(
      providers: [for (final p in data.providers) p.id == id ? f(p) : p],
      protocols: data.protocols,
      presets: data.presets,
      catalogs: data.catalogs,
    ),
  );

  static ProviderItem copy(
    ProviderItem p, {
    ProviderSettings? settings,
    bool? enabled,
    SettingsTone? status,
    int? latencyMs,
    DateTime? checkedAt,
    String? error,
    bool? testing,
    String? apiKeyMasked,
    Map<String, ProviderModelInfo>? models,
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
    apiKeyMasked: apiKeyMasked ?? p.apiKeyMasked,
    status: status ?? p.status,
    latencyMs: latencyMs ?? p.latencyMs,
    checkedAt: checkedAt ?? p.checkedAt,
    error: error ?? p.error,
    testing: testing ?? p.testing,
    hint: p.hint,
    models: models ?? p.models,
  );

  ProviderItem _get(String id) => data.providers.firstWhere((p) => p.id == id);

  ProvidersActions get actions => ProvidersActions(
    onCreate: (preset) async {
      final pr = data.presets.firstWhere((x) => x.id == preset);
      final id = 'new${++_n}';
      log('onCreate($preset) → $id');
      _set(
        ProvidersViewData(
          providers: [
            ...data.providers,
            ProviderItem(
              id: id,
              presetId: preset,
              group: pr.group,
              logoAsset: pr.logoAsset,
              mark: pr.custom ? '自' : null,
              local: pr.group == ProviderGroup.local && !pr.custom,
              settings: ProviderSettings(
                name: pr.name,
                baseUrl: pr.custom ? '' : 'https://${pr.host}/v1',
                protocolId: 'openaiChatCompletions',
              ),
            ),
          ],
          protocols: data.protocols,
          presets: data.presets,
          catalogs: data.catalogs,
        ),
      );
      return id;
    },
    onEnabled: (id, v) {
      log('onEnabled($id, $v)');
      _provider(id, (p) => copy(p, enabled: v));
    },
    onTest: (id, edited, key) {
      log('onTest($id, ${edited.baseUrl}, key: ${key == null ? '已保存' : '草稿'})');
      _provider(id, (p) => copy(p, testing: true));
      Timer(const Duration(milliseconds: 900), () {
        final ok = id != 'relay' || (key?.isNotEmpty ?? false);
        _provider(
          id,
          (p) => copy(
            p,
            testing: false,
            status: ok ? SettingsTone.ok : SettingsTone.error,
            latencyMs: ok ? 120 + _n * 7 : null,
            error: ok ? '' : '401 · API Key 无效',
            checkedAt: ProvidersFixture.now,
          ),
        );
      });
    },
    onTestModel: (id, model, edited, key) {
      log(
        'onTestModel($id, $model, temperature: ${edited.model(model)?.temperature})',
      );
      void info(ProviderModelInfo Function(ProviderModelInfo) f) => _provider(
        id,
        (p) => copy(p, models: {...p.models, model: f(p.info(model))}),
      );
      ProviderModelInfo with_(
        ProviderModelInfo i, {
        bool? testing,
        ProviderTestResult? last,
      }) => ProviderModelInfo(
        detail: i.detail,
        usedFor: i.usedFor,
        retired: i.retired,
        testing: testing ?? i.testing,
        lastTest: last ?? i.lastTest,
      );
      info((i) => with_(i, testing: true));
      Timer(const Duration(milliseconds: 1100), () {
        info(
          (i) => with_(
            i,
            testing: false,
            last: const ProviderTestResult(
              ok: true,
              latencyMs: 842,
              message: '“你好！有什么可以帮你？”',
            ),
          ),
        );
      });
    },
    onSave: ({required providerId, required base, required edited, apiKey}) async {
      log('onSave($providerId, key: ${apiKey == null ? '不改' : '新 Key'})');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (++_saves % 3 == 0) {
        log('  → 模拟冲突：别处把超时改成了 150 秒');
        _provider(
          providerId,
          (p) => copy(p, settings: p.settings.copyWith(timeoutSeconds: 150)),
        );
        return ProvidersSaveResult.conflict;
      }
      _provider(
        providerId,
        (p) => copy(
          p,
          settings: edited,
          apiKeyMasked: apiKey == null
              ? p.apiKeyMasked
              : apiKey.isEmpty
              ? ''
              : '${apiKey.substring(0, apiKey.length.clamp(0, 3))}••••••••${apiKey.length > 4 ? apiKey.substring(apiKey.length - 4) : ''}',
        ),
      );
      return ProvidersSaveResult.saved;
    },
    onRevealApiKey: (id) async {
      log('onRevealApiKey($id)');
      return 'sk-preview-${id}0123456789abcdef';
    },
    onFetchCatalog: (id) {
      log('onFetchCatalog($id)');
      void put(ProviderCatalog c) => _set(
        ProvidersViewData(
          providers: data.providers,
          protocols: data.protocols,
          presets: data.presets,
          catalogs: {...data.catalogs, id: c},
        ),
      );
      final old = data.catalog(id);
      put(
        ProviderCatalog(
          state: ProviderCatalogState.loading,
          entries: old.entries,
        ),
      );
      Timer(const Duration(milliseconds: 800), () {
        if (id == 'relay') {
          return put(
            const ProviderCatalog(
              state: ProviderCatalogState.failed,
              error: '401 · API Key 无效',
            ),
          );
        }
        put(
          ProviderCatalog(
            state: ProviderCatalogState.ready,
            fetchedAt: ProvidersFixture.now,
            entries: old.entries.isNotEmpty
                ? old.entries
                : [
                    for (final m in _get(id).settings.models)
                      ProviderCatalogEntry(
                        id: m.id,
                        contextWindow: m.contextWindow,
                      ),
                    const ProviderCatalogEntry(
                      id: 'preview-extra-1',
                      contextWindow: 32000,
                    ),
                    const ProviderCatalogEntry(
                      id: 'preview-extra-2',
                      contextWindow: 128000,
                    ),
                  ],
          ),
        );
      });
    },
    onAddModels: (id, ids, {manual = false}) {
      log('onAddModels($id, $ids, manual: $manual)');
      final cat = data.catalog(id);
      _provider(
        id,
        (p) => copy(
          p,
          settings: p.settings.copyWith(
            models: [
              ...p.settings.models,
              for (final m in ids)
                ProviderModelSettings(
                  id: m,
                  contextWindow: cat.entries
                      .where((e) => e.id == m)
                      .firstOrNull
                      ?.contextWindow,
                ),
            ],
          ),
        ),
      );
    },
    onRemoveModel: (id, model) {
      log('onRemoveModel($id, $model)');
      _provider(
        id,
        (p) => copy(
          p,
          settings: p.settings.copyWith(
            models: [...p.settings.models]..removeWhere((m) => m.id == model),
          ),
        ),
      );
    },
    onReorderModels: (id, ids) {
      log('onReorderModels($id, $ids)');
      _provider(
        id,
        (p) => copy(
          p,
          settings: p.settings.copyWith(
            models: [for (final m in ids) p.settings.model(m)!],
          ),
        ),
      );
    },
    onDelete: (id) {
      log('onDelete($id)');
      _set(
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
