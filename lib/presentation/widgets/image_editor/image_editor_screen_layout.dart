part of 'image_editor_screen.dart';

extension _ImageEditorScreenLayout on _ImageEditorScreenState {
  /// 浮层与屏幕边缘的间距
  static const double _overlayInset = 10;

  /// 桌面端布局 - 官方风格全屏画布 + 四角浮层
  Widget _buildDesktopLayout(Size mediaSize) {
    return Scaffold(
      body: Stack(
        children: [
          // 全屏画布区域（保留 outpaint / 焦点蒙版 / 蒙版填充等既有覆盖层）
          Positioned.fill(child: _buildCanvasArea()),

          // 左上：焦点蒙版卡片 + 当前工具设置
          Positioned(
            top: _isInpaintMode && mediaSize.width < 560 ? 66 : _overlayInset,
            left: _overlayInset,
            child: _buildTopLeftOverlay(mediaSize),
          ),

          // 右上：压缩控制、下载画布、保存并关闭、退出
          Positioned(
            top: _overlayInset,
            right: _overlayInset,
            child: _buildTopRightActions(mediaSize),
          ),

          // 底部居中：悬浮主工具栏
          Positioned(
            left: _overlayInset,
            right: _overlayInset,
            bottom: _overlayInset,
            child: Center(child: _buildFloatingToolbar(mediaSize)),
          ),

          // 右下：图层缩略图托盘 + 计数开关
          if (_showLayerPanel)
            Positioned(
              right: _overlayInset,
              bottom: _isInpaintMode ? _overlayInset + 50 : _overlayInset,
              child: _buildLayerTrayOverlay(),
            ),

          // 详细图层面板 flyout（非模态浮层，避开右下托盘与顶部栏）
          if (!_isInpaintMode && _showLayerPanel && _showLayerFlyout)
            Positioned(
              top: _overlayInset + 56,
              right: _overlayInset + 92,
              bottom: _overlayInset + 56,
              width: 300,
              child: _buildLayerDetailFlyout(),
            ),
        ],
      ),
    );
  }

