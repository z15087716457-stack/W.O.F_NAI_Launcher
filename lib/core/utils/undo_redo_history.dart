import 'dart:async';

/// 历史命令抽象类
abstract class HistoryCommand {
  final String description;
  HistoryCommand(this.description);

  /// 执行命令
  Future<void> execute();

  /// 撤销命令
  Future<void> undo();
}

/// 撤销/重做历史管理器
class UndoRedoHistory {
  final List<HistoryCommand> _history = [];
  final List<HistoryCommand> _redoStack = [];
  final int _maxSize;
  Future<void> _pending = Future.value();

  UndoRedoHistory({int maxSize = 50}) : _maxSize = maxSize;

  /// 获取历史记录列表（只读）
  List<HistoryCommand> get history => List.unmodifiable(_history);

  /// 获取重做栈（只读）
  List<HistoryCommand> get redoStack => List.unmodifiable(_redoStack);

  /// 是否可以撤销
  bool get canUndo => _history.isNotEmpty;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 添加命令
  Future<void> push(HistoryCommand command) => _run(() {
    _history.add(command);
    _redoStack.clear();
    if (_history.length > _maxSize) {
      _history.removeAt(0);
    }
  });

  /// 撤销
  Future<void> undo() => _run(() async {
    if (canUndo) {
      final command = _history.last;
      await command.undo();
      _history.removeLast();
      _redoStack.add(command);
    }
  });

  /// 重做
  Future<void> redo() => _run(() async {
    if (canRedo) {
      final command = _redoStack.last;
      await command.execute();
      _redoStack.removeLast();
      _history.add(command);
    }
  });

  /// 清空历史
  Future<void> clear() => _run(() {
    _history.clear();
    _redoStack.clear();
  });

  /// 所有栈变更按调用顺序完成；失败保留原栈并把错误交给调用者。
  Future<void> _run(FutureOr<void> Function() operation) async {
    final previous = _pending;
    final finished = Completer<void>();
    _pending = finished.future;
    try {
      await previous;
      await operation();
    } finally {
      finished.complete();
    }
  }
}
