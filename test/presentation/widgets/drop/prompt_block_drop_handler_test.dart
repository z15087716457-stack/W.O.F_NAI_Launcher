import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/drop/prompt_block_drop_handler.dart';

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  testWidgets(
    'block drop does not synchronously parse and cannot open a menu after unmount',
    (tester) async {
      final directory = await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp('block-drop-');
        Hive.init(directory.path);
        await ImageMetadataService().initialize();
        return directory;
      });
      addTearDown(() async {
        await Hive.close();
        await directory!.delete(recursive: true);
      });
      late BuildContext dropContext;
      late WidgetRef dropRef;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) {
                dropContext = context;
                dropRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );
      UnifiedMetadataParser.resetStatistics();
      await tester.runAsync(() async {
        final handling = PromptBlockDropHandler.handle(
          context: dropContext,
          ref: dropRef,
          fileName: 'plain.png',
          bytes: bytes,
        );
        expect(UnifiedMetadataParser.statistics.totalAttempts, 0);
        await tester.pumpWidget(const SizedBox());
        await handling;
      });
      expect(UnifiedMetadataParser.statistics.totalAttempts, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
