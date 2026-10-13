import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_branch.dart';
import 'bulk_operation_provider.dart';
import 'generation/cloud_upscale_provider.dart';
import 'generation/local_upscale_provider.dart';
import 'image_generation_provider.dart';

final navActivityProvider =
    NotifierProvider<NavActivityNotifier, NavActivityState>(
      NavActivityNotifier.new,
    );

enum NavTaskSource { localUpscale, cloudUpscale, bulkOperation }

class NavGenerationResult {
  const NavGenerationResult({
    required this.status,
    required this.total,
    this.error,
  });
  final GenerationStatus status;
  final int total;
  final String? error;
}

class NavBackgroundTask {
  const NavBackgroundTask({
    required this.id,
    required this.source,
    this.local,
    this.cloud,
    this.bulk,
    this.finished = false,
  });
  final String id;
  final NavTaskSource source;
  final LocalUpscaleTaskState? local;
  final CloudUpscaleState? cloud;
  final BulkOperationState? bulk;
  final bool finished;
}

class NavActivityState {
  const NavActivityState({this.unreadGeneration, this.tasks = const []});
  final NavGenerationResult? unreadGeneration;
  final List<NavBackgroundTask> tasks;
}

class NavActivityNotifier extends Notifier<NavActivityState> {
  final _runningIds = <NavTaskSource, String>{};
  final _timers = <String, Timer>{};
  int _serial = 0;
  AppBranch _currentBranch = AppBranch.generation;
  String? _latestBulkId;
  String? _undoingTaskId;
  String? _undoneBulkTaskId;
  bool _disposed = false;
  AppBranch get currentBranch => _currentBranch;

