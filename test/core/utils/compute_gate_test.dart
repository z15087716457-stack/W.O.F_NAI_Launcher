import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/isolate_pool.dart';

void main() {
  group('ComputeGate', () {
    test('limits concurrent work', () async {
      final gate = ComputeGate.forTesting(maxConcurrentTasks: 1);
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      var activeTasks = 0;
      var maxActiveTasks = 0;

      final Future<void> first = gate.run(() async {
        activeTasks++;
        maxActiveTasks = activeTasks > maxActiveTasks
            ? activeTasks
            : maxActiveTasks;
        firstStarted.complete();
        await releaseFirst.future;
        activeTasks--;
      });

      await firstStarted.future;

      final Future<void> second = gate.run(() async {
        activeTasks++;
        maxActiveTasks = activeTasks > maxActiveTasks
            ? activeTasks
            : maxActiveTasks;
        activeTasks--;
      });

      await Future<void>.delayed(Duration.zero);
      expect(maxActiveTasks, 1);

      releaseFirst.complete();
      await Future.wait([first, second]);

      expect(maxActiveTasks, 1);
    });

    test(
      'N tasks run at most K at a time and failures release permits',
      () async {
        final gate = ComputeGate.forTesting(maxConcurrentTasks: 2);
        final release = Completer<void>();
        var active = 0, peak = 0, started = 0;
        final tasks = [
          for (var i = 0; i < 9; i++)
            gate
                .run(() async {
                  started++;
                  active++;
                  if (active > peak) peak = active;
                  try {
                    await release.future;
                    if (i == 0) throw StateError('fixture');
                  } finally {
                    active--;
                  }
                })
                .catchError((Object _) {}),
        ];
        await Future<void>.delayed(Duration.zero);
        expect(started, 2);
        release.complete();
        await Future.wait(tasks);
        expect(started, 9);
        expect(peak, 2);
        expect(active, 0);
        expect(await gate.run(() => 42), 42);
      },
    );

    test('keeps default concurrency within processor-safe bounds', () {
      expect(ComputeGate.defaultMaxConcurrentTasks(processorCount: 1), 1);
      expect(ComputeGate.defaultMaxConcurrentTasks(processorCount: 2), 1);
      expect(ComputeGate.defaultMaxConcurrentTasks(processorCount: 8), 3);
    });
  });
}
