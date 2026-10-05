part of 'model3d_editor_screen.dart';

extension _Model3dControls on Model3dEditorState {
  bool get _enabled => _ready && !_busy;
  bool get _hasModel => _modelRef != null;

  Widget _buildOfficialLayout(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: widget.embedded || !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (widget.embedded ||
            didPop ||
            !await _confirmExit() ||
            !context.mounted) {
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, box) {
            final narrow = box.maxWidth < 860;
            final top = narrow ? 66.0 : 10.0;
            final settingsWidth = narrow
                ? box.maxWidth - 20
                : (box.maxWidth - 260).clamp(280.0, 680.0);
            final panelHeight = (box.maxHeight - top - 120).clamp(60.0, 1800.0);
            return Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: top + (box.maxWidth < 560 ? 90 : 60),
                  bottom: 70,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.renderWidth / widget.renderHeight,
                      child: ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLowest,
                        child:
                            widget.viewportBuilder?.call(context) ??
                            (_editorUrl == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Model3dWebViewport(
                                    editorUrl: _editorUrl!,
                                    onControllerReady: (evalJs) {
                                      _bridge = Model3dBridge(
                                        evalJs: (source) async {
                                          await evalJs.evaluateJavascript(
                                            source: source,
                                          );
                                        },
                                        onEvent: _onBridgeEvent,
                                      );
                                    },
                                    onBridgeMessage: (args) =>
                                        _bridge?.handleJsMessage(args),
                                  )),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: top,
                  left: 10,
                  child: _topSettings(settingsWidth),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: InpaintPanel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EditButton(
                          glyph: 'download',
                          tooltip: l.common_download,
                          onPressed: _enabled ? _download : null,
                        ),
                        SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: _enabled ? _apply : null,
                            style: FilledButton.styleFrom(
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(120, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              l.editor_saveAndExit,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        EditButton(
                          glyph: 'close',
                          tooltip: l.common_close,
                          onPressed: _busy
                              ? null
                              : () async {
                                  if (widget.onClose != null) {
                                    await widget.onClose!();
                                    return;
                                  }
                                  if (await _confirmExit() && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showBones || _showMorphs)
                  Positioned(
                    top: top + (box.maxWidth < 560 ? 90 : 60),
                    left: 10,
                    width: (box.maxWidth - 20).clamp(100.0, 200.0),
                    height: panelHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showBones) Expanded(child: _bonePanel()),
                        if (_showBones && _showMorphs)
                          const SizedBox(height: 6),
                        if (_showMorphs) Expanded(child: _morphPanel()),
                      ],
                    ),
                  ),
                if (_showSettings)
                  Positioned(
                    right: widget.layerTray == null ? 10 : 114,
                    bottom: 70,
                    width:
                        (box.maxWidth - (widget.layerTray == null ? 20 : 124))
                            .clamp(150.0, 260.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (box.maxHeight - top - 80).clamp(
                          40.0,
                          1200.0,
                        ),
                      ),
                      child: _renderSettings(),
                    ),
                  ),
                if (widget.layerTray != null)
                  Positioned(right: 10, bottom: 70, child: widget.layerTray!),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Center(
                    child: _bottomToolbar(
                      (box.maxWidth - 20).clamp(0.0, 830.0),
                    ),
                  ),
                ),
                if (_busy)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.scrim.withValues(alpha: .12),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topSettings(double width) {
    final l = context.l10n;
    final tool = _mode == 'pose' ? l.model3d_toolPose : l.model3d_toolTransform;
    return InpaintPanel(
      child: ConstrainedBox(
        key: const ValueKey('model3d-top-settings'),
        constraints: BoxConstraints(maxWidth: width, minHeight: 50),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 62,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EditGlyph(_mode == 'pose' ? 'model_pose' : 'model_move'),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        tool,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Wrap(
                      key: const ValueKey('model3d-settings-row'),
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_hasModel) ...[
                              Tooltip(
                                message: _modelName,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 126,
                                  ),
                                  padding: const EdgeInsets.only(left: 5),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _modelName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      EditButton(
                                        glyph: 'clear',
                                        tooltip: l.model3d_removeModel,
                                        size: 24,
                                        onPressed: _enabled
                                            ? () => _sendSafely(() async {
                                                if (!await _confirmReplace(
                                                  removing: true,
                                                )) {
                                                  return;
                                                }
                                                await _bridge!.removeModel();
                                                if (mounted) {
                                                  _refresh(() {
                                                    _modelRef = null;
                                                    _modelName = '';
                                                    _dirty = true;
                                                  });
                                                }
                                              })
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            _choice(
                              l.common_import,
                              glyph: 'model_import',
                              onTap: _enabled ? _importModel : null,
                            ),
                            const SizedBox(width: 4),
                            _choice(
                              l.model3d_resetModel,
                              glyph: 'model_reset',
                              compactLabel: l.common_reset,
                              onTap: _enabled && _hasModel
                                  ? () => _sendSafely(_bridge!.resetModel)
                                  : null,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final entry in [
                              (
                                'translate',
                                l.model3d_gizmoTranslate,
                                'model_move',
                              ),
                              ('rotate', l.model3d_gizmoRotate, 'model_rotate'),
                              ('scale', l.model3d_gizmoScale, 'model_scale'),
                            ]) ...[
                              _choice(
                                entry.$2,
                                glyph: entry.$3,
                                selected: _gizmo == entry.$1,
                                onTap: _enabled
                                    ? () => _setMode(_mode, entry.$1)
                                    : null,
                              ),
                              const SizedBox(width: 2),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(
    String label, {
    String? glyph,
    String? compactLabel,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final s = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: Material(
          color: selected ? s.primaryContainer : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(color: s.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (glyph != null) ...[
                    EditGlyph(
                      glyph,
                      size: 12,
                      color: onTap == null
                          ? s.onSurface.withValues(alpha: .3)
                          : s.onSurface,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    compactLabel ?? label,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: onTap == null
                          ? s.onSurface.withValues(alpha: .3)
                          : s.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomToolbar(double width) {
    final l = context.l10n;
    return InpaintPanel(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (width - 6).clamp(352.0, 824.0),
            height: 44,
            child: Row(
              children: [
                EditButton(
                  glyph: 'model_move',
                  tooltip: l.model3d_modeTransform,
                  selected: _mode == 'transform',
                  onPressed: _enabled
                      ? () => _setMode('transform', _gizmo)
                      : null,
                ),
                EditButton(
                  glyph: 'model_pose',
                  tooltip: l.model3d_modePose,
                  selected: _mode == 'pose',
                  onPressed: _enabled ? () => _setMode('pose', _gizmo) : null,
                ),
                const Spacer(),
                EditButton(
                  glyph: 'model_settings',
                  tooltip: l.model3d_settings,
                  selected: _showSettings,
                  onPressed: _enabled ? _toggleSettings : null,
                ),
                EditButton(
                  glyph: 'model_pose',
                  tooltip: l.model3d_bones,
                  selected: _showBones,
                  onPressed: _enabled
                      ? () => _toggleSidePanel(bones: true)
                      : null,
                ),
                EditButton(
                  glyph: 'model_expression',
                  tooltip: l.model3d_morphs,
                  selected: _showMorphs,
                  onPressed: _enabled ? _toggleSidePanel : null,
                ),
                if (widget.onResizeCanvas != null)
                  EditButton(
                    glyph: 'shift',
                    tooltip: l.editor_changeCanvasSize,
                    onPressed: _enabled ? widget.onResizeCanvas : null,
                  ),
                InpaintButton(
                  glyph: 'undo',
                  tooltip: l.editor_undo,
                  onPressed: !_enabled
                      ? null
                      : widget.canUndoCanvas && !_dirty
                      ? widget.onCanvasUndo
                      : _editorState['canUndo'] == true
                      ? () => _sendSafely(_bridge!.undoPose)
                      : widget.canUndoCanvas
                      ? widget.onCanvasUndo
                      : null,
                ),
                InpaintButton(
                  glyph: 'redo',
                  tooltip: l.editor_redo,
                  onPressed: !_enabled
                      ? null
                      : widget.canRedoCanvas && !_dirty
                      ? widget.onCanvasRedo
                      : _editorState['canRedo'] == true
                      ? () => _sendSafely(_bridge!.redoPose)
                      : widget.canRedoCanvas
                      ? widget.onCanvasRedo
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bonePanel() {
    final l = context.l10n;
    final bones = (_editorState['bones'] as List? ?? []).cast<Map>();
    return _sidePanel(
      l.model3d_bones,
      bones.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.model3d_noBones,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            )
          : ListView(
              children: [
                for (final bone in bones)
                  Material(
                    color: _editorState['selectedBone'] == bone['id']
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    child: InkWell(
                      onTap: !_enabled
                          ? null
                          : () => _sendSafely(() async {
                              await _setMode('pose', _gizmo);
                              await _bridge!.selectBone(bone['id'] as int);
                            }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        child: Text(
                          bone['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _morphPanel() {
    final l = context.l10n;
    final entries = (_editorState['morphs'] as List? ?? []).cast<Map>();
    return _sidePanel(
      l.model3d_morphs,
      entries.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.model3d_noMorphs,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            )
          : ListView(
              children: [
                for (final e in entries)
                  _sliderRow(
                    e['name'].toString(),
                    (e['value'] as num).toDouble(),
                    0,
                    1,
                    (v) =>
                        _sendSafely(() => _bridge!.setMorph(e['id'] as int, v)),
                    text: (e['value'] as num).toStringAsFixed(2),
                    onStart: (v) => _sendSafely(
                      () => _bridge!.setMorph(e['id'] as int, v, begin: true),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sidePanel(String title, Widget body) => InpaintPanel(
    key: ValueKey('model3d-panel-$title'),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, height: 1.3)),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    ),
  );

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String? text,
    ValueChanged<double>? onStart,
  }) => Row(
    children: [
      SizedBox(
        width: 54,
        child: Tooltip(
          message: label,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.2),
          ),
        ),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: _enabled ? onChanged : null,
            onChangeStart: onStart,
          ),
        ),
      ),
      SizedBox(
        width: 36,
        child: Text(
          text ?? value.round().toString(),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 10, height: 1.2),
        ),
      ),
    ],
  );

  Widget _renderSettings() {
    final l = context.l10n;
    void update(String key, dynamic value) {
      _refresh(() => _settings[key] = value);
      _sendSafely(() => _bridge!.setSettings({key: value}));
    }

    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .75),
        ),
      ),
    );
    Widget choices(String key, List<(String, String)> values) => Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final e in values)
          _choice(
            e.$2,
            selected: _settings[key] == e.$1,
            onTap: _enabled ? () => update(key, e.$1) : null,
          ),
      ],
    );
    Widget toggle(String key) => Wrap(
      spacing: 4,
      children: [
        _choice(
          l.common_enabled,
          selected: _settings[key] == true,
          onTap: _enabled ? () => update(key, true) : null,
        ),
        _choice(
          l.common_disabled,
          selected: _settings[key] != true,
          onTap: _enabled ? () => update(key, false) : null,
        ),
      ],
    );
    return InpaintPanel(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              section(l.model3d_projection),
              choices('projection', [
                ('perspective', l.model3d_perspective),
                ('orthographic', l.model3d_orthographic),
              ]),
              if (_settings['projection'] != 'orthographic')
                _sliderRow(
                  l.model3d_fov,
                  (_settings['fov'] as num).toDouble(),
                  10,
                  120,
                  (v) => update('fov', v),
                ),
              section(l.model3d_light),
              for (final row in [
                ('ambient', l.model3d_ambient),
                ('direct', l.model3d_direct),
              ])
                _sliderRow(
                  row.$2,
                  (_settings[row.$1] as num).toDouble() * 100,
                  0,
                  row.$1 == 'direct' ? 300 : 200,
                  (v) => update(row.$1, v / 100),
                  text: '${((_settings[row.$1] as num) * 100).round()}%',
                ),
              section(l.model3d_direction),
              choices('direction', [
                ('front', l.model3d_front),
                ('frontTop', l.model3d_frontTop),
                ('top', l.model3d_top),
                ('left', l.model3d_left),
                ('right', l.model3d_right),
                ('back', l.model3d_back),
              ]),
              section(l.model3d_shadows),
              toggle('shadows'),
              if (_settings['shadows'] == true) ...[
                section(l.model3d_quality),
                choices('quality', [
                  ('veryLow', l.model3d_veryLow),
                  ('low', l.model3d_low),
                  ('medium', l.model3d_medium),
                  ('high', l.model3d_high),
                  ('veryHigh', l.model3d_veryHigh),
                ]),
              ],
              section(l.model3d_display),
              Text(l.model3d_showBones, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 4),
              toggle('showBones'),
            ],
          ),
        ),
      ),
    );
  }
}
