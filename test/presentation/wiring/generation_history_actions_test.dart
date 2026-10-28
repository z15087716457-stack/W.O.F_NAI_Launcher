import '../../helpers/grouped_canvas_batches.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as pixels;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/wiring/generation_history_actions.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings;

class HistoryGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void publish(ImageGenerationState value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late GenerationHistoryActions actions;
  final bytes = Uint8List.fromList(
    pixels.encodePng(pixels.Image(width: 64, height: 64)),
  );
  GeneratedImage image(String id, int run) => GeneratedImage(
    id: id,
    bytes: bytes,
    width: 64,
    height: 64,
    generationRunId: run,
  );
  void publish(ImageGenerationState value) =>
      (container.read(imageGenerationNotifierProvider.notifier)
              as HistoryGeneration)
          .publish(value);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-history-');
    final storage = MemoryDraftSettings();
    container = ProviderContainer(
      overrides: [
        groupedCanvasBatchesOverride,
        localStorageServiceProvider.overrideWithValue(storage),
        imageGenerationNotifierProvider.overrideWith(HistoryGeneration.new),
      ],
    );
    container.read(canvasPinnedNotifierProvider.notifier).debugRepository =
        CanvasPinRepository(storage: storage, directory: directory);
    actions = container.read(generationHistoryActionsProvider);
  });
  tearDown(() async {
    container.dispose();
    await directory.delete(recursive: true);
  });
  test('批次点击可重复发定位请求，点单图保持所属批次与索引', () {
    final first = image('first', 1);
    final second = image('second', 1);
    publish(ImageGenerationState(history: [first, second]));
    actions.focusBatch('run:1');
    expect(
      container.read(generationCanvasGroupSelectionProvider)!.group,
      'run:1',
    );
    final request = container.read(canvasHistoryFocusRequestProvider)!;
    actions.focusBatch('run:1');
    expect(
      container.read(canvasHistoryFocusRequestProvider)!.revision,
      request.revision + 1,
    );
    actions.focusTile(second.id);
    expect(container.read(generationPreviewSelectionProvider), second.id);
    expect(container.read(generationCanvasGroupSelectionProvider)!.subimage, 1);
  });
  test('显式钉住的连点串行且幂等，不因 toggle 重复执行撤销', () async {
    final first = image('first', 1);
    publish(ImageGenerationState(history: [first]));
    await Future.wait([
      actions.pin(first.id, true),
      actions.pin(first.id, true),
    ]);
    expect(container.read(canvasPinnedNotifierProvider), {first.id});
    await Future.wait([
      actions.pin(first.id, false),
      actions.pin(first.id, false),
    ]);
    expect(container.read(canvasPinnedNotifierProvider), isEmpty);
  });
  test('删会话图并移除其钉板身份，其他图与磁盘副本保留', () async {
    final first = image('first', 1);
    final second = image('second', 1);
    publish(ImageGenerationState(history: [first, second]));
    await actions.pin(first.id, true);
    final files = directory.listSync().whereType<File>().toList();
    actions.focusTile(first.id);
    await actions.delete([first.id, first.id]);
    expect(
      container
          .read(imageGenerationNotifierProvider)
          .history
          .map((image) => image.id),
      [second.id],
    );
    expect(container.read(canvasPinnedNotifierProvider), isEmpty);
    expect(container.read(generationPreviewSelectionProvider), second.id);
    expect(files.every((file) => file.existsSync()), isTrue);
  });
  test('清历史保留当前显示图和独立钉板，不遗留已删图的焦点', () async {
    final first = image('first', 1);
    final current = image('current', 2);
    publish(
      ImageGenerationState(
        history: [first],
        currentImages: [current],
        displayImages: [current],
      ),
    );
    await actions.pin(first.id, true);
    actions.focusTile(current.id);
    actions.clear();
    expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
    expect(
      container.read(imageGenerationNotifierProvider).displayImages.single.id,
      current.id,
    );
    expect(container.read(canvasPinnedNotifierProvider), {first.id});
    expect(container.read(generationPreviewSelectionProvider), current.id);
    actions.focusPins();
    expect(
      container.read(generationCanvasGroupSelectionProvider)!.group,
      'pin:first',
    );
  });
  test('点已移除的图或批次不改变当前选择', () {
    publish(ImageGenerationState(history: [image('kept', 1)]));
    actions.focusTile('kept');
    actions.focusTile('gone');
    actions.focusBatch('run:999');
    expect(container.read(generationPreviewSelectionProvider), 'kept');
  });
}
