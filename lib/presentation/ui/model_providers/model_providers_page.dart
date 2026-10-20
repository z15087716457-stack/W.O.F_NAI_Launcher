import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../kit/ui_inputs.dart';
import '../settings/settings_contract.dart' show SettingsOption, SettingsTone;
import '../settings/settings_format.dart';
import '../settings/settings_kit.dart';
import '../settings/settings_page.dart'
    show SettingsDockBar, SettingsDockButton;
import 'model_providers_catalog.dart';
import 'model_providers_contract.dart';
import 'model_providers_controller.dart';
import 'model_providers_inspector.dart';
import 'model_providers_kit.dart';
import 'model_providers_picker.dart';

/// 服务商工作台（方案 B · 三栏检查器）：服务商列表 | 连接 + 请求 + 模型列表 | 模型检查器。
///
/// 放在设置页“模型与接口 → 服务商”标签里（外面已有卡片和标签栏）。
/// 宽度 ≥ 1040 时三栏；更窄时检查器移到中栏模型列表下方。
class ModelProvidersPanel extends StatefulWidget {
  const ModelProvidersPanel({
    super.key,
    required this.data,
    required this.actions,
    required this.now,
    this.confirm,
    this.onDirty,
    this.selectedId,
    this.controller,
  });

  /// 外部持有的界面状态（切标签不丢草稿）；null 时自己建。
  final ProvidersController? controller;

  final ProvidersViewData data;
  final ProvidersActions actions;
  final DateTime now;

  /// 弹确认框（删除服务商 / 移除模型）；null 时直接执行。
  final void Function({
    required String title,
    required String body,
    required String confirm,
    required VoidCallback onConfirm,
  })?
  confirm;

  /// 有 / 没有未保存修改（宿主切页前确认）。
  final ValueChanged<bool>? onDirty;

  /// 初始选中的服务商（搜索跳转 `provider-<id>`）。
  final String? selectedId;

  /// 三栏的最小宽度。
  static const threeColumn = 1040.0;

  @override
  State<ModelProvidersPanel> createState() => ModelProvidersPanelState();
}

class ModelProvidersPanelState extends State<ModelProvidersPanel> {
  late final ProvidersController ctrl =
      widget.controller ?? ProvidersController();
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedId case final id?) ctrl.select(id);
    ctrl.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant ModelProvidersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId &&
        widget.selectedId != null) {
      ctrl.select(widget.selectedId!);
    }
    if (widget.data != oldWidget.data) ctrl.sync(widget.data);
    _reportDirty();
  }

  @override
  void dispose() {
    ctrl.removeListener(_changed);
    if (widget.controller == null) ctrl.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _reportDirty();
  }

  void _reportDirty() {
    final d = ctrl.anyDirty(widget.data);
    if (d == _dirty) return;
    _dirty = d;
    final cb = widget.onDirty;
    if (cb != null) WidgetsBinding.instance.addPostFrameCallback((_) => cb(d));
  }

  void _ask({
    required String title,
    required String body,
    required String confirm,
    required VoidCallback onConfirm,
  }) {
    final c = widget.confirm;
    if (c == null) return onConfirm();
    c(title: title, body: body, confirm: confirm, onConfirm: onConfirm);
  }

  Future<void> _save(ProviderItem p) => ctrl.save(p, widget.actions);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final d = widget.data;
    final p = ctrl.selectedOf(d);
    if (p == null) {
      return _Empty(onAdd: () => ctrl.pickerOpen = true);
    }
    // 外层设置页整体滚动：三栏按内容长高，底色 / 分隔线铺满最高的一栏。
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= ModelProvidersPanel.threeColumn;
        final listW = wide ? 212.0 : 196.0;
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
              if (ctrl.changes(p) > 0) _save(p);
            },
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 640),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: listW,
                        decoration: BoxDecoration(
                          color: c.sunk,
                          border: Border(right: BorderSide(color: c.rowLine)),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (wide)
                        Container(
                          width: 336,
                          decoration: BoxDecoration(
                            color: c.sunk,
                            border: Border(left: BorderSide(color: c.rowLine)),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: listW,
                      child: _ProviderList(data: d, ctrl: ctrl, selected: p.id),
                    ),
                    Expanded(
                      child: _Middle(
                        key: ValueKey('mid-${p.id}'),
                        panel: this,
                        item: p,
                        inlineInspector: !wide,
                      ),
                    ),
                    if (wide)
                      SizedBox(
                        width: 336,
                        child: _InspectorColumn(panel: this, item: p),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 页面级浮层：底部保存条 + 添加服务商弹窗。放在设置页滚动区外面的 Stack 里（铺满内容区），
/// 这样保存条始终贴着窗口底部。
class ModelProvidersOverlays extends StatelessWidget {
  const ModelProvidersOverlays({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
  });
  final ProvidersViewData data;
  final ProvidersActions actions;
  final ProvidersController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final ctrl = controller;
      final p = ctrl.selectedOf(data);
      final draft = p == null ? null : ctrl.draft(p.id);
      final dock = p != null && (ctrl.changes(p) > 0 || draft?.result != null);
      return Stack(
        children: [
          if (dock)
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Center(
                child: _SaveDock(
                  item: p,
                  ctrl: ctrl,
                  onSave: () => ctrl.save(p, actions),
                ),
              ),
            ),
          if (ctrl.pickerOpen)
            Positioned.fill(
              child: ProvidersPicker(
                presets: data.presets,
                existing: {
                  for (final x in data.providers)
                    if (x.presetId != null) x.presetId!,
                },
                onClose: () => ctrl.pickerOpen = false,
                onPick: (id) async {
                  ctrl.pickerOpen = false;
                  final created = await actions.onCreate(id);
                  if (created != null) ctrl.select(created);
                },
              ),
            ),
        ],
      );
    },
  );
}

