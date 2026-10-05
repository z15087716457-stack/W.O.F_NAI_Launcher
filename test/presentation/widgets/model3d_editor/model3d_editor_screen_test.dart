import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/model3d_layer_data.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_bridge.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_library_service.dart';

/// 1x1 透明 PNG
const _tinyPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// 自动应答桥:每条命令按类型立即回 response,走真实 Model3dBridge 逻辑
Model3dBridge autoReplyBridge() {
  late Model3dBridge bridge;
  bridge = Model3dBridge(
    evalJs: (source) async {
      final match = RegExp(r'dispatch\((.+)\)$').firstMatch(source)!;
      final command =
          jsonDecode(jsonDecode(match.group(1)!) as String)
              as Map<String, dynamic>;
      final data = switch (command['type'] as String) {
        'render' => {'png': _tinyPng},
        'serialize' => {
          'sceneState': {'version': 1},
        },
        'loadModel' || 'getState' => {
          'bones': [
            {'id': 0, 'name': 'Hip'},
          ],
          'morphs': [
            {'id': 0, 'name': 'Smile', 'value': 0.0},
          ],
          'canUndo': true,
        },
        _ => <String, dynamic>{},
      };
      // 模拟 JS 异步回复
      Future.microtask(
        () => bridge.handleJsMessage([
          {
            'type': 'response',
            'requestId': command['requestId'],
            'ok': true,
            'data': data,
          },
        ]),
      );
    },
  );
  return bridge;
}

/// 打开编辑器,返回 Navigator.push 的结果 Future(供断言 pop 返回值)
Future<Future<Model3dEditResult?>> pumpEditor(
  WidgetTester tester, {
  Model3dLayerData? existing,
  Model3dBridge? bridge,
  Future<File?> Function()? picker,
}) async {
  final sample = File('test-model.glb');
  late Future<Model3dEditResult?> resultFuture;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            resultFuture = Navigator.push<Model3dEditResult>(
              context,
              MaterialPageRoute(
                builder: (_) => Model3dEditorScreen(
                  renderWidth: 8,
                  renderHeight: 8,
                  existing: existing,
                  bridgeOverride: bridge ?? autoReplyBridge(),
                  viewportBuilder: (_) => const ColoredBox(color: Colors.black),
                  markReadyForTest: true,
                  libraryService: _UiLibrary(),
                  pickModelFile: picker ?? () async => sample,
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return resultFuture;
}

class _UiLibrary extends Model3dLibraryService {
  _UiLibrary() : super(libraryDir: Directory.systemTemp);
  @override
  Future<String> importModel(File source) async => 'lib:${'a' * 64}';
}

void main() {
  testWidgets('empty scene can be saved and reopened as a 3D layer', (
    tester,
  ) async {
    final resultFuture = await pumpEditor(tester);
    await tester.tap(find.text('Save and Exit'));
    await tester.pumpAndSettle();
    final result = await resultFuture;
    expect(result!.modelRef, Model3dLibraryService.emptySceneRef);
    await pumpEditor(
      tester,
      existing: Model3dLayerData(
        modelRef: result.modelRef,
        sceneState: result.sceneState,
      ),
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unapplied changes?'), findsNothing);
  });

  testWidgets(
    'removing a model saves an empty scene instead of keeping its old ref',
    (tester) async {
      final resultFuture = await pumpEditor(tester);
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove model'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and Exit'));
      await tester.pumpAndSettle();
      expect(
        (await resultFuture)!.modelRef,
        Model3dLibraryService.emptySceneRef,
      );
    },
  );

  testWidgets('empty scene exposes official import without builtin card', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.text('Add Built-in Mannequin'), findsNothing);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('importing model enables save and close', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Import'), findsOneWidget);
    final applyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save and Exit'),
    );
    expect(applyButton.onPressed, isNotNull);
  });

  testWidgets('apply pops with png, sceneState and modelRef', (tester) async {
    final resultFuture = await pumpEditor(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and Exit'));
    await tester.pumpAndSettle();
    // 编辑器已关闭(返回打开页)
    expect(find.text('open'), findsOneWidget);
    final result = await resultFuture;
    expect(result, isNotNull);
    expect(result!.pngBytes, isNotEmpty);
    expect(result.modelRef, startsWith('lib:'));
    expect(result.sceneState['version'], 1);
  });

  testWidgets('back with dirty scene asks confirmation', (tester) async {
    await pumpEditor(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    // loadModel 后编辑器视为脏(内容尚未应用)
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unapplied changes?'), findsOneWidget);
  });

  testWidgets('bridge timeout surfaces a snackbar', (tester) async {
    // evalJs 从不回复,模拟 JS 侧卡死/无响应,驱动 Model3dBridge 的 15s
    // 超时路径(此处缩短为 100ms 以加快测试)。
    await pumpEditor(
      tester,
      bridge: Model3dBridge(
        evalJs: (_) async {},
        timeout: const Duration(milliseconds: 100),
      ),
    );
    await tester.tap(find.text('Import'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('existing builtin layer restores without dirty', (tester) async {
    await pumpEditor(
      tester,
      existing: const Model3dLayerData(
        modelRef: 'builtin:mannequin',
        sceneState: {'version': 1},
      ),
    );
    // 恢复完成:人偶已自动加载,空态卡片不再显示
    expect(find.text('Import'), findsOneWidget);
    // 恢复不置脏:返回应直接关闭,不出现放弃确认
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unapplied changes?'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
