import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// The drag/drop plugin exposes its test transport through this dependency.
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/web_left_panel.dart';
import '../../../../helpers/light_theme_contrast.dart';
import '../../../../helpers/official_ui_capture_fonts.dart';

class _Storage extends InMemoryLocalStorageService {
  @override
  bool getEnableAutocomplete() => false;
  @override
  bool getEnableCooccurrenceRecommendation() => false;
  @override
  String getLastPrompt() => 'city lights, scenery, no humans, very aesthetic';
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig().addCharacter(
    gender: CharacterGender.female,
    name: 'Character 1',
    prompt: 'blue eyes, white hair',
  );
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dragContext = MockMessageChannelContext()
    ..registerMockMethodCallHandler('DropManager', (_) async => null)
    ..registerMockMethodCallHandler('DragManager', (_) async => null);
  setContextOverride(dragContext);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  setUpAll(loadOfficialUiCaptureFonts);
  setUp(() async {
    await setUpTemporaryHive();
    await Hive.openBox(StorageKeys.settingsBox);
  });
  testWidgets(
    'official sidebar renders grouped typography and compact character actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(460, 1250));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final mode = ValueNotifier(false);
      addTearDown(mode.dispose);
      final container = createStorageFreeContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Storage()),
          imageGenerationNotifierProvider.overrideWith(_Generation.new),
          characterPromptNotifierProvider.overrideWith(_Characters.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
          subscriptionNotifierProvider.overrideWith(_Subscription.new),
          tipEpochProvider.overrideWith((ref) => Stream.value(0)),
          for (final target in PromptTokenCountTarget.values)
            promptTokenUsageProvider(target).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 12, limit: 512),
            ),
        ],
      );
      addTearDown(container.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              fontFamily: 'OfficialUiCapture',
            ),
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RepaintBoundary(
                key: boundary,
                child: WebLeftPanel(negativeModeNotifier: mode),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'city lights, scenery, no humans, very aesthetic',
      );
      final label = tester.widget<Text>(find.text('参考图'));
      final title = tester.widget<Text>(find.text('图像尺寸'));
      expect(label.style!.fontSize, lessThan(title.style!.fontSize!));
      expect(find.byIcon(Icons.more_horiz), findsWidgets);
      if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('.dart_tool/official-ui-captures/sidebar.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