  /// 移动端布局
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editorTitle()),
        actions: [
          _buildMobileCompressionAction(),
          // 图层按钮
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMobileLayerSheet,
            tooltip: context.l10n.editor_layers,
          ),
          if (!_isInpaintMode)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showEffectsDialog,
              tooltip: context.l10n.editor_effects,
            ),
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _canExportAndClose ? _exportAndClose : null,
            tooltip: context.l10n.editor_done,
          ),
        ],
      ),
      body: Column(
        children: [
          // 画布区域
          Expanded(
            child: Stack(
              children: [Positioned.fill(child: _buildCanvasArea())],
            ),
          ),

          // 工具设置（可折叠）
          _buildMobileToolSettings(),

          // 底部工具栏
          MobileToolbar(state: _state, onLayersPressed: _showMobileLayerSheet),
        ],
      ),
    );
  }

  /// 左上浮层：当前工具设置卡片
  Widget _buildTopLeftOverlay(Size mediaSize) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _isInpaintMode ? 280 : 264,
        maxHeight: mediaSize.height * 0.72,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [_buildToolSettingsPanel()],
        ),
      ),
    );
  }

  /// 右上浮层：压缩控制、下载画布、保存并关闭、退出
  Widget _buildTopRightActions(Size mediaSize) {
    if (_isInpaintMode) {
      final l10n = context.l10n;
      return InpaintPanel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InpaintButton(
              glyph: 'download',
              tooltip: l10n.common_download,
              onPressed: _downloadCanvasImage,
            ),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _canExportAndClose ? _exportAndClose : null,
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(),
                  minimumSize: const Size(120, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  l10n.editor_saveAndExit,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            InpaintButton(
              glyph: 'close',
              tooltip: l10n.common_close,
              onPressed: _confirmExit,
            ),
          ],
        ),
      );
    }
    final l10n = context.l10n;

    return EditorOverlayCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 宽屏时展示完整压缩滑杆，其余宽度用紧凑图标
          if (mediaSize.width >= 1700)
            _buildDesktopCompressionControl(expanded: true)
          else
            EditorOverlayIconButton(
              icon: Icons.compress,
              tooltip: l10n.editor_compressionTooltip,
              onPressed: _showCompressionSheet,
            ),
          EditorOverlayIconButton(
            icon: Icons.download_outlined,
            tooltip: l10n.common_download,
            onPressed: _downloadCanvasImage,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: _canExportAndClose ? () => _exportAndClose() : null,
            icon: const Icon(Icons.check, size: 16),
            label: Text(l10n.editor_saveAndExit),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
          EditorOverlayIconButton(
            icon: Icons.close,
            tooltip: l10n.common_close,
            onPressed: () => _confirmExit(),
          ),
        ],
      ),
    );
  }

  /// 底部悬浮工具栏
  Widget _buildFloatingToolbar(Size mediaSize) {
    if (_isInpaintMode) {
      return InpaintToolbar(
        state: _state,
        width: (mediaSize.width * 0.74).clamp(
          288,
          (mediaSize.width - 20).clamp(288, 1100),
        ),
        onClear: _resetInpaintMask,
        onShiftEdges: _showShiftEdgesDialog,
      );
    }
    // 为右下图层托盘预留水平空间，避免窄窗口下重叠
    final reservedRight = _showLayerPanel ? 200.0 : 40.0;

    return EditorFloatingToolbar(
      state: _state,
      maxWidth: (mediaSize.width - reservedRight)
          .clamp(240.0, 1100.0)
          .toDouble(),
      menuActions: _buildMoreMenuActions(),
    );
  }

  /// “更多”菜单动作项（null = 分隔线）
  List<EditorMenuAction?> _buildMoreMenuActions() {
    final l10n = context.l10n;
    return [
      if (!_isInpaintMode)
        EditorMenuAction(
          icon: Icons.tune_rounded,
          label: l10n.editor_effects,
          onPressed: _showEffectsDialog,
        ),
      EditorMenuAction(
        icon: Icons.aspect_ratio,
        label: l10n.editor_changeCanvasSize,
        onPressed: _changeCanvasSize,
      ),
      EditorMenuAction(
        icon: Icons.compress,
        label: l10n.editor_compressionTitle,
        onPressed: _showCompressionSheet,
      ),
      null,
      EditorMenuAction(
        icon: Icons.restart_alt,
        label: l10n.editor_resetView,
        onPressed: () => _state.canvasController.resetView(_state.canvasSize),
      ),
      EditorMenuAction(
        icon: _showLayerPanel
            ? Icons.view_sidebar
            : Icons.view_sidebar_outlined,
        label: l10n.editor_togglePanels,
        checked: _showLayerPanel,
        onPressed: () => _updateLayoutState(() {
          _showLayerPanel = !_showLayerPanel;
          if (!_showLayerPanel) {
            _showLayerFlyout = false;
          }
        }),
      ),
      null,
      EditorMenuAction(
        icon: Icons.keyboard,
        label: l10n.editor_shortcutHelpTitle,
        onPressed: _showShortcutHelp,
      ),
    ];
  }

  /// 右下图层托盘
  Widget _buildLayerTrayOverlay() {
    return EditorLayerTray(
      state: _state,
      inpaint: _isInpaintMode,
      virtualMaskRects: _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
      onAdd3dLayer: () => _addInpaint3dLayer(),
      onEdit3dLayer: (layer) => _addInpaint3dLayer(layer: layer),
      detailsOpen: _showLayerFlyout,
      onOpenDetails: () => _updateLayoutState(() {
        _showLayerFlyout = !_showLayerFlyout;
      }),
    );
  }

  Future<void> _addInpaint3dLayer({Layer? layer}) async {
    final result = await Model3dEditorScreen.show(
      context,
      renderWidth: _state.canvasSize.width.round(),
      renderHeight: _state.canvasSize.height.round(),
      existing: layer?.model3d,
    );
    if (result == null || !mounted) return;
    final added =
        layer ??
        await _state.layerManager.addLayerFromImage(
          result.pngBytes,
          name: context.l10n.model3d_editorTitle,
        );
    if (added == null || !mounted) return;
    if (layer != null) await layer.setBaseImage(result.pngBytes);
    added.inpaintMask = false;
    added.model3d = Model3dLayerData(
      modelRef: result.modelRef,
      sceneState: result.sceneState,
    );
    final maskLayer = _state.layerManager.layers
        .where((layer) => layer.inpaintMask)
        .firstOrNull;
    if (maskLayer != null) _state.layerManager.setActiveLayer(maskLayer.id);
    _state.requestUiUpdate();
  }

  /// 详细图层面板浮层：完整 LayerPanel + 颜色面板（编辑模式）
  Widget _buildLayerDetailFlyout() {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return EditorOverlayCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.editor_layers,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                EditorOverlayIconButton(
                  icon: Icons.close,
                  tooltip: l10n.common_close,
                  size: 28,
                  iconSize: 16,
                  onPressed: () => _updateLayoutState(() {
                    _showLayerFlyout = false;
                  }),
                ),
              ],
            ),
          ),
          const ThemedDivider(height: 1),
          Expanded(child: LayerPanel(state: _state)),
          if (!_isInpaintMode) ...[
            const ThemedDivider(height: 1),
            ColorPanel(state: _state),
          ],
        ],
      ),
    );
  }

  /// 将当前画布导出为 PNG 文件（不影响保存/关闭流程）
  Future<void> _downloadCanvasImage() async {
    final l10n = context.l10n;
    try {
      var bytes = _isInpaintMode
          ? await _exportInpaintLayerMaskAtCompressionTarget(
              _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
            )
          : await ImageExporterNew.exportMergedImage(
              _state.layerManager,
              _state.canvasSize,
            );
      if (_isInpaintMode) {
        final binary = InpaintMaskUtils.decodeBinaryMask(bytes);
        if (binary == null) throw StateError('Invalid exported mask');
        final width = (binary.width / 8).round(),
            height = (binary.height / 8).round();
        final latent = InpaintMaskUtils.resizeBinaryMask(
          binary.mask,
          sourceWidth: binary.width,
          sourceHeight: binary.height,
          targetWidth: width,
          targetHeight: height,
        );
        bytes = await InpaintMaskUtils.encodeEditorOverlayFromBinaryMaskAsync(
          latent,
          width: width,
          height: height,
          overlayAlpha: 255,
        );
      }
      if (!mounted) return;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.common_download,
        fileName: 'canvas_${DateTime.now().millisecondsSinceEpoch}.png',
        type: FileType.custom,
        allowedExtensions: const ['png'],
      );
      if (path == null || !mounted) return;
      final filePath = path.toLowerCase().endsWith('.png') ? path : '$path.png';
      await File(filePath).writeAsBytes(bytes);
      if (mounted) {
        AppToast.success(context, l10n.image_imageSaved(filePath));
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l10n.editor_exportFailed(e));
      }
    }
  }

  /// 工具设置面板 - 左上紧凑卡片，跟随当前工具
  /// 使用 toolChangeNotifier 实现细粒度监听，仅在工具切换时重建
  Widget _buildToolSettingsPanel() {
    if (_isInpaintMode) return InpaintToolSettings(state: _state);
    return ValueListenableBuilder<EditorTool?>(
      valueListenable: _state.toolChangeNotifier,
      builder: (context, tool, _) {
        if (tool == null) {
          return const SizedBox.shrink();
        }
        if (tool.id == 'brush' || tool.id == 'eraser') {
          return EditorQuickSettings(
            state: _state,
            tool: tool,
            inpaint: _isInpaintMode,
            onDetails: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 340,
                    maxHeight: 640,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: context.l10n.common_close,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        tool.buildSettingsPanel(context, _state),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return EditorOverlayCard(
          width: 252,
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: SingleChildScrollView(
              child: tool.buildSettingsPanel(context, _state),
            ),
          ),
        );
      },
    );
  }

  /// 移动端工具设置
  /// 使用 toolChangeNotifier 实现细粒度监听
  Widget _buildMobileToolSettings() {
    return ValueListenableBuilder<EditorTool?>(
      valueListenable: _state.toolChangeNotifier,
      builder: (context, tool, _) {
        if (tool == null) return const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: tool.buildSettingsPanel(context, _state),
          ),
        );
      },
    );
  }

  /// 显示移动端图层面板
  void _showMobileLayerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return LayerPanel(state: _state);
        },
      ),
    );
  }

  /// 显示快捷键帮助
  void _showShortcutHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.keyboard),
            const SizedBox(width: 8),
            Text(context.l10n.editor_shortcutHelpTitle),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 350),
          child: SingleChildScrollView(
            primary: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShortcutSection(context.l10n.editor_shortcutPaintTools, [
                  ('B', context.l10n.editor_toolBrush),
                  ('E', context.l10n.editor_toolEraser),
                  ('W', context.l10n.editor_toolMagicWand),
                  ('P', context.l10n.editor_toolColorPicker),
                  ('Alt', context.l10n.editor_shortcutTemporaryColorPicker),
                ]),
                _buildShortcutSection(
                  context.l10n.editor_shortcutSelectionTools,
                  [
                    ('M', context.l10n.editor_shortcutRectSelection),
                    ('U', context.l10n.editor_shortcutEllipseSelection),
                    ('L', context.l10n.editor_shortcutLassoSelection),
                  ],
                ),
                _buildShortcutSection(context.l10n.editor_shortcutCanvasView, [
                  ('1', context.l10n.editor_shortcut100Zoom),
                  ('2', context.l10n.editor_shortcutFitHeight),
                  ('3', context.l10n.editor_shortcutFitWidth),
                  ('4', context.l10n.editor_shortcutRotateLeft15),
                  ('5', context.l10n.editor_shortcutResetRotation),
                  ('6', context.l10n.editor_shortcutRotateRight15),
                  ('F', context.l10n.editor_shortcutFlipHorizontal),
                  ('R', context.l10n.editor_resetView),
                  (context.l10n.editor_shortcutWheel, context.l10n.editor_zoom),
                  ('Ctrl+0', context.l10n.editor_shortcut100Zoom),
                  ('Ctrl++', context.l10n.editor_zoomIn),
                  ('Ctrl+-', context.l10n.editor_zoomOut),
                ]),
                _buildShortcutSection(context.l10n.editor_shortcutBrushAdjust, [
                  ('[', context.l10n.editor_shortcutBrushSmaller),
                  (']', context.l10n.editor_shortcutBrushLarger),
                  ('I', context.l10n.editor_shortcutOpacityLower),
                  ('O', context.l10n.editor_shortcutOpacityHigher),
                  ('Shift + Drag', context.l10n.editor_shortcutDragBrushSize),
                ]),
                _buildShortcutSection(context.l10n.editor_shortcutColors, [
                  ('X', context.l10n.editor_shortcutSwapColors),
                ]),
                _buildShortcutSection(
                  context.l10n.editor_shortcutCanvasActions,
                  [
                    ('Space + Drag', context.l10n.editor_shortcutPanCanvas),
                    ('Middle Drag', context.l10n.editor_shortcutPanCanvas),
                  ],
                ),
                _buildShortcutSection(
                  context.l10n.editor_shortcutHistoryActions,
                  [
                    ('Ctrl+Z', context.l10n.editor_undo),
                    ('Ctrl+Shift+Z', context.l10n.editor_redo),
                    ('Ctrl+Y', context.l10n.editor_redo),
                  ],
                ),
                _buildShortcutSection(
                  context.l10n.editor_shortcutSelectionActions,
                  [
                    (
                      'Delete',
                      context.l10n.editor_shortcutClearSelectionContent,
                    ),
                    (
                      'Backspace',
                      context.l10n.editor_shortcutClearSelectionContent,
                    ),
                    ('Esc', context.l10n.editor_shortcutCancelCurrentAction),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSection(String title, List<(String, String)> shortcuts) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...shortcuts.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: StudioTypography.mono,
                        fontFamilyFallback: StudioTypography.fallback,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(s.$2, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
