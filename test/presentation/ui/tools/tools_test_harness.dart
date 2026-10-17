import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';

import '../gen/gen_test_harness.dart';

export '../gen/gen_test_harness.dart' show tapKey, hoverOver, genRail;

/// 原型窗口：1600 × 1000。
const toolsWindow = Size(1600, 1000);

class ToolsRecorder {
  final calls = <String>[];
  late final editor = ToolsEditorActions.logging(calls.add);
  late final director = ToolsDirectorActions.logging(calls.add);
  late final enhance = ToolsEnhanceActions.logging(calls.add);
  late final upscale = ToolsUpscaleActions.logging(calls.add);
  late final gen = _genActions();

  GenActions _genActions() {
    final b = GenActions.logging(calls.add);
    return GenActions(
      onLayoutChanged: b.onLayoutChanged,
      onModelChanged: b.onModelChanged,
      onTurboChanged: b.onTurboChanged,
      onFurryChanged: b.onFurryChanged,
      onOpenQuota: b.onOpenQuota,
      onNegativeTab: b.onNegativeTab,
      onClearPrompt: b.onClearPrompt,
      onQualityPreset: b.onQualityPreset,
      onUcPreset: b.onUcPreset,
      onTransparentChanged: b.onTransparentChanged,
      onPromptTool: b.onPromptTool,
      onOpenPalette: b.onOpenPalette,
      onTranslate: b.onTranslate,
      onToggleTranslation: b.onToggleTranslation,
      onTranslationSettings: b.onTranslationSettings,
      onOpenBridge: b.onOpenBridge,
      onAddCharacter: b.onAddCharacter,
      onClearCharacters: b.onClearCharacters,
      onRemoveCharacter: b.onRemoveCharacter,
      onMoveCharacter: b.onMoveCharacter,
      onCharacterEnabled: b.onCharacterEnabled,
      onRenameCharacter: b.onRenameCharacter,
      onCharacterGender: b.onCharacterGender,
      onCharacterToLibrary: b.onCharacterToLibrary,
      onAiPositionChanged: b.onAiPositionChanged,
      onCharacterPosition: b.onCharacterPosition,
      onPositioningChanged: b.onPositioningChanged,
      onImg2ImgUpload: b.onImg2ImgUpload,
      onImg2ImgFromLibrary: b.onImg2ImgFromLibrary,
      onImg2ImgSketch: b.onImg2ImgSketch,
      onImg2ImgChanged: b.onImg2ImgChanged,
      onImg2ImgEdit: b.onImg2ImgEdit,
      onImg2ImgInpaint: b.onImg2ImgInpaint,
      onImg2ImgPlace: b.onImg2ImgPlace,
      onImg2ImgRemove: b.onImg2ImgRemove,
      onAddVibeFiles: b.onAddVibeFiles,
      onAddVibeFromLibrary: b.onAddVibeFromLibrary,
      onAddRecentVibe: b.onAddRecentVibe,
      onVibeChanged: b.onVibeChanged,
      onEncodeVibe: b.onEncodeVibe,
      onRemoveVibe: b.onRemoveVibe,
      onClearVibes: b.onClearVibes,
      onSaveVibes: b.onSaveVibes,
      onNormalizeChanged: b.onNormalizeChanged,
      onAddPreciseFiles: b.onAddPreciseFiles,
      onAddPreciseFromLibrary: b.onAddPreciseFromLibrary,
      onPreciseChanged: b.onPreciseChanged,
      onRemovePrecise: b.onRemovePrecise,
      onClearPrecise: b.onClearPrecise,
      onSavePrecise: b.onSavePrecise,
      onSizeChanged: b.onSizeChanged,
      onCountChanged: b.onCountChanged,
      onRepeatChanged: b.onRepeatChanged,
      onParamChanged: b.onParamChanged,
      onSeedChanged: b.onSeedChanged,
      onSeedPinned: b.onSeedPinned,
      onSamplerChanged: b.onSamplerChanged,
      onNoiseChanged: b.onNoiseChanged,
      onVarietyChanged: b.onVarietyChanged,
      onDecrispChanged: b.onDecrispChanged,
      onSmeaChanged: b.onSmeaChanged,
      onGenerate: b.onGenerate,
      onStop: b.onStop,
      onEnhance: b.onEnhance,
      onVariations: b.onVariations,
      onUpscale: b.onUpscale,
      onUpscaleOption: b.onUpscaleOption,
      onSetInit: b.onSetInit,
      onEditImage: b.onEditImage,
      onInpaint: b.onInpaint,
      onSendToTools: b.onSendToTools,
      onUseSeed: b.onUseSeed,
      onCopySeed: b.onCopySeed,
      onPin: b.onPin,
      onCopyImage: b.onCopyImage,
      onSaveImage: b.onSaveImage,
      onOpenViewer: b.onOpenViewer,
      onFocusTile: b.onFocusTile,
      onBackdropChanged: b.onBackdropChanged,
      onZoomToFillChanged: b.onZoomToFillChanged,
      onRetry: b.onRetry,
      onDismissError: b.onDismissError,
      onFocusBatch: b.onFocusBatch,
      onAutoSaveChanged: b.onAutoSaveChanged,
      onFocusPins: b.onFocusPins,
      onSaveImages: b.onSaveImages,
      onPackImages: b.onPackImages,
      onDeleteImages: b.onDeleteImages,
      onClearHistory: b.onClearHistory,
      onFavorite: b.onFavorite,
      onSendTo: b.onSendTo,
      onReveal: b.onReveal,
      onUpscaleSettings: () => calls.add('onUpscaleSettings'),
    );
  }

