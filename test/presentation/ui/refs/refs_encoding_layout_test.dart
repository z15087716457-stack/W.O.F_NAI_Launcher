import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_parts.dart';
import 'package:nai_launcher/presentation/wiring/refs_mapping.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'refs_test_harness.dart';

Finder inside(Finder root, String key) =>
    find.descendant(of: root, matching: find.byKey(Key(key)));

void checkAction(WidgetTester tester, Finder root, String variant) {
  final button = inside(root, 'refs-encode-now');
  final label = inside(root, 'refs-encode-label');
  final price = inside(root, 'refs-encode-cost');
  final context = tester.element(button);
  final l10n = AppLocalizations.of(context)!;
  expect(button, findsOneWidget);
  expect(tester.widget<Text>(label).data, contains('V4.5 $variant'));
  expect(tester.widget<Text>(label).data, isNot(contains('NAI Diffusion')));
  expect(
    find.descendant(of: price, matching: find.text(l10n.refs_encodingPrice(2))),
    findsOneWidget,
  );
  expect(
    tester.widget<Text>(inside(root, 'refs-encoding-description')).data,
    isNot(contains('Anlas')),
  );
  final bounds = tester.getRect(button);
  final feeBounds = tester.getRect(price);
  expect(feeBounds.left, greaterThanOrEqualTo(bounds.left));
  expect(feeBounds.right, lessThanOrEqualTo(bounds.right));
  expect(tester.getRect(label).right, lessThanOrEqualTo(feeBounds.left));
  expect(tester.getSize(button).height, 26);
  expect(tester.getSize(price).height, 18);
  expect(tester.renderObject<RenderParagraph>(label).text.style!.fontSize, 12);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final variant in ['Full', 'Curated']) {
        testWidgets('真实 V4.5 $variant 侧栏编码按钮 $locale dark=$dark', (
          tester,
        ) async {
          final model = refsModel(
            variant == 'Full'
                ? ImageModels.animeDiffusionV45Full
                : ImageModels.animeDiffusionV45Curated,
          );
          await pumpRefs(
            tester,
            data: RefsFixture.vibe(model: model, selectedKey: 'c01'),
            locale: locale,
            dark: dark,
          );
          checkAction(tester, find.byKey(const Key('refs-inspector')), variant);
        });
      }
      testWidgets('真实 Curated 详情弹窗编码按钮 $locale dark=$dark', (tester) async {
        await pumpRefs(
          tester,
          data: RefsFixture.vibe(
            model: refsModel(ImageModels.animeDiffusionV45Curated),
            selectedKey: 'c01',
          ),
          locale: locale,
          dark: dark,
        );
        await tapKey(tester, 'refs-insp-preview');
        checkAction(tester, find.byKey(const Key('refs-detail')), 'Curated');
      });
    }
    testWidgets('重新编码说明不重复费用 $locale', (tester) async {
      await pumpRefs(
        tester,
        data: RefsFixture.vibe(
          model: refsModel(ImageModels.animeDiffusionV45Full),
          selectedKey: 'c11',
        ),
        locale: locale,
      );
      final inspector = find.byKey(const Key('refs-inspector'));
      checkAction(tester, inspector, 'Full');
      final l10n = AppLocalizations.of(tester.element(inspector))!;
      expect(
        tester
            .widget<Text>(inside(inspector, 'refs-encoding-description'))
            .data,
        l10n.refs_encReBody('V4', 'NAI Diffusion V4.5 (Full)'),
      );
    });
  }

  testWidgets('窄空间只收缩文案，费用保持完整且跟随传入报价', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 220);
    addTearDown(tester.view.reset);
    var calls = 0;
    final model = refsModel(ImageModels.animeDiffusionV45Curated);
    const costs = RefsCosts(encode: 12);
    await tester.pumpWidget(
      refsApp(
        SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: RefsEncodingBox(
                entry: const RefsEntry(
                  key: 'isolated',
                  name: 'isolated',
                  hasRaw: true,
                  encoding: RefsEncoding.encodeOnUse,
                ),
                model: model,
                costs: costs,
                onEncodeNow: () => calls++,
              ),
            ),
          ),
        ),
        locale: 'en',
      ),
    );
    await tester.pumpAndSettle();
    final label = find.byKey(const Key('refs-encode-label'));
    final price = find.byKey(const Key('refs-encode-cost'));
    final button = find.byKey(const Key('refs-encode-now'));
    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isTrue,
    );
    expect(find.text('12 Anlas'), findsOneWidget);
    expect(
      tester.getRect(price).right,
      lessThanOrEqualTo(tester.getRect(button).right),
    );
    expect(
      tester.getRect(label).right,
      lessThanOrEqualTo(tester.getRect(price).left),
    );
    await hoverOver(tester, button);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text('Encode for NAI Diffusion V4.5 (Curated) now · 12 Anlas'),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('编码按钮仍调用当前库条目动作', (tester) async {
    final recorder = RecordingRefsActions();
    await pumpRefs(
      tester,
      data: RefsFixture.vibe(
        model: refsModel(ImageModels.animeDiffusionV45Full),
        selectedKey: 'c01',
      ),
      actions: recorder.actions,
    );
    await tapKey(tester, 'refs-encode-now');
    expect(recorder.calls, contains('encode:c01'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('自定义模型名称保留，完整型号仍可悬停查看', (tester) async {
    const name = 'Custom Full (preview)';
    await tester.pumpWidget(
      refsApp(
        const Center(
          child: SizedBox(
            width: 300,
            child: RefsEncodingBox(
              entry: RefsEntry(
                key: 'isolated',
                name: 'isolated',
                hasRaw: true,
                encoding: RefsEncoding.encodeOnUse,
              ),
              model: RefsModel(
                name: name,
                shortName: 'Custom',
                vibeUsable: true,
                preciseUsable: false,
              ),
              costs: RefsCosts(),
              onEncodeNow: _ignoreEncode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('refs-encode-label'))).data,
      contains(name),
    );
    expect(tester.takeException(), isNull);
  });
}

void _ignoreEncode() {}
