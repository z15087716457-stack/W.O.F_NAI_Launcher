import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_prompt.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

class _Controller extends Fake implements GenController {}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final width in [960.0, 560.0]) {
    for (final character in [false, true]) {
      for (final negative in [false, true]) {
        testWidgets(
          'header flush right $width character=$character negative=$negative',
          (t) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width + 96, 800);
            addTearDown(t.view.resetDevicePixelRatio);
            addTearDown(t.view.resetPhysicalSize);
            final data = GenFixture.view(v45: true).copyWith(
              characters: GenCharactersData(
                list: [GenCharacter(id: 'long', name: '很长的角色名称需要省略显示' * 10)],
              ),
            );
            await t.pumpWidget(
              genApp(
                Center(
                  child: GenScope(
                    data: data,
                    actions: GenActions.logging((_) {}),
                    slots: GenSlots(editor: (_, _) => const SizedBox()),
                    controller: _Controller(),
                    child: GenFullscreenEditor(
                      target: character
                          ? GenEditorTarget.character(
                              0,
                              negative: negative,
                              fullscreen: true,
                            )
                          : GenEditorTarget.base(
                              negative: negative,
                              fullscreen: true,
                            ),
                    ),
                  ),
                ),
              ),
            );
            final dialog = t.getRect(
              find.byKey(const Key('gen-fullscreen-editor')),
            );
            final close = t.getRect(
              find.byKey(const Key('gen-fullscreen-close')),
            );
            expect(dialog.width, width);
            expect(dialog.right - close.right, inInclusiveRange(11, 16));
            expect(
              find.byKey(const Key('gen-fullscreen-tabs')),
              character ? findsNothing : findsOneWidget,
            );
            expect(t.takeException(), isNull);
            if (character) {
              final title = t.widget<Text>(
                find.text(data.characters!.list.first.name!),
              );
              expect(title.overflow, TextOverflow.ellipsis);
            }
          },
        );
      }
    }
  }
}
