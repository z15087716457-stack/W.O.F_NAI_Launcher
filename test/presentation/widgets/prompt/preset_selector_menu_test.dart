import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/quality_tags_selector.dart';
import 'package:nai_launcher/presentation/widgets/prompt/uc_preset_selector.dart';

class _QualityState extends QualityPresetNotifier {
  @override
  QualityPresetState build() => const QualityPresetState();
}

class _UcState extends UcPresetNotifier {
  @override
  UcPresetState build() => const UcPresetState();
}

Widget _host(Widget selector) => ProviderScope(
  overrides: [
    qualityPresetNotifierProvider.overrideWith(_QualityState.new),
    ucPresetNotifierProvider.overrideWith(_UcState.new),
    qualityCustomEntriesProvider.overrideWith((ref) => const []),
  ],
  child: MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: selector)),
  ),
);

Future<List<String?>> _openMenu(WidgetTester tester, Widget selector) async {
  await tester.pumpWidget(_host(selector));
  await tester.tap(find.byType(selector.runtimeType));
  await tester.pumpAndSettle();
  return tester
      .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
      .map((item) => item.value)
      .toList();
}

void main() {
  testWidgets('quality menu has only official presets, without library', (
    tester,
  ) async {
    expect(
      await _openMenu(
        tester,
        const QualityTagsSelector(model: ImageModels.animeDiffusionV5Full),
      ),
      ['standard', 'light', 'none'],
    );
    expect(find.text('从词库添加'), findsNothing);
  });

  testWidgets('UC menu follows the selected model and omits library', (
    tester,
  ) async {
    expect(
      await _openMenu(
        tester,
        const UcPresetSelector(model: ImageModels.animeDiffusionV4Full),
      ),
      ['preset_0', 'preset_1', 'preset_4'],
    );
    expect(find.text('从词库添加'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      await _openMenu(
        tester,
        const UcPresetSelector(model: ImageModels.furryDiffusion),
      ),
      ['preset_6', 'preset_5', 'preset_4'],
    );
    expect(find.text('低质量'), findsOneWidget);
    expect(find.text('解剖错误'), findsOneWidget);
  });
}
