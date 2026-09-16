import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'thumbnail_image_normalizer.dart';

/// Prompt 块预览图文件落地。
///
/// 与词库条目同策略：选图后统一归一化为 PNG，复制进应用文档目录
/// `prompt_block_thumbnails/`，块只保存该目录内的路径；外部源文件
/// 此后被移动/删除不影响块显示。
Future<Directory> _thumbnailDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  return Directory(p.join(appDir.path, 'prompt_block_thumbnails'));
}

/// 归一化并保存块预览图，返回应用目录内绝对路径。
Future<String> savePromptBlockThumbnail(Uint8List bytes) async {
  final png = normalizeThumbnailImageToPng(bytes);
  final dir = await _thumbnailDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File(p.join(dir.path, '${const Uuid().v4()}.png'));
  await file.writeAsBytes(png, flush: true);
  return file.path;
}

/// 删除应用目录内的块预览图；目录外路径（外部源文件）一律不动。
Future<void> deletePromptBlockThumbnail(String? thumbnailPath) async {
  if (thumbnailPath == null || thumbnailPath.isEmpty) return;
  try {
    final dir = await _thumbnailDirectory();
    if (!p.isWithin(dir.path, thumbnailPath)) return;
    final file = File(thumbnailPath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // 清理失败不影响主流程
  }
}
