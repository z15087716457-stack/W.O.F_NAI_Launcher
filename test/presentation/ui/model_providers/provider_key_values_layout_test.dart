import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  testWidgets(
    'name and value have separate rows; values grow, scroll and shrink without losing text',
    (t) async {
      await t.runAsync(loadStudioCaptureFonts);
      for (final json in [true, false]) {
        var items = const [ProviderKeyValue('name', 'x')];
        await t.pumpWidget(
          MaterialApp(
            theme: GeistTheme.dark,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: StatefulBuilder(
                    builder: (context, setState) => ProviderKeyValues(
                      items: items,
                      json: json,
                      tag: json ? '请求体' : '请求头',
                      onChanged: (value) => setState(() => items = value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pump();
        final name = find.byKey(const Key('kv-0-key'));
        final value = find.byKey(const Key('kv-0-value'));
        final field = find.descendant(
          of: value,
          matching: find.byType(TextField),
        );
        final editable = find.descendant(
          of: value,
          matching: find.byType(EditableText),
        );
        expect(t.getRect(name).bottom, lessThan(t.getRect(value).top));
        expect(t.getRect(value).width, greaterThan(t.getRect(name).width));
        final initial = t.getRect(value);
        final render = t.state<EditableTextState>(editable).renderEditable;
        final caret = render.getLocalRectForCaret(
          const TextPosition(offset: 0),
        );
        final globalCaret = caret.shift(render.localToGlobal(Offset.zero));
        expect(globalCaret.top - initial.top, greaterThanOrEqualTo(5));
        expect(initial.bottom - globalCaret.bottom, greaterThanOrEqualTo(5));
        expect(globalCaret.center.dy, closeTo(initial.center.dy, 2));
        await t.enterText(field, 'a\nb\nc');
        await t.pump();
        expect(t.getRect(value).height, greaterThan(initial.height));
        final six = List.generate(6, (i) => 'line $i').join('\n');
        await t.enterText(field, six);
        await t.pump();
        final cap = t.getRect(value).height;
        final fifteen = List.generate(15, (i) => 'line $i').join('\n');
        await t.enterText(field, fifteen);
        await t.pumpAndSettle();
        expect(t.getRect(value).height, closeTo(cap, .1));
        expect(
          t.state<EditableTextState>(editable).renderEditable.offset.pixels,
          greaterThan(0),
        );
        expect(items.single.value, fifteen);
        final longValue = 'long-token-' * 120;
        await t.enterText(field, longValue);
        await t.pumpAndSettle();
        expect(t.getRect(value).height, closeTo(cap, .1));
        expect(items.single.value, longValue);
        await t.enterText(field, 'z');
        await t.pumpAndSettle();
        expect(t.getRect(value).height, closeTo(initial.height, .1));
        expect(items.single.key, 'name');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'key/value rows fit real fonts, both themes, locales and text scaling',
    (t) async {
      await t.runAsync(loadStudioCaptureFonts);
      for (final dark in [false, true]) {
        for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
          for (final scale in [1.0, 1.5, 2.0]) {
            await t.pumpWidget(
              MaterialApp(
                theme: dark ? GeistTheme.dark : GeistTheme.light,
                locale: locale == 'zh_TW'
                    ? const Locale('zh', 'TW')
                    : Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 280,
                          child: ProviderKeyValues(
                            json: true,
                            items: const [ProviderKeyValue('', '')],
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pump();
            final value = find.byKey(const Key('kv-0-value'));
            final editable = find.descendant(
              of: value,
              matching: find.byType(EditableText),
            );
            final outer = t.getRect(value);
            final render = t.state<EditableTextState>(editable).renderEditable;
            final caret = render
                .getLocalRectForCaret(const TextPosition(offset: 0))
                .shift(render.localToGlobal(Offset.zero));
            expect(caret.top, greaterThanOrEqualTo(outer.top + 4));
            expect(caret.bottom, lessThanOrEqualTo(outer.bottom - 4));
            expect(
              t.takeException(),
              isNull,
              reason: '$locale dark=$dark scale=$scale',
            );
          }
        }
      }
    },
  );
}
