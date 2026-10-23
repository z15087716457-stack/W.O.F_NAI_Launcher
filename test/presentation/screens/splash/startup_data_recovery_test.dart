import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/adjacent_app_data_migration.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/splash/startup_data_recovery.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  AdjacentAppDataException failure() => AdjacentAppDataException(
    const FileSystemException(
      'Both application data directories contain data; refusing to merge',
    ),
    legacyPath: r'C:\Users\Synthetic\AppData\Roaming\com.example\nai_launcher',
    destinationPath: r'D:\W.O.F NAI Studio\user-data',
  );

  for (final locale in AppLocalizations.supportedLocales) {
    for (final width in [480.0, 1000.0]) {
      testWidgets(
        'storage recovery renders without databases at $locale $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 720);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            RepaintBoundary(
              key: const Key('recovery-capture'),
              child: StartupDataRecoveryApp(
                error: failure(),
                locale: locale,
                onRetry: () async {},
                onClose: () async {},
                onOpenDirectory: (_) async {},
                onCopy: (_) async {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(failure().destinationPath), findsOneWidget);
          expect(find.byKey(const Key('startup-retry')), findsOneWidget);
          expect(tester.takeException(), isNull);
          final directory = Platform.environment['STARTUP_RECOVERY_CAPTURES'];
          if (directory != null &&
              locale == const Locale('zh') &&
              width == 1000) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('recovery-capture')),
              );
              final image = await boundary.toImage();
              try {
                final png = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await Directory(directory).create(recursive: true);
                await File(
                  '$directory/recovery-zh.png',
                ).writeAsBytes(png!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }
        },
      );
    }
  }

  testWidgets(
    'folder/copy/close callbacks work and pending retry prevents duplicate actions',
    (tester) async {
      final calls = <String>[];
      final pending = Completer<void>();
      await tester.pumpWidget(
        StartupDataRecoveryApp(
          error: failure(),
          locale: const Locale('en'),
          onRetry: () {
            calls.add('retry');
            return pending.future;
          },
          onClose: () async {
            calls.add('close');
          },
          onOpenDirectory: (path) async {
            calls.add(path);
          },
          onCopy: (text) async {
            expect(text, contains(failure().legacyPath));
            expect(text, contains(failure().destinationPath));
            calls.add('copy');
          },
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'startup-open-current',
        'startup-open-legacy',
        'startup-copy',
        'startup-close',
      ]) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }
      expect(calls, [
        failure().destinationPath,
        failure().legacyPath,
        'copy',
        'close',
      ]);
      await tester.tap(find.byKey(const Key('startup-retry')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('startup-retry')));
      await tester.pump();
      expect(calls.where((call) => call == 'retry'), hasLength(1));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('startup-retry')))
            .onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('startup-retry')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'generic preparation and action errors remain visible and redact secrets',
    (tester) async {
      String? copied;
      await tester.pumpWidget(
        StartupDataRecoveryApp(
          error: const FileSystemException(
            'token=synthetic-secret permission denied',
          ),
          locale: const Locale('en'),
          onRetry: () async => throw StateError('token=another-secret'),
          onClose: () async {},
          onOpenDirectory: (_) async {},
          onCopy: (text) async {
            copied = text;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('startup-open-current')), findsNothing);
      await tester.tap(find.byKey(const Key('startup-copy')));
      await tester.pumpAndSettle();
      expect(copied, contains('[REDACTED]'));
      expect(copied, isNot(contains('synthetic-secret')));
      await tester.tap(find.byKey(const Key('startup-retry')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Action failed:'), findsOneWidget);
      expect(find.textContaining('another-secret'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
