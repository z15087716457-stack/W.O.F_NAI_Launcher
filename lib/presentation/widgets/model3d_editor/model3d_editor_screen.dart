import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/localization_extension.dart';
import '../image_editor/widgets/panels/edit_image_controls.dart';
import '../image_editor/widgets/panels/inpaint_controls.dart';
import '../image_editor/layers/model3d_layer_data.dart';
import 'local_asset_server.dart';
import 'model3d_bridge.dart';
import 'model3d_library_service.dart';
import 'model3d_web_viewport.dart';
part 'model3d_controls.dart';

/// 编辑结果:透明 PNG + 场景状态 + 模型引用
class Model3dEditResult {
  final Uint8List pngBytes;
  final Map<String, dynamic> sceneState;
  final String modelRef;

  const Model3dEditResult({
    required this.pngBytes,
    required this.sceneState,
    required this.modelRef,
  });
}

/// 3D 模型图层全屏编辑器
class Model3dEditorScreen extends StatefulWidget {
  final Model3dLayerData? existing;
  final int renderWidth;
  final int renderHeight;
  final Model3dLibraryService? libraryService;

  /// 测试注入口
  final Model3dBridge? bridgeOverride;
  final WidgetBuilder? viewportBuilder;
  final LocalAssetServer? serverOverride;
  final Future<File?> Function()? pickModelFile;
  final bool markReadyForTest;

  const Model3dEditorScreen({
    super.key,
    this.existing,
    required this.renderWidth,
    required this.renderHeight,
    this.libraryService,
    this.bridgeOverride,
    this.viewportBuilder,
    this.serverOverride,
    this.pickModelFile,
    this.markReadyForTest = false,
  });

  static Future<Model3dEditResult?> show(
    BuildContext context, {
    Model3dLayerData? existing,
    required int renderWidth,
    required int renderHeight,
    Model3dLibraryService? libraryService,
  }) {
    return Navigator.push<Model3dEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => Model3dEditorScreen(
          existing: existing,
          renderWidth: renderWidth,
          renderHeight: renderHeight,
          libraryService: libraryService,
        ),
      ),
    );
  }

  @override
  State<Model3dEditorScreen> createState() => _Model3dEditorScreenState();
}

class _Model3dEditorScreenState extends State<Model3dEditorScreen> {
  LocalAssetServer? _server;
  Model3dBridge? _bridge;
  Model3dLibraryService? _library;
  Uri? _editorUrl;

  bool _ready = false;
  bool _dirty = false;
  bool _busy = false;
  String? _modelRef;
  String _mode = 'transform';
  String _gizmo = 'translate';
  String _modelName = '';
  bool _showSettings = false, _showBones = false, _showMorphs = false;
  Map<String, dynamic> _editorState = {};
  Map<String, dynamic> _settings = {
    'projection': 'perspective',
    'fov': 50,
    'ambient': .6,
    'direct': .8,
    'direction': 'frontTop',
    'shadows': false,
    'quality': 'medium',
    'showBones': true,
  };
  late final Future<void> _servicesReady;