  @override
  NavActivityState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    ref.listen(imageGenerationNotifierProvider, _onGeneration);
    ref.listen(localUpscaleTaskProvider, (previous, next) {
      _onTask(NavTaskSource.localUpscale, running: next.running, local: next);
    });
    ref.listen(cloudUpscaleTaskProvider, (previous, next) {
      _onTask(NavTaskSource.cloudUpscale, running: next.running, cloud: next);
    });
    ref.listen(bulkOperationNotifierProvider, (previous, next) {
      _onTask(
        NavTaskSource.bulkOperation,
        running: next.isOperationInProgress,
        bulk: next,
      );
    });
    final local = ref.read(localUpscaleTaskProvider);
    final cloud = ref.read(cloudUpscaleTaskProvider);
    final bulk = ref.read(bulkOperationNotifierProvider);
    return NavActivityState(
      tasks: List.unmodifiable([
        if (local.running)
          NavBackgroundTask(
            id: _startTask(NavTaskSource.localUpscale),
            source: NavTaskSource.localUpscale,
            local: local,
          ),
        if (cloud.running)
          NavBackgroundTask(
            id: _startTask(NavTaskSource.cloudUpscale),
            source: NavTaskSource.cloudUpscale,
            cloud: cloud,
          ),
        if (bulk.isOperationInProgress)
          NavBackgroundTask(
            id: _startTask(NavTaskSource.bulkOperation),
            source: NavTaskSource.bulkOperation,
            bulk: bulk,
          ),
      ]),
    );
  }

  void setCurrentBranch(AppBranch branch) {
    _currentBranch = branch;
    if (branch == AppBranch.generation && state.unreadGeneration != null) {
      state = NavActivityState(tasks: state.tasks);
    }
  }

  void _onGeneration(
    ImageGenerationState? previous,
    ImageGenerationState next,
  ) {
    if (next.isGenerating) {
      if (state.unreadGeneration != null) {
        state = NavActivityState(tasks: state.tasks);
      }
      return;
    }
    if (previous?.isGenerating != true ||
        previous!.generationRunId != next.generationRunId ||
        _currentBranch == AppBranch.generation ||
        (next.status != GenerationStatus.completed &&
            next.status != GenerationStatus.error)) {
      return;
    }
    state = NavActivityState(
      unreadGeneration: NavGenerationResult(
        status: next.status,
        total: next.currentImages
            .where(
              (image) =>
                  !image.isVariationOriginal &&
                  !image.isFailedStreamSnapshot &&
                  (next.generationRunId == null ||
                      image.generationRunId == next.generationRunId),
            )
            .length,
        error: next.errorMessage,
      ),
      tasks: state.tasks,
    );
  }

  String _startTask(NavTaskSource source) {
    final id = '${source.name}:${++_serial}';
    _runningIds[source] = id;
    if (source == NavTaskSource.bulkOperation) _latestBulkId = id;
    return id;
  }

  void _onTask(
    NavTaskSource source, {
    required bool running,
    LocalUpscaleTaskState? local,
    CloudUpscaleState? cloud,
    BulkOperationState? bulk,
  }) {
    var id = _runningIds[source];
    if (running) {
      id ??= _startTask(source);
    } else if (id == null) {
      if (source == NavTaskSource.bulkOperation && _latestBulkId != null) {
        final latest = state.tasks
            .where((task) => task.id == _latestBulkId)
            .firstOrNull;
        if (latest != null) {
          _replaceTask(
            NavBackgroundTask(
              id: latest.id,
              source: source,
              bulk: bulk?.currentOperation == null ? latest.bulk : bulk,
              finished: true,
            ),
          );
        }
      }
      return;
    } else {
      _runningIds.remove(source);
      final finishedId = id;
      _timers[id] = Timer(const Duration(seconds: 10), () {
        _timers.remove(finishedId);
        state = NavActivityState(
          unreadGeneration: state.unreadGeneration,
          tasks: List.unmodifiable(
            state.tasks.where((task) => task.id != finishedId),
          ),
        );
      });
    }
    if (source == NavTaskSource.bulkOperation &&
        bulk?.currentOperation == null) {
      bulk = state.tasks.where((task) => task.id == id).firstOrNull?.bulk;
    }
    _replaceTask(
      NavBackgroundTask(
        id: id,
        source: source,
        local: local,
        cloud: cloud,
        bulk: bulk,
        finished: !running,
      ),
    );
  }

  void _replaceTask(NavBackgroundTask task) {
    final index = state.tasks.indexWhere((entry) => entry.id == task.id);
    final tasks = [...state.tasks];
    if (index < 0) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
    state = NavActivityState(
      unreadGeneration: state.unreadGeneration,
      tasks: List.unmodifiable(tasks),
    );
  }

  bool canCancelTask(String id) =>
      _runningIds[NavTaskSource.localUpscale] == id &&
      ref.read(localUpscaleTaskProvider).running &&
      !ref.read(localUpscaleTaskProvider).cancelling;

  bool canUndoTask(String id) =>
      _undoingTaskId == null &&
      _undoneBulkTaskId != id &&
      _latestBulkId == id &&
      state.tasks.any(
        (task) =>
            task.id == id &&
            task.finished &&
            task.bulk?.isCompleted == true &&
            task.bulk?.error == null &&
            const {
              BulkOperationType.delete,
              BulkOperationType.metadataEdit,
              BulkOperationType.toggleFavorite,
            }.contains(task.bulk?.currentOperation),
      ) &&
      !ref.read(bulkOperationNotifierProvider).isOperationInProgress &&
      ref.read(bulkOperationNotifierProvider).canUndo;

  void cancelTask(String id) {
    if (canCancelTask(id)) ref.read(localUpscaleTaskProvider.notifier).cancel();
  }

  Future<void> undoTask(String id) async {
    if (!canUndoTask(id)) return;
    _undoingTaskId = id;
    state = NavActivityState(
      unreadGeneration: state.unreadGeneration,
      tasks: state.tasks,
    );
    try {
      await ref.read(bulkOperationNotifierProvider.notifier).undo();
      if (!_disposed && !ref.read(bulkOperationNotifierProvider).hasError) {
        _undoneBulkTaskId = id;
      }
    } finally {
      _undoingTaskId = null;
      if (!_disposed) {
        state = NavActivityState(
          unreadGeneration: state.unreadGeneration,
          tasks: state.tasks,
        );
      }
    }
  }
}
