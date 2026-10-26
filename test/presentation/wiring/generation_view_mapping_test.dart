import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_view_mapping.dart';

GeneratedImage image(
  String id, {
  int? run,
  int? slot,
  int time = 1,
  GeneratedImageKind kind = GeneratedImageKind.completed,
  ImageOperation? operation,
}) => GeneratedImage(
  id: id,
  bytes: Uint8List(0),
  width: 512,
  height: 768,
  generationRunId: run,
  batchIndex: slot,
  createdAt: DateTime(2026, 10, 12, 0, time),
  kind: kind,
  operation: operation,
);

void main() {
  test('history pending preview shares the first unfinished canvas slot', () {
    final bytes = Uint8List.fromList([1]);
    final state = ImageGenerationState(
      generationRunId: 2,
      status: GenerationStatus.generating,
      totalImages: 2,
      currentImage: 2,
      currentImages: [image('done', run: 2, slot: 0)],
      streamPreviewSlots: [
        StreamPreviewSlot(
          imageNumber: 2,
          totalImages: 2,
          progress: .5,
          previewBytes: bytes,
        ),
      ],
    );
    final preview = generationHistoryView(state).batches.single.pendingPreview;
    expect(preview, isNotNull);
    expect(
      identical(
        preview,
        generationHistoryView(state).batches.single.pendingPreview,
      ),
      isTrue,
    );
    expect(
      identical(preview, generationFocusView(state)!.tiles.last.preview),
      isTrue,
    );
    expect(
      generationHistoryView(
        state.copyWith(streamPreviewSlots: []),
      ).batches.single.pendingPreview,
      isNull,
    );
    expect(
      generationHistoryView(
        state.copyWith(streamPreviewSlots: [], streamPreview: bytes),
      ).batches.single.pendingPreview,
      same(preview),
    );
    final outOfOrder = state.copyWith(
      currentImage: 1,
      currentImages: [image('second', run: 2, slot: 1)],
      streamPreviewSlots: [
        StreamPreviewSlot(
          imageNumber: 2,
          totalImages: 2,
          progress: 1,
          previewBytes: Uint8List.fromList([2]),
        ),
        StreamPreviewSlot(
          imageNumber: 1,
          totalImages: 2,
          progress: .4,
          previewBytes: bytes,
        ),
      ],
    );
    expect(
      generationHistoryView(outOfOrder).batches.single.pendingPreview,
      same(preview),
    );
    final completed = generationHistoryView(
      state.copyWith(
        status: GenerationStatus.completed,
        currentImages: [
          image('done', run: 2, slot: 0),
          image('second', run: 2, slot: 1),
        ],
      ),
    ).batches.single;
    expect(completed.images, hasLength(2));
    expect(completed.pendingPreview, isNull);
  });
  test('简洁单图投影按选中图展示，默认最新，批次原身份不变', () {
    final first = image('a', run: 1, slot: 0);
    final second = image('b', run: 1, slot: 1);
    final state = ImageGenerationState(
      history: [first, second],
      displayImages: [first, second],
    );
    expect(
      generationFocusView(
        state,
        selectedImage: 'b',
        singleImages: true,
      )!.tiles.single.id,
      'b',
    );
    expect(
      generationFocusView(state, singleImages: true)!.tiles.single.id,
      'b',
    );
    expect(
      generationFocusView(state, selectedImage: 'b')!.tiles.map((t) => t.id),
      ['a', 'b'],
    );
    final flat = generationHistoryView(state, singleImages: true);
    expect(flat.batches.map((b) => b.id).toSet(), {'img:a', 'img:b'});
    expect(flat.batches.every((b) => b.images.length == 1), isTrue);
    expect(generationHistoryView(state).batches.single.images.length, 2);
    expect(second.generationRunId, 1);
    expect(state.history, [first, second]);
  });

  test('工具宿主按临时收栏后的真实画布边界定位，不改变用户宽度偏好', () {
    const layout = GenLayout(leftWidth: 560, historyWidth: 400);
    expect(generationCanvasInsets(layout, 780), (left: 380.0, right: 40.0));
    expect(generationCanvasInsets(layout, 1600), (left: 560.0, right: 400.0));
    expect(generationCanvasInsets(layout.copyWith(dockOpen: true), 2000), (
      left: 860.0,
      right: 400.0,
    ));
    expect(
      generationCanvasInsets(
        layout.copyWith(leftOpen: false, historyOpen: false),
        1200,
      ),
      (left: 40.0, right: 40.0),
    );
    expect(layout.leftWidth, 560);
    expect(layout.historyWidth, 400);
  });

  test('V5 参数按能力隐藏噪声、多样性、SMEA 和 Decrisp', () {
    final view = generationParamsView(
      const ImageParams(model: 'nai-diffusion-5-full'),
    );
    expect(view.noise, isNull);
    expect(view.varietyPlus, isNull);
    expect(view.decrisp, isNull);
    expect(view.smea, isNull);
    expect(view.samplers.map((value) => value.id), Samplers.v5Samplers);
    expect(
      view.samplers
          .singleWhere((value) => value.id == Samplers.kEulerAncestral)
          .detail,
      isNotNull,
    );
  });
  test('V4.5 保留噪声与 Variety，V3 按采样器展示 SMEA', () {
    final modern = generationParamsView(
      const ImageParams(model: 'nai-diffusion-4-5-full'),
    );
    expect(modern.noise, 'karras');
    expect(modern.varietyPlus, isFalse);
    expect(modern.decrisp, isNull);
    expect(
      generationParamsView(const ImageParams(model: 'nai-diffusion-3')).smea,
      isNotNull,
    );
    expect(
      generationParamsView(
        const ImageParams(model: 'nai-diffusion-3', sampler: Samplers.ddim),
      ).smea,
      isNull,
    );
  });
  test('旧 Furry 不展示 V3 专用的 Decrisp 与 SMEA', () {
    final old = generationParamsView(
      const ImageParams(model: ImageModels.furryDiffusion),
    );
    expect(old.decrisp, isNull);
    expect(old.smea, isNull);
    final v3 = generationParamsView(
      const ImageParams(model: ImageModels.furryDiffusionV3),
    );
    expect(v3.decrisp, isNotNull);
    expect(v3.smea, isNotNull);
  });
  test('随机种子显示上次实际种子，手动种子优先', () {
    expect(generationParamsView(const ImageParams(), lastSeed: 19).seed, 19);
    expect(
      generationParamsView(const ImageParams(), lastSeed: 19).seedPinned,
      isFalse,
    );
    expect(
      generationParamsView(const ImageParams(seed: 7), lastSeed: 19).seed,
      7,
    );
    expect(generationParamsView(const ImageParams(seed: 7)).seedPinned, isTrue);
  });
  test('每次张数与重复次数对应真实生成链，不能反接', () {
    final view = generationImageView(
      const ImageParams(nSamples: 9),
      imagesPerRequest: 3,
    );
    expect(view.count, 3);
    expect(view.repeat, 9);
  });
  test('历史去重、按 run 归组和槽位排序，旧图不按相近时间合并', () {
    final first = image('first', run: 2, slot: 0, time: 2);
    final second = image('second', run: 2, slot: 1, time: 2);
    final history = generationHistoryView(
      ImageGenerationState(
        currentImages: [second, first],
        history: [first, image('old-a'), image('old-b')],
      ),
    );
    expect(history.batches.map((batch) => batch.id), [
      'run:2',
      'img:old-a',
      'img:old-b',
    ]);
    expect(history.batches.first.images.map((value) => value.id), [
      'first',
      'second',
    ]);
    expect(history.total, 4);
  });
  test('活动批次立即有占位，晚到首图仍回到同一批', () {
    final state = ImageGenerationState(
      generationRunId: 3,
      status: GenerationStatus.generating,
      totalImages: 3,
      batchWidth: 640,
      batchHeight: 960,
      currentImages: [image('second', run: 3, slot: 1)],
    );
    final history = generationHistoryView(state);
    expect(history.batches.first.id, 'run:3');
    expect(history.batches.first.pending, 2);
    expect(history.batches.first.count, 3);
    final focus = generationFocusView(state);
    expect(focus!.id, 'run:3');
    expect(focus.tiles.length, 3);
    expect(focus.tiles[0].state, GenTileState.pending);
    expect(focus.tiles[1].id, 'second');
    expect(focus.tiles[2].width, 640);
  });
  test('占位身份绑定 run，不同批次不会重用同一槽身份', () {
    ImageGenerationState pending(int run) => ImageGenerationState(
      generationRunId: run,
      status: GenerationStatus.generating,
      totalImages: 1,
      batchWidth: 512,
      batchHeight: 768,
    );
    expect(
      generationFocusView(pending(1))!.tiles.single.id,
      isNot(generationFocusView(pending(2))!.tiles.single.id),
    );
  });
  test('切到历史组后流式帧不能夺回焦点', () {
    final old = image('old', run: 1);
    final state = ImageGenerationState(
      generationRunId: 2,
      status: GenerationStatus.generating,
      totalImages: 1,
      batchWidth: 512,
      batchHeight: 768,
      history: [old],
      streamPreviewSlots: [
        StreamPreviewSlot(
          imageNumber: 1,
          totalImages: 1,
          progress: .5,
          previewBytes: Uint8List.fromList([1]),
        ),
      ],
    );
    final group = generationFocusView(
      state,
      focus: const CanvasFocus(group: 'run:1'),
    );
    expect(group!.tiles.single.id, 'old');
    final live = generationFocusView(state);
    expect(live!.tiles.single.state, GenTileState.streaming);
    expect(live.tiles.single.progress, .5);
  });
  test('历史清空后保留显示组，固定图仍能独立打开', () {
    final shown = image('shown', run: 1);
    final pin = image('pin');
    final state = ImageGenerationState(displayImages: [shown]);
    expect(generationHistoryView(state).total, 0);
    expect(generationFocusView(state)!.tiles.single.id, 'shown');
    expect(
      generationFocusView(
        state,
        focus: const CanvasFocus(group: 'pin:pin'),
        pinned: [pin],
      )!.tiles.single.id,
      'pin',
    );
  });
  test('取消后只统计留存张数，不保留排队占位', () {
    final state = ImageGenerationState(
      generationRunId: 3,
      status: GenerationStatus.cancelled,
      totalImages: 5,
      currentImages: [image('done', run: 3)],
    );
    expect(generationHistoryView(state).batches.single.count, 1);
    expect(generationFocusView(state)!.tiles.length, 1);
  });
  test('失败快照明确标记，历史操作来源只按记录映射', () {
    final failed = image(
      'failed',
      kind: GeneratedImageKind.failedStreamSnapshot,
    );
    final state = ImageGenerationState(
      history: [
        failed,
        image('enhanced', operation: ImageOperation.enhance),
      ],
    );
    expect(generationFocusView(state)!.tiles.single.state, GenTileState.failed);
    expect(
      generationHistoryView(state).batches.last.images.single.op,
      GenOp.enhance,
    );
  });
  test('批次按本地时间新到旧，收藏与选中来自真实状态', () {
    final state = ImageGenerationState(
      history: [image('old', run: 1), image('new', run: 2, time: 2)],
    );
    final view = generationHistoryView(
      state,
      selected: 'run:1',
      favorites: {'new'},
      autoSave: false,
      pinned: 2,
    );
    expect(view.batches.first.id, 'run:2');
    expect(view.batches.first.images.single.favorite, isTrue);
    expect(view.selected, 'run:1');
    expect(view.autoSave, isFalse);
    expect(view.pinned, 2);
  });
}
