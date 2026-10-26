import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:super_clipboard/super_clipboard.dart';

import '../../../helpers/agent_data_reader.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

class _HeldImage extends AgentFixtureDataReader {
  _HeldImage(this.gate)
    : super(bytes: img.encodePng(img.Image(width: 2, height: 2)));
  final Completer<void> gate;
  @override
  ReadProgress? getFile(
    FileFormat? value,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) => super.getFile(value, (file) async {
    await gate.future;
    await onFile(file);
  }, onError: onError);
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  setUp(() {
    h = AgentWiringHarness();
  });
  tearDown(() async {
    await h.dispose();
  });
  testWidgets(
    'mixed clipboard inserts exact paths at selection and imports files once',
    (tester) async {
      late File image;
      await tester.runAsync(() async {
        await h.init();
        image = File('${h.root.path}/原图 with spaces.png');
        await image.writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
        h.clipboard = () async => [
          AgentFixtureDataReader(
            fileUri: Uri.file('${h.root.path}/中文 file.txt'),
          ),
          AgentFixtureDataReader(fileUri: image.uri),
          AgentFixtureDataReader(fileUri: image.uri),
          AgentFixtureDataReader(
            bytes: img.encodePng(img.Image(width: 1, height: 1)),
          ),
          AgentFixtureDataReader(fileUri: Uri.file('${h.root.path}/other.pdf')),
        ];
      });
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await h.pump(tester);
      final field = find.byKey(const Key('agent-input'));
      // Use the real composer paste path, including insertion at the caret.
      final editable = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      await tester.enterText(editable, 'before after');
      tester.widget<EditableText>(editable).controller.selection =
          const TextSelection.collapsed(offset: 7);
      await h.paste(tester);
      await h.finishFiles(tester);
      final paths = [
        '${h.root.path}\\中文 file.txt',
        '${h.root.path}\\other.pdf',
      ];
      expect(h.c.selected!.composer.text, 'before ${paths.join('\n')}after');
      expect(h.c.selected!.composer.attachments, hasLength(1));
      expect(
        h.c.selected!.composer.attachments.single.name,
        '原图 with spaces.png',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'non-image file list returns newline-separated full paths without reading files',
    (tester) async {
      await tester.runAsync(() async {
        await h.init();
        h.clipboard = () async => [
          AgentFixtureDataReader(
            fileUri: Uri.file(r'C:\Folder with spaces\中文.txt'),
          ),
          AgentFixtureDataReader(
            fileUri: Uri.file(r'C:\Folder with spaces\notes.pdf'),
          ),
        ];
      });
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await h.pump(tester);
      expect(
        await tester.runAsync(h.panel(tester).actions.onPaste),
        'C:\\Folder with spaces\\中文.txt\nC:\\Folder with spaces\\notes.pdf',
      );
      expect(h.c.selected!.composer.attachments, isEmpty);
      expect(h.c.selected!.pendingImageCount, 0);
    },
  );
  for (final count in [1, 3]) {
    testWidgets('$count pasted images count files, not nested reservations', (
      tester,
    ) async {
      late Completer<void> gate;
      await tester.runAsync(() async {
        await h.init();
        gate = Completer<void>();
        h.clipboard = () async => List.generate(count, (_) => _HeldImage(gate));
      });
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await h.pump(tester);
      late Future<String?> paste;
      await tester.runAsync(() async {
        paste = h.panel(tester).actions.onPaste();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(
        h.c.selected!.importingImages,
        2,
      ); // Both lifecycle reservations remain.
      expect(h.panel(tester).data.composer.importing, count);
      await tester.runAsync(() async {
        gate.complete();
        await paste;
      });
      await tester.pump();
      expect(h.c.selected!.composer.attachments, hasLength(count));
      expect(h.panel(tester).data.composer.importing, 0);
    });
  }
}
