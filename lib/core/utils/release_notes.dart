import 'package:markdown/markdown.dart' as md;

/// Keep the changes section; release-page downloads and checksums stay on GitHub.
String updateNotesMarkdown(String? notes) {
  final lines = (notes ?? '').split('\n');
  final headings = <({int line, int level, String title})>[];
  final heading = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$');
  var fence = '';
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    final marker = RegExp(r'^\s*(`{3,}|~{3,})').firstMatch(line);
    if (marker != null) {
      final kind = marker.group(1)![0];
      if (fence.isEmpty) {
        fence = kind;
      } else if (fence == kind) {
        fence = '';
      }
      continue;
    }
    if (fence.isNotEmpty) continue;
    final match = heading.firstMatch(line);
    if (match != null) {
      headings.add((
        line: i,
        level: match.group(1)!.length,
        title: match.group(2)!,
      ));
    }
  }
  final changes = RegExp(
    r'更新内容|更新內容|更新日志|更新日誌|release notes|changelog|what[’\x27]?s new',
    caseSensitive: false,
  );
  final section = headings.where((h) => changes.hasMatch(h.title)).firstOrNull;
  if (section != null) {
    final end = headings
        .where((h) => h.line > section.line && h.level <= section.level)
        .firstOrNull;
    return lines.sublist(section.line + 1, end?.line).join('\n').trim();
  }
  // Older releases may only contain a list, with no named changes section.
  final metadata = RegExp(
    r'^(按系统下载|按系統下載|下载|下載|安装说明|安裝說明|文件校验|檔案校驗|檔案驗證|downloads?|installation|checksums?|file verification)\s*$',
    caseSensitive: false,
  );
  final hidden = <int>{};
  for (final h in headings.where(
    (h) => metadata.hasMatch(
      h.title.replaceFirst(RegExp(r'^[^A-Za-z\u3400-\u9fff]+'), '').trim(),
    ),
  )) {
    final end = headings
        .where((next) => next.line > h.line && next.level <= h.level)
        .firstOrNull;
    for (var i = h.line; i < (end?.line ?? lines.length); i++) {
      hidden.add(i);
    }
  }
  return [
    for (var i = 0; i < lines.length; i++)
      if (!hidden.contains(i)) lines[i],
  ].join('\n').trim();
}

/// The settings contract uses plain items, not raw Markdown source lines.
List<String> updateNoteItems(String? notes) {
  final nodes = md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.gitHubWeb,
  ).parse(updateNotesMarkdown(notes));
  final items = <String>[];
  for (final node in nodes.whereType<md.Element>()) {
    if (node.tag == 'ul' || node.tag == 'ol') {
      items.addAll(node.children!.map(_noteText));
    } else if (node.tag == 'p') {
      items.add(_noteText(node));
    }
  }
  return items
      .map((item) => item.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _noteText(md.Node node) {
  if (node is md.Text) return node.text;
  final element = node as md.Element;
  if (element.tag == 'img') return '';
  if (element.tag == 'br') return ' ';
  final text = (element.children ?? const <md.Node>[]).map(_noteText).join();
  return const {'p', 'li'}.contains(element.tag) ? '$text ' : text;
}
