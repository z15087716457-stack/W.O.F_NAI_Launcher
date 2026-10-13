import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/vibe_library_path_helper.dart';
import '../../core/utils/novelai_vibe_codec.dart';
import 'refs_drop_reader.dart';
import '../router/app_router.dart';
import '../ui/refs/refs_contract.dart';
import '../utils/clipboard_image.dart';
import '../utils/dropped_file_reader.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import '../widgets/common/themed_input_dialog.dart';

final refsPlatformProvider = Provider<RefsPlatform>(
  (ref) => const RefsPlatform(),
);

class RefsPlatform {
  const RefsPlatform();

  Future<List<DroppedFileData>> pickFiles(
    RefsKind kind,
    RefsImportSource source,
  ) async {
    if (source == RefsImportSource.clipboard) {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        throw UnsupportedError(currentL10n.clipboard_unsupportedPlatform);
      }
      final reader = await clipboard.read();
      final image = await DroppedFileReader.read(
        reader,
        allowVibeFiles: kind == RefsKind.vibe,
        allowRemoteImages: false,
      );
      if (image != null) return [image];
      final text = await reader.readValue(Formats.plainText);
      if (kind == RefsKind.vibe && text != null && text.trim().isNotEmpty) {
        return [clipboardText(text)];
      }
      return [];
    }
    final images =
        kind == RefsKind.precise || source == RefsImportSource.images;
    final result = await FilePicker.platform.pickFiles(
      type: images ? FileType.image : FileType.custom,
      allowedExtensions: images
          ? null
          : [
              'png',
              'jpg',
              'jpeg',
              'webp',
              'bmp',
              'gif',
              'naiv4vibe',
              'naiv4vibebundle',
            ],
      allowMultiple: true,
      withData: false,
      lockParentWindow: true,
    );
    if (result == null) return [];
    final paths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .toList();
    final local = await RefsDropReader.readPaths(paths);
    return [
      ...local,
      for (final file in result.files)
        if (file.path == null && file.bytes != null)
          DroppedFileData(fileName: file.name, bytes: file.bytes!),
    ];
  }

  static DroppedFileData clipboardText(String text) {
    final trimmed = text.trim();
    var data = trimmed;
    if (!trimmed.startsWith('{')) {
      final raw = base64Decode(trimmed);
      try {
        final decoded = utf8.decode(raw);
        if (decoded.startsWith('{')) data = decoded;
      } on FormatException {
        data = trimmed;
      }
    }
    final Map<String, dynamic> json = data.startsWith('{')
        ? jsonDecode(data) as Map<String, dynamic>
        : {
            'identifier': NovelAiVibeCodec.singleIdentifier,
            'version': NovelAiVibeCodec.version,
            'id': NovelAiVibeCodec.hashString(trimmed),
            'type': 'encoding',
            'name': 'clipboard',
            'encodings': {
              'unknown': {
                'unknown': {'encoding': trimmed},
              },
            },
          };
    final bundle = json['vibes'] is List;
    return DroppedFileData(
      fileName: 'clipboard.${bundle ? 'naiv4vibebundle' : 'naiv4vibe'}',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );
  }

  Future<String?> folder() => FilePicker.platform.getDirectoryPath();
  Future<String> libraryFolder() => VibeLibraryPathHelper.instance.getPath();
  Future<void> copyImage(Uint8List bytes) =>
      writeImageBytesToClipboardAsPng(bytes);

  Future<void> openFolder(String path) async {
    final directory = await FileSystemEntity.isDirectory(path)
        ? path
        : p.dirname(path);
    await Process.start('explorer.exe', [
      directory,
    ], mode: ProcessStartMode.detached);
  }

  Future<bool> confirmEncoding(
    BuildContext context, {
    required int count,
    required int cost,
    required String model,
  }) => ThemedConfirmDialog.show(
    context: context,
    title: context.l10n.refs_encodeNow(model, cost * count),
    content: context.l10n.vibe_import_confirmCost,
    type: ThemedConfirmDialogType.warning,
  );

  Future<String?> bundleName(BuildContext context) => ThemedInputDialog.show(
    context: context,
    title: context.l10n.refs_packBundle,
    initialValue: '',
    hintText: context.l10n.vibe_name,
  );

  void generate(BuildContext context) => context.go(AppRoutes.generation);
  void library(BuildContext context, RefsKind kind) => context.go(
    kind == RefsKind.vibe ? AppRoutes.vibeLibrary : AppRoutes.preciseRefLibrary,
  );
  void error(BuildContext context, Object error) =>
      AppToast.error(context, error.toString());
  void sent(
    BuildContext context,
    int count, {
    bool truncated = false,
    RefsKind kind = RefsKind.vibe,
  }) {
    if (truncated) {
      AppToast.warning(context, context.l10n.vibeLibrary_maxVibesReached);
    }
    if (count > 0) {
      AppToast.success(
        context,
        kind == RefsKind.precise
            ? context.l10n.preciseRef_addedCount(count)
            : context.l10n.vibe_addedCount(count),
      );
    }
  }

  void imported(
    BuildContext context,
    int success,
    int failed, {
    RefsKind kind = RefsKind.vibe,
  }) {
    if (success == 0 && failed == 0) return;
    if (failed > 0) {
      AppToast.warning(
        context,
        context.l10n.vibeLibrary_importSummary(success, failed),
      );
    } else {
      AppToast.success(
        context,
        kind == RefsKind.precise
            ? context.l10n.preciseRefLib_importedCount(success)
            : context.l10n.vibeLibrary_importSuccessCount(success),
      );
    }
  }
}
