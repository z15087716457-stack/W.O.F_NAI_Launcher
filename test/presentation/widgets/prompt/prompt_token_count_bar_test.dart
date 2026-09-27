import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_token_count_bar.dart';

Widget _host(Widget bar) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: bar)),
  ),
);

void main() {
  testWidgets(
    'token numbers appear on hover instead of beside the full-width line',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const PromptTokenCountBar(
            usage: PromptTokenUsage(usedTokens: 128, limit: 512),
          ),
        ),
      );
      expect(find.textContaining('128'), findsNothing);
      final line = find.byType(LinearProgressIndicator);
      expect(tester.getSize(line).width, 320);
      expect(tester.getSize(line).height, 3);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(line));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Token 用量：128 / 512'), findsOneWidget);
      await mouse.removePointer();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('over-limit line is red and remains bounded', (tester) async {
    await tester.pumpWidget(
      _host(
        const PromptTokenCountBar(
          usage: PromptTokenUsage(usedTokens: 520, limit: 512),
        ),
      ),
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 1);
    expect(
      progress.valueColor!.value,
      Theme.of(
        tester.element(find.byType(PromptTokenCountBar)),
      ).colorScheme.error,
    );
    expect(find.textContaining('520'), findsNothing);
  });

  testWidgets('block reference line becomes striped at and above the guide', (
    tester,
  ) async {
    for (final used in [512, 600]) {
      await tester.pumpWidget(
        _host(
          PromptTokenCountBar(
            usage: PromptTokenUsage(usedTokens: used, limit: 512),
            referenceLimit: true,
          ),
        ),
      );
      final stripes = find.byKey(const Key('prompt-token-reference-stripes'));
      expect(stripes, findsOneWidget);
      expect(tester.getSize(stripes), const Size(320, 5));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        contains('单块进度仅供参考'),
      );
    }
  });

  testWidgets('block reference line stays neutral below the guide', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PromptTokenCountBar(
          usage: PromptTokenUsage(usedTokens: 511, limit: 512),
          referenceLimit: true,
        ),
      ),
    );
    expect(
      find.byKey(const Key('prompt-token-reference-stripes')),
      findsNothing,
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 511 / 512);
    expect(
      progress.valueColor!.value,
      Theme.of(
        tester.element(find.byType(PromptTokenCountBar)),
      ).colorScheme.onSurface,
    );
  });

  testWidgets('hover includes accurate total and composition breakdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PromptTokenCountBar(
          usage: PromptTokenUsage(
            usedTokens: 129,
            limit: 512,
            breakdown: [
              PromptTokenBreakdownEntry(label: '提示词', tokens: 100),
              PromptTokenBreakdownEntry(label: '固定词', tokens: 20),
              PromptTokenBreakdownEntry(label: '网页端校准', tokens: 1),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      'Token 用量：129 / 512\n提示词 108\n固定词 20\n网页端校准 1',
    );
  });

  testWidgets('character contribution shows shared model budget on hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const PromptTokenCountBar(
          usage: PromptTokenUsage(usedTokens: 31, limit: 1471),
          totalTokens: 44,
        ),
      ),
    );
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      '此提示词：31 Token；总用量：44 / 1471',
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      31 / 1471,
    );
  });

  testWidgets('keeps previous token usage while reloading', (tester) async {
    final usage = const AsyncLoading<PromptTokenUsage?>().copyWithPrevious(
      const AsyncData<PromptTokenUsage?>(
        PromptTokenUsage(usedTokens: 128, limit: 512),
      ),
      isRefresh: false,
    );
    await tester.pumpWidget(_host(PromptTokenCountAsyncBar(usage: usage)));
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      'Token 用量：128 / 512',
    );
    expect(find.textContaining('128'), findsNothing);
  });
}
