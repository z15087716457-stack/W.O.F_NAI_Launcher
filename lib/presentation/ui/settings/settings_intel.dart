import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/upscale_brand_logo.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_controls.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_page.dart';
import 'settings_scope.dart';

// ───────────────────────────── NAI Agent ─────────────────────────────

class SettingsAgentPage extends StatefulWidget {
  const SettingsAgentPage({super.key});

  @override
  State<SettingsAgentPage> createState() => _SettingsAgentPageState();
}

class _SettingsAgentPageState extends State<SettingsAgentPage> {
  TextEditingController? _global;
  TextEditingController? _prefix;
  var _instrDirty = false;
  var _instrSaved = ('', '');
  (String, String)? _instrObserved;
  var _instrSaving = false;
  var _instrFailed = false;
  var _saveInFlight = false;

  // 基础提示词：草稿和开始编辑时的 (文字, 沿用全局)、工作区，保存时一并交回核对。
  final _base = TextEditingController();
  var _baseOpen = false;
  var _scope = SettingsPromptScope.global;
  var _useGlobal = false;
  var _baseSaved = ('', false);
  var _baseWs = '';
  String? _baseOrigin;
  var _baseDirty = false;
  var _baseFailed = false;
  var _baseSaving = false;
  var _loading = false;
  (String, String?, String, String?)? _baseObserved;

  bool get _dirty => _instrDirty || _baseDirty;
  bool get _protected => _dirty || _saveInFlight;
  bool get _instructionsChanged =>
      (_global!.text, _prefix!.text) != _instrSaved;