// ───────────────────────────── 左栏 ─────────────────────────────

class _ProviderList extends StatelessWidget {
  const _ProviderList({
    required this.data,
    required this.ctrl,
    required this.selected,
  });
  final ProvidersViewData data;
  final ProvidersController ctrl;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('mp-list'),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.set_mdProviderCount('${data.providers.length}'),
                    style: UiText.sans(11, color: c.faint),
                  ),
                ),
                SettingsIconBtn(
                  key: const Key('mp-add'),
                  glyph: UiGlyphs.plus,
                  tooltip: l.mp_pickerTitle,
                  size: 22,
                  onTap: () => ctrl.pickerOpen = true,
                ),
              ],
            ),
          ),
          for (final p in data.providers)
            SettingsAnchor(
              anchor: 'provider-${p.id}',
              radius: 9,
              child: UiPressable(
                key: Key('mp-provider-${p.id}'),
                onTap: () => ctrl.select(p.id),
                builder: (context, hover) {
                  final on = p.id == selected;
                  final dirty = ctrl.changes(p) > 0;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                    decoration: BoxDecoration(
                      color: on
                          ? c.accent.withValues(alpha: .09)
                          : hover
                          ? c.hover
                          : null,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      spacing: 10,
                      children: [
                        Opacity(
                          opacity: p.enabled ? 1 : .5,
                          child: ProviderLogo.of(p),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.settings.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(
                                  13,
                                  weight: FontWeight.w500,
                                  color: p.enabled ? c.ink : c.faint,
                                ),
                              ),
                              Text(
                                p.enabled
                                    ? l.set_mdModelCount(
                                        '${p.settings.models.length}',
                                      )
                                    : l.set_mdDisabled,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(11, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        if (dirty)
                          Container(
                            key: Key('mp-dirty-${p.id}'),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        else if (p.enabled)
                          SettingsDot(p.status),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 中栏 ─────────────────────────────

class _Middle extends StatefulWidget {
  const _Middle({
    super.key,
    required this.panel,
    required this.item,
    required this.inlineInspector,
  });
  final ModelProvidersPanelState panel;
  final ProviderItem item;
  final bool inlineInspector;

  @override
  State<_Middle> createState() => _MiddleState();
}

class _MiddleState extends State<_Middle> {
  var _reveal = false;
  String? _revealed;

  /// 上一帧草稿里的新 Key：从有到无（保存成功或放弃）时，[_revealed] 是旧 Key，
  /// 要丢掉重新读，否则保存后输入框会退回旧值、复制也会复制旧 Key。
  String? _lastDraftKey;
  var _renaming = false;
  var _manual = false;

  ProvidersController get ctrl => widget.panel.ctrl;
  ProvidersActions get actions => widget.panel.widget.actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final p = widget.item;
    final s = ctrl.display(p);
    final data = widget.panel.widget.data;
    final draft = ctrl.draft(p.id);
    final errors = ProvidersValidate.errors(s);
    final proto = data.protocol(s.protocolId);
    void edit(ProviderSettings Function(ProviderSettings) f) => ctrl.edit(p, f);

    final head = Row(
      spacing: 10,
      children: [
        ProviderLogo.of(p, size: 36),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_renaming)
                SizedBox(
                  width: 240,
                  child: ProviderInput(
                    key: const Key('mp-name'),
                    value: s.name,
                    autofocus: true,
                    height: 28,
                    error: errors.contains('name'),
                    onChanged: (v) => edit((x) => x.copyWith(name: v)),
                    onSubmitted: (_) => setState(() => _renaming = false),
                  ),
                )
              else
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        s.name,
                        key: const Key('mp-title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          15,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    ProviderTinyBtn(
                      key: const Key('mp-rename'),
                      glyph: UiGlyphs.pencil,
                      glyphSize: 13,
                      tooltip: l.mp_rename,
                      onTap: () => setState(() => _renaming = true),
                    ),
                  ],
                ),
              Text(
                proto?.label ?? s.protocolId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.muted),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: ProviderStatusPill(item: p, now: widget.panel.widget.now),
        ),
        SettingsBtn(
          key: const Key('mp-test'),
          label: p.testing ? l.mp_testing : l.mp_test,
          glyph: UiGlyphs.bolt,
          small: true,
          onTap: p.testing || !p.enabled
              ? null
              : () => actions.onTest(p.id, s, draft?.apiKey),
        ),
        SettingsSwitch(
          key: const Key('mp-enabled'),
          value: p.enabled,
          onChanged: (v) => actions.onEnabled(p.id, v),
        ),
      ],
    );

    if (_lastDraftKey != null && draft?.apiKey == null && _revealed != null) {
      _revealed = null;
      if (_reveal) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final k = await actions.onRevealApiKey(p.id);
          if (mounted && _reveal && ctrl.draft(p.id)?.apiKey == null) {
            setState(() => _revealed = k);
          }
        });
      }
    }
    _lastDraftKey = draft?.apiKey;
    final keyValue = draft?.apiKey ?? _revealed ?? '';
    final keyField = ProviderInput(
      key: const Key('mp-key'),
      value: keyValue,
      mono: true,
      obscure: !_reveal && draft?.apiKey != null,
      ghost:
          draft?.apiKey == null &&
              _revealed == null &&
              p.apiKeyMasked.isNotEmpty
          ? p.apiKeyMasked
          : null,
      hint: p.local ? l.mp_keyHintLocal : l.mp_keyHint,
      error: p.enabled && p.status == SettingsTone.error,
      onChanged: (v) => ctrl.setApiKey(p, v),
      trailing: [
        if (p.apiKeyMasked.isNotEmpty || draft?.apiKey != null)
          ProviderTinyBtn(
            key: const Key('mp-key-reveal'),
            glyph: _reveal ? UiGlyphs.eyeOff : ProvidersGlyphs.eye,
            tooltip: _reveal ? l.mp_hide : l.mp_show,
            onTap: () async {
              if (_reveal) {
                return setState(() {
                  _reveal = false;
                  _revealed = null;
                });
              }
              if (draft?.apiKey != null) return setState(() => _reveal = true);
              final k = await actions.onRevealApiKey(p.id);
              if (mounted && k != null) {
                setState(() {
                  _reveal = true;
                  _revealed = k;
                });
              }
            },
          ),
        if (p.apiKeyMasked.isNotEmpty || draft?.apiKey != null)
          ProviderTinyBtn(
            key: const Key('mp-key-copy'),
            glyph: UiGlyphs.copy,
            glyphSize: 13,
            tooltip: l.set_copy,
            onTap: () async {
              final k =
                  draft?.apiKey ??
                  _revealed ??
                  await actions.onRevealApiKey(p.id);
              if (k != null) await providersCopy(k);
            },
          ),
      ],
    );

    final connection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        ProviderField(
          label: l.set_mdBaseUrl,
          error: errors.contains('baseUrl') ? l.modelService_invalidUrl : null,
          child: ProviderInput(
            key: const Key('mp-url'),
            value: s.baseUrl,
            mono: true,
            error: errors.contains('baseUrl'),
            onChanged: (v) => edit((x) => x.copyWith(baseUrl: v)),
          ),
        ),
        LayoutBuilder(
          builder: (context, cs) {
            final key = ProviderField(label: l.set_mdApiKey, child: keyField);
            final protocol = ProviderField(
              label: l.mp_protocol,
              child: SettingsSelect(
                key: const Key('mp-protocol'),
                label: proto?.label ?? s.protocolId,
                width: double.infinity,
                menuWidth: 240,
                selected: s.protocolId,
                options: [
                  for (final x in data.protocols)
                    SettingsOption(value: x.id, label: x.label),
                ],
                onSelected: (v) => edit((x) => x.copyWith(protocolId: v)),
              ),
            );
            if (cs.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [key, protocol],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(child: key),
                Expanded(child: protocol),
              ],
            );
          },
        ),
        // 连接提示只在还没填 Key 时出现（新建 / 本机服务），已配置好的服务商不占位置。
        if (p.hint.isNotEmpty &&
            p.apiKeyMasked.isEmpty &&
            draft?.apiKey == null)
          Row(
            spacing: 6,
            children: [
              UiGlyph(ProvidersGlyphs.info, size: 13, color: c.faint),
              Expanded(
                child: Text(p.hint, style: UiText.sans(12, color: c.faint)),
              ),
            ],
          ),
      ],
    );

    final request = _RequestStrip(item: p, settings: s, ctrl: ctrl);
    final mode = ctrl.mode(p.id);
    final catalog = data.catalog(p.id);
    final listHead = LayoutBuilder(
      builder: (context, cs) => Row(
        spacing: 8,
        children: [
          UiSeg<ProvidersListMode>(
            key: const Key('mp-mode'),
            small: false,
            values: ProvidersListMode.values,
            selected: mode,
            labelOf: (m) => switch (m) {
              ProvidersListMode.added => '${l.mp_added} ${s.models.length}',
              ProvidersListMode.catalog =>
                catalog.entries.isEmpty
                    ? l.mp_catalog
                    : '${l.mp_catalog} ${catalog.entries.length}',
            },
            onChanged: (m) {
              ctrl.setMode(p.id, m);
              if (m == ProvidersListMode.catalog &&
                  catalog.state == ProviderCatalogState.idle) {
                actions.onFetchCatalog(p.id);
              }
            },
          ),
          const Spacer(),
          if (cs.maxWidth >= 480)
            Flexible(
              flex: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: UiSearchField(
                  key: Key('mp-filter-${mode.name}'),
                  value: ctrl.filter(p.id),
                  hint: l.mp_filter,
                  height: 30,
                  onChanged: (q) => ctrl.setFilter(p.id, q),
                ),
              ),
            ),
          if (mode == ProvidersListMode.catalog)
            SettingsBtn(
              key: const Key('mp-refresh'),
              label: l.set_refresh,
              glyph: UiGlyphs.refresh,
              small: true,
              tone: SettingsBtnTone.ghost,
              onTap: catalog.state == ProviderCatalogState.loading
                  ? null
                  : () => actions.onFetchCatalog(p.id),
            )
          else
            SettingsBtn(
              key: const Key('mp-manual'),
              label: l.mp_manualAdd,
              glyph: UiGlyphs.plus,
              small: true,
              tone: SettingsBtnTone.ghost,
              onTap: () => setState(() => _manual = true),
            ),
        ],
      ),
    );

    final models = mode == ProvidersListMode.catalog
        ? ProvidersCatalogList(
            item: p,
            settings: s,
            catalog: catalog,
            ctrl: ctrl,
            now: widget.panel.widget.now,
            onFetch: () => actions.onFetchCatalog(p.id),
          )
        : _ModelList(
            item: p,
            settings: s,
            ctrl: ctrl,
            onReorder: (ids) => actions.onReorderModels(p.id, ids),
          );

    return Container(
      key: const Key('mp-middle'),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          if (p.enabled && p.status == SettingsTone.error) ...[
            const SizedBox(height: 14),
            _ErrorBanner(
              item: p,
              onRetry: p.testing
                  ? null
                  : () => actions.onTest(p.id, s, draft?.apiKey),
            ),
          ],
          const SizedBox(height: 16),
          connection,
          const SizedBox(height: 18),
          _SectionTitle(title: l.mp_request, sub: l.mp_requestSub),
          const SizedBox(height: 12),
          request,
          const SizedBox(height: 18),
          listHead,
          if (_manual && mode == ProvidersListMode.added) ...[
            const SizedBox(height: 8),
            _ManualAdd(
              existing: {for (final m in s.models) m.id},
              onAdd: (id) {
                setState(() => _manual = false);
                actions.onAddModels(p.id, [id], manual: true);
                ctrl.selectModel(p.id, id);
              },
              onCancel: () => setState(() => _manual = false),
            ),
          ],
          const SizedBox(height: 10),
          models,
          if (widget.inlineInspector && mode == ProvidersListMode.added) ...[
            const SizedBox(height: 16),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _InspectorColumn(panel: widget.panel, item: p),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              SettingsBtn(
                key: const Key('mp-delete'),
                label: l.set_mdDelete,
                glyph: ProvidersGlyphs.trash,
                small: true,
                tone: SettingsBtnTone.ghost,
                onTap: () => widget.panel._ask(
                  title: l.set_mdDeleteTitle(s.name),
                  body: l.set_mdDeleteBody,
                  confirm: l.set_delete,
                  onConfirm: () {
                    ctrl.discard(p.id);
                    actions.onDelete(p.id);
                  },
                ),
              ).danger(context),
              const Spacer(),
              if (mode == ProvidersListMode.added && s.models.length > 1)
                Flexible(
                  child: Text(
                    l.mp_dragHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(11, color: c.faint),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on SettingsBtn {
  /// 幽灵按钮但红字（原型 `.btn.ghost.dngt`）。
  Widget danger(BuildContext context) => DefaultTextStyle.merge(
    child: IconTheme.merge(
      data: IconThemeData(color: context.ui.error),
      child: _DangerGhost(btn: this),
    ),
  );
}

class _DangerGhost extends StatelessWidget {
  const _DangerGhost({required this.btn});
  final SettingsBtn btn;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: btn.key,
      onTap: btn.onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: hover ? c.error.withValues(alpha: .08) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (btn.glyph != null)
              UiGlyph(btn.glyph!, size: 14, color: c.error),
            Text(
              btn.label,
              style: UiText.sans(
                12,
                weight: FontWeight.w500,
                color: c.error,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.sub});
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 10,
      children: [
        Text(
          title,
          style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
        ),
        if (sub != null)
          Flexible(
            child: Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.muted),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.item, required this.onRetry});
  final ProviderItem item;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('mp-error'),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.error.withValues(alpha: .05), c.card),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color.lerp(c.border, c.error, .30)!),
      ),
      child: Row(
        spacing: 10,
        children: [
          UiGlyph(ProvidersGlyphs.alert, size: 15, color: c.error),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l.set_mdUnreachable,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · ${item.error}'),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12.5, color: c.ink),
            ),
          ),
          SettingsBtn(label: l.set_retry, small: true, onTap: onRetry),
        ],
      ),
    );
  }
}