  bool called(String prefix) => calls.any((c) => c.startsWith(prefix));
  String? last(String prefix) =>
      calls.lastWhere((c) => c.startsWith(prefix), orElse: () => '');
}

/// 生图页画布 + 工具条落下的面板（原型 `enhance` / `upscale` / `uprun` / `bar`）。
GenViewData toolsGenData({
  GenToolSheet? sheet,
  double? progress,
  bool cloud = false,
  ImageProvider? Function(String key)? images,
}) {
  final v = GenFixture.view(images: images);
  final cv = v.canvas;
  final info = cv.info!;
  return v.copyWith(
    canvas: GenCanvasData(
      focus: cv.focus,
      info: GenFocusInfo(
        tileId: info.tileId,
        width: info.width,
        height: info.height,
        seed: info.seed,
        pinned: info.pinned,
        variationsCost: info.variationsCost ?? 48,
        enhanceCost: 20,
        canUseAsInput: info.canUseAsInput,
      ),
      upscale: GenUpscale(
        options: cv.upscale.options,
        selected: cv.upscale.selected,
        cost: cloud ? 1 : null,
        running: progress != null,
        progress: progress,
        status: progress == null ? null : '本机放大 · SeedVR2 推理中',
      ),
      backdrop: cv.backdrop,
      zoomToFill: cv.zoomToFill,
      sheet: sheet,
    ),
  );
}

Widget toolsSheetFor(
  GenToolSheet? sheet,
  ToolsRecorder r, {
  bool custom = false,
  bool local = false,
}) => switch (sheet) {
  GenToolSheet.enhance => ToolsEnhanceSheet(
    data: ToolsFixture.enhance(custom: custom, local: local),
    actions: r.enhance,
  ),
  GenToolSheet.upscale => ToolsUpscaleSheet(
    data: ToolsFixture.upscale(),
    actions: r.upscale,
  ),
  null => const SizedBox.shrink(),
};

Future<void> pumpToolsGen(
  WidgetTester tester, {
  required ToolsRecorder r,
  GenToolSheet? sheet,
  double? progress,
  bool custom = false,
  bool local = false,
  bool dark = false,
  ImageProvider? Function(String key)? images,
}) async {
  final data = toolsGenData(sheet: sheet, progress: progress, images: images);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(
    toolsWindow.width - genRail,
    toolsWindow.height,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    genApp(
      GenerationPage(
        data: data,
        actions: r.gen,
        slots: GenSlots(
          editor: GenFixtureEditor.builder,
          toolSheet: toolsSheetFor(sheet, r, custom: custom, local: local),
        ),
      ),
      dark: dark,
    ),
  );
  await precacheGen(tester, [
    for (final t in data.canvas.focus?.tiles ?? const <GenTile>[]) ?t.image,
    for (final b in data.history.batches) ...b.images.map((i) => i.thumb),
  ]);
}

Future<void> pumpToolsEditor(
  WidgetTester tester, {
  required ToolsEditorData data,
  ToolsRecorder? r,
  bool dark = false,
  double width = 1600,
  double height = 1000,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width - genRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    genApp(
      ToolsEditorPage(
        data: data,
        actions: (r ?? ToolsRecorder()).editor,
        slots: const ToolsEditorSlots(canvas: ToolsFixtureStage.builder),
      ),
      dark: dark,
    ),
  );
  await precacheGen(tester, [
    ?data.image,
    for (final l in data.layers) ?l.thumb,
  ]);
}

Future<void> pumpToolsDirector(
  WidgetTester tester, {
  required ToolsDirectorData data,
  ToolsRecorder? r,
  bool dark = false,
  double width = 1600,
  double height = 1000,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    genApp(
      ToolsDirectorPage(data: data, actions: (r ?? ToolsRecorder()).director),
      dark: dark,
    ),
  );
  await precacheGen(tester, [
    for (final i in data.inputs) i.thumb,
    for (final run in data.runs) ...run.images,
  ]);
}