  @override
  void initState() {
    super.initState();
    _base.addListener(() => _changed(base: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = SettingsScope.of(context).data.agent;
    final instructions = (a.globalInstructions, a.systemPrefix);
    if (_global == null) {
      _instrSaved = instructions;
      _global = TextEditingController(text: a.globalInstructions)
        ..addListener(() => _changed(instructions: true));
      _prefix = TextEditingController(text: a.systemPrefix)
        ..addListener(() => _changed(instructions: true));
    } else if (!_instrDirty &&
        !_saveInFlight &&
        instructions != _instrObserved) {
      _loadInstructions(instructions);
    }
    _instrObserved = instructions;
    final sp = a.systemPrompt;
    if (sp != null) {
      final source = (sp.builtin, sp.global, sp.workspaceId, sp.workspace);
      if (!_baseDirty &&
          !_busy(sp) &&
          (source != _baseObserved || sp.workspaceId != _baseWs)) {
        _loadBase(sp);
      }
      _baseObserved = source;
    }
  }

  void _loadInstructions((String, String) saved) {
    _instrSaved = saved;
    _loading = true;
    _global!.text = saved.$1;
    _prefix!.text = saved.$2;
    _loading = false;
  }

  /// 按当前范围把已保存的基础提示词读进草稿（不触发脏检查）。
  void _loadBase(SettingsSystemPrompt sp) {
    if (sp.workspaceId.isEmpty) _scope = SettingsPromptScope.global;
    final ws = _scope == SettingsPromptScope.workspace;
    final inherit = ws && sp.workspace == null;
    final text = ws ? sp.workspace ?? sp.effectiveGlobal : sp.effectiveGlobal;
    _baseWs = sp.workspaceId;
    _baseOrigin = ws ? sp.workspace : sp.global;
    _baseSaved = (text, inherit);
    _useGlobal = inherit;
    _setBase(text);
  }

  void _setBase(String text) {
    if (_base.text == text) return;
    _loading = true;
    _base.text = text;
    _loading = false;
  }

  void _changed({bool instructions = false, bool base = false}) {
    if (_loading) return;
    final a = SettingsScope.of(context).data.agent;
    final was = _protected;
    final instr = _instructionsChanged;
    final baseDirty =
        a.systemPrompt != null &&
        (_base.text != _baseSaved.$1 || _useGlobal != _baseSaved.$2);
    if (instr != _instrDirty ||
        baseDirty != _baseDirty ||
        (instructions && _instrFailed) ||
        (base && _baseFailed)) {
      setState(() {
        _instrDirty = instr;
        _baseDirty = baseDirty;
        if (instructions) _instrFailed = false;
        if (base) _baseFailed = false;
      });
    }
    if (_protected != was) {
      SettingsScope.of(context).reportDirty(_protected);
    }
  }

  Future<bool> _acknowledged(Future<bool> Function() save) async {
    try {
      return await save();
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    final s = SettingsScope.of(context);
    if (!_dirty || _busy(s.data.agent.systemPrompt)) return;
    // Capture both layers before awaiting either callback. Later edits belong
    // to the next save; a successful layer only acknowledges this snapshot.
    final instructions = _instrDirty ? (_global!.text, _prefix!.text) : null;
    final expectedInstructions = _instrSaved;
    final base = _baseDirty ? (_base.text, _useGlobal, _scope, _baseWs) : null;
    final expectedBase = _baseOrigin;
    setState(() {
      _saveInFlight = true;
      _instrSaving = instructions != null;
      _baseSaving = base != null;
    });
    s.reportDirty(true);
    try {
      if (instructions != null) {
        final ok = await _acknowledged(
          () => s.actions.onSaveInstructions(
            global: instructions.$1,
            prefix: instructions.$2,
            expectedGlobal: expectedInstructions.$1,
            expectedPrefix: expectedInstructions.$2,
          ),
        );
        if (!mounted) return;
        setState(() {
          _instrSaving = false;
          _instrFailed = !ok;
          if (ok) _instrSaved = instructions;
          _instrDirty = _instructionsChanged;
        });
      }
      if (base != null) {
        final ok = await _acknowledged(
          () => s.actions.onSaveSystemPrompt(
            scope: base.$3,
            text: base.$3 == SettingsPromptScope.workspace && base.$2
                ? null
                : base.$1,
            workspaceId: base.$4,
            expectedText: expectedBase,
          ),
        );
        if (!mounted) return;
        setState(() {
          _baseSaving = false;
          _baseFailed = !ok;
          if (ok) {
            _baseSaved = (base.$1, base.$2);
            _baseOrigin = base.$3 == SettingsPromptScope.workspace && base.$2
                ? null
                : base.$1;
          }
          _baseDirty =
              _base.text != _baseSaved.$1 || _useGlobal != _baseSaved.$2;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saveInFlight = false);
        SettingsScope.of(context).reportDirty(_protected);
      }
    }
  }

  void _discard() {
    final a = SettingsScope.of(context).data.agent;
    if (_busy(a.systemPrompt)) return;
    setState(() {
      _loadInstructions((a.globalInstructions, a.systemPrefix));
      _instrDirty = false;
      _instrFailed = false;
      if (a.systemPrompt != null && _baseDirty) _loadBase(a.systemPrompt!);
      _baseDirty = false;
      _baseFailed = false;
    });
    SettingsScope.of(context).reportDirty(_protected);
  }

  bool _busy(SettingsSystemPrompt? sp) =>
      _saveInFlight || (sp?.saving ?? false);

  void _switchScope(SettingsPromptScope to) {
    if (to == _scope) return;
    final s = SettingsScope.of(context);
    if (_busy(s.data.agent.systemPrompt)) return;
    final l = context.l10n;
    void go() {
      final sp = SettingsScope.of(context).data.agent.systemPrompt;
      if (sp == null) return;
      setState(() {
        _scope = to;
        _baseDirty = false;
        _baseFailed = false;
        _loadBase(sp);
      });
      SettingsScope.of(context).reportDirty(_protected);
    }

    if (!_baseDirty) return go();
    s.confirm(
      title: l.set_agBaseSwitchTitle,
      body: l.set_agBaseSwitchBody,
      confirm: l.set_discard,
      danger: true,
      onConfirm: go,
    );
  }

  void _toggleInherit(bool v, SettingsSystemPrompt sp) {
    setState(() {
      _useGlobal = v;
      if (v) _setBase(sp.effectiveGlobal);
    });
    _changed(base: true);
  }

  void _restoreBuiltin() {
    final s = SettingsScope.of(context);
    final l = context.l10n;
    s.confirm(
      title: l.set_agBaseRestoreTitle,
      body: l.set_agBaseRestoreBody,
      confirm: l.set_agBaseRestore,
      danger: true,
      onConfirm: () async {
        final latest = SettingsScope.of(context);
        final sp = latest.data.agent.systemPrompt;
        if (sp == null || _busy(sp)) return;
        setState(() {
          _saveInFlight = true;
          _baseSaving = true;
        });
        latest.reportDirty(true);
        final ok = await _acknowledged(
          () => latest.actions.onSaveSystemPrompt(
            scope: SettingsPromptScope.global,
            text: null,
            workspaceId: _baseWs,
            expectedText: sp.global,
          ),
        );
        if (!mounted) return;
        setState(() {
          _baseSaving = false;
          _saveInFlight = false;
          _baseFailed = !ok;
          if (ok) {
            _baseSaved = (sp.builtin, false);
            _baseOrigin = null;
            _setBase(sp.builtin);
            _baseDirty = false;
          }
        });
        SettingsScope.of(context).reportDirty(_protected);
      },
    );
  }

  @override
  void dispose() {
    _global?.dispose();
    _prefix?.dispose();
    _base.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final ag = s.data.agent;
    final a = s.actions;
    final model = s.data.options[SettingKey.agentModel]
        ?.where((o) => o.value == s.data.values.text(SettingKey.agentModel))
        .firstOrNull;
    // 和 AgentWorkspaceStore.effectiveSystemPrompt 的拼接顺序一致。
    final order = [
      l.set_agOrderPrefix,
      l.set_agOrderBuiltin,
      l.set_agOrderGlobal,
      l.set_agOrderWorkspace,
      l.set_agOrderSkills,
    ];
    String mcpState(SettingsMcpServer m) => switch (m.state) {
      SettingsMcpState.connected => l.set_agConnected('${m.tools}'),
      SettingsMcpState.connecting => l.set_agConnecting,
      SettingsMcpState.needsLogin => l.set_agNeedsLogin,
      SettingsMcpState.error => l.set_agMcpError,
      SettingsMcpState.disabled => l.set_agMcpOff,
      SettingsMcpState.unchecked => l.set_agMcpUnchecked,
    };
    SettingsTone mcpTone(SettingsMcpServer m) => switch (m.state) {
      SettingsMcpState.connected => SettingsTone.ok,
      SettingsMcpState.connecting => SettingsTone.idle,
      SettingsMcpState.needsLogin => SettingsTone.warn,
      SettingsMcpState.error => SettingsTone.error,
      SettingsMcpState.disabled => SettingsTone.idle,
      SettingsMcpState.unchecked => SettingsTone.idle,
    };
    final page = SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.agent),
        title: l.set_pageAgent,
        description: l.set_agDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_agTools,
          trailing: l.set_agToolCount('${ag.tools.length}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final t in ag.tools)
                    Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: c.control,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        widthFactor: 1,
                        child: Text(
                          t,
                          style: UiText.mono(
                            10.5,
                            weight: FontWeight.w500,
                            color: c.muted,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.set_agToolsTip,
                style: UiText.sans(11, color: c.muted, height: 1.6),
              ),
            ],
          ),
        ),
        if (ag.context != null)
          SettingsAsideCard(
            key: const Key('agent-context'),
            title: l.set_agContext,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsAsideList(
                  rows: [
                    for (final (label, tokens) in [
                      (l.set_agContextPrompt, ag.context!.promptTokens),
                      (
                        l.set_agContextSkills('${ag.context!.skillCount}'),
                        ag.context!.skillTokens,
                      ),
                      (
                        l.set_agContextTools('${ag.context!.toolCount}'),
                        ag.context!.toolTokens,
                      ),
                    ])
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: UiText.sans(12, color: c.ink),
                            ),
                          ),
                          Text(
                            '\u2248 ${SettingsFormat.count(tokens)}',
                            style: UiText.mono(12, color: c.ink),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.set_agContextTip,
                  style: UiText.sans(11, color: c.faint, height: 1.5),
                ),
              ],
            ),
          ),
        if (ag.skillFolders.isNotEmpty)
          SettingsAsideCard(
            key: const Key('agent-skill-folders'),
            title: l.set_agSkillPlaces,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                for (final (source, path) in ag.skillFolders)
                  SettingsPathBox(
                    path: path,
                    tag: source == SettingsSkillSource.global
                        ? l.set_agSkillGlobal
                        : l.set_agSkillWorkspace,
                    actions: [
                      SettingsIconBtn(
                        glyph: SettingsGlyphs.folder,
                        tooltip: l.set_agSkillOpenFolder,
                        onTap: () => a.onOpenSkillRoot(source),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  l.set_agSkillPlacesTip,
                  style: UiText.sans(11, color: c.muted, height: 1.6),
                ),
              ],
            ),
          ),
        SettingsAsideCard(
          title: l.set_agData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsPathBox(
                path: ag.dataPath,
                actions: [
                  SettingsIconBtn(
                    glyph: SettingsGlyphs.external,
                    tooltip: l.set_open,
                    onTap: () => a.onOpenFolder(SettingsFolder.agent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SettingsAsideList(
                rows: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.set_agWorkspaces,
                          style: UiText.sans(12, color: c.ink),
                        ),
                      ),
                      Text(
                        '${ag.workspaces}',
                        style: UiText.mono(12, color: c.ink),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.set_agSessions,
                          style: UiText.sans(12, color: c.ink),
                        ),
                      ),
                      Text(
                        '${ag.sessions}',
                        style: UiText.mono(12, color: c.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_agCostTip),
      ],
      children: [
        SettingsSection(
          title: l.set_agModelSec,
          children: [
            SettingKeyRow(
              SettingKey.agentModel,
              title: l.set_agModel,
              subtitle: l.set_agModelSub,
              control: SetSelect(
                SettingKey.agentModel,
                width: 230,
                leading: model?.mark == null
                    ? null
                    : SettingsLogo(
                        mark: model!.mark!,
                        color: model.color ?? 0xFF555555,
                        size: 18,
                      ),
              ),
            ),
            SettingKeyRow(
              SettingKey.agentEnterToSend,
              title: l.set_agEnter,
              subtitle: l.set_agEnterSub,
              control: const SetSwitch(SettingKey.agentEnterToSend),
            ),
            SettingKeyRow(
              SettingKey.agentMaxRequests,
              title: l.set_agMax,
              subtitle: l.set_agMaxSub,
              control: SetStepper(
                SettingKey.agentMaxRequests,
                unit: l.set_agTimesUnit,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_agInstr,
          subtitle: l.set_agInstrSub,
          children: [
            SettingsAnchor(
              anchor: 'agentInstructions',
              child: SettingsBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      key: const Key('agent-instruction-order'),
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final (i, t) in order.indexed) ...[
                          SettingsChip(label: t, selected: i == 2),
                          if (i < order.length - 1)
                            UiGlyph(
                              UiGlyphs.chevronRight,
                              size: 12,
                              color: c.faint,
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label(
                      context,
                      l.set_agGlobal,
                      _instrDirty && _global!.text != _instrSaved.$1,
                    ),
                    _TextArea(
                      key: const Key('agent-global'),
                      controller: _global!,
                      minHeight: 92,
                      hint: l.set_agGlobalHint,
                      onSave: _save,
                    ),
                    const SizedBox(height: 16),
                    _label(
                      context,
                      l.set_agPrefix,
                      _instrDirty && _prefix!.text != _instrSaved.$2,
                    ),
                    _TextArea(
                      key: const Key('agent-prefix'),
                      controller: _prefix!,
                      minHeight: 58,
                      hint: l.set_agPrefixHint,
                      onSave: _save,
                    ),
                    if (_instrSaving || _instrFailed)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _instrSaving
                              ? l.set_agInstructionsSaving
                              : l.set_agInstructionsFailed,
                          key: const Key('agent-instructions-status'),
                          style: UiText.sans(
                            11.5,
                            color: _instrSaving ? c.muted : c.warn,
                            height: 1.6,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      key: const Key('agent-prompt-actions'),
                      spacing: 8,
                      children: [
                        SettingsBtn(
                          label: l.set_agBuiltin,
                          small: true,
                          tone: SettingsBtnTone.ghost,
                          trailingChevron: true,
                          onTap: a.onViewBuiltinPrompt,
                        ),
                        SettingsBtn(
                          label: l.set_agFinal,
                          glyph: UiGlyphs.eye,
                          small: true,
                          onTap: a.onViewFinalPrompt,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (ag.workspaceRulesPath case final path?)
              SettingsRow(
                anchor: 'agentWorkspaceRules',
                title: l.ag_memoryWorkspace,
                subtitle: path,
                control: SettingsBtn(
                  label: l.ag_memoryEdit,
                  small: true,
                  onTap: a.onEditWorkspaceRules,
                ),
              ),
            if (ag.systemPrompt != null)
              ..._basePrompt(context, ag.systemPrompt!),
          ],
        ),
        SettingsSection(
          title: l.set_agSkills,
          subtitle: l.set_agSkillsSub,
          trailing: Text(
            l.set_agSkillsLoaded(
              '${ag.skills.where((x) => x.state == SettingsSkillState.active).length}',
            ),
            style: UiText.mono(11, color: c.faint),
          ),
          children: [
            SettingsAnchor(
              anchor: 'agentSkills',
              child: Column(
                children: [
                  for (final skill in ag.skills) _SkillRow(skill: skill),
                ],
              ),
            ),
            SettingsBlock(
              child: Row(
                spacing: 8,
                children: [
                  SettingsBtn(
                    key: const Key('skill-add'),
                    label: l.set_agSkillAdd,
                    glyph: SettingsGlyphs.folder,
                    small: true,
                    onTap: a.onAddSkill,
                  ),
                  SettingsBtn(
                    key: const Key('skill-new'),
                    label: l.set_agSkillNew,
                    glyph: UiGlyphs.plus,
                    small: true,
                    onTap: a.onNewSkill,
                  ),
                  Expanded(
                    child: Text(
                      l.set_agSkillSlashHint,
                      textAlign: TextAlign.end,
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ),
                ],
              ),
            ),
            SettingsBlock(
              child: SettingsHint.text(
                context,
                l.set_agSkillTrust,
                glyph: SettingsGlyphs.warn,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_agExt,
          subtitle: l.set_agExtSub,
          children: [
            for (final e in ag.extensions)
              e.builtin
                  ? SettingsRow(
                      title: l.set_agStudioExt,
                      subtitle: l.set_agStudioExtSub,
                      control: UiMini(l.set_agRequired),
                    )
                  : SettingsRow(
                      key: Key('ext-${e.id}'),
                      title: e.name,
                      subtitle: e.path,
                      control: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          SettingsSwitch(
                            value: e.enabled,
                            onChanged: (v) => a.onExtensionEnabled(e.id, v),
                          ),
                          SettingsMoreButton(
                            items: [
                              (
                                l.set_agRemoveExt,
                                () => a.onRemoveExtension(e.id),
                                true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            SettingsBlock(
              child: Row(
                spacing: 8,
                children: [
                  SettingsBtn(
                    label: l.set_agAddFile,
                    glyph: UiGlyphs.plus,
                    small: true,
                    onTap: () => a.onAddExtension(false),
                  ),
                  SettingsBtn(
                    label: l.set_agAddDir,
                    glyph: SettingsGlyphs.folder,
                    small: true,
                    onTap: () => a.onAddExtension(true),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_agMcp,
          subtitle: l.set_agMcpSub,
          children: [
            for (final m in ag.mcp)
              SettingsRow(
                key: Key('mcp-${m.id}'),
                anchor: 'mcp-${m.id}',
                title: m.builtin ? l.set_agBuiltinTools : m.name,
                subtitle: m.builtin ? l.set_agBuiltinToolsSub : m.transport,
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    if (!m.builtin && m.enabled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          SettingsDot(mcpTone(m)),
                          Text(
                            mcpState(m),
                            style: UiText.sans(
                              12,
                              color: m.state == SettingsMcpState.needsLogin
                                  ? c.warn
                                  : c.muted,
                            ),
                          ),
                        ],
                      ),
                    if (m.state == SettingsMcpState.needsLogin && m.enabled)
                      SettingsBtn(
                        label: l.set_login,
                        small: true,
                        onTap: () => a.onMcpLogin(m.id),
                      )
                    else
                      _ModeMenu(server: m),
                    if (m.builtin)
                      SettingsSwitch(
                        value: m.enabled,
                        onChanged: (v) => a.onMcpEnabled(m.id, v),
                      )
                    else
                      SettingsMoreButton(
                        items: [
                          (
                            m.enabled ? l.set_agDisable : l.set_agEnable,
                            () => a.onMcpEnabled(m.id, !m.enabled),
                            false,
                          ),
                          (l.set_agEditMcp, () => a.onEditMcp(m.id), false),
                          (l.set_agRemoveMcp, () => a.onRemoveMcp(m.id), true),
                        ],
                      ),
                  ],
                ),
              ),
            SettingsBlock(
              child: Row(
                children: [
                  SettingsBtn(
                    label: l.set_agAddMcp,
                    glyph: UiGlyphs.plus,
                    small: true,
                    onTap: () => a.onEditMcp(null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    return Stack(
      children: [
        Positioned.fill(child: page),
        if (_protected)
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: SettingsDockBar(
                key: const Key('agent-unsaved'),
                children: [
                  UiGlyph(UiGlyphs.infoCircle, size: 15, color: c.tipInk),
                  Text(
                    _baseDirty ? l.set_unsavedAgent : l.set_unsavedInstructions,
                    style: UiText.sans(12.5, color: c.tipInk),
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
                    onTap: _busy(ag.systemPrompt) ? null : _discard,
                  ),
                  SettingsDockButton(
                    label: l.set_save,
                    onTap: _busy(ag.systemPrompt) ? null : _save,
                    primary: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 基础提示词：一行状态 + 展开后的编辑区（范围、沿用全局、正文、恢复内置）。
  List<Widget> _basePrompt(BuildContext context, SettingsSystemPrompt sp) {
    final l = context.l10n;
    final c = context.ui;
    final busy = _busy(sp);
    final saving = _baseSaving || sp.saving;
    final hasWs = sp.workspaceId.isNotEmpty;
    final ws = _scope == SettingsPromptScope.workspace;
    final global = l.set_agBaseGlobalState(
      sp.global == null ? l.set_agBaseBuiltin : l.set_agBaseCustom,
    );
    final summary = [
      global,
      if (hasWs)
        l.set_agBaseWsState(
          sp.workspaceName,
          sp.workspace == null ? l.set_agBaseInherit : l.set_agBaseOwn,
        ),
    ].join(' · ');
    return [
      SettingsRow(
        key: const Key('agent-base'),
        anchor: 'agentSystemPrompt',
        title: l.set_agBase,
        subtitle: summary,
        control: SettingsBtn(
          key: const Key('agent-base-toggle'),
          label: _baseOpen ? l.set_agBaseCollapse : l.set_agBaseEdit,
          small: true,
          onTap: () => setState(() => _baseOpen = !_baseOpen),
        ),
      ),
      if (_baseOpen)
        SettingsBlock(
          key: const Key('agent-base-editor'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 8,
                children: [
                  if (hasWs)
                    UiSegmented<SettingsPromptScope>(
                      key: const Key('agent-base-scope'),
                      values: SettingsPromptScope.values,
                      selected: _scope,
                      labelOf: (v) => v == SettingsPromptScope.global
                          ? l.set_agScopeGlobal
                          : l.set_agScopeWorkspace(sp.workspaceName),
                      onChanged: busy ? (_) {} : _switchScope,
                    )
                  else
                    Text(
                      l.set_agScopeGlobal,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  const Spacer(),
                  if (!ws)
                    SettingsBtn(
                      key: const Key('agent-base-restore'),
                      label: l.set_agBaseRestore,
                      small: true,
                      tone: SettingsBtnTone.ghost,
                      onTap: sp.global == null || busy ? null : _restoreBuiltin,
                    ),
                ],
              ),
              if (ws)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    spacing: 10,
                    children: [
                      SettingsSwitch(
                        key: const Key('agent-base-inherit'),
                        value: _useGlobal,
                        onChanged: busy ? null : (v) => _toggleInherit(v, sp),
                      ),
                      Flexible(
                        child: Text(
                          _useGlobal
                              ? l.set_agBaseUseGlobalOn
                              : l.set_agBaseUseGlobalOff,
                          style: UiText.sans(12.5, color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              _TextArea(
                key: const Key('agent-base-text'),
                controller: _base,
                minHeight: 160,
                maxLines: 16,
                enabled: !busy && !(ws && _useGlobal),
                onSave: _save,
              ),
              const SizedBox(height: 8),
              Text(
                l.set_agBaseHint,
                style: UiText.sans(11.5, color: c.muted, height: 1.6),
              ),
              if (_baseFailed || saving)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    saving ? l.set_agBaseSaving : l.set_agBaseFailed,
                    key: const Key('agent-base-status'),
                    style: UiText.sans(
                      11.5,
                      color: saving ? c.muted : c.warn,
                      height: 1.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _label(BuildContext context, String text, bool modified) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsModMark(
        on: modified,
        child: Text(
          text,
          style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
        ),
      ),
    );
  }
}

class _TextArea extends StatefulWidget {
  const _TextArea({
    super.key,
    required this.controller,
    required this.minHeight,
    required this.onSave,
    this.hint,
    this.maxLines,
    this.enabled = true,
  });
  final TextEditingController controller;

  /// 含边框和内边距的最小高度（原型 .ta min-height）。
  final double minHeight;
  final String? hint;
  final VoidCallback onSave;

  /// 超过这么多行就在框内滚动；null = 跟着内容长高。
  final int? maxLines;

  /// false = 只读（沿用全局、保存中），文字变淡。
  final bool enabled;

  @override
  State<_TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<_TextArea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = _focus.hasFocus && widget.enabled;
    final style = UiText.sans(
      12.5,
      color: widget.enabled ? c.ink : c.muted,
      height: 1.65,
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            widget.onSave,
      },
      child: GestureDetector(
        // 点文本框下方的空白也能聚焦。
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: on ? c.accent : c.border),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: .16),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            readOnly: !widget.enabled,
            minLines: 1,
            maxLines: widget.maxLines,
            style: style,
            cursorColor: c.accent,
            decoration: uiBareDecoration(
              hintText: widget.hint,
              hintStyle: style.copyWith(color: c.faint),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});
  final SettingsSkill skill;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final a = SettingsScope.of(context).actions;
    final k = skill;
    final source = switch (k.source) {
      SettingsSkillSource.builtin => UiMini(
        l.set_agSkillBuiltin,
        tone: UiMiniTone.accent,
      ),
      SettingsSkillSource.global => UiMini(l.set_agSkillGlobal),
      SettingsSkillSource.workspace => UiMini(l.set_agSkillWorkspace),
    };
    final error = switch (k.error) {
      SettingsSkillError.description => l.set_agSkillErrDescription,
      SettingsSkillError.name => l.set_agSkillErrName,
      SettingsSkillError.missing => l.set_agSkillErrMissing,
      SettingsSkillError.parse => l.set_agSkillErrParse,
      null => null,
    };
    final subtitle =
        error ??
        (k.state == SettingsSkillState.shadowed
            ? '${l.set_agSkillShadowed} \u00b7 ${k.description}'
            : k.description);
    final menu = SettingsMoreButton(
      items: [
        (l.set_agSkillView, () => a.onViewSkill(k.id), false),
        (l.set_agSkillOpenFolder, () => a.onOpenSkillFolder(k.id), false),
        if (!k.builtin)
          (l.set_agSkillRemove, () => a.onRemoveSkill(k.id), true),
      ],
    );
    final Widget control;
    if (k.error != null) {
      control = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          const SettingsDot(SettingsTone.error),
          Text(l.set_agSkillNotLoaded, style: UiText.sans(12, color: c.error)),
          menu,
        ],
      );
    } else if (k.builtin) {
      control = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Tooltip(
            message: k.manual ? l.set_agSkillManualTip : l.set_agSkillAutoTip,
            child: UiMini(k.manual ? l.set_agSkillManual : l.set_agSkillAuto),
          ),
          SettingsBtn(
            label: l.set_agSkillView,
            glyph: UiGlyphs.eye,
            small: true,
            onTap: () => a.onViewSkill(k.id),
          ),
        ],
      );
    } else {
      control = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          _SkillModeMenu(skill: k),
          SettingsSwitch(
            value: k.enabled,
            onChanged: (v) => a.onSkillEnabled(k.id, v),
          ),
          menu,
        ],
      );
    }
    return SettingsRow(
      key: Key('skill-${k.id}'),
      title: k.name,
      titleStyle: UiText.mono(13, weight: FontWeight.w500, color: c.ink),
      badges: [source],
      subtitleWidget: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: UiText.sans(
          12,
          color: k.error != null ? c.error : c.muted,
          height: 1.5,
        ),
      ),
      disabled: k.state == SettingsSkillState.shadowed,
      control: control,
    );
  }
}

class _SkillModeMenu extends StatefulWidget {
  const _SkillModeMenu({required this.skill});
  final SettingsSkill skill;

  @override
  State<_SkillModeMenu> createState() => _SkillModeMenuState();
}

class _SkillModeMenuState extends State<_SkillModeMenu> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = SettingsScope.of(context).actions;
    final k = widget.skill;
    return SettingsPopupMenu(
      open: _open,
      onClose: () => setState(() => _open = false),
      items: [
        (l.set_agSkillAuto, () => a.onSkillManual(k.id, false), false),
        (l.set_agSkillManual, () => a.onSkillManual(k.id, true), false),
      ],
      child: Tooltip(
        message: k.manual ? l.set_agSkillManualTip : l.set_agSkillAutoTip,
        child: UiPressable(
          key: Key('skill-mode-${k.id}'),
          onTap: () => setState(() => _open = true),
          builder: (context, _) =>
              UiMini(k.manual ? l.set_agSkillManual : l.set_agSkillAuto),
        ),
      ),
    );
  }
}

class _ModeMenu extends StatefulWidget {
  const _ModeMenu({required this.server});
  final SettingsMcpServer server;

  @override
  State<_ModeMenu> createState() => _ModeMenuState();
}

class _ModeMenuState extends State<_ModeMenu> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final m = widget.server;
    return SettingsPopupMenu(
      open: _open,
      onClose: () => setState(() => _open = false),
      items: [
        for (final mode in SettingsMcpMode.values)
          (mode.name, () => s.actions.onMcpMode(m.id, mode), false),
      ],
      child: UiPressable(
        key: Key('mcp-mode-${m.id}'),
        onTap: () => setState(() => _open = true),
        builder: (context, _) => UiMini(m.mode.name),
      ),
    );
  }
}

// ───────────────────────────── 语义检索 ─────────────────────────────

class SettingsRagPage extends StatelessWidget {
  const SettingsRagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final rg = d.rag;
    final a = s.actions;
    final on = d.values.flag(SettingKey.ragEnabled);
    final usable = on && rg.runtimeReady;
    final loading = on && rg.initializing;
    final building = rg.sources.any(
      (x) => x.enabled && x.state != SettingsRagState.ready,
    );
    final allDone =
        rg.sources.any((x) => x.enabled) &&
        rg.sources
            .where((x) => x.enabled)
            .every(
              (x) => x.state == SettingsRagState.ready && x.done >= x.total,
            );
    String? errorText(String? value) =>
        value == 'initialization_timeout' ? l.set_rgLoadingTimeout : value;
    final loadingHint = switch (rg.initializationPhase) {
      'loading' => l.set_rgLoadingSaved,
      'restoring' => l.set_rgRestoring(
        SettingsFormat.count(rg.initializationProcessed),
        SettingsFormat.count(rg.initializationTotal),
      ),
      'saving' => l.set_rgSaving,
      'sources' => l.set_rgReadingSources,
      _ => l.set_rgOpening,
    };
    Widget step(String n, SettingsRagStep x, bool first) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: first ? null : Border(left: BorderSide(color: c.rowLine)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              n,
              style: UiText.mono(
                10.5,
                weight: FontWeight.w500,
                color: c.faint,
                letterSpacing: .5,
              ),
            ),
            Row(
              spacing: 6,
              children: [
                SettingsDot(x.tone),
                Flexible(
                  child: Text(
                    x.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              x.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11, color: c.faint),
            ),
          ],
        ),
      ),
    );
    String count(SettingsRagSource x) => switch (x.kind) {
      SettingsRagSourceKind.tags => l.set_rgCount(
        SettingsFormat.count(x.done),
        SettingsFormat.count(x.total),
      ),
      SettingsRagSourceKind.gallery => l.set_rgGalleryCount(
        SettingsFormat.count(x.done),
        SettingsFormat.count(x.total),
        SettingsFormat.count(x.secondary ?? 0),
      ),
      _ => l.set_rgSegments(
        SettingsFormat.count(x.done),
        SettingsFormat.count(x.total),
      ),
    };
    String sub(SettingsRagSourceKind k) => switch (k) {
      SettingsRagSourceKind.tags => l.set_rgTagsSub,
      SettingsRagSourceKind.wiki => l.set_rgWikiSub,
      SettingsRagSourceKind.blocks => l.set_rgBlocksSub,
      SettingsRagSourceKind.gallery => l.set_rgGallerySub,
    };
    Widget? below(SettingsRagSource x) {
      if (!x.enabled) return null;
      final plan = rg.plan?.kind == x.kind ? rg.plan : null;
      final parts = [
        if (rg.preparing == x.kind)
          Row(
            key: Key('rag-preparing-${x.kind.name}'),
            spacing: 8,
            children: [
              const UiSpinner(),
              Expanded(
                child: Text(
                  l.set_rgPreparingHint,
                  style: UiText.sans(11.5, color: c.muted, height: 1.5),
                ),
              ),
            ],
          ),
        if (x.known && x.state != SettingsRagState.empty)
          Row(
            spacing: 10,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: SettingsBar(
                    value: x.fraction,
                    color: x.fraction >= 1 ? c.ok : c.accent,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  count(x),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11, color: c.muted),
                ),
              ),
            ],
          ),
        if (x.skipped > 0)
          Text(
            l.set_rgSkipped(SettingsFormat.count(x.skipped)),
            style: UiText.sans(11.5, color: c.faint),
          ),
        if (x.error != null)
          Text(
            errorText(x.error)!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12, color: c.error, height: 1.5),
          ),
        if (plan != null) _RagPlanCard(plan: plan),
      ];
      if (parts.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: parts,
      );
    }

    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.rag),
        title: l.set_pageRag,
        description: l.set_rgDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_rgProgress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 6,
                children: [
                  Text(
                    rg.progressKnown ? SettingsFormat.percent(rg.overall) : '—',
                    style: settingsBig(context, size: 26),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      l.set_rgOverall,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                ],
              ),
              for (final x in rg.sources.where((x) => x.enabled))
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Row(
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          SettingsFormat.ragShort(context, x.kind),
                          style: UiText.sans(12, color: c.muted),
                        ),
                      ),
                      Expanded(
                        child: SettingsBar(
                          value: x.known ? x.fraction : 0,
                          color: x.fraction >= 1 ? c.ok : c.accent,
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          x.known ? SettingsFormat.percent(x.fraction) : '—',
                          textAlign: TextAlign.right,
                          style: UiText.mono(11, color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_rgTip),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: SettingsAnchor(
            anchor: SettingKey.ragEnabled.name,
            radius: 11,
            child: SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Flexible(
                                  child: Text(
                                    !on
                                        ? l.set_rgOff
                                        : loading
                                        ? l.set_rgLoading
                                        : rg.checking && !usable
                                        ? l.set_testing
                                        : !rg.progressKnown && rg.error != null
                                        ? l.set_rgNotReady
                                        : usable
                                        ? l.set_rgReady
                                        : l.set_rgNotReady,
                                    style: UiText.sans(
                                      15,
                                      weight: FontWeight.w600,
                                      color: c.ink,
                                    ),
                                  ),
                                ),
                                if (usable &&
                                    !loading &&
                                    rg.progressKnown &&
                                    (building || allDone))
                                  UiMini(
                                    building
                                        ? l.set_rgPartial
                                        : l.set_rgAllDone,
                                    tone: UiMiniTone.ok,
                                  ),
                              ],
                            ),
                            Text(
                              loading
                                  ? loadingHint
                                  : on && rg.checking && !usable
                                  ? l.set_rgEnvSub
                                  : on && !usable
                                  ? l.set_rgNotReadySub
                                  : l.set_rgPool,
                              style: UiText.sans(12, color: c.muted),
                            ),
                            if (rg.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  errorText(rg.error)!,
                                  key: const Key('rag-error'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(12, color: c.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        SettingsFormat.bytes(rg.indexBytes),
                        style: UiText.mono(12, color: c.muted),
                      ),
                      SettingsBtn(
                        label: l.set_refresh,
                        glyph: UiGlyphs.refresh,
                        small: true,
                        tone: SettingsBtnTone.ghost,
                        onTap: loading ? null : a.onRagRefresh,
                      ),
                      const SetSwitch(SettingKey.ragEnabled),
                    ],
                  ),
                ),
                Row(
                  children: [
                    step('01 · ${l.set_rgStepRuntime}', rg.runtime, true),
                    step('02 · ${l.set_rgStepEmbed}', rg.embedder, false),
                    step('03 · ${l.set_rgStepRerank}', rg.reranker, false),
                    step('04 · ${l.set_rgStepDevice}', rg.device, false),
                  ],
                ),
              ],
            ),
          ),
        ),
        SettingsSection(
          title: l.set_rgSources,
          subtitle: l.set_rgSourcesSub,
          children: [
            for (final x in rg.sources)
              SettingsRow(
                key: Key('rag-${x.kind.name}'),
                anchor: 'rag-${x.kind.name}',
                alignTop: true,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                disabled: !on,
                title: SettingsFormat.ragSource(context, x.kind),
                subtitle: sub(x.kind),
                badges: [
                  if (x.enabled && x.state == SettingsRagState.loading)
                    UiMini(l.set_rgLoading, tone: UiMiniTone.accent)
                  else if (rg.preparing == x.kind)
                    UiMini(l.set_rgPreparing, tone: UiMiniTone.accent)
                  else ...[
                    if (x.enabled && x.state == SettingsRagState.empty)
                      UiMini(l.set_rgEmpty),
                    if (x.enabled && x.state == SettingsRagState.paused)
                      UiMini(l.set_rgPaused, tone: UiMiniTone.warn),
                    if (x.enabled && x.state == SettingsRagState.building)
                      UiMini(l.set_rgBuilding, tone: UiMiniTone.accent),
                    if (x.enabled && x.state == SettingsRagState.error)
                      UiMini(l.set_rgError, tone: UiMiniTone.error),
                  ],
                ],
                below: below(x),
                control: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      if (!x.enabled)
                        const SizedBox.shrink()
                      else if (x.state == SettingsRagState.loading)
                        const UiSpinner()
                      else if (x.state == SettingsRagState.paused)
                        SettingsBtn(
                          key: Key('rag-resume-${x.kind.name}'),
                          label: l.set_resume,
                          glyph: UiGlyphs.play,
                          small: true,
                          onTap: rg.busy || !rg.runtimeReady
                              ? null
                              : () => a.onRagResume(x.kind),
                        )
                      else if (x.state == SettingsRagState.building)
                        SettingsBtn(
                          label: l.set_pause,
                          glyph: UiGlyphs.pause,
                          small: true,
                          onTap: () => a.onRagPause(x.kind),
                        )
                      else if (x.state == SettingsRagState.error)
                        SettingsBtn(
                          label: l.set_retry,
                          glyph: UiGlyphs.refresh,
                          small: true,
                          onTap: rg.busy
                              ? null
                              : () {
                                  if (!x.known ||
                                      x.error == 'initialization_timeout' ||
                                      x.error == 'worker_closed') {
                                    a.onRagRefresh();
                                  } else {
                                    a.onRagRebuild(x.kind);
                                  }
                                },
                        )
                      else if (x.state == SettingsRagState.empty ||
                          (x.state == SettingsRagState.ready &&
                              x.done < x.total))
                        SettingsBtn(
                          key: Key('rag-build-${x.kind.name}'),
                          label: x.state == SettingsRagState.empty
                              ? l.set_rgBuild
                              : l.set_rgContinue,
                          small: true,
                          tone: SettingsBtnTone.primary,
                          onTap: rg.busy || !rg.runtimeReady || rg.plan != null
                              ? null
                              : () => a.onRagBuild(x.kind),
                        ),
                      if (x.enabled &&
                          x.known &&
                          x.state != SettingsRagState.empty &&
                          x.state != SettingsRagState.loading &&
                          x.state != SettingsRagState.building)
                        SettingsMoreButton(
                          key: Key('rag-more-${x.kind.name}'),
                          enabled: !rg.busy,
                          items: [
                            if (!rg.busy && rg.runtimeReady)
                              (
                                l.set_rebuild,
                                () => a.onRagRebuild(x.kind),
                                false,
                              ),
                            (
                              l.set_rgClearIndex,
                              () => s.confirm(
                                title: l.set_rgClearTitle(
                                  SettingsFormat.ragSource(context, x.kind),
                                ),
                                body: l.set_rgClearBody,
                                confirm: l.set_clear,
                                danger: true,
                                onConfirm: () {
                                  final latest = SettingsScope.of(context);
                                  if (!latest.data.rag.busy) {
                                    latest.actions.onRagClear(x.kind);
                                  }
                                },
                              ),
                              true,
                            ),
                          ],
                        ),
                      SettingsSwitch(
                        key: Key('rag-switch-${x.kind.name}'),
                        value: x.enabled,
                        onChanged: (v) => a.onRagSourceEnabled(x.kind, v),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SettingsSection(
          title: l.set_rgContext,
          subtitle: l.set_rgContextSub,
          children: [
            SettingKeyRow(
              SettingKey.ragContext,
              title: l.set_rgRange,
              control: const SetSeg(SettingKey.ragContext),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_rgRuntime,
          children: [
            const _RagModelRow(SettingsRagModel.embedder),
            const _RagModelRow(SettingsRagModel.reranker),
            SettingsRow(
              key: const Key('rag-discover'),
              sub: true,
              title: l.set_rgDiscover,
              subtitle: l.set_rgDiscoverSub,
              below: rg.modelsMissing
                  ? Text(
                      l.set_rgModelsMissing,
                      key: const Key('rag-models-missing'),
                      style: UiText.sans(12, color: c.warn, height: 1.5),
                    )
                  : null,
              control: SettingsBtn(
                key: const Key('rag-discover-btn'),
                label: l.set_rgFind,
                glyph: UiGlyphs.search,
                small: true,
                onTap: rg.busy ? null : a.onRagDiscoverModels,
              ),
            ),
            SettingKeyRow(
              SettingKey.ragDevice,
              title: l.set_rgDevice,
              control: const SetSeg(SettingKey.ragDevice),
            ),
            SettingKeyRow(
              SettingKey.ragPythonPath,
              title: l.set_rgPython,
              subtitle: l.set_rgPythonSub,
              below: rg.pythonPending
                  ? Row(
                      spacing: 10,
                      children: [
                        Expanded(
                          child: Text(
                            l.set_rgPythonPending,
                            style: UiText.sans(12, color: c.warn, height: 1.5),
                          ),
                        ),
                        SettingsBtn(
                          key: const Key('rag-use-python'),
                          label: l.set_rgUsePython,
                          small: true,
                          tone: SettingsBtnTone.primary,
                          onTap: rg.busy ? null : a.onRagUsePython,
                        ),
                      ],
                    )
                  : null,
              control: SetPath(
                SettingKey.ragPythonPath,
                width: 330,
                open: false,
                defaultPath: rg.runtimePython.isEmpty
                    ? l.set_rgPythonNone
                    : rg.runtimePython,
                defaultTag: rg.runtimePython.isEmpty ? '' : l.set_rgPythonAuto,
              ),
            ),
            const _RagRuntimeRow(),
          ],
        ),
      ],
    );
  }
}

/// 模型目录 + 下载：下载中路径下方出进度与“取消”。
class _RagModelRow extends StatelessWidget {
  const _RagModelRow(this.model);
  final SettingsRagModel model;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final rg = s.data.rag;
    final a = s.actions;
    final key = model == SettingsRagModel.embedder
        ? SettingKey.ragEmbedPath
        : SettingKey.ragRerankPath;
    final dl = rg.download?.model == model ? rg.download : null;
    return SettingKeyRow(
      key,
      title: model == SettingsRagModel.embedder
          ? l.set_rgEmbedPath
          : l.set_rgRerankPath,
      below: dl == null
          ? null
          : Row(
              key: Key('rag-download-${model.name}'),
              spacing: 10,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: SettingsBar(
                      value: dl.total > 0 ? dl.received / dl.total : 0,
                      color: dl.verifying ? c.ok : c.accent,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    dl.verifying
                        ? l.set_rgVerifying
                        : dl.total > 0
                        ? l.set_rgDownloading(
                            SettingsFormat.bytes(dl.received),
                            SettingsFormat.bytes(dl.total),
                          )
                        : l.set_rgDownloadingUnknown(
                            SettingsFormat.bytes(dl.received),
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.mono(11, color: c.muted),
                  ),
                ),
              ],
            ),
      control: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (dl != null)
            SettingsBtn(
              key: Key('rag-download-cancel-${model.name}'),
              label: l.set_cancel,
              small: true,
              tone: SettingsBtnTone.ghost,
              onTap: a.onRagCancelDownload,
            )
          else
            SettingsBtn(
              key: Key('rag-download-btn-${model.name}'),
              label: l.set_rgDownload,
              small: true,
              tone: s.data.values.text(key) == null
                  ? SettingsBtnTone.normal
                  : SettingsBtnTone.ghost,
              onTap: rg.busy ? null : () => a.onRagDownload(model),
            ),
          SetPath(key, width: 280, open: false),
        ],
      ),
    );
  }
}

/// 运行环境：已就绪 / 未安装 / 安装中。安装与重装先在原地选 CUDA 或 CPU。
class _RagRuntimeRow extends StatefulWidget {
  const _RagRuntimeRow();

  @override
  State<_RagRuntimeRow> createState() => _RagRuntimeRowState();
}

class _RagRuntimeRowState extends State<_RagRuntimeRow> {
  var _choosing = false;

  String _clock(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final sc = SettingsScope.of(context);
    final rg = sc.data.rag;
    final a = sc.actions;
    final install = rg.install;
    if (install != null) {
      _choosing = false;
      return SettingsRow(
        key: const Key('rag-runtime'),
        anchor: 'rag-runtime',
        title: l.set_rgEnv,
        titleLead: const SettingsDot(SettingsTone.ok),
        subtitle: switch (install.phase) {
          SettingsRagInstallPhase.existing => l.set_rgPhaseExisting,
          SettingsRagInstallPhase.download => l.set_rgPhaseDownload,
          SettingsRagInstallPhase.create => l.set_rgPhaseCreate,
          SettingsRagInstallPhase.cuda => l.set_rgPhaseCuda,
          SettingsRagInstallPhase.packages => l.set_rgPhasePackages,
          SettingsRagInstallPhase.check => l.set_rgPhaseCheck,
        },
        below: Column(
          key: const Key('rag-install'),
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              l.set_rgElapsed(_clock(install.elapsed)),
              style: UiText.mono(11, color: c.muted),
            ),
            if (install.detail.isNotEmpty)
              Text(
                install.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.mono(11, color: c.faint, height: 1.5),
              ),
          ],
        ),
        control: SettingsBtn(
          key: const Key('rag-install-cancel'),
          label: l.set_cancel,
          small: true,
          tone: SettingsBtnTone.ghost,
          onTap: a.onRagCancelInstall,
        ),
      );
    }
    final locked = rg.busy || rg.checking;
    return SettingsRow(
      key: const Key('rag-runtime'),
      anchor: 'rag-runtime',
      title: l.set_rgEnv,
      subtitle: l.set_rgEnvSub,
      badges: [
        UiMini(
          rg.runtimeReady
              ? l.set_rgEnvReady
              : rg.checking
              ? l.set_testing
              : l.set_rgEnvMissing,
          tone: rg.runtimeReady
              ? UiMiniTone.ok
              : rg.checking
              ? UiMiniTone.plain
              : UiMiniTone.warn,
        ),
      ],
      below: !_choosing
          ? null
          : Container(
              key: const Key('rag-install-choice'),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: c.sunk,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    l.set_rgInstallHint,
                    style: UiText.sans(12, color: c.muted, height: 1.55),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SettingsBtn(
                        key: const Key('rag-install-cuda'),
                        label: l.set_rgInstallCuda,
                        small: true,
                        tone: SettingsBtnTone.primary,
                        onTap: () {
                          setState(() => _choosing = false);
                          a.onRagInstallRuntime(cuda: true);
                        },
                      ),
                      SettingsBtn(
                        key: const Key('rag-install-cpu'),
                        label: l.set_rgInstallCpu,
                        small: true,
                        onTap: () {
                          setState(() => _choosing = false);
                          a.onRagInstallRuntime(cuda: false);
                        },
                      ),
                      SettingsBtn(
                        label: l.set_cancel,
                        small: true,
                        tone: SettingsBtnTone.ghost,
                        onTap: () => setState(() => _choosing = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      control: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (rg.runtimeReady) ...[
            SettingsBtn(
              key: const Key('rag-check'),
              label: rg.checking ? l.set_testing : l.set_rgCheck,
              small: true,
              onTap: locked ? null : a.onRagCheckRuntime,
            ),
            SettingsBtn(
              key: const Key('rag-reinstall'),
              label: l.set_rgReinstall,
              small: true,
              tone: SettingsBtnTone.ghost,
              onTap: locked ? null : () => setState(() => _choosing = true),
            ),
          ] else
            SettingsBtn(
              key: const Key('rag-install'),
              label: rg.checking ? l.set_testing : l.set_rgInstall,
              small: true,
              tone: SettingsBtnTone.primary,
              onTap: locked ? null : () => setState(() => _choosing = true),
            ),
        ],
      ),
    );
  }
}

/// 建库计划：在来源下方原地确认（统计中只显示一行）。
class _RagPlanCard extends StatelessWidget {
  const _RagPlanCard({required this.plan});
  final SettingsRagPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final a = s.actions;
    final rg = s.data.rag;
    final n = SettingsFormat.count(plan.total);
    final text = plan.loading
        ? l.set_rgPlanLoading
        : switch (plan.kind) {
            SettingsRagSourceKind.tags => l.set_rgPlanTags(n),
            SettingsRagSourceKind.gallery => l.set_rgPlanGallery(
              SettingsFormat.count(plan.images),
              n,
            ),
            _ => l.set_rgPlanText(SettingsFormat.count(plan.documents), n),
          };
    return Container(
      key: Key('rag-plan-${plan.kind.name}'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(
            text,
            style: UiText.sans(
              12.5,
              weight: FontWeight.w500,
              color: c.ink,
              height: 1.5,
            ),
          ),
          if (!plan.loading)
            for (final r in plan.roots)
              Text(
                r,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.mono(11, color: c.muted),
              ),
          if (!plan.loading)
            Text(
              plan.rebuild ? l.set_rgPlanRebuild : l.set_rgPlanNote,
              style: UiText.sans(
                11.5,
                color: plan.rebuild ? c.warn : c.faint,
                height: 1.5,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              SettingsBtn(
                key: const Key('rag-plan-cancel'),
                label: l.set_cancel,
                small: true,
                tone: SettingsBtnTone.ghost,
                onTap: a.onRagCancelPlan,
              ),
              SettingsBtn(
                key: const Key('rag-plan-start'),
                label: plan.rebuild ? l.set_rebuild : l.set_rgStart,
                small: true,
                tone: plan.rebuild
                    ? SettingsBtnTone.danger
                    : SettingsBtnTone.primary,
                onTap: plan.loading || rg.busy || !rg.runtimeReady
                    ? null
                    : a.onRagStartPlan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 本地放大 ─────────────────────────────

class SettingsUpscalePage extends StatefulWidget {
  const SettingsUpscalePage({super.key});

  @override
  State<SettingsUpscalePage> createState() => _SettingsUpscalePageState();
}

class _SettingsUpscalePageState extends State<SettingsUpscalePage> {
  var _noise = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final up = d.upscale;
    final a = s.actions;
    final v = d.values;
    String sub(SettingsUpscaleModel m) => switch (m.id) {
      'seed3b' => l.set_upSeed3bSub,
      'seed7b' => l.set_upSeed7bSub,
      'seed7bSharp' => l.set_upSeed7bSharpSub,
      _ => m.file,
    };
    void remove(SettingsUpscaleModel m) => s.confirm(
      title: l.set_upRemoveTitle(SettingsFormat.upscaleName(context, m.id)),
      body: l.set_upRemoveBody,
      confirm: l.set_delete,
      danger: true,
      onConfirm: () => a.onUpscaleRemove(m.id),
    );
    Widget card(SettingsUpscaleModel m, {required bool seed}) {
      final downloading = m.state == SettingsInstallState.downloading;
      final installed =
          m.state == SettingsInstallState.installed ||
          m.state == SettingsInstallState.builtin;
      final stateText = switch (m.state) {
        SettingsInstallState.builtin => l.set_upBuiltin,
        SettingsInstallState.installed => l.set_upInstalled,
        SettingsInstallState.failed => l.set_upFailed,
        _ => l.set_upNotInstalled,
      };
      final Widget action = downloading
          ? Text(
              SettingsFormat.percent(m.total <= 0 ? 0 : m.received / m.total),
              style: UiText.mono(11, color: c.accent),
            )
          : installed
          ? (m.state == SettingsInstallState.builtin
                ? const SizedBox()
                : seed
                ? SettingsMoreButton(
                    items: [(l.set_delete, () => remove(m), true)],
                  )
                : SettingsIconBtn(
                    glyph: SettingsGlyphs.trash,
                    tooltip: l.set_delete,
                    onTap: () => remove(m),
                  ))
          : SettingsBtn(
              key: Key('upscale-install-${m.id}'),
              label: seed ? l.set_install : l.set_download,
              glyph: UiGlyphs.download,
              small: true,
              onTap: () => a.onUpscaleInstall(m.id),
            );
      return Container(
        key: Key('upscale-${m.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(
            color: m.isDefault || (seed && installed) ? c.accent : c.border,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: m.isDefault || (seed && installed)
              ? [
                  BoxShadow(
                    color: c.accent.withValues(alpha: .13),
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              // 原型 .row：有按钮时按按钮高（26），没有时按文字高。
              constraints: const BoxConstraints(minHeight: 19),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            SettingsFormat.upscaleName(context, m.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(
                              13,
                              weight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (m.isDefault)
                          UiMini(l.set_defaultTag, tone: UiMiniTone.accent),
                        if (seed && installed)
                          UiMini(l.set_upInstalled, tone: UiMiniTone.ok),
                      ],
                    ),
                  ),
                  action,
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub(m),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: seed
                  ? UiText.sans(12, color: c.muted)
                  : UiText.mono(12, color: c.muted),
            ),
            if (downloading) ...[
              const SizedBox(height: 12),
              SettingsBar(value: m.total <= 0 ? 0 : m.received / m.total),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.set_upProgress(
                        SettingsFormat.bytes(m.received),
                        m.total > 0 ? SettingsFormat.bytes(m.total) : '—',
                        SettingsFormat.bytes(m.speed),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.mono(11, color: c.faint),
                    ),
                  ),
                  UiPressable(
                    key: Key('upscale-cancel-${m.id}'),
                    onTap: () => a.onUpscaleCancel(m.id),
                    builder: (context, _) => Text(
                      l.set_cancel,
                      style: UiText.sans(11, color: c.accent),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 2,
                children: [
                  if (!seed)
                    Text(stateText, style: UiText.mono(11, color: c.faint)),
                  Text(
                    m.bytes > 0 ? SettingsFormat.bytes(m.bytes) : '—',
                    style: UiText.mono(11, color: c.faint),
                  ),
                  if (m.vramGb != null)
                    Text(
                      l.set_upVram('${m.vramGb}'),
                      style: UiText.mono(11, color: c.faint),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    final defaultOptions =
        d.options[SettingKey.upscaleDefault] ?? const <SettingsOption>[];
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.upscale),
        title: l.set_pageUpscale,
        description: l.set_upDesc,
      ),
      aside: [
        SettingsAnchor(
          anchor: SettingKey.upscaleDefault.name,
          radius: 11,
          child: SettingsAsideCard(
            title: l.set_upDefault,
            minTitleHeight: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in defaultOptions)
                  UiPressable(
                    key: Key('upscale-default-${o.value}'),
                    onTap: () =>
                        a.onChanged(SettingKey.upscaleDefault, o.value),
                    builder: (context, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        spacing: 8,
                        children: [
                          UiRadio(
                            value: v.text(SettingKey.upscaleDefault) == o.value,
                          ),
                          Expanded(
                            child: Text(
                              o.label,
                              style: UiText.sans(12, color: c.ink),
                            ),
                          ),
                          if (o.detail != null)
                            Text(
                              o.detail!,
                              style: UiText.sans(11, color: c.faint),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  l.set_upDefaultTip,
                  style: UiText.sans(11, color: c.muted, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        SettingsHint.text(context, l.set_upVramTip, glyph: SettingsGlyphs.warn),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Container(
            key: const Key('upscale-gpu'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              spacing: 12,
              children: [
                UiGlyph(
                  SettingsGlyphs.gpu,
                  size: 20,
                  color: up.gpuName == null ? c.faint : c.accent,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        up.gpuName == null
                            ? l.set_upNoGpu
                            : l.set_upGpu(up.gpuName!, '${up.vramGb}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        l.set_upLocal,
                        style: UiText.sans(12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                for (final cap in up.caps)
                  UiMini(
                    switch (cap) {
                      SettingsGpuCap.vulkan => 'Vulkan',
                      SettingsGpuCap.cuda =>
                        up.cudaVersion.isEmpty
                            ? 'CUDA'
                            : 'CUDA ${up.cudaVersion}',
                      SettingsGpuCap.int8 => 'INT8',
                      SettingsGpuCap.rtxVideo => 'RTX Video',
                    },
                    tone: UiMiniTone.ok,
                    glyph: UiGlyphs.check,
                  ),
              ],
            ),
          ),
        ),
        SettingsSection(
          title: l.set_upEsrgan,
          subtitle: l.set_upEsrganSub,
          children: [
            SettingsBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsGrid(
                    columns: 3,
                    minItem: 200,
                    children: [for (final m in up.esrgan) card(m, seed: false)],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SettingsBtn(
                        label: l.set_upImport,
                        glyph: SettingsGlyphs.upload,
                        small: true,
                        onTap: a.onUpscaleImport,
                      ),
                      Text(
                        l.set_upImportHint,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_upSeed,
          badge: const UpscaleBrandLogo.seedvr(
            key: Key('settings-upscale-seed-logo'),
            size: 18,
          ),
          subtitle: l.set_upSeedSub,
          children: [
            SettingsBlock(
              child: SettingsGrid(
                columns: 3,
                minItem: 200,
                children: [for (final m in up.seed) card(m, seed: true)],
              ),
            ),
            SettingKeyRow(
              SettingKey.seedVramMode,
              title: l.set_upVramMode,
              control: const SetSeg(SettingKey.seedVramMode),
            ),
            SettingKeyRow(
              SettingKey.seedCpuOffload,
              title: l.set_upOffload,
              subtitle: l.set_upOffloadSub,
              sub: true,
              control: SetSlider(
                SettingKey.seedCpuOffload,
                ticks: 4,
                label: (x) => '${x.round()}',
              ),
            ),
            SettingKeyRow(
              SettingKey.seedVaeTile,
              title: l.set_upTiling,
              subtitle: l.set_upTilingSub,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (v.flag(SettingKey.seedVaeTiling))
                    const SetSeg(SettingKey.seedVaeTile),
                  const SetSwitch(SettingKey.seedVaeTiling),
                ],
              ),
            ),
            SettingsRow(
              anchor: 'seedNoise',
              title: l.set_upNoise,
              subtitle: l.set_upNoiseSub(
                v
                    .number(SettingKey.seedInputNoise)
                    .toStringAsFixed(2)
                    .replaceFirst(RegExp(r'\.?0+$'), ''),
                v
                    .number(SettingKey.seedLatentNoise)
                    .toStringAsFixed(2)
                    .replaceFirst(RegExp(r'\.?0+$'), ''),
              ),
              modified:
                  d.modified.contains(SettingKey.seedInputNoise) ||
                  d.modified.contains(SettingKey.seedLatentNoise),
              badges: [UiMini(l.set_upExperimental)],
              control: SettingsBtn(
                key: const Key('noise-adjust'),
                label: _noise ? l.set_collapse : l.set_adjust,
                small: true,
                tone: SettingsBtnTone.ghost,
                trailingChevron: !_noise,
                onTap: () => setState(() => _noise = !_noise),
              ),
            ),
            if (_noise) ...[
              SettingKeyRow(
                SettingKey.seedInputNoise,
                title: l.set_upInputNoise,
                sub: true,
                control: SetSlider(
                  SettingKey.seedInputNoise,
                  label: (x) => x.toStringAsFixed(2),
                ),
              ),
              SettingKeyRow(
                SettingKey.seedLatentNoise,
                title: l.set_upLatentNoise,
                sub: true,
                control: SetSlider(
                  SettingKey.seedLatentNoise,
                  label: (x) => x.toStringAsFixed(2),
                ),
              ),
            ],
          ],
        ),
        if (up.rtx != null)
          SettingsSection(
            title: l.set_upRtx,
            badge: const UpscaleBrandLogo.nvidia(
              key: Key('settings-upscale-rtx-logo'),
              size: 18,
            ),
            subtitle: l.set_upRtxSub,
            children: [
              SettingsRow(
                title: l.set_upRtxName,
                subtitle: l.set_upRtxNeeds,
                control:
                    up.rtx!.state == SettingsInstallState.installed ||
                        up.rtx!.state == SettingsInstallState.builtin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          UiMini(l.set_upInstalled, tone: UiMiniTone.ok),
                          SettingsMoreButton(
                            items: [
                              (l.set_delete, () => remove(up.rtx!), true),
                            ],
                          ),
                        ],
                      )
                    : SettingsBtn(
                        label: l.set_install,
                        glyph: UiGlyphs.download,
                        small: true,
                        onTap: () => a.onUpscaleInstall(up.rtx!.id),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
