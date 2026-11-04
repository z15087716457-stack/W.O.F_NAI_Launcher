/// 画廊路径规范化工具
///
/// Windows 中文/长路径（`\\?\` 前缀）、大小写、分隔符统一处理。
/// 任何路径比较/存储/前缀判断必须走这套函数，禁止自行拼字符串比较。
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 测试用：按哪个平台的路径规则判断（true = Windows，false = macOS 等 POSIX 平台）。
///
/// 为 null 时跟随运行的机器。路径规则看的是宿主系统，`debugDefaultTargetPlatformOverride`
/// 改不了它，测试要在任何机器上验证两套规则就用这个开关。
@visibleForTesting
bool? debugGalleryPathWindowsRulesOverride;

bool get _windowsRules =>
    debugGalleryPathWindowsRulesOverride ?? Platform.isWindows;

/// 规范化画廊文件路径
///
/// - Windows 下去掉 `\\?\` / `\\?\UNC\` 前缀
/// - 统一为反斜杠分隔
String normalizeGalleryFilePath(String filePath) {
  final trimmed = filePath.trim();
  if (!_windowsRules) return trimmed;

  var normalized = trimmed.replaceAll('/', r'\');
  if (normalized.startsWith(r'\\?\UNC\')) {
    normalized = r'\\' + normalized.substring(r'\\?\UNC\'.length);
  } else if (normalized.startsWith(r'\\?\')) {
    normalized = normalized.substring(r'\\?\'.length);
  }
  return normalized;
}

/// 画廊文件路径键（Windows 小写化，用于比较/去重/前缀匹配）
String galleryFilePathKey(String filePath) {
  final normalized = normalizeGalleryFilePath(filePath);
  return _windowsRules ? normalized.toLowerCase() : normalized;
}

/// 两个画廊文件路径是否相等（大小写不敏感、忽略 `\\?\` 前缀）
bool galleryFilePathsEqual(String left, String right) =>
    galleryFilePathKey(left) == galleryFilePathKey(right);

/// [childPath] 是否位于 [rootPath] 之内（含相等）
///
/// 按规范化 key 前缀匹配，Windows 大小写不敏感，避免 `p.isWithin`
/// 在 Windows 下的大小写敏感问题。比较前先去掉 root 的尾随分隔符，
/// 使 `C:\a\` 与 `C:\a` 视为同一根。
bool galleryPathIsWithin(String rootPath, String childPath) {
  var rootKey = galleryFilePathKey(rootPath);
  // 尾随分隔符归一（normalize 后 Windows 下统一为反斜杠，此处双保险）
  while (rootKey.endsWith('/') || rootKey.endsWith(r'\')) {
    rootKey = rootKey.substring(0, rootKey.length - 1);
  }
  final childKey = galleryFilePathKey(childPath);
  if (childKey == rootKey) return true;
  final separator = _windowsRules ? r'\' : '/';
  return childKey.startsWith('$rootKey$separator');
}

/// [path] 是否为绝对路径
///
/// 盘符（`C:\`）和 UNC 前缀（`\\server`）在哪个平台都算；macOS 等 POSIX 平台上以 `/`
/// 开头的也算（外部图库源在 `/Users/…`、`/Volumes/…` 下）。
bool isAbsoluteGalleryPath(String path) {
  final normalized = normalizeGalleryFilePath(path);
  if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(normalized) ||
      normalized.startsWith(r'\\')) {
    return true;
  }
  return !_windowsRules && p.posix.isAbsolute(normalized);
}
