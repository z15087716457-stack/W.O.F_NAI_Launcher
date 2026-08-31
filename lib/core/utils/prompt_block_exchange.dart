import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../data/repositories/prompt_block_repository.dart';

/// 一个待导入的来源文件。
class PromptBlockExchangeFile {
  PromptBlockExchangeFile({required this.path, required this.content})
    : hash = PromptBlockExchange.contentHash(content);

  /// 来源文件绝对路径。
  final String path;

  /// 文件内容原文（已去除 UTF-8 BOM，其余原样保留）。
  final String content;

  /// 内容 SHA-256 十六进制摘要。
  final String hash;

  String get fileName => p.basename(path);

  String get title {
    final base = p.basenameWithoutExtension(path);
    return base.trim().isEmpty ? fileName : base.trim();
  }
}

/// 计划条目动作。
enum PromptBlockExchangeAction { create, skipUnchanged, update }

/// 交换计划中的单个条目。
class PromptBlockExchangeItem {
  PromptBlockExchangeItem({
    required this.file,
    required this.action,
    required this.folderChain,
    this.existingBlock,
    this.localModified = false,
  });

  final PromptBlockExchangeFile file;

  final PromptBlockExchangeAction action;

  /// 新建块的目标文件夹名链（从块库根开始逐级命名）。
  ///
  /// TXT 单文件导入传当前浏览目标；策展目录导入传镜像目录链。
  final List<String> folderChain;

  /// 已存在同来源块；skipUnchanged / update 时非空。
  final PromptBlock? existingBlock;

  /// 块当前正文与上次导入记录不一致（用户手动改过导入块）。
  final bool localModified;
}

/// 一次交换的完整计划。纯数据，不写块库。
class PromptBlockExchangePlan {
  PromptBlockExchangePlan({required this.items});

  final List<PromptBlockExchangeItem> items;

  int get createCount =>
      items.where((e) => e.action == PromptBlockExchangeAction.create).length;

  int get skipCount => items
      .where((e) => e.action == PromptBlockExchangeAction.skipUnchanged)
      .length;

  int get updateCount =>
      items.where((e) => e.action == PromptBlockExchangeAction.update).length;

  int get localModifiedCount => items.where((e) => e.localModified).length;
}

/// 块库与外部来源（TXT 文件 / 策展目录 / 库备份 JSON）的交换逻辑。
///
/// 纯领域层：只读来源、计算摘要、构建计划；不写块库。是否覆盖已变更块
/// 由调用方（经用户确认）在执行时显式决定，本层不做任何隐式覆盖。
class PromptBlockExchange {
  PromptBlockExchange._();

  static const String backupSchemaKey = 'schemaVersion';
  static const int backupSchemaVersion = 1;

  /// 内容 SHA-256 十六进制摘要。
  static String contentHash(String content) =>
      sha256.convert(utf8.encode(content)).toString();

  /// 来源匹配键。Windows 路径大小写不敏感，统一小写比较。
  static String normalizeSourcePath(String path) =>
      Platform.isWindows ? path.toLowerCase() : path;