/// 请求控制条：超时 / 并发 / 重试 / 图片输入 + 自定义请求头。
class _RequestStrip extends StatelessWidget {
  const _RequestStrip({
    required this.item,
    required this.settings,
    required this.ctrl,
  });
  final ProviderItem item;
  final ProviderSettings settings;
  final ProvidersController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = settings;
    void edit(ProviderSettings Function(ProviderSettings) f) =>
        ctrl.edit(item, f);
    final errs = ProvidersValidate.errors(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 28,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ProviderField(
              label: l.mp_timeout,
              help: l.mp_timeoutHelp,
              child: ProviderNumBox(
                key: const Key('mp-timeout'),
                value: s.timeoutSeconds,
                min: ProviderSettings.timeoutRange.min,
                max: ProviderSettings.timeoutRange.max,
                step: 10,
                unit: l.mp_seconds,
                valueWidth: 52,
                onChanged: (v) => edit(
                  (x) => x.copyWith(
                    timeoutSeconds: v ?? ProviderSettings.timeoutRange.min,
                  ),
                ),
              ),
            ),
            ProviderField(
              label: l.mp_concurrency,
              help: l.mp_concurrencyHelp,
              child: ProviderNumBox(
                key: const Key('mp-concurrency'),
                value: s.maxConcurrency,
                min: ProviderSettings.concurrencyRange.min,
                max: ProviderSettings.concurrencyRange.max,
                step: 1,
                unit: l.mp_countUnit,
                valueWidth: 40,
                onChanged: (v) => edit(
                  (x) => x.copyWith(
                    maxConcurrency: v ?? ProviderSettings.concurrencyRange.min,
                  ),
                ),
              ),
            ),
            ProviderField(
              label: l.mp_retry,
              help: l.mp_retryHelp,
              child: UiSeg<int>(
                key: const Key('mp-retry'),
                values: const [0, 1, 2, 3],
                selected: s.retryAttempts,
                labelOf: (v) => v == 0 ? l.mp_retryOff : '$v',
                onChanged: (v) => edit((x) => x.copyWith(retryAttempts: v)),
              ),
            ),
            ProviderField(
              label: l.mp_imageInput,
              help: l.mp_imageInputHelp,
              child: SizedBox(
                height: 28,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    SettingsSwitch(
                      key: const Key('mp-image'),
                      value: s.imageInput,
                      onChanged: (v) => edit((x) => x.copyWith(imageInput: v)),
                    ),
                    Text(
                      s.imageInput ? l.mp_allow : l.mp_noSend,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const ProviderDashLine(),
        const SizedBox(height: 10),
        Row(
          spacing: 8,
          children: [
            Text(l.mp_headers, style: UiText.sans(12, color: c.muted)),
            if (s.headers.isEmpty)
              Text(l.mp_none, style: UiText.sans(12, color: c.faint))
            else
              UiMini('${s.headers.length}'),
            const Spacer(),
            SettingsBtn(
              key: const Key('mp-add-header'),
              label: l.mp_addHeader,
              glyph: UiGlyphs.plus,
              small: true,
              tone: SettingsBtnTone.ghost,
              onTap: () => edit(
                (x) => x.copyWith(
                  headers: [...x.headers, const ProviderKeyValue('', '')],
                ),
              ),
            ),
          ],
        ),
        if (s.headers.isNotEmpty) ...[
          const SizedBox(height: 8),
          ProviderKeyValues(
            key: const Key('mp-headers'),
            keyPrefix: 'mp-header',
            items: s.headers,
            errors: {
              for (final (i, _) in s.headers.indexed)
                if (errs.contains('header:$i')) i,
            },
            onChanged: (v) => edit((x) => x.copyWith(headers: v)),
          ),
        ],
      ],
    );
  }
}

/// 手动添加模型：一行输入框，回车添加，Esc 取消。
class _ManualAdd extends StatefulWidget {
  const _ManualAdd({
    required this.existing,
    required this.onAdd,
    required this.onCancel,
  });
  final Set<String> existing;
  final ValueChanged<String> onAdd;
  final VoidCallback onCancel;

