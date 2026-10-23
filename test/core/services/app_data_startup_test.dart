import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_data_startup.dart';
import 'package:nai_launcher/core/utils/app_support_directory.dart';

void main() {
  test(
    'failed preparation shows recovery and never opens application services',
    () async {
      final calls = <String>[];
      const error = FileSystemException('synthetic conflict');
      await startWithPreparedAppData(
        prepare: () async {
          calls.add('prepare');
          throw error;
        },
        start: () async => calls.add('open databases'),
        onFailure: (failure, stack) async {
          expect(failure, same(error));
          calls.add('show recovery');
        },
      );
      expect(calls, ['prepare', 'show recovery']);
    },
  );

  test(
    'resolver shares successful preparation and clears synchronous or async errors',
    () async {
      for (final syncFailure in [true, false]) {
        var attempts = 0;
        final ready = Completer<Directory>();
        final resolver = ApplicationSupportDirectoryResolver(() {
          attempts++;
          if (attempts == 1) {
            if (syncFailure) throw const FileSystemException('not ready');
            return Future.error(const FileSystemException('not ready'));
          }
          return ready.future;
        });
        await expectLater(
          resolver.resolve(),
          throwsA(isA<FileSystemException>()),
        );
        final next = resolver.resolve();
        expect(resolver.resolve(), same(next));
        final directory = Directory('synthetic-data');
        ready.complete(directory);
        expect(await next, directory);
        expect(await resolver.resolve(), directory);
        expect(attempts, 2);
      }
    },
  );

  test(
    'retry starts services exactly once after storage becomes ready',
    () async {
      var attempts = 0, starts = 0, recoveries = 0;
      final resolver = ApplicationSupportDirectoryResolver(() async {
        if (++attempts == 1) throw const FileSystemException('not ready');
        return Directory('synthetic-data');
      });
      Future<void> attempt() => startWithPreparedAppData(
        prepare: resolver.resolve,
        start: () async {
          starts++;
        },
        onFailure: (_, __) async {
          recoveries++;
        },
      );
      await attempt();
      expect(starts, 0);
      await attempt();
      expect([attempts, starts, recoveries], [2, 1, 1]);
    },
  );

  test(
    'failures after services start are not retried through data recovery',
    () async {
      var recoveries = 0;
      await expectLater(
        startWithPreparedAppData(
          prepare: () async => Directory('synthetic-data'),
          start: () async => throw StateError('later startup failure'),
          onFailure: (_, __) async {
            recoveries++;
          },
        ),
        throwsStateError,
      );
      expect(recoveries, 0);
    },
  );
}
