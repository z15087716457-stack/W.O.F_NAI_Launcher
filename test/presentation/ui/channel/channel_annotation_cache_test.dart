import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_format.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';

import '../gen/gen_test_harness.dart';

void main() {
  test('same-day checks use calendar dates across time representations', () {
    expect(
      ChannelFormat.sameDay(
        DateTime(2026, 10, 16),
        DateTime.utc(2026, 10, 16, 23, 59),
      ),
      isTrue,
    );
    expect(
      ChannelFormat.sameDay(
        DateTime(2026, 10, 16, 23, 59),
        DateTime(2026, 10, 17),
      ),
      isFalse,
    );
    expect(
      ChannelFormat.sameDay(DateTime(2025, 12, 31), DateTime(2026, 1, 1)),
      isFalse,
    );
    expect(
      ChannelFormat.sameDay(
        DateTime.utc(2024, 2, 29),
        DateTime(2024, 2, 29, 12),
      ),
      isTrue,
    );
  });

  testWidgets(
    'camera frames reuse annotations; date, locale, ruler and batches invalidate them',
    (tester) async {
      var batches = [
        ChannelBatch(
          id: 'a',
          rect: const Rect.fromLTWH(-416, 0, 832, 1216),
          time: DateTime(2026, 10, 16, 12),
          count: 2,
        ),
      ];
      var now = DateTime(2026, 10, 16, 23, 59);
      const base = ChannelSettings(seed: 7, motion: false);
      Future<ChannelBackdropPainter> pump({
        String locale = 'zh',
        bool ruler = true,
        double y = 0,
      }) async {
        await tester.pumpWidget(
          genApp(
            ChannelBackdrop(
              data: ChannelViewData(
                settings: base.copyWith(ruler: ruler),
                camera: ChannelCamera(offset: Offset(400, y), scale: .5),
                batches: batches,
                now: now,
              ),
            ),
            locale: locale,
          ),
        );
        return tester
                .widget<CustomPaint>(find.byKey(const Key('channel-backdrop')))
                .painter!
            as ChannelBackdropPainter;
      }

      final first = await pump();
      final moved = await pump(y: 50);
      expect(moved.labels, same(first.labels));
      expect(moved.days, same(first.days));
      expect(moved.names, same(first.names));
      expect(moved.labels.single, '12:00 · 2 张 · 最新');
      expect(moved.days.single, startsWith('今天'));
      now = DateTime(2026, 10, 17);
      final midnight = await pump(y: 50);
      expect(midnight.days.single, startsWith('昨天'));
      final english = await pump(locale: 'en');
      expect(english.days, isNot(midnight.days));
      expect(english.names, isNot(midnight.names));
      expect((await pump(ruler: false)).labels, isEmpty);
      final enabled = await pump();
      expect(enabled.labels.single, contains('2 张'));
      batches = [
        ChannelBatch(
          id: 'a',
          rect: batches.single.rect,
          time: now,
          count: 4,
          pending: true,
        ),
      ];
      final pending = await pump();
      expect(pending.labels.single, '生成中 · 4 张');
      expect(pending.days.single, startsWith('今天'));
    },
  );
}
