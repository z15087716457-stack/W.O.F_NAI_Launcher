import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_approval_card.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  const owner = NaiAgentConversationOwner('workspace', 'chat');
  final pixels = Uint8List.fromList(
    img.encodePng(
      img.Image(width: 64, height: 48)..clear(img.ColorRgb8(56, 141, 185)),
    ),
  );
  final quote = {
    'tool': 'cloud_upscale',
    'width': 832,
    'height': 1216,
    'account_name': 'Local test account',
    'estimated_anlas': 1,
    'balance_anlas': 2218,
  };
  late ProviderContainer container;
  late NaiAgentImageApprovals broker;
  setUp(() {
    container = ProviderContainer();
    broker = container.read(naiAgentImageApprovalsProvider);
  });
  tearDown(() => container.dispose());
  Future<void> pump(
    WidgetTester tester,
    AgentImageApproval request, {
    String locale = 'zh',
    Brightness brightness = Brightness.light,
    double width = 440,
    GlobalKey? key,
  }) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.getTheme(AppStyle.geist, brightness),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: RepaintBoundary(
                  key: key,
                  child: NaiAgentImageApprovalCard(request: request),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'image confirmation requires a real button; changed checks disable confirm but retain cancel',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var valid = true;
      final future = broker.request(
        owner,
        quote,
        DateTime.now().add(const Duration(minutes: 5)),
        NaiAgentCancellation(),
        () {
          if (!valid) throw const NaiAgentToolError('quote_changed', 'changed');
        },
        sourceBytes: pixels,
      );
      final request = broker.forChat('chat').single;
      await pump(tester, request);
      expect(find.byType(Image), findsOneWidget);
      expect(broker.forChat('chat'), hasLength(1));
      valid = false;
      await pump(tester, request);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('agent-image-confirm')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('agent-image-decline')));
      await tester.pump();
      expect(await future, false);
      final next = broker.request(
        owner,
        quote,
        DateTime.now().add(const Duration(minutes: 5)),
        NaiAgentCancellation(),
        () {},
      );
      await pump(tester, broker.forChat('chat').single);
      await tester.tap(find.byKey(const Key('agent-image-confirm')));
      await tester.pump();
      expect(await next, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('image authorization expires and Stop completes its wait', () async {
    final expired = broker.request(
      owner,
      quote,
      DateTime.now().subtract(const Duration(seconds: 1)),
      NaiAgentCancellation(),
      () {},
    );
    await expectLater(
      expired,
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'quote_expired'),
      ),
    );
    final token = NaiAgentCancellation(),
        pending = broker.request(
          owner,
          quote,
          DateTime.now().add(const Duration(minutes: 5)),
          token,
          () {},
        );
    token.cancel();
    await expectLater(
      pending,
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    expect(broker.forChat('chat'), isEmpty);
  });
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in Brightness.values) {
      {
        testWidgets(
          'real-font $locale ${brightness.name} image approval fits narrow chat',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final pending = broker.request(
                  owner,
                  quote,
                  DateTime.now().add(const Duration(minutes: 5)),
                  NaiAgentCancellation(),
                  () {},
                  sourceBytes: pixels,
                ),
                request = broker.forChat('chat').single;
            final key = GlobalKey();
            for (final width in [320.0, 440.0]) {
              await pump(
                tester,
                request,
                locale: locale,
                brightness: brightness,
                width: width,
                key: key,
              );
              expect(tester.takeException(), isNull);
              expect(
                tester.getRect(find.byType(NaiAgentImageApprovalCard)).right,
                lessThanOrEqualTo(width),
              );
              if (Platform.environment['CAPTURE_NAI_AGENT'] == '1' &&
                  locale == 'zh') {
                await tester.runAsync(() async {
                  final image =
                          await (key.currentContext!.findRenderObject()
                                  as RenderRepaintBoundary)
                              .toImage(),
                      bytes = await image.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                  final directory = Directory(
                    '.dart_tool/nai-agent-stage-e5b/native-captures',
                  )..createSync(recursive: true);
                  File(
                    '${directory.path}/image-approval-${brightness.name}-${width.toInt()}.png',
                  ).writeAsBytesSync(bytes!.buffer.asUint8List());
                  image.dispose();
                });
              }
            }
            broker.decide(request.id, run: false);
            await pending;
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
