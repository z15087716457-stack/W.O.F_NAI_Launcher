import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'model_providers_contract.dart';

/// 中栏模型列表的两种视图。
enum ProvidersListMode { added, catalog }

/// 一个服务商的未保存草稿。
///
/// [base] 是开始编辑时的已保存配置，[edited] 是用户改过的完整配置。显示值 = 以最新已保存配置为底，
/// 叠上用户相对 [base] 改过的字段（[ProviderSettings.merge]）：别处的修改不会被旧读数覆盖，
/// 用户的修改也不会被刷新掉。
class ProviderDraft {
  ProviderDraft(this.base, this.edited);
  ProviderSettings base;
  ProviderSettings edited;
  // Saved snapshot plus only the user's edits made while saving.
  ProviderSettings? _afterSave;

  /// 新 Key；null = 不改，空串 = 清除。
  String? apiKey;
  var saving = false;
  ProvidersSaveResult? result;

  ProviderSettings display(ProviderSettings latest) =>
      base == latest ? edited : ProviderSettings.merge(base, edited, latest);

  int changes(ProviderSettings latest) =>
      display(latest).differences(latest) + (apiKey == null ? 0 : 1);
}

/// 服务商工作台的界面状态：选中项、草稿、目录勾选、添加弹窗。不接后端，只调 [ProvidersActions]。
class ProvidersController extends ChangeNotifier {
  String? _selected;
  final _model = <String, String>{};
  final _mode = <String, ProvidersListMode>{};
  final _filter = <String, String>{};
  final _picks = <String, Set<String>>{};
  final _drafts = <String, ProviderDraft>{};
  var _pickerOpen = false;
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── 选中

  /// 当前服务商：选中的还在就用它，否则第一个。
  ProviderItem? selectedOf(ProvidersViewData d) =>
      d.providers.where((p) => p.id == _selected).firstOrNull ??
      d.providers.firstOrNull;

  void select(String providerId) {
    if (_selected == providerId) return;
    _selected = providerId;
    _notify();
  }

  /// 当前模型：选中的还在就用它，否则第一个。
  ProviderModelSettings? modelOf(ProviderSettings s, String providerId) =>
      s.model(_model[providerId] ?? '') ?? s.models.firstOrNull;

  void selectModel(String providerId, String modelId) {
    _model[providerId] = modelId;
    _mode[providerId] = ProvidersListMode.added;
    _notify();
  }

  ProvidersListMode mode(String providerId) =>
      _mode[providerId] ?? ProvidersListMode.added;

  void setMode(String providerId, ProvidersListMode m) {
    _mode[providerId] = m;
    _notify();
  }

  String filter(String providerId) => _filter[providerId] ?? '';

  void setFilter(String providerId, String q) {
    _filter[providerId] = q;
    _notify();
  }

  // ── 目录勾选

  Set<String> picks(String providerId) => _picks[providerId] ?? const {};

  void togglePick(String providerId, String modelId) {
    final s = {...picks(providerId)};
    s.contains(modelId) ? s.remove(modelId) : s.add(modelId);
    _picks[providerId] = s;
    _notify();
  }

  void clearPicks(String providerId) {
    _picks.remove(providerId);
    _notify();
  }

  // ── 添加弹窗

  bool get pickerOpen => _pickerOpen;
  set pickerOpen(bool v) {
    if (_pickerOpen == v) return;
    _pickerOpen = v;
    _notify();
  }

  // ── 草稿

  ProviderDraft? draft(String providerId) => _drafts[providerId];

  /// 界面上显示的配置（已保存 + 草稿）。
  ProviderSettings display(ProviderItem p) =>
      _drafts[p.id]?.display(p.settings) ?? p.settings;

  int changes(ProviderItem p) => _drafts[p.id]?.changes(p.settings) ?? 0;

  /// 任何服务商有未保存修改。
  bool anyDirty(ProvidersViewData d) => d.providers.any((p) => changes(p) > 0);

  /// 改草稿：先以最新已保存配置为底重新定基，再套用 [f]。
  void edit(ProviderItem p, ProviderSettings Function(ProviderSettings) f) {
    final d = _drafts[p.id];
    final before = display(p);
    final next = f(before);
    if (d == null) {
      _drafts[p.id] = ProviderDraft(p.settings, next);
    } else {
      if (d._afterSave case final pending?) {
        // Model membership is immediate; only this edit's changed fields are pending.
        final projection = ProviderSettings.merge(before, pending, before);
        d._afterSave = ProviderSettings.merge(before, next, projection);
      }
      d
        ..base = p.settings
        ..edited = next
        ..result = null;
    }
    _prune(p);
    _notify();
  }

