import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';

import '../../../../helpers/novelai_billing.dart';
import '../../../../helpers/light_theme_contrast.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/presentation/screens/generation/handlers/vibe_import_handler.dart';

class _FilePicker extends FilePicker {
  _FilePicker(this.file);
  final PlatformFile file;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => FilePickerResult([file]);
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(model: ImageModels.animeDiffusionV45Full);
  @override
  Future<void> saveGenerationState() async {}
}

void main() {
  for (final picked in [true, false]) {
    testWidgets(
      'manual Vibe file import shows server reason before adding a raw image (picked: $picked)',
      (tester) async {
        final api = FakeNovelAi()..refuse = (_, _) => 403;
        final container = createStorageFreeContainer(
          overrides: [
            generationParamsNotifierProvider.overrideWith(_Params.new),
            naiImageEnhancementApiServiceProvider.overrideWithValue(
              NAIImageEnhancementApiService(
                Dio()..httpClientAdapter = api,
                ledger: unrecordedLedger(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final bytes = Uint8List.fromList([1, 2]);
        const fileName = 'source.jpg';
        if (picked) {
          FilePicker? previous;
          try {
            previous = FilePicker.platform;
          } catch (_) {
            /* no desktop plugin */
          }
          FilePicker.platform = _FilePicker(
            PlatformFile(name: fileName, size: bytes.length, bytes: bytes),
          );
          addTearDown(() {
            if (previous != null) FilePicker.platform = previous;
          });
        }
        late VibeImportHandler handler;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    handler = VibeImportHandler(ref: ref, context: context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );
        final running = picked
            ? handler.importFromFiles()
            : handler.importDroppedFile(fileName: fileName, bytes: bytes);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        final reason = find.textContaining('synthetic refusal');
        expect(reason, findsOneWidget);
        expect(
          tester.widget<Text>(reason).data,
          allOf(contains('403'), isNot(contains('Exception:'))),
        );
        expect(
          container.read(generationParamsNotifierProvider).vibeReferencesV4,
          isEmpty,
        );
        expect(api.paths, ['/ai/encode-vibe']);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        await running;
        expect(
          container.read(generationParamsNotifierProvider).vibeReferencesV4,
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  test('单个来自库的 Vibe 会匹配到可覆盖的原始条目', () {
    final imageBytes = Uint8List.fromList(const [1, 2, 3, 4]);
    final entry = VibeLibraryEntry(
      id: 'library-entry',
      name: 'Library Vibe',
      vibeDisplayName: 'Library Vibe',
      vibeEncoding: 'encoded-before',
      thumbnail: imageBytes,
      rawImageData: imageBytes,
      strength: 0.6,
      infoExtracted: 0.2,
      sourceTypeIndex: VibeSourceType.naiv4vibe.index,
      createdAt: DateTime(2026, 4, 15),
    );

    final candidate = findOriginalLibraryEntryForOverwrite(
      [entry.toVibeReference()],
      [entry],
    );

    expect(candidate?.id, 'library-entry');
  });

  test('多个 Vibe 保存到库时不会显示覆盖原条目的入口', () {
    final entries = [
      VibeLibraryEntry(
        id: 'library-entry',
        name: 'Library Vibe',
        vibeDisplayName: 'Library Vibe',
        vibeEncoding: 'encoded-before',
        thumbnail: Uint8List.fromList(const [1, 2, 3, 4]),
        rawImageData: Uint8List.fromList(const [1, 2, 3, 4]),
        strength: 0.6,
        infoExtracted: 0.2,
        sourceTypeIndex: VibeSourceType.naiv4vibe.index,
        createdAt: DateTime(2026, 4, 15),
      ),
    ];

    final candidate = findOriginalLibraryEntryForOverwrite([
      entries.first.toVibeReference(),
      entries.first.toVibeReference().copyWith(displayName: 'Other'),
    ], entries);

    expect(candidate, isNull);
  });

  test('只要存在无法重编码的 Vibe，保存到库时就不显示信息提取调节项', () {
    final imageBytes = Uint8List.fromList(const [1, 2, 3, 4]);
    final withRaw = VibeReference(
      displayName: 'With Raw',
      vibeEncoding: 'encoded-before',
      rawImageData: imageBytes,
      thumbnail: imageBytes,
      strength: 0.6,
      infoExtracted: 0.2,
      sourceType: VibeSourceType.naiv4vibe,
    );
    final encodedOnly = VibeReference(
      displayName: 'Encoded Only',
      vibeEncoding: 'encoded-before',
      thumbnail: imageBytes,
      strength: 0.6,
      infoExtracted: 0.2,
      sourceType: VibeSourceType.naiv4vibe,
    );

    expect(shouldShowInfoExtractedForLibrarySave([withRaw]), isTrue);
    expect(
      shouldShowInfoExtractedForLibrarySave([withRaw, encodedOnly]),
      isFalse,
    );
    expect(shouldShowInfoExtractedForLibrarySave([encodedOnly]), isFalse);
  });

  test('外部图片立即编码后仍保留原图以支持后续信息提取调节', () {
    final imageBytes = Uint8List.fromList(const [9, 8, 7, 6]);
    final rawVibe = VibeReference(
      displayName: 'raw-image.png',
      vibeEncoding: '',
      thumbnail: imageBytes,
      rawImageData: imageBytes,
      strength: 0.42,
      infoExtracted: 0.33,
      sourceType: VibeSourceType.rawImage,
    );

    final encoded = buildEncodedImportVibe(
      rawVibe,
      'encoded-after',
      model: ImageModels.animeDiffusionV45Full,
    );

    expect(encoded.vibeEncoding, 'encoded-after');
    expect(encoded.sourceType, VibeSourceType.naiv4vibe);
    expect(encoded.rawImageData, imageBytes);
    expect(encoded.canReencodeFromRawSource, isTrue);
    expect(encoded.infoExtracted, 0.33);
    expect(encoded.encodingModel, ImageModels.animeDiffusionV45Full);
    expect(shouldShowInfoExtractedForLibrarySave([encoded]), isTrue);
  });
}