  @override
  State<_ManualAdd> createState() => _ManualAddState();
}

class _ManualAddState extends State<_ManualAdd> {
  var _v = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = _v.trim();
    final dup = widget.existing.contains(id);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel,
      },
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: ProviderInput(
              key: const Key('mp-manual-input'),
              value: '',
              mono: true,
              autofocus: true,
              hint: l.mp_manualHint,
              error: dup,
              onChanged: (v) => setState(() => _v = v),
              onSubmitted: (_) {
                if (id.isNotEmpty && !dup) widget.onAdd(id);
              },
            ),
          ),
          SettingsBtn(
            key: const Key('mp-manual-confirm'),
            label: dup ? l.mp_added : l.common_add,
            small: true,
            tone: SettingsBtnTone.primary,
            onTap: id.isEmpty || dup ? null : () => widget.onAdd(id),
          ),
          SettingsBtn(
            label: l.set_cancel,
            small: true,
            tone: SettingsBtnTone.ghost,
            onTap: widget.onCancel,
          ),
        ],
      ),
    );
  }
}

/// 已添加的模型：可拖动排序，点选打开右侧检查器。
class _ModelList extends StatelessWidget {
  const _ModelList({
    required this.item,
    required this.settings,
    required this.ctrl,
    required this.onReorder,
  });
  final ProviderItem item;
  final ProviderSettings settings;
  final ProvidersController ctrl;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final q = ctrl.filter(item.id).toLowerCase();
    final all = settings.models;
    final shown = q.isEmpty
        ? all
        : all
              .where(
                (m) =>
                    m.id.toLowerCase().contains(q) ||
                    m.alias.toLowerCase().contains(q),
              )
              .toList();
    final current = ctrl.modelOf(settings, item.id);
    final box = BoxDecoration(
      color: c.card,
      border: Border.all(color: c.border),
      borderRadius: BorderRadius.circular(9),
    );
    if (all.isEmpty || shown.isEmpty) {
      return Container(
        key: const Key('mp-models-empty'),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: box,
        child: Column(
          spacing: 4,
          children: [
            Text(
              all.isEmpty ? l.mp_noModels : l.mp_noMatch,
              style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
            ),
            if (all.isEmpty)
              Text(
                l.mp_noModelsSub,
                textAlign: TextAlign.center,
                style: UiText.sans(12, color: c.muted),
              ),
          ],
        ),
      );
    }
    Widget row(int i, ProviderModelSettings m) {
      final info = item.info(m.id);
      final on = m.id == current?.id;
      final sub = info.usedFor.isNotEmpty
          ? l.set_mdUsedFor(
              info.usedFor
                  .map((t) => SettingsFormat.task(context, t))
                  .join(' · '),
            )
          : m.alias.isNotEmpty
          ? m.alias
          : info.detail.isNotEmpty
          ? info.detail
          : '—';
      final level = m.reasoningLevels == null
          ? l.mp_unconfirmed
          : m.reasoningLevels!.isEmpty
          ? l.mp_unsupported
          : providerLevelLabel(context, m.effectiveDefault);
      return UiPressable(
        key: Key('mp-model-${m.id}'),
        onTap: () => ctrl.selectModel(item.id, m.id),
        builder: (context, hover) => Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
          decoration: BoxDecoration(
            color: on
                ? c.accent.withValues(alpha: .08)
                : hover
                ? c.hover
                : null,
            border: Border(
              left: BorderSide(
                color: on ? c.accent : Colors.transparent,
                width: 2,
              ),
              top: i == 0 ? BorderSide.none : BorderSide(color: c.rowLine),
            ),
          ),
          child: Row(
            spacing: 10,
            children: [
              q.isEmpty
                  ? ReorderableDragStartListener(
                      index: i,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: UiGlyph(
                          UiGlyphs.drag,
                          size: 13,
                          color: c.faint.withValues(alpha: .6),
                        ),
                      ),
                    )
                  : const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.mono(
                        12,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ],
                ),
              ),
              if (info.retired) UiMini(l.set_mdRetired, tone: UiMiniTone.warn),
              if (ctrl.draft(item.id) case final d?
                  when d.base.model(m.id) != null &&
                      m.differences(d.base.model(m.id)!) > 0)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ProviderCapIcons(m.capabilities),
              SizedBox(
                width: 76,
                child: Text(
                  '${providerTokens(m.contextWindow)} / ${providerTokens(m.maxOutput)}',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  style: UiText.mono(11, color: c.muted),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  level,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    12,
                    color: m.reasoningLevels?.isNotEmpty == true
                        ? c.ink
                        : c.faint,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      key: const Key('mp-models'),
      clipBehavior: Clip.antiAlias,
      decoration: box,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: shown.length,
        proxyDecorator: (child, _, _) => Material(
          color: c.card,
          elevation: 6,
          shadowColor: Colors.black26,
          child: child,
        ),
        onReorderItem: (from, to) {
          final ids = [for (final m in all) m.id];
          ids.insert(to, ids.removeAt(from));
          onReorder(ids);
        },
        itemBuilder: (context, i) =>
            KeyedSubtree(key: ValueKey(shown[i].id), child: row(i, shown[i])),
      ),
    );
  }
}