  @override
  void initState() {
    super.initState();
    _bridge = widget.bridgeOverride; // 真桥在 WebView controller 就绪后创建
    if (widget.markReadyForTest) {
      _ready = true;
      // 与真实 onReady 事件走同一条恢复路径,让测试覆盖 existing 恢复逻辑
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreExisting();
      });
    }
    _servicesReady = _startServices();
  }

  Future<void> _startServices() async {
    final library = widget.libraryService ?? await _defaultLibrary();
    _library = library;
    if (widget.viewportBuilder == null) {
      final server =
          widget.serverOverride ??
          LocalAssetServer(modelLibraryDir: library.libraryDir);
      final base = await server.start();
      if (!mounted) {
        await server.stop();
        return;
      }
      setState(() {
        _server = server;
        _editorUrl = base.resolve('editor/editor.html');
      });
    }
  }

  Future<Model3dLibraryService> _defaultLibrary() async {
    final support = await getApplicationSupportDirectory();
    return Model3dLibraryService(
      libraryDir: Directory('${support.path}/model3d_library'),
    );
  }

  @override
  void dispose() {
    _bridge?.dispose();
    _server?.stop();
    super.dispose();
  }

  void _onBridgeEvent(String type, Map<String, dynamic> data) {
    if (!mounted) return;
    switch (type) {
      case 'onReady':
        setState(() => _ready = true);
        _restoreExisting();
      case 'onDirty':
        setState(() => _dirty = true);
      case 'onState':
        _acceptState(data);
      case 'onLoadError':
        _showSnack('${context.l10n.model3d_loadError}: ${data['error'] ?? ''}');
    }
  }

  Future<void> _restoreExisting() async {
    await _servicesReady;
    if (!mounted) return;
    final existing = widget.existing;
    if (existing == null) return;
    if (existing.modelRef == Model3dLibraryService.emptySceneRef) {
      await _runBusy(() async {
        await _bridge!.restoreScene(existing.sceneState);
        if (mounted) setState(() => _dirty = false);
      });
      return;
    }
    if (existing.modelRef == Model3dLibraryService.builtinMannequinRef) {
      // 恢复已保存的图层不算脏:未做任何新修改就返回时不应弹放弃确认
      await _loadBuiltin(
        sceneState: existing.sceneState,
        confirm: false,
        markDirty: false,
      );
      return;
    }
    final library = _library;
    final file = library?.resolveFile(existing.modelRef);
    if (library == null || file == null || !file.existsSync()) {
      _showSnack(context.l10n.model3d_missingModel);
      return;
    }
    final path = library.urlPathFor(existing.modelRef)!;
    await _runBusy(() async {
      final data = await _bridge!.loadModel(
        url: _editorUrl!.resolve(path).toString(),
        sceneState: existing.sceneState,
      );
      _acceptState(data);
      if (!mounted) return;
      setState(() {
        _modelRef = existing.modelRef;
        _modelName =
            existing.sceneState['fileName'] as String? ??
            context.l10n.model3d_editorTitle;
        _dirty = false;
      });
    });
  }

  Future<bool> _confirmReplace({bool removing = false}) async {
    if (_modelRef == null) return true;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          removing
              ? context.l10n.model3d_removeConfirm
              : context.l10n.model3d_replaceConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _loadBuiltin({
    Map<String, dynamic>? sceneState,
    bool confirm = true,
    bool markDirty = true,
  }) async {
    if (confirm && !await _confirmReplace()) return;
    await _runBusy(() async {
      final data = await _bridge!.loadModel(
        builtin: 'mannequin',
        sceneState: sceneState,
      );
      _acceptState(data);
      if (!mounted) return;
      setState(() {
        _modelRef = Model3dLibraryService.builtinMannequinRef;
        _modelName = context.l10n.model3d_editorTitle;
        _dirty = markDirty;
      });
    });
  }

  Future<void> _importModel() async {
    await _servicesReady;
    if (!await _confirmReplace()) return;
    final pick = widget.pickModelFile ?? _pickWithFilePicker;
    final file = await pick();
    if (file == null || _library == null) return;
    await _runBusy(() async {
      try {
        final ref = await _library!.importModel(file);
        final path = _library!.urlPathFor(ref)!;
        final data = await _bridge!.loadModel(
          url: (_editorUrl ?? Uri.parse('http://127.0.0.1/'))
              .resolve(path)
              .toString(),
        );
        _acceptState(data);
        if (!mounted) return;
        setState(() {
          _modelRef = ref;
          _modelName = file.uri.pathSegments.last;
          _dirty = true;
        });
      } on Model3dImportException catch (e) {
        if (!mounted) return;
        _showSnack('${context.l10n.model3d_loadError}: ${e.message}');
      }
    });
  }

  Future<File?> _pickWithFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
    );
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  Future<void> _apply() async {
    await _runBusy(() async {
      final sceneState = await _bridge!.serialize();
      sceneState['fileName'] = _modelName;
      final png = await _bridge!.render(
        width: widget.renderWidth,
        height: widget.renderHeight,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        Model3dEditResult(
          pngBytes: png,
          sceneState: sceneState,
          modelRef: _modelRef ?? Model3dLibraryService.emptySceneRef,
        ),
      );
    });
  }

  Future<void> _setMode(String mode, String gizmo) async {
    await _sendSafely(() async {
      await _bridge!.setMode(mode: mode, gizmo: gizmo);
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _gizmo = gizmo;
      });
    });
  }

  void _refresh(VoidCallback action) => setState(action);
  void _toggleSettings() => setState(() {
    _showSettings = !_showSettings;
    if (_showSettings && MediaQuery.sizeOf(context).width < 560) {
      _showBones = _showMorphs = false;
    }
  });
  void _toggleSidePanel({bool bones = false}) => setState(() {
    if (bones) {
      _showBones = !_showBones;
    } else {
      _showMorphs = !_showMorphs;
    }
    if (MediaQuery.sizeOf(context).width < 560) _showSettings = false;
  });

  void _acceptState(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _editorState = {..._editorState, ...data};
      if (data['settings'] is Map) {
        _settings = Map<String, dynamic>.from(data['settings']);
      }
    });
  }

  Future<void> _sendSafely(Future<void> Function() action) async {
    try {
      await action();
    } on Model3dBridgeException catch (e) {
      _showSnack(e.message);
    } on TimeoutException catch (e) {
      _showSnack(e.message ?? 'timeout');
    } on FileSystemException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _download() async {
    await _runBusy(() async {
      final bytes = await _bridge!.render(
        width: widget.renderWidth,
        height: widget.renderHeight,
      );
      final path = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: ['png'],
        fileName: 'model3d.png',
      );
      if (path != null) await File(path).writeAsBytes(bytes);
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Model3dBridgeException catch (e) {
      _showSnack(e.message);
    } on TimeoutException catch (e) {
      _showSnack(e.message ?? 'timeout');
    } on FileSystemException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmExit() async {
    if (!_dirty) return true;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.l10n.model3d_discardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    return answer == true;
  }

  @override
  Widget build(BuildContext context) => _buildOfficialLayout(context);
}
