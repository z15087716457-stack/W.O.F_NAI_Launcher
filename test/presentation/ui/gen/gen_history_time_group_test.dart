import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  GenBatch batch(String id, DateTime time, {int count = 1, int pending = 0}) {
    final source = GenFixture.view().history.batches.first.images.first;
    return GenBatch(
      id: id,
      time: time,
      pending: pending,
      images: [
        for (var index = 0; index < count; index++)
          GenHistoryImage(
            id: '$id-$index',
            thumb: source.thumb,
            width: source.width,
            height: source.height,
          ),
      ],
    );
  }

  GenViewData data(List<GenBatch> batches, {bool openDetailOnClick = false}) =>
      GenFixture.view().copyWith(
        history: GenHistoryData(
          batches: batches,
          openDetailOnClick: openDetailOnClick,
        ),
      );
  test('点击模式变化使历史契约失效并触发刷新', () {
    expect(
      const GenHistoryData(),
      isNot(const GenHistoryData(openDetailOnClick: true)),
    );
  });
  testWidgets('打开详情模式单击开封面，未出图占位仍只定位', (tester) async {
    final recorder = GenRecorder();
    await pumpGen(
      tester,
      actions: recorder.actions,
      data: data([
        batch('done', DateTime(2026, 10, 12, 10, 46), count: 2),
        batch('pending', DateTime(2026, 10, 12, 10, 45), count: 0, pending: 1),
      ], openDetailOnClick: true),
    );
    await tapKey(tester, 'gen-batch-tile-done');
    expect(recorder.last('onOpenViewer'), 'onOpenViewer(done-0)');
    expect(recorder.called('onFocusBatch'), isFalse);
    await tapKey(tester, 'gen-batch-tile-pending');
    expect(recorder.last('onFocusBatch'), 'onFocusBatch(pending)');
    expect(recorder.calls.where((c) => c.startsWith('onOpenViewer')), [
      'onOpenViewer(done-0)',
    ]);
  });
  testWidgets('打开详情模式仍优先 Ctrl、Shift 和多选按钮', (tester) async {
    final recorder = GenRecorder();
    await pumpGen(
      tester,
      actions: recorder.actions,
      data: data([
        for (final id in ['first', 'second', 'third'])
          batch(id, DateTime(2026, 10, 12, 10, 46)),
      ], openDetailOnClick: true),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tapKey(tester, 'gen-batch-tile-first');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tapKey(tester, 'gen-batch-tile-third');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tapKey(tester, 'gen-history-save-selected');
    expect(
      recorder.last('onSaveImages'),
      'onSaveImages([first-0, second-0, third-0])',
    );
    expect(recorder.called('onOpenViewer'), isFalse);
    expect(recorder.called('onFocusBatch'), isFalse);
    await tapKey(tester, 'gen-history-select');
    await tapKey(tester, 'gen-history-select');
    await tapKey(tester, 'gen-batch-tile-second');
    await tapKey(tester, 'gen-history-save-selected');
    expect(recorder.last('onSaveImages'), 'onSaveImages([second-0])');
    expect(recorder.called('onOpenViewer'), isFalse);
    await tapKey(tester, 'gen-history-select');
    await tapKey(tester, 'gen-batch-tile-second');
    expect(recorder.last('onOpenViewer'), 'onOpenViewer(second-0)');
    expect(tester.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    testWidgets('同一分钟不同请求共享时间标题，保留两个缩略图 $dark', (tester) async {
      await pumpGen(
        tester,
        dark: dark,
        data: data([
          batch('new', DateTime(2026, 10, 12, 10, 46, 59)),
          batch('old', DateTime(2026, 10, 12, 10, 46, 1)),
        ]),
      );
      expect(find.text('10:46'), findsOneWidget);
      expect(find.byKey(const Key('gen-batch-tile-new')), findsOneWidget);
      expect(find.byKey(const Key('gen-batch-tile-old')), findsOneWidget);
    });
    testWidgets('分钟切换保留各自标题，不将 10:45 合入 10:46 $dark', (tester) async {
      await pumpGen(
        tester,
        dark: dark,
        data: data([
          batch('new', DateTime(2026, 10, 12, 10, 46)),
          batch('old', DateTime(2026, 10, 12, 10, 45, 59)),
        ]),
      );
      expect(find.text('10:46'), findsOneWidget);
      expect(find.text('10:45'), findsOneWidget);
    });
    testWidgets('不同日期的相同分钟分别标注日期 $dark', (tester) async {
      await pumpGen(
        tester,
        dark: dark,
        data: data([
          batch('today', DateTime(2026, 10, 12, 10, 46)),
          batch('yesterday', DateTime(2026, 10, 11, 10, 46)),
        ]),
      );
      final headings = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.endsWith('10:46') == true,
      );
      expect(headings, findsNWidgets(2));
      expect(
        tester.widgetList<Text>(headings).map((widget) => widget.data).toSet(),
        hasLength(2),
      );
    });
  }
  testWidgets('共享标题仍保留批次张数、待出进度与批次回调', (tester) async {
    final recorder = GenRecorder();
    await pumpGen(
      tester,
      actions: recorder.actions,
      data: data([
        batch('new', DateTime(2026, 10, 12, 10, 46, 59)),
        batch('old', DateTime(2026, 10, 12, 10, 46, 1), count: 2, pending: 1),
      ]),
    );
    expect(find.text('10:46'), findsOneWidget);
    expect(find.text('3 张'), findsOneWidget);
    expect(find.text('· 还剩 1 张'), findsOneWidget);
    await tapKey(tester, 'gen-batch-tile-old');
    expect(recorder.last('onFocusBatch'), 'onFocusBatch(old)');
    await tester.tap(find.byKey(const Key('gen-batch-tile-old')));
    await tester.pumpAndSettle();
    expect(recorder.last('onOpenViewer'), 'onOpenViewer(old-0)');
    await tapKey(tester, 'gen-history-select');
    await tapKey(tester, 'gen-batch-tile-new');
    await tapKey(tester, 'gen-batch-tile-old');
    await tapKey(tester, 'gen-history-save-selected');
    expect(
      recorder.last('onSaveImages'),
      'onSaveImages([new-0, old-0, old-1])',
    );
  });
  testWidgets('删除分组第一批后，剩余批次接过时间标题', (tester) async {
    final remaining = batch('old', DateTime(2026, 10, 12, 10, 46));
    await pumpGen(
      tester,
      data: data([batch('new', DateTime(2026, 10, 12, 10, 46, 59)), remaining]),
    );
    await pumpGen(tester, data: data([remaining]));
    expect(find.text('10:46'), findsOneWidget);
    expect(find.byKey(const Key('gen-batch-tile-old')), findsOneWidget);
    expect(find.byKey(const Key('gen-batch-tile-new')), findsNothing);
  });
  testWidgets('UTC 时间按本地日期和分钟归组，标题也显示本地时间', (tester) async {
    await pumpGen(
      tester,
      data: data([
        batch('utc', DateTime(2026, 10, 12, 10, 46, 59).toUtc()),
        batch('local', DateTime(2026, 10, 12, 10, 46)),
      ]),
    );
    expect(find.text('10:46'), findsOneWidget);
  });
}
