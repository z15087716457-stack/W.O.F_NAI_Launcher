import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nai_launcher/core/services/mac_legacy_data_import.dart';
import 'package:path/path.dart' as p;

Future<void> writeData(Directory root, String relative, Object content) async {
  final file = File(p.join(root.path, relative));
  await file.parent.create(recursive: true);
  if (content is List<int>) {
    await file.writeAsBytes(content);
  } else {
    await file.writeAsString('$content');
  }
}

/// Relative path to content and modification time, independent of the code
/// under test. Directories map to a fixed marker.
Future<Map<String, String>> treeOf(
  Directory root, {
  Set<String> skip = const {},
}) async {
  final result = <String, String>{};
  if (!await root.exists()) return result;
  await for (final entry in root.list(recursive: true, followLinks: false)) {
    final relative = p.relative(entry.path, from: root.path);
    if (skip.contains(relative)) continue;
    if (entry is Link) {
      result[relative] = 'link -> ${await entry.target()}';
    } else if (entry is Directory) {
      result[relative] = 'dir';
    } else if (entry is File) {
      final stat = await entry.stat();
      result[relative] =
          '${base64.encode(await entry.readAsBytes())} '
          '@${stat.modified.millisecondsSinceEpoch}';
    }
  }
  return result;
}

/// Records what the startup window was asked to show; the first-launch copy
/// keeps the plain names, a sync or undo adds its task.
class RecordingPresenter implements MacLegacyDataImportPresenter {
  RecordingPresenter({this.skipWhenRunning = false, this.retry});

  final bool skipWhenRunning;
  final bool? retry;
  final calls = <String>[];

  String _name(String step, MacLegacyDataTask task) =>
      task == MacLegacyDataTask.import ? step : '$step:${task.name}';

  @override
  void showCopying(MacLegacyDataTask task) => calls.add(_name('copying', task));

  @override
  void showLegacyRunning(
    MacLegacyDataTask task, {
    required void Function() onSkip,
  }) {
    calls.add(_name('running', task));
    if (skipWhenRunning) scheduleMicrotask(onSkip);
  }

  @override
  void showFailed(
    MacLegacyDataTask task,
    Object error, {
    required void Function() onRetry,
    required void Function() onSkip,
  }) {
    calls.add(_name('failed', task));
    scheduleMicrotask(retry == true ? onRetry : onSkip);
  }

  @override
  void showStarting() => calls.add('starting');
}
