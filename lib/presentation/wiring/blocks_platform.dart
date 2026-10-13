import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/file_picker_utils.dart';
import '../../core/utils/prompt_block_thumbnails.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../ui/blocks/blocks_contract.dart';

final blocksPlatformProvider = Provider<BlocksPlatform>(
  (ref) => BlocksPlatform(),
);

class BlocksPlatform {
  final _picked = <String>{};
  final _images = <String, Uint8List>{};
  var _nextImage = 0;

  BlockThumbPick prepareThumbnail(Uint8List bytes) {
    final token = 'memory:${_nextImage++}';
    final copy = Uint8List.fromList(bytes);
    _images[token] = copy;
    return BlockThumbPick(MemoryImage(copy), token);
  }

  void releaseThumbnail(String token) {
    _images.remove(token);
    _picked.remove(token);
  }

  Future<BlockThumbPick?> pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.firstOrNull?.path;
    if (path == null) return null;
    _picked.add(path);
    return BlockThumbPick(FileImage(File(path)), path);
  }

  Future<String> saveThumbnail(String token) async {
    final bytes = _images[token];
    if (bytes != null) return savePromptBlockThumbnail(bytes);
    if (!_picked.contains(token)) {
      throw StateError('Unknown thumbnail selection');
    }
    return savePromptBlockThumbnail(await File(token).readAsBytes());
  }

  Future<List<String>> pickTxt(String title) async =>
      (await FilePicker.platform.pickFiles(
        dialogTitle: title,
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: true,
      ))?.paths.whereType<String>().toList() ??
      [];

  Future<String?> pickDirectory(String title) =>
      FilePickerUtils.pickDirectoryModal(dialogTitle: title);

  Future<Map<String, dynamic>?> pickBackup(String title) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: title,
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return null;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw const FormatException('Unreadable block backup');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid block backup');
    }
    return decoded;
  }

  Future<void> exportBackup(Map<String, dynamic> data, String title) async {
    final target = await FilePicker.platform.saveFile(
      dialogTitle: title,
      fileName:
          'prompt-block-library-${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (target == null) return;
    await File(
      target.toLowerCase().endsWith('.json') ? target : '$target.json',
    ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
  }

  Future<void> exportTxt(List<PromptBlock> blocks, String title) async {
    final directory = await pickDirectory(title);
    if (directory == null) return;
    for (final block in blocks) {
      var name = block.displayTitle
          .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
          .replaceAll(RegExp(r'[. ]+$'), '');
      if (name.isEmpty) name = 'block';
      if (name.length > 100) name = String.fromCharCodes(name.runes.take(80));
      if (RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
        caseSensitive: false,
      ).hasMatch(name)) {
        name = '_$name';
      }
      var target = File(p.join(directory, '$name.txt'));
      var index = 2;
      while (await target.exists()) {
        target = File(p.join(directory, '$name (${index++}).txt'));
      }
      await target.writeAsString(block.content, flush: true);
    }
  }

  Future<void> backupDraft(String snapshot) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'draft-backups'));
    await directory.create(recursive: true);
    await File(
      p.join(
        directory.path,
        'before-blocks-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    ).writeAsString(snapshot, flush: true);
  }
}
