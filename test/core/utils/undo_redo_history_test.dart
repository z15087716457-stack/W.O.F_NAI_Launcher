import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/undo_redo_history.dart';

class _Command extends HistoryCommand {
  _Command(super.description, {this.onUndo, this.onExecute});
  final Future<void> Function()? onUndo;
  final Future<void> Function()? onExecute;
  @override
  Future<void> execute() async => onExecute?.call();
  @override
  Future<void> undo() async => onUndo?.call();
}

void main() {
  test('failed undo keeps the command and allows an explicit retry', () async {
    final history = UndoRedoHistory();
    var fail = true;
    final command = _Command(
      'edit',
      onUndo: () async {
        if (fail) throw StateError('database unavailable');
      },
    );
    await history.push(command);
    await expectLater(history.undo(), throwsStateError);
    expect(history.history, [command]);
    expect(history.redoStack, isEmpty);
    expect(history.canUndo, isTrue);
    fail = false;
    await history.undo();
    expect(history.history, isEmpty);
    expect(history.redoStack, [command]);
  });

  test('failed redo keeps its place and allows an explicit retry', () async {
    final history = UndoRedoHistory();
    var fail = true;
    final command = _Command(
      'edit',
      onExecute: () async {
        if (fail) throw StateError('database unavailable');
      },
    );
    await history.push(command);
    await history.undo();
    await expectLater(history.redo(), throwsStateError);
    expect(history.redoStack, [command]);
    expect(history.history, isEmpty);
    fail = false;
    await history.redo();
    expect(history.history, [command]);
    expect(history.redoStack, isEmpty);
  });

  test('a partial command failure stays available for completion', () async {
    final history = UndoRedoHistory();
    final restored = {'a': false, 'b': false};
    var fail = true;
    final command = _Command(
      'restore batch',
      onUndo: () async {
        for (final path in restored.keys) {
          restored[path] = true;
          if (fail) throw StateError('remaining item unavailable');
        }
      },
    );
    await history.push(command);
    await expectLater(history.undo(), throwsStateError);
    expect(restored, {'a': true, 'b': false});
    expect(history.history, [command]);
    fail = false;
    await history.undo();
    expect(restored.values, everyElement(isTrue));
    expect(history.redoStack, [command]);
  });

  test('concurrent undo requests execute commands in history order', () async {
    final history = UndoRedoHistory();
    final started = Completer<void>();
    final release = Completer<void>();
    final events = <String>[];
    final first = _Command('first', onUndo: () async => events.add('first'));
    final last = _Command(
      'last',
      onUndo: () async {
        events.add('last-start');
        started.complete();
        await release.future;
        events.add('last-end');
      },
    );
    await history.push(first);
    await history.push(last);
    final undoLast = history.undo();
    await started.future;
    final undoFirst = history.undo();
    await Future<void>.delayed(Duration.zero);
    expect(events, ['last-start']);
    release.complete();
    await Future.wait([undoLast, undoFirst]);
    expect(events, ['last-start', 'last-end', 'first']);
    expect(history.redoStack, [last, first]);
  });

  test('redo queued during undo sees the completed undo', () async {
    final history = UndoRedoHistory();
    final release = Completer<void>();
    final command = _Command('edit', onUndo: () => release.future);
    await history.push(command);
    final undo = history.undo();
    final redo = history.redo();
    release.complete();
    await Future.wait([undo, redo]);
    expect(history.history, [command]);
    expect(history.redoStack, isEmpty);
  });

  test('a failed queued operation does not block the next request', () async {
    final history = UndoRedoHistory();
    var attempts = 0;
    final command = _Command(
      'edit',
      onUndo: () async {
        if (++attempts == 1) throw StateError('first failed');
      },
    );
    await history.push(command);
    final failed = expectLater(history.undo(), throwsStateError);
    final retry = history.undo();
    await failed;
    await retry;
    expect(attempts, 2);
    expect(history.redoStack, [command]);
  });

  for (final clear in [false, true]) {
    test(
      'mutation queued during undo preserves its result; clear=$clear',
      () async {
        final history = UndoRedoHistory();
        final started = Completer<void>();
        final release = Completer<void>();
        final old = _Command(
          'old',
          onUndo: () async {
            started.complete();
            await release.future;
          },
        );
        final next = _Command('next');
        await history.push(old);
        final undo = history.undo();
        await started.future;
        final mutation = Future<void>.sync(
          () => clear ? history.clear() : history.push(next),
        );
        release.complete();
        await Future.wait([undo, mutation]);
        expect(history.history, clear ? isEmpty : [next]);
        expect(history.redoStack, isEmpty);
      },
    );
  }

  test('size limit and empty history remain consistent', () async {
    final history = UndoRedoHistory(maxSize: 2);
    final a = _Command('a'), b = _Command('b'), c = _Command('c');
    await history.push(a);
    await history.push(b);
    await history.push(c);
    expect(history.history, [b, c]);
    await history.clear();
    await history.undo();
    await history.redo();
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
  });
}