  void editModel(
    ProviderItem p,
    String modelId,
    ProviderModelSettings Function(ProviderModelSettings) f,
  ) => edit(p, (s) {
    final m = s.model(modelId);
    return m == null ? s : s.withModel(f(m));
  });

  void setApiKey(ProviderItem p, String? key) {
    final d = _drafts[p.id] ??= ProviderDraft(p.settings, p.settings);
    d
      ..apiKey = key
      ..result = null;
    _prune(p);
    _notify();
  }

  void discard(String providerId) {
    _drafts.remove(providerId);
    _notify();
  }

  void _prune(ProviderItem p) {
    final d = _drafts[p.id];
    if (d != null && !d.saving && d.changes(p.settings) == 0) {
      _drafts.remove(p.id);
    }
  }

  /// 数据刷新后丢掉已经没有差异的草稿（例如别处改成了同样的值）。
  void sync(ProvidersViewData data) {
    for (final p in data.providers) {
      _prune(p);
    }
    final ids = {for (final p in data.providers) p.id};
    _drafts.removeWhere((id, d) => !ids.contains(id) && !d.saving);
  }

  /// 保存。保存期间仍可继续编辑：成功后把“已发送”的配置当作新的起点，期间的修改继续留在草稿里。
  Future<ProvidersSaveResult?> save(
    ProviderItem p,
    ProvidersActions actions,
  ) async {
    final d = _drafts[p.id];
    if (d == null || d.saving) return null;
    final sent = d.display(p.settings);
    final sentKey = d.apiKey;
    d
      ..base = p.settings
      ..edited = sent
      .._afterSave = sent
      ..saving = true
      ..result = null;
    _notify();
    ProvidersSaveResult r;
    try {
      r = await actions.onSave(
        providerId: p.id,
        base: p.settings,
        edited: sent,
        apiKey: sentKey,
      );
    } catch (_) {
      r = ProvidersSaveResult.failed;
    }
    if (_disposed || !identical(_drafts[p.id], d)) return r;
    d.saving = false;
    final afterSave = d._afterSave!;
    d._afterSave = null;
    if (r == ProvidersSaveResult.saved) {
      // Models added after submission use their observed settings as the base.
      d
        ..base = sent.copyWith(
          models: [
            for (final model in d.base.models) sent.model(model.id) ?? model,
          ],
        )
        ..edited = afterSave;
      if (d.apiKey == sentKey) d.apiKey = null;
      // 成功后若已无差异，在下一次数据同步 / 这里清掉。
      if (d.changes(d.base) == 0) {
        _drafts.remove(p.id);
      }
    } else {
      d.result = r;
    }
    _notify();
    return r;
  }
}

/// 草稿校验：返回出错的字段键（界面按键标红，保存按钮置灰）。
abstract final class ProvidersValidate {
  static final _url = RegExp(r'^https?://[^\s/]+', caseSensitive: false);
  static final _header = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

  static bool url(String v) => _url.hasMatch(v.trim());
  static bool headerName(String v) => _header.hasMatch(v);
  static bool json(String v) {
    final t = v.trim();
    if (t.isEmpty) return false;
    try {
      jsonDecode(t);
      return true;
    } on FormatException {
      return false;
    }
  }

  static bool outputTooLarge(ProviderModelSettings m) =>
      m.contextWindow != null &&
      m.maxOutput != null &&
      m.maxOutput! > m.contextWindow!;

  /// 有错的字段键：`name`、`baseUrl`、`header:<i>`、`<model>:maxOutput`、`<model>:body:<i>`、`<model>:header:<i>`。
  static Set<String> errors(ProviderSettings s) => {
    if (s.name.trim().isEmpty) 'name',
    if (!url(s.baseUrl)) 'baseUrl',
    for (final (i, h) in s.headers.indexed)
      if (!headerName(h.key)) 'header:$i',
    for (final m in s.models) ...{
      if (outputTooLarge(m)) '${m.id}:maxOutput',
      for (final (i, b) in m.body.indexed)
        if (b.key.trim().isEmpty || !json(b.value)) '${m.id}:body:$i',
      for (final (i, h) in m.headers.indexed)
        if (!headerName(h.key)) '${m.id}:header:$i',
    },
  };
}
