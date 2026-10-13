import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nav_activity_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';

class FakeNavGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void emit(ImageGenerationState value) => state = value;
}

class FakeNavLocalUpscale extends LocalUpscaleTask {
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState();
  void emit(LocalUpscaleTaskState value) => state = value;
}

class FakeNavCloudUpscale extends CloudUpscaleTask {
  @override
  CloudUpscaleState build() => const CloudUpscaleState();
  void emit(CloudUpscaleState value) => state = value;
}

class FakeNavBulk extends BulkOperationNotifier {
  int undoCalls = 0;
  bool failUndo = false;
  Completer<void>? undoWait;

  @override
  BulkOperationState build() => const BulkOperationState();
  void emit(BulkOperationState value) => state = value;

  @override
  Future<void> undo() async {
    undoCalls++;
    if (undoWait != null) await undoWait!.future;
    state = state.copyWith(
      canUndo: true,
      canRedo: true,
      error: failUndo
          ? const BulkOperationError(BulkOperationErrorCode.undoFailed)
          : null,
    );
  }
}

void main() {
  late ProviderContainer container;
  late FakeNavGeneration generation;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(FakeNavGeneration.new),
        localUpscaleTaskProvider.overrideWith(FakeNavLocalUpscale.new),
        cloudUpscaleTaskProvider.overrideWith(FakeNavCloudUpscale.new),
        bulkOperationNotifierProvider.overrideWith(FakeNavBulk.new),
      ],
    );
    container.read(navActivityProvider);
    generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as FakeNavGeneration;
  });
  tearDown(() => container.dispose());

  GeneratedImage image(
    String id, {
    bool original = false,
    bool failed = false,
  }) => GeneratedImage(
    id: id,
    bytes: Uint8List(0),
    width: 1,
    height: 1,
    generationRunId: 1,
    isVariationOriginal: original,
    kind: failed
        ? GeneratedImageKind.failedStreamSnapshot
        : GeneratedImageKind.completed,
  );
  void start() => generation.emit(
    const ImageGenerationState(
      generationRunId: 1,
      status: GenerationStatus.generating,
      totalImages: 4,
    ),
  );

  test(
    'unread completion uses actual batch outputs and clears on returning',
    () {
      final activity = container.read(navActivityProvider.notifier);
      activity.setCurrentBranch(AppBranch.statistics);
      start();
      generation.emit(
        ImageGenerationState(
          generationRunId: 1,
          status: GenerationStatus.completed,
          currentImages: [
            image('one'),
            image('two'),
            image('source', original: true),
            image('failed', failed: true),
          ],
        ),
      );
      final unread = container.read(navActivityProvider).unreadGeneration!;
      expect(unread.status, GenerationStatus.completed);
      expect(unread.total, 2);
      activity.setCurrentBranch(AppBranch.generation);
      expect(container.read(navActivityProvider).unreadGeneration, isNull);
      generation.emit(
        container.read(imageGenerationNotifierProvider).copyWith(progress: 1),
      );
      expect(container.read(navActivityProvider).unreadGeneration, isNull);
    },
  );

  test('visible completion and cancellation do not become unread errors', () {
    start();
    generation.emit(
      const ImageGenerationState(
        generationRunId: 1,
        status: GenerationStatus.completed,
      ),
    );
    expect(container.read(navActivityProvider).unreadGeneration, isNull);
    container
        .read(navActivityProvider.notifier)
        .setCurrentBranch(AppBranch.localGallery);
    start();
    generation.emit(
      const ImageGenerationState(
        generationRunId: 1,
        status: GenerationStatus.cancelled,
      ),
    );
    expect(container.read(navActivityProvider).unreadGeneration, isNull);
    start();
    generation.emit(
      const ImageGenerationState(
        generationRunId: 1,
        status: GenerationStatus.error,
        errorMessage: 'failure',
      ),
    );
    expect(
      container.read(navActivityProvider).unreadGeneration?.status,
      GenerationStatus.error,
    );
    start();
    expect(container.read(navActivityProvider).unreadGeneration, isNull);
  });

  test('a mismatched generation run cannot overwrite the active result', () {
    container
        .read(navActivityProvider.notifier)
        .setCurrentBranch(AppBranch.statistics);
    start();
    generation.emit(
      const ImageGenerationState(
        generationRunId: 0,
        status: GenerationStatus.completed,
      ),
    );
    expect(container.read(navActivityProvider).unreadGeneration, isNull);
  });

  testWidgets(
    'finished tasks expire after ten seconds without affecting a newer task',
    (tester) async {
      final local =
          container.read(localUpscaleTaskProvider.notifier)
              as FakeNavLocalUpscale;
      local.emit(const LocalUpscaleTaskState(running: true));
      final first = container.read(navActivityProvider).tasks.single.id;
      local.emit(const LocalUpscaleTaskState(completed: true));
      expect(container.read(navActivityProvider).tasks.single.finished, isTrue);
      await tester.pump(const Duration(seconds: 9));
      local.emit(const LocalUpscaleTaskState(running: true));
      final tasks = container.read(navActivityProvider).tasks;
      expect(tasks.length, 2);
      final second = tasks.last.id;
      expect(second, isNot(first));
      expect(
        container.read(navActivityProvider.notifier).canCancelTask(first),
        isFalse,
      );
      expect(
        container.read(navActivityProvider.notifier).canCancelTask(second),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(navActivityProvider).tasks.single.id, second);
      local.emit(const LocalUpscaleTaskState(cancelling: true, running: true));
      expect(
        container.read(navActivityProvider.notifier).canCancelTask(second),
        isFalse,
      );
      local.emit(const LocalUpscaleTaskState());
      await tester.pump(const Duration(seconds: 10));
      expect(container.read(navActivityProvider).tasks, isEmpty);
    },
  );

  testWidgets('only the most recent finished bulk operation is undoable', (
    tester,
  ) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    final activity = container.read(navActivityProvider.notifier);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
        totalItems: 3,
      ),
    );
    final first = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
        totalItems: 3,
        currentProgress: 3,
      ),
    );
    expect(activity.canUndoTask(first), isTrue);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.metadataEdit,
        isOperationInProgress: true,
        canUndo: true,
      ),
    );
    expect(activity.canUndoTask(first), isFalse);
    final second = container.read(navActivityProvider).tasks.last.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.metadataEdit,
        isCompleted: true,
        canUndo: true,
      ),
    );
    expect(activity.canUndoTask(first), isFalse);
    expect(activity.canUndoTask(second), isTrue);
    await tester.pump(const Duration(seconds: 10));
    expect(activity.canUndoTask(second), isFalse);
  });

  testWidgets('one task cannot undo earlier history after its own undo', (
    tester,
  ) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    final activity = container.read(navActivityProvider.notifier);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
      ),
    );
    final id = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
      ),
    );
    await activity.undoTask(id);
    expect(container.read(bulkOperationNotifierProvider).canUndo, isTrue);
    expect(activity.canUndoTask(id), isFalse);
    await activity.undoTask(id);
    expect(bulk.undoCalls, 1);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a pending undo cannot be dispatched twice', (tester) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    final activity = container.read(navActivityProvider.notifier);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
      ),
    );
    final id = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
      ),
    );
    bulk.undoWait = Completer<void>();
    final first = activity.undoTask(id);
    await activity.undoTask(id);
    expect(bulk.undoCalls, 1);
    bulk.undoWait!.complete();
    await first;
    expect(activity.canUndoTask(id), isFalse);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('an unsuccessful undo can be retried after its error clears', (
    tester,
  ) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    final activity = container.read(navActivityProvider.notifier);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
      ),
    );
    final id = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
      ),
    );
    bulk.failUndo = true;
    await activity.undoTask(id);
    bulk.failUndo = false;
    bulk.emit(
      container.read(bulkOperationNotifierProvider).copyWith(error: null),
    );
    expect(activity.canUndoTask(id), isTrue);
    await activity.undoTask(id);
    expect(activity.canUndoTask(id), isFalse);
    expect(bulk.undoCalls, 2);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('undoing one task does not consume a later task', (tester) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    final activity = container.read(navActivityProvider.notifier);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
      ),
    );
    final first = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
      ),
    );
    await activity.undoTask(first);
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.metadataEdit,
        isOperationInProgress: true,
      ),
    );
    final second = container.read(navActivityProvider).tasks.last.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.metadataEdit,
        isCompleted: true,
        canUndo: true,
      ),
    );
    expect(activity.canUndoTask(first), isFalse);
    expect(activity.canUndoTask(second), isTrue);
    await activity.undoTask(second);
    expect(activity.canUndoTask(second), isFalse);
    expect(bulk.undoCalls, 2);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('an export cannot undo a previous unrelated operation', (
    tester,
  ) async {
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.export,
        isOperationInProgress: true,
        canUndo: true,
      ),
    );
    final id = container.read(navActivityProvider).tasks.single.id;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.export,
        isCompleted: true,
        canUndo: true,
      ),
    );
    expect(
      container.read(navActivityProvider.notifier).canUndoTask(id),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets(
    'resetting bulk state retains its task identity until the original expiry',
    (tester) async {
      final bulk =
          container.read(bulkOperationNotifierProvider.notifier) as FakeNavBulk;
      bulk.emit(
        const BulkOperationState(
          currentOperation: BulkOperationType.delete,
          isOperationInProgress: true,
        ),
      );
      final id = container.read(navActivityProvider).tasks.single.id;
      bulk.emit(const BulkOperationState());
      expect(
        container.read(navActivityProvider).tasks.single.bulk!.currentOperation,
        BulkOperationType.delete,
      );
      await tester.pump(const Duration(seconds: 8));
      bulk.emit(const BulkOperationState());
      expect(container.read(navActivityProvider).tasks.single.id, id);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(navActivityProvider).tasks, isEmpty);
    },
  );

  testWidgets(
    'cloud and local tasks expire independently and generation is not a task',
    (tester) async {
      start();
      final cloud =
          container.read(cloudUpscaleTaskProvider.notifier)
              as FakeNavCloudUpscale;
      final local =
          container.read(localUpscaleTaskProvider.notifier)
              as FakeNavLocalUpscale;
      cloud.emit(const CloudUpscaleState(running: true));
      local.emit(const LocalUpscaleTaskState(running: true));
      expect(container.read(navActivityProvider).tasks.length, 2);
      cloud.emit(const CloudUpscaleState(completed: true));
      await tester.pump(const Duration(seconds: 10));
      expect(
        container.read(navActivityProvider).tasks.single.source,
        NavTaskSource.localUpscale,
      );
      local.emit(const LocalUpscaleTaskState(completed: true));
      await tester.pump(const Duration(seconds: 10));
    },
  );
}