  /// 读取一组 TXT 文件为待导入项。
  ///
  /// UTF-8 解码（容错替换无效字节），去除开头 BOM；其余内容原样保留。
  static Future<List<PromptBlockExchangeFile>> readTxtFiles(
    List<String> paths,
  ) async {
    final files = <PromptBlockExchangeFile>[];
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('Source file not found', path);
      }
      files.add(
        PromptBlockExchangeFile(path: path, content: await _readText(file)),
      );
    }
    return files;
  }

  /// 递归扫描目录下全部 TXT 文件（扩展名大小写不敏感），按相对路径排序。
  ///
  /// 不做任何目录排除；预览界面负责把将导入的文件透明列给用户确认。
  static Future<List<PromptBlockExchangeFile>> scanTxtDirectory(
    String rootPath,
  ) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Source directory not found', rootPath);
    }

    final files = <PromptBlockExchangeFile>[];
    final stack = <Directory>[root];
    while (stack.isNotEmpty) {
      final dir = stack.removeLast();
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          stack.add(entity);
        } else if (entity is File &&
            entity.path.toLowerCase().endsWith('.txt')) {
          files.add(
            PromptBlockExchangeFile(
              path: entity.path,
              content: await _readText(entity),
            ),
          );
        }
      }
    }

    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// 策展目录导入的镜像文件夹链：根目录名 + 文件相对目录段。
  static List<String> curationFolderChain(
    PromptBlockExchangeFile file,
    String rootPath,
  ) {
    final rootName = p.basename(p.normalize(rootPath));
    final segments = p.split(p.normalize(p.dirname(file.path)));
    final rootSegments = p.split(p.normalize(rootPath));
    final relative = segments.length > rootSegments.length
        ? segments.sublist(rootSegments.length)
        : const <String>[];
    return [if (rootName.trim().isNotEmpty) rootName.trim(), ...relative];
  }

  /// 按来源路径对照库中块，把待导入文件分类为新建 / 未变更 / 已变更。
  static PromptBlockExchangePlan buildPlan({
    required List<PromptBlockExchangeFile> files,
    required PromptBlockLibraryData library,
    required List<String> Function(PromptBlockExchangeFile file) folderChainOf,
  }) {
    final bySource = <String, PromptBlock>{};
    for (final block in library.blocks) {
      final source = block.sourcePath;
      if (source == null || source.isEmpty) continue;
      bySource.putIfAbsent(normalizeSourcePath(source), () => block);
    }

    final items = <PromptBlockExchangeItem>[];
    for (final file in files) {
      final existing = bySource[normalizeSourcePath(file.path)];
      if (existing == null) {
        items.add(
          PromptBlockExchangeItem(
            file: file,
            action: PromptBlockExchangeAction.create,
            folderChain: folderChainOf(file),
          ),
        );
        continue;
      }

      if (existing.sourceHash == file.hash) {
        items.add(
          PromptBlockExchangeItem(
            file: file,
            action: PromptBlockExchangeAction.skipUnchanged,
            folderChain: folderChainOf(file),
            existingBlock: existing,
          ),
        );
        continue;
      }

      final localModified =
          existing.sourceHash != null &&
          contentHash(existing.content) != existing.sourceHash;
      items.add(
        PromptBlockExchangeItem(
          file: file,
          action: PromptBlockExchangeAction.update,
          folderChain: folderChainOf(file),
          existingBlock: existing,
          localModified: localModified,
        ),
      );
    }
    return PromptBlockExchangePlan(items: items);
  }

  /// 库备份 JSON 结构。
  static Map<String, dynamic> exportLibraryJson({
    required List<PromptBlock> blocks,
    required List<PromptBlockFolder> folders,
  }) {
    return {
      backupSchemaKey: backupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': folders.map((folder) => folder.toJson()).toList(),
      'blocks': blocks.map((block) => block.toJson()).toList(),
    };
  }

  /// 解析并规划库备份导入：同 ID 实体跳过不覆盖；引用了库与备份中
  /// 都不存在的父级 / 文件夹的实体，把引用置空（回根目录）而不是挂空。
  static PromptBlockLibraryImportPlan planLibraryImport({
    required Map<String, dynamic> json,
    required PromptBlockLibraryData library,
  }) {
    if (json[backupSchemaKey] is! int ||
        json['folders'] is! List ||
        json['blocks'] is! List) {
      throw const FormatException('Not a prompt block library backup');
    }

    final existingFolders = library.folders.map((f) => f.id).toSet();
    final existingBlocks = library.blocks.map((b) => b.id).toSet();

    final folders = <PromptBlockFolder>[];
    var skippedFolders = 0;
    for (final raw in json['folders'] as List) {
      if (raw is! Map) {
        throw const FormatException('Corrupt folder record in backup');
      }
      PromptBlockFolder folder;
      try {
        folder = PromptBlockFolder.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        throw const FormatException('Corrupt folder record in backup');
      }
      if (existingFolders.contains(folder.id)) {
        skippedFolders++;
        continue;
      }
      folders.add(folder);
      existingFolders.add(folder.id);
    }

    final importedFolderIds = folders.map((f) => f.id).toSet();
    final resolved = folders.map((folder) {
      final parent = folder.parentId;
      if (parent != null &&
          !existingFolders.contains(parent) &&
          !importedFolderIds.contains(parent)) {
        return folder.copyWith(parentId: null);
      }
      return folder;
    }).toList();

    final blocks = <PromptBlock>[];
    var skippedBlocks = 0;
    for (final raw in json['blocks'] as List) {
      if (raw is! Map) {
        throw const FormatException('Corrupt block record in backup');
      }
      PromptBlock block;
      try {
        block = PromptBlock.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        throw const FormatException('Corrupt block record in backup');
      }
      if (existingBlocks.contains(block.id)) {
        skippedBlocks++;
        continue;
      }
      final folderId = block.folderId;
      if (folderId != null &&
          !existingFolders.contains(folderId) &&
          !importedFolderIds.contains(folderId)) {
        block = block.copyWith(folderId: null);
      }
      blocks.add(block);
      existingBlocks.add(block.id);
    }

    return PromptBlockLibraryImportPlan(
      folders: resolved,
      blocks: blocks,
      skippedFolders: skippedFolders,
      skippedBlocks: skippedBlocks,
    );
  }

  static Future<String> _readText(File file) async {
    var bytes = await file.readAsBytes();
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      bytes = bytes.sublist(3);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// 库备份导入计划。
class PromptBlockLibraryImportPlan {
  PromptBlockLibraryImportPlan({
    required this.folders,
    required this.blocks,
    required this.skippedFolders,
    required this.skippedBlocks,
  });

  final List<PromptBlockFolder> folders;
  final List<PromptBlock> blocks;
  final int skippedFolders;
  final int skippedBlocks;
}