// ───────────────────────────── 右栏 ─────────────────────────────

class _InspectorColumn extends StatelessWidget {
  const _InspectorColumn({required this.panel, required this.item});
  final ModelProvidersPanelState panel;
  final ProviderItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final ctrl = panel.ctrl;
    final s = ctrl.display(item);
    final data = panel.widget.data;
    final mode = ctrl.mode(item.id);
    final child = mode == ProvidersListMode.catalog
        ? ProvidersPickTray(
            item: item,
            settings: s,
            ctrl: ctrl,
            onAdd: (ids) {
              panel.widget.actions.onAddModels(item.id, ids);
              ctrl
                ..clearPicks(item.id)
                ..setMode(item.id, ProvidersListMode.added);
              if (ids.isNotEmpty) ctrl.selectModel(item.id, ids.first);
            },
          )
        : switch (ctrl.modelOf(s, item.id)) {
            null => const SizedBox.shrink(),
            final m => ProvidersInspector(
              key: ValueKey('insp-${item.id}-${m.id}'),
              item: item,
              model: m,
              protocol: data.protocol(s.protocolId),
              onEdit: (f) => ctrl.editModel(item, m.id, f),
              onTest: () => panel.widget.actions.onTestModel(
                item.id,
                m.id,
                s,
                ctrl.draft(item.id)?.apiKey,
              ),
              onRemove: () {
                final l = context.l10n;
                panel._ask(
                  title: l.mp_removeTitle(m.id),
                  body: l.mp_removeBody,
                  confirm: l.mp_removeModel,
                  onConfirm: () =>
                      panel.widget.actions.onRemoveModel(item.id, m.id),
                );
              },
            ),
          };
    return Container(
      key: const Key('mp-inspector'),
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(11)),
      ),
      child: child,
    );
  }
}

