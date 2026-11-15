import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_mode_provider.dart';

class _Settings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

void main() {
  test(
    'mode choice persists, while an unset choice retains legacy document detection',
    () async {
      final settings = _Settings();
      ProviderContainer create() => ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(settings)],
      );
      var container = create();
      expect(container.read(promptTranslationModeProvider), isNull);
      await container
          .read(promptTranslationModeProvider.notifier)
          .select(PromptTranslationMode.inline);
      expect(
        container.read(promptTranslationModeProvider),
        PromptTranslationMode.inline,
      );
      container.dispose();
      container = create();
      expect(
        container.read(promptTranslationModeProvider),
        PromptTranslationMode.inline,
      );
      await container
          .read(promptTranslationModeProvider.notifier)
          .select(PromptTranslationMode.blocks);
      expect(
        container.read(promptTranslationModeProvider),
        PromptTranslationMode.blocks,
      );
      container.dispose();
    },
  );
  test(
    'annotations and visibility reopen from isolated Hive without altering block data',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'lightweight-reading-storage-',
      );
      Hive.init(temp.path);
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
      const doc = PillDocument(
        text: 'blue eyes, \uE000',
        instances: {'\uE000': PillInstance(blockId: 'existing')},
        readings: [
          PromptReading(
            start: 0,
            end: 10,
            source: 'blue eyes,',
            translation: '蓝眼睛',
          ),
        ],
        readingsVisible: false,
      );
      final storage = PillWorkspaceStorage();
      await storage.persist('main', doc);
      await Hive.close();
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
      expect(storage.tryLoadSync('main'), doc);
      expect(storage.tryLoadSync('negative'), isNull);
      await Hive.close();
      assert(
        temp.absolute.path.startsWith(Directory.systemTemp.absolute.path) &&
            temp.path.contains('lightweight-reading-storage-'),
      );
      await temp.delete(recursive: true);
    },
  );
}
