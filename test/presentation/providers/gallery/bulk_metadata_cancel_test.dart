import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/database_manager.dart';
import 'package:nai_launcher/core/database/database_providers.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:nai_launcher/presentation/widgets/bulk_progress_dialog.dart';

import '../../../helpers/app_logger_test_isolation.dart';
import '../../ui/refs/refs_test_harness.dart' show refsApp;

class _Manager implements DatabaseManager {
  _Manager(this.source);
  final GalleryDataSource source;
  @override
  T? getDataSource<T>(String name) => source as T;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gallery implements GalleryDataSource {
  _Gallery({this.readGate, this.writeGate, this.failId});
  final int? readGate, writeGate, failId;
  final entered = Completer<void>();
  final release = Completer<void>();
  final tags = <int, List<String>>{
    1: ['base-1'],
    2: ['base-2'],
    3: ['base-3'],
  };
  final written = <int>[];
  final attempted = <int>[];
  var reads = 0, writes = 0;
  @override
  Future<int?> getImageIdByPath(String path) async =>
      int.parse(path.split('-').last);
  @override
  Future<List<String>> getImageTags(int imageId) async {
    if (++reads == readGate) {
      entered.complete();
      await release.future;
    }
    return List.of(tags[imageId]!);
  }

  @override
  Future<void> setImageTags(int imageId, List<String> values) async {
    attempted.add(imageId);
    if (++writes == writeGate) {
      entered.complete();
      await release.future;
    }
    if (imageId == failId) throw StateError('Fixture write failure');
    tags[imageId] = List.of(values);
    written.add(imageId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  for (final (
        label,
        readGate,
        writeGate,
        failId,
        expectedSuccess,
        expectedFailed,
        cancel,
      )
      in [
        ('during preparation', 1, null, null, 0, 0, true),
        ('after reading tags before writing', 4, null, null, 0, 0, true),
        ('during the first write', null, 1, null, 1, 0, true),
        ('during the second write', null, 2, null, 2, 0, true),
        ('after a failed write', null, 2, 1, 1, 1, true),
        ('normal completion', null, 1, null, 3, 0, false),
      ]) {
    testWidgets(
      'metadata edit cancellation $label drains and records only completed writes',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(1200, 900);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final source = _Gallery(
          readGate: readGate,
          writeGate: writeGate,
          failId: failId,
        );
        final container = ProviderContainer(
          overrides: [
            databaseManagerProvider.overrideWith(
              (ref) async => _Manager(source),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(bulkOperationNotifierProvider.notifier);
        final task = notifier.bulkEditMetadata(
          ['fixture-1', 'fixture-2', 'fixture-3'],
          tagsToAdd: ['added-tag'],
        );
        bool? dialogResult;
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: refsApp(
              Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    dialogResult = await BulkProgressDialog.show(context);
                  },
                  child: const Text('show-progress'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('show-progress'));
        await t.pumpAndSettle();
        expect(source.entered.isCompleted, isTrue);
        if (cancel) {
          await t.tap(find.text('取消'));
          await t.pumpAndSettle();
        }
        final visibleBeforeStop = find
            .byType(BulkProgressDialog)
            .evaluate()
            .isNotEmpty;
        final resultBeforeStop = dialogResult;
        source.release.complete();
        await t.pumpAndSettle();
        final result = await task;
        expect(visibleBeforeStop, isTrue);
        expect(resultBeforeStop, isNull);
        expect(result.success, expectedSuccess);
        expect(result.failed, expectedFailed);
        expect(dialogResult, !cancel);
        expect(find.byType(BulkProgressDialog), findsNothing);
        final state = container.read(bulkOperationNotifierProvider);
        expect(state.isOperationInProgress, isFalse);
        expect(state.isCompleted, !cancel);
        expect(state.currentProgress, expectedSuccess + expectedFailed);
        expect(state.lastResult?.success, expectedSuccess);
        expect(state.canUndo, expectedSuccess > 0);

        final edited = source.written.toSet();
        for (final id in source.tags.keys.where((id) => !edited.contains(id))) {
          source.tags[id] = ['external-$id'];
        }
        if (edited.isNotEmpty) {
          source.attempted.clear();
          await notifier.undo();
          expect(source.attempted.toSet(), edited);
          for (final id in edited) {
            expect(source.tags[id], ['base-$id']);
          }
          source.attempted.clear();
          await notifier.redo();
          expect(source.attempted.toSet(), edited);
          for (final id in edited) {
            expect(source.tags[id], ['base-$id', 'added-tag']);
          }
        }
        for (final id in source.tags.keys.where((id) => !edited.contains(id))) {
          expect(source.tags[id], ['external-$id']);
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