// ───────────────────────────── 底部 / 空态 ─────────────────────────────

class _SaveDock extends StatelessWidget {
  const _SaveDock({
    required this.item,
    required this.ctrl,
    required this.onSave,
  });
  final ProviderItem item;
  final ProvidersController ctrl;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = ctrl.draft(item.id);
    final n = ctrl.changes(item);
    final errs = ProvidersValidate.errors(ctrl.display(item)).length;
    final saving = d?.saving ?? false;
    final (glyph, tone, text) = saving
        ? (null, c.tipInk, l.mp_saving)
        : errs > 0
        ? (ProvidersGlyphs.alert, c.warn, l.mp_invalid('$errs'))
        : switch (d?.result) {
            ProvidersSaveResult.conflict => (
              ProvidersGlyphs.alert,
              c.warn,
              l.mp_conflict,
            ),
            ProvidersSaveResult.failed => (
              ProvidersGlyphs.alert,
              c.error,
              l.mp_saveFailed,
            ),
            _ => (
              UiGlyphs.infoCircle,
              c.tipInk,
              l.mp_unsaved(item.settings.name, '$n'),
            ),
          };
    return SettingsDockBar(
      key: const Key('mp-dock'),
      children: [
        if (glyph == null)
          const UiSpinner(size: 14)
        else
          UiGlyph(glyph, size: 15, color: tone),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12.5, color: c.tipInk),
          ),
        ),
        Text(
          'Ctrl+S',
          style: UiText.mono(
            10.5,
            weight: FontWeight.w500,
            color: c.tipInk.withValues(alpha: .55),
          ),
        ),
        SettingsDockButton(
          label: l.set_discard,
          onTap: saving || n == 0 ? null : () => ctrl.discard(item.id),
        ),
        SettingsDockButton(
          label: l.set_save,
          primary: true,
          onTap: saving || n == 0 || errs > 0 ? null : onSave,
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Padding(
      key: const Key('mp-empty'),
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      child: Column(
        spacing: 6,
        children: [
          Text(
            l.set_mdEmpty,
            style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
          ),
          Text(l.set_mdEmptySub, style: UiText.sans(12, color: c.muted)),
          const SizedBox(height: 8),
          SettingsBtn(
            key: const Key('mp-empty-add'),
            label: l.set_mdAddProvider,
            glyph: UiGlyphs.plus,
            small: true,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
