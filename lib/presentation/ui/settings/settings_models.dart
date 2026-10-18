import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/models/prompt_task_definitions.dart'
    show reasoningEffortLabel;
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../model_providers/model_providers_controller.dart';
import '../model_providers/model_providers_page.dart';
import 'settings_contract.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_scope.dart';

enum _Tab { providers, tasks, presets, requests }

/// 模型与接口（宽页，无侧注）：服务商 / 功能分配 / 提示词预设 / 请求记录。
class SettingsModelsPage extends StatefulWidget {
  const SettingsModelsPage({super.key, this.initialTab});

  /// 测试与预览用：直接打开某个标签页（`tasks`、`presets`、`requests`）。
  final String? initialTab;

  @override
  State<SettingsModelsPage> createState() => _SettingsModelsPageState();
}

class _SettingsModelsPageState extends State<SettingsModelsPage> {
  late var _tab = _Tab.values.firstWhere(
    (t) => t.name == widget.initialTab,
    orElse: () => _Tab.providers,
  );
  final _taskScroll = ScrollController();
  final _requestScroll = ScrollController();

  /// 工作台状态（选中项、草稿）跨标签保留。
  final _workbench = ProvidersController();
  String? _handled;

  @override
  void dispose() {
    _workbench.dispose();
    _taskScroll.dispose();
    _requestScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final m = s.data.models;
    final labels = {
      _Tab.providers: l.set_mdProviders,
      _Tab.tasks: l.set_mdTasks,
      _Tab.presets: l.set_mdPresets,
      _Tab.requests: l.set_mdRequests,
    };
    final page = SettingsPageFrame(
      wide: true,
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.models),
        title: l.set_pageModels,
        description: l.set_mdDesc,
      ),
      children: [
        SettingsCard(
          divided: false,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rowLine)),
              ),
              child: Row(
                spacing: 2,
                children: [
                  for (final t in _Tab.values)
                    UiPressable(
                      key: Key('models-tab-${t.name}'),
                      onTap: () => setState(() => _tab = t),
                      builder: (context, hover) => Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tab == t ? c.ink : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          spacing: 6,
                          children: [
                            Text(
                              labels[t]!,
                              style: UiText.sans(
                                13,
                                weight: _tab == t
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _tab == t || hover ? c.ink : c.muted,
                              ),
                            ),
                            if (t == _Tab.requests && m.requestTotal > 0)
                              Text(
                                '${m.requestTotal}',
                                style: UiText.mono(11, color: c.faint),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            switch (_tab) {
              _Tab.providers => _providers(context, m),
              _Tab.tasks => _tasks(context, m),
              _Tab.presets => _presets(context, m),
              _Tab.requests => _requests(context, m),
            },
          ],
        ),
        if (_tab == _Tab.tasks)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.set_mdTaskHint,
              key: const Key('models-task-hint'),
              textAlign: TextAlign.right,
              style: UiText.sans(11, color: c.muted, height: 1.5),
            ),
          ),
      ],
    );
    final wb = m.workbench;
    if (wb == null) return page;
    return Stack(
      children: [
        Positioned.fill(child: page),
        Positioned.fill(
          child: ModelProvidersOverlays(
            data: wb,
            actions: s.actions.providers,
            controller: _workbench,
          ),
        ),
      ],
    );
  }

  Widget _providers(BuildContext context, SettingsModelsData m) {
    final s = SettingsScope.of(context);
    if (m.workbench case final wb?) {
      final hl = s.highlight;
      if (hl == 'provider-add' && _handled != hl) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _workbench.pickerOpen = true;
        });
      }
      _handled = hl;
      return ModelProvidersPanel(
        data: wb,
        actions: s.actions.providers,
        now: s.data.now,
        controller: _workbench,
        selectedId:
            hl != null && hl.startsWith('provider-') && hl != 'provider-add'
            ? hl.substring(9)
            : null,
        onDirty: s.reportDirty,
        confirm:
            ({
              required title,
              required body,
              required confirm,
              required onConfirm,
            }) => s.confirm(
              title: title,
              body: body,
              confirm: confirm,
              danger: true,
              onConfirm: onConfirm,
            ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _tasks(BuildContext context, SettingsModelsData m) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final head = UiText.sans(11, weight: FontWeight.w500, color: c.faint);
    Widget line(List<Widget> cells, {EdgeInsets? pad}) => Padding(
      padding: pad ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        spacing: 16,
        children: [
          SizedBox(width: 120, child: cells[0]),
          SizedBox(width: 150, child: cells[1]),
          SizedBox(width: 190, child: cells[2]),
          SizedBox(width: 130, child: cells[3]),
          SizedBox(width: 150, child: cells[4]),
          Expanded(child: cells[5]),
        ],
      ),
    );
    final table = Column(
      key: const Key('models-task-table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line([
          Text(l.set_mdFeature, style: head),
          Text(l.set_mdProvider, style: head),
          Text(l.set_mdModel, style: head),
          Row(
            spacing: 4,
            children: [
              Flexible(child: Text(l.modelReasoning_strength, style: head)),
              Tooltip(
                key: const Key('models-reasoning-help'),
                message: l.modelSettings_reasoningHelp,
                waitDuration: const Duration(milliseconds: 450),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: UiGlyph(UiGlyphs.help, size: 13, color: c.faint),
                  ),
                ),
              ),
            ],
          ),
          Text(l.set_mdPreset, style: head),
          Text(l.set_mdStatus, style: head),
        ], pad: const EdgeInsets.fromLTRB(18, 12, 18, 8)),
        for (final a in m.assignments) ...[
          Container(height: 1, color: c.rowLine),
          SettingsAnchor(
            anchor: 'task-${a.task.name}',
            radius: 0,
            child: Builder(
              builder: (context) {
                final p = m.providers
                    .where((x) => x.id == a.providerId)
                    .firstOrNull;
                final presets = m.presets
                    .where((x) => x.task == a.task)
                    .toList();
                final model = p?.models
                    .where((x) => x.id == a.modelId)
                    .firstOrNull;
                final efforts = model?.reasoningEfforts;
                final effort = efforts?.contains(a.reasoningEffort) == true
                    ? a.reasoningEffort
                    : null;
                final unsupported = efforts?.isEmpty == true;
                return line([
                  Text(
                    SettingsFormat.task(context, a.task),
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                  SettingsSelect(
                    key: Key('assign-provider-${a.task.name}'),
                    width: 150,
                    label: p?.name ?? '—',
                    selected: a.providerId,
                    options: [
                      for (final x in m.providers.where((x) => x.enabled))
                        SettingsOption(value: x.id, label: x.name),
                    ],
                    onSelected: (id) => s.actions.onAssign(
                      a.task,
                      providerId: id,
                      presetId: a.presetId,
                    ),
                  ),
                  SettingsSelect(
                    key: Key('assign-model-${a.task.name}'),
                    width: 190,
                    label: a.modelId ?? l.set_mdNotChosen,
                    selected: a.modelId,
                    options: [
                      for (final x in p?.models ?? const <SettingsModel>[])
                        if (!x.retired)
                          SettingsOption(
                            value: x.id,
                            label: x.id,
                            detail: x.detail,
                          ),
                    ],
                    menuWidth: 260,
                    onSelected: (id) => s.actions.onAssign(
                      a.task,
                      providerId: a.providerId,
                      modelId: id,
                      presetId: a.presetId,
                    ),
                  ),
                  SettingsSelect(
                    key: Key('assign-reasoning-${a.task.name}'),
                    width: 130,
                    menuWidth: 260,
                    label: model == null
                        ? '—'
                        : unsupported
                        ? l.modelReasoning_unsupported
                        : effort != null
                        ? reasoningEffortLabel(l, effort)
                        : l.modelReasoning_followModel,
                    selected: effort ?? 'inherit',
                    options: [
                      if (p?.enabled == true &&
                          model != null &&
                          !model.retired &&
                          !unsupported) ...[
                        SettingsOption(
                          value: 'inherit',
                          label: l.modelReasoning_followModel,
                          detail: l.modelReasoning_modelDefault(
                            reasoningEffortLabel(
                              l,
                              model.defaultReasoningEffort,
                            ),
                          ),
                        ),
                        for (final value in efforts ?? const <String>[])
                          SettingsOption(
                            value: value,
                            label: reasoningEffortLabel(l, value),
                          ),
                      ],
                    ],
                    onSelected: (value) => s.actions.onAssign(
                      a.task,
                      providerId: a.providerId,
                      modelId: a.modelId,
                      reasoningEffort: value == 'inherit' ? null : value,
                      clearReasoningEffort: value == 'inherit',
                    ),
                  ),
                  SettingsSelect(
                    key: Key('assign-preset-${a.task.name}'),
                    width: 150,
                    label:
                        presets
                            .where((x) => x.id == a.presetId)
                            .firstOrNull
                            ?.name ??
                        '—',
                    selected: a.presetId,
                    options: [
                      for (final x in presets)
                        SettingsOption(value: x.id, label: x.name),
                    ],
                    onSelected: (id) => s.actions.onAssign(
                      a.task,
                      providerId: a.providerId,
                      modelId: a.modelId,
                      presetId: id,
                    ),
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      SettingsDot(
                        a.fallback ? SettingsTone.warn : SettingsTone.ok,
                      ),
                      Expanded(
                        child: Text(
                          a.fallback ? l.set_mdFallback : l.set_mdAvailable,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            12,
                            color: a.fallback ? c.warn : c.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]);
              },
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumWidth = 980 * MediaQuery.textScalerOf(context).scale(1);
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            key: const Key('models-task-scrollbar'),
            controller: _taskScroll,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              key: const Key('models-task-scroll'),
              controller: _taskScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < minimumWidth
                    ? minimumWidth
                    : constraints.maxWidth,
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _presets(BuildContext context, SettingsModelsData m) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in m.presets) ...[
          SettingsRow(
            key: Key('preset-${p.id}'),
            minHeight: 50,
            title: p.name,
            subtitle: SettingsFormat.task(context, p.task),
            badges: [if (p.builtin) UiMini(l.set_mdBuiltin)],
            control: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                SettingsBtn(
                  label: l.set_mdEdit,
                  small: true,
                  tone: SettingsBtnTone.ghost,
                  onTap: () => s.actions.onEditPreset(p.id),
                ),
                if (!p.builtin)
                  SettingsIconBtn(
                    glyph: SettingsGlyphs.trash,
                    tooltip: l.set_delete,
                    onTap: () => s.actions.onDeletePreset(p.id),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: c.rowLine),
        ],
        SettingsBlock(
          child: Row(
            children: [
              SettingsBtn(
                label: l.set_mdNewPreset,
                glyph: UiGlyphs.plus,
                small: true,
                onTap: () => s.actions.onEditPreset(null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _requests(BuildContext context, SettingsModelsData m) {
    final l = context.l10n;
    final c = context.ui;
    final now = SettingsScope.of(context).data.now;
    final shown = m.requests.take(50).toList();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final head = UiText.sans(11, weight: FontWeight.w500, color: c.faint);
    Widget line(List<Widget> cells, {EdgeInsets? pad}) => Padding(
      padding: pad ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        spacing: 16,
        children: [
          SizedBox(width: 90 * scale, child: cells[0]),
          SizedBox(width: 110 * scale, child: cells[1]),
          Expanded(child: cells[2]),
          SizedBox(width: 70 * scale, child: cells[3]),
          SizedBox(width: 70 * scale, child: cells[4]),
          SizedBox(width: 100 * scale, child: cells[5]),
          SizedBox(width: 80 * scale, child: cells[6]),
        ],
      ),
    );
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line([
          Text(l.set_mdTime, style: head),
          Text(l.set_mdFeature, style: head),
          Text(l.set_mdModel, style: head),
          Text(l.set_mdStatus, style: head),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
        ], pad: const EdgeInsets.fromLTRB(18, 12, 18, 8)),
        for (final r in shown) ...[
          Container(height: 1, color: c.rowLine),
          _RequestHoverRow(
            key: r.id == null ? ObjectKey(r) : ValueKey<String>(r.id!),
            builder: (visible) => line([
              Text(
                SettingsFormat.ago(context, r.at, now),
                style: UiText.mono(12, color: c.muted),
              ),
              Text(
                SettingsFormat.task(context, r.task),
                style: UiText.sans(12.5, color: c.ink),
              ),
              Text(
                '${r.provider} · ${r.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.mono(12, color: c.ink),
              ),
              Row(
                spacing: 6,
                children: [
                  SettingsDot(r.ok ? SettingsTone.ok : SettingsTone.error),
                  Text(
                    r.ok ? l.set_mdOk : l.set_mdFailed,
                    style: UiText.sans(12, color: r.ok ? c.muted : c.error),
                  ),
                ],
              ),
              Text(
                r.latencyMs == null ? '' : SettingsFormat.ms(r.latencyMs!),
                textAlign: TextAlign.right,
                style: UiText.mono(12, color: c.muted),
              ),
              Text(
                r.tokens == null
                    ? ''
                    : l.set_mdTokens(SettingsFormat.count(r.tokens!)),
                textAlign: TextAlign.right,
                style: UiText.mono(12, color: c.faint),
              ),
              SizedBox(
                height: 26,
                child: r.id == null
                    ? null
                    : Visibility(
                        visible: visible,
                        maintainState: true,
                        maintainAnimation: true,
                        maintainSize: true,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SettingsBtn(
                            key: Key('request-details-${r.id}'),
                            label: l.modelRequest_detailsAction,
                            small: true,
                            tone: SettingsBtnTone.ghost,
                            trailingChevron: true,
                            onTap: () => SettingsScope.of(
                              context,
                            ).actions.onRequestDetails(r.id!),
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ],
        Container(height: 1, color: c.rowLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Text(
            l.set_mdShowing('${shown.length}', '${m.requestTotal}'),
            style: UiText.sans(11, color: c.faint),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _requestScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          key: const Key('models-request-scroll'),
          controller: _requestScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 900 * scale
                ? 900 * scale
                : constraints.maxWidth,
            child: table,
          ),
        ),
      ),
    );
  }
}

/// Reserve the action slot so hovering never moves the log columns.
class _RequestHoverRow extends StatefulWidget {
  const _RequestHoverRow({super.key, required this.builder});
  final Widget Function(bool visible) builder;

  @override
  State<_RequestHoverRow> createState() => _RequestHoverRowState();
}

class _RequestHoverRowState extends State<_RequestHoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: widget.builder(_hover),
  );
}
