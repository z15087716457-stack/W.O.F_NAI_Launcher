import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_controls.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

const _paused = SettingsRagSource(
  kind: SettingsRagSourceKind.tags,
  state: SettingsRagState.paused,
  done: 10,
  total: 100,
);
const _wiki = SettingsRagSource(
  kind: SettingsRagSourceKind.wiki,
  state: SettingsRagState.empty,
);
const _ready = SettingsRagSource(
  kind: SettingsRagSourceKind.blocks,
  state: SettingsRagState.ready,
  done: 10,
  total: 10,
);
const _plan = SettingsRagPlan(kind: SettingsRagSourceKind.wiki, total: 100);

SettingsRagData _rag(String busy, {bool runtimeReady = true}) =>
    SettingsRagData(
      runtimeReady: runtimeReady,
      plan: _plan,
      install: busy == 'install'
          ? const SettingsRagInstall(phase: SettingsRagInstallPhase.packages)
          : null,
      download: busy == 'download'
          ? const SettingsRagDownload(model: SettingsRagModel.embedder)
          : null,
      sources: [
        _paused,
        _wiki,
        _ready,
        if (busy == 'build')
          const SettingsRagSource(
            kind: SettingsRagSourceKind.gallery,
            state: SettingsRagState.building,
            done: 1,
            total: 100,
          ),
      ],
    );

