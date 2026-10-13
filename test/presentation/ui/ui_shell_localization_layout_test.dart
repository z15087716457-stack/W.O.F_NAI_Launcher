import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_fixture.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/uiux_frontend_capture.dart';
import 'gen/gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final pages = <String, Widget Function()>{
    'nav': () => NavShell(
      data: NavFixture.view(pinned: true),
      actions: NavActions.none,
      child: const SizedBox.expand(),
    ),
    'statistics': () =>
        StatisticsPage(data: StatsFixture.view(), actions: StatsActions.none),
    'online': () => OnlineGalleryPage(
      data: OnlineFixture.view(),
      actions: OnlineActions.none,
    ),
    'blocks': () => BlocksLibraryPage(
      data: BlocksFixture.library(),
      actions: BlocksLibraryActions.none,
    ),
    'explore': () => StyleExplorePage(
      data: ExploreFixture.view(),
      actions: ExploreActions.none,
      editor: exploreFixtureEditor,
    ),
    'vibe': () =>
        RefsLibraryPage(data: RefsFixture.vibe(), actions: RefsActions.none),
    'precise': () => RefsLibraryPage(
      data: RefsFixture.preciseView(),
      actions: RefsActions.none,
    ),
    'viewer': () => ImageViewerPage(
      data: ViewerFixture.gallery(),
      actions: ViewerActions.none,
    ),
    'viewer-generation': () => ImageViewerPage(
      data: ViewerFixture.generation(),
      actions: ViewerActions.none,
    ),
    'director': () => ToolsDirectorPage(
      data: ToolsFixture.director(),
      actions: ToolsDirectorActions.logging((_) {}),
    ),
    for (final tool in ToolsDirectorTool.values)
      if (tool != ToolsDirectorTool.sketch)
        'director-${tool.name}': () => ToolsDirectorPage(
          data: tool == ToolsDirectorTool.emotion
              ? ToolsFixture.emotion()
              : ToolsFixture.director(tool: tool),
          actions: ToolsDirectorActions.logging((_) {}),
        ),
  };
  for (final page in pages.entries) {
    for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      for (final dark in [false, true]) {
        for (final width in [900.0, 1600.0]) {
          testWidgets('shell ${page.key} $locale dark=$dark width=$width', (
            t,
          ) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width - 48, 1200);
            addTearDown(t.view.reset);
            await t.pumpWidget(
              genApp(page.value(), locale: locale, dark: dark),
            );
            await t.pumpAndSettle();
            final context = t.element(find.byType(Scaffold));
            expect(
              AppLocalizations.of(context)!.localeName,
              locale == 'zh_TW' ? 'zh_TW' : locale,
            );
            expect(t.takeException(), isNull, reason: uiuxOverflowDetails(t));
            if (page.key == 'director' &&
                locale == 'ja' &&
                !dark &&
                width == 900) {
              await captureUiuxRegion(
                t,
                find.byKey(const Key('gen-capture')),
                'director-ja-900',
                t.getRect(find.byKey(const Key('tools-director-actions'))),
              );
            }
            await t.pumpWidget(const SizedBox());
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  }
}
