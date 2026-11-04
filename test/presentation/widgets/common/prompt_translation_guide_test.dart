import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/prompt_translation_guide.dart';

Future<void> _pumpGuide(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: PromptTranslationGuide(onBack: () {})),
  ),
);

void main() {
  testWidgets(
    '切换原文 / 译文：Windows 写中键，macOS 写 ⌘ + 点击',
    (tester) async {
      await _pumpGuide(tester);
      final mac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(find.text('⌘ + 点击块'), mac ? findsOneWidget : findsNothing);
      expect(find.text('中键点块'), mac ? findsNothing : findsOneWidget);
      expect(find.text('切换原文与译文'), findsOneWidget);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