Future<void> _tap(WidgetTester t, String key) async {
  final finder = find.byKey(Key(key));
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final busy in ['download', 'install', 'build']) {
    testWidgets('RAG $busy blocks start/resume/clear and keeps stop controls', (
      t,
    ) async {
      final data = SettingsFixture.view(
        page: SettingsPageId.rag,
      ).copyWith(rag: _rag(busy));
      final rec = await pumpSettings(t, data: data);
      await _tap(t, 'rag-resume-tags');
      await _tap(t, 'rag-plan-start');
      await _tap(t, 'rag-more-blocks');
      expect(rec.calls, isEmpty);
      expect(
        t.widget<SettingsBtn>(find.byKey(const Key('rag-plan-start'))).onTap,
        isNull,
      );
      expect(
        t
            .widget<SettingsMoreButton>(
              find.byKey(const Key('rag-more-blocks')),
            )
            .enabled,
        isFalse,
      );
      await t.ensureVisible(find.byKey(const Key('rag-plan-wiki')));
      await t.pumpAndSettle();
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'rag-busy-$busy',
        t.getRect(find.byKey(const Key('rag-wiki'))),
      );
      await _tap(t, 'rag-plan-cancel');
      expect(rec.calls, ['ragCancelPlan']);
      if (busy == 'download') {
        await _tap(t, 'rag-download-cancel-embedder');
        expect(rec.calls.last, 'ragCancelDownload');
      } else if (busy == 'install') {
        await _tap(t, 'rag-install-cancel');
        expect(rec.calls.last, 'ragCancelInstall');
      } else {
        final pause = find.descendant(
          of: find.byKey(const Key('rag-gallery')),
          matching: find.widgetWithText(SettingsBtn, '暂停'),
        );
        await t.ensureVisible(pause);
        await t.tap(pause);
        await t.pumpAndSettle();
        expect(rec.calls.last, 'ragPause:gallery');
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'RAG idle permits resume and start; missing runtime blocks both',
    (t) async {
      final data = SettingsFixture.view(
        page: SettingsPageId.rag,
      ).copyWith(rag: _rag('idle', runtimeReady: false));
      final rec = await pumpSettings(t, data: data);
      await _tap(t, 'rag-resume-tags');
      await _tap(t, 'rag-plan-start');
      expect(rec.calls, isEmpty);
      t
          .state<SettingsHostState>(find.byType(SettingsHost))
          .updateData(data.copyWith(rag: _rag('idle')));
      await t.pumpAndSettle();
      await _tap(t, 'rag-resume-tags');
      await _tap(t, 'rag-plan-start');
      expect(rec.calls, ['ragResume:tags', 'ragStartPlan']);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('RAG menu closes if a background operation becomes busy', (
    t,
  ) async {
    final data = SettingsFixture.view(
      page: SettingsPageId.rag,
    ).copyWith(rag: _rag('idle'));
    final rec = await pumpSettings(t, data: data);
    await _tap(t, 'rag-more-blocks');
    expect(find.text('清除索引'), findsOneWidget);
    t
        .state<SettingsHostState>(find.byType(SettingsHost))
        .updateData(data.copyWith(rag: _rag('download')));
    await t.pumpAndSettle();
    expect(find.text('清除索引'), findsNothing);
    expect(rec.calls, isEmpty);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('RAG clear confirmation rechecks the latest busy state', (
    t,
  ) async {
    final data = SettingsFixture.view(
      page: SettingsPageId.rag,
    ).copyWith(rag: _rag('idle'));
    final rec = await pumpSettings(t, data: data);
    await _tap(t, 'rag-more-blocks');
    await t.tap(find.text('清除索引'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
    t
        .state<SettingsHostState>(find.byType(SettingsHost))
        .updateData(data.copyWith(rag: _rag('download')));
    await t.pumpAndSettle();
    await _tap(t, 'confirm-ok');
    expect(rec.calls, isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  for (final maximum in [32, 36]) {
    for (final search in [false, true]) {
      testWidgets(
        'offload max $maximum search=$search preserves value and allows the endpoint',
        (t) async {
          final original = maximum - 1.0;
          final data = SettingsFixture.view(page: SettingsPageId.upscale)
              .copyWith(
                values: SettingsFixture.values.copyWith(
                  SettingKey.seedCpuOffload,
                  original,
                ),
                upscale: SettingsUpscaleData(seedOffloadMaxBlocks: maximum),
              );
          final rec = await pumpSettings(
            t,
            data: data,
            initialQuery: search ? 'seedCpuOffload' : '',
          );
          final slider = find.byKey(const Key('slider-seedCpuOffload'));
          await t.ensureVisible(slider);
          await t.pumpAndSettle();
          final widget = t.widget<SettingsSlider>(slider);
          expect(widget.value, original);
          expect(widget.max, maximum);
          expect(rec.changes, isEmpty);
          await captureUiuxRegion(
            t,
            find.byKey(const Key('settings-capture')),
            'offload-$maximum-$search',
            t.getRect(slider).inflate(6),
          );
          final track = find.descendant(
            of: slider,
            matching: find.byType(GestureDetector),
          );
          final rect = t.getRect(track);
          await t.tapAt(Offset(rect.right - .1, rect.center.dy));
          await t.pumpAndSettle();
          expect(rec.changes.last, (
            SettingKey.seedCpuOffload,
            maximum.toDouble(),
          ));
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'offload range update preserves separate model values without writing',
    (t) async {
      final seven = SettingsFixture.view(page: SettingsPageId.upscale).copyWith(
        values: SettingsFixture.values.copyWith(
          SettingKey.seedCpuOffload,
          35.0,
        ),
        upscale: const SettingsUpscaleData(seedOffloadMaxBlocks: 36),
      );
      final rec = await pumpSettings(t, data: seven);
      final host = t.state<SettingsHostState>(find.byType(SettingsHost));
      final three = seven.copyWith(
        values: seven.values.copyWith(SettingKey.seedCpuOffload, 16.0),
        upscale: const SettingsUpscaleData(seedOffloadMaxBlocks: 32),
      );
      for (final data in [three, seven]) {
        host.updateData(data);
        await t.pumpAndSettle();
        final slider = t.widget<SettingsSlider>(
          find.byKey(const Key('slider-seedCpuOffload')),
        );
        expect(slider.value, data.values.number(SettingKey.seedCpuOffload));
        expect(slider.max, data.upscale.seedOffloadMaxBlocks);
      }
      expect(rec.changes, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  test('offload limits match existing model rules', () {
    expect(
      const SettingsUpscaleData().seedOffloadMaxBlocks,
      Seedvr2Options.maxBlocks('seedvr2-3b'),
    );
    for (final model in [
      'seedvr2-7b',
      'seedvr2-7b-sharp',
      'seedvr2-7b-int8',
      'seedvr2-7b-sharp-int8',
    ]) {
      expect(
        SettingSpec.of(SettingKey.seedCpuOffload).max,
        Seedvr2Options.maxBlocks(model),
      );
    }
  });
}
