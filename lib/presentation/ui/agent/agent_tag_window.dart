import 'agent_contract.dart';

List<AgentDiffSegment?> agentDiffWindow(
  List<AgentDiffSegment> segments, {
  int context = 3,
  bool windowUnchanged = false,
}) {
  // 切成一个个 tag：每个 tag 是若干小段（同一个 tag 里可能有删有加）。
  final tags = <List<AgentDiffSegment>>[[]];
  for (final seg in segments) {
    var rest = seg.text;
    while (rest.isNotEmpty) {
      final comma = rest.indexOf(',');
      if (comma < 0) {
        tags.last.add(AgentDiffSegment(rest, seg.kind));
        break;
      }
      tags.last.add(AgentDiffSegment(rest.substring(0, comma + 1), seg.kind));
      tags.add([]);
      rest = rest.substring(comma + 1);
    }
  }
  if (tags.last.isEmpty) tags.removeLast();
  final changed = [
    for (final t in tags)
      t.any((x) => x.kind != AgentDiffKind.same && x.text.trim().isNotEmpty),
  ];
  if (!changed.contains(true) && !windowUnchanged) return segments;
  final show = List.filled(tags.length, false);
  for (var i = 0; i < tags.length; i++) {
    if (!changed[i]) continue;
    for (var j = i - context; j <= i + context; j++) {
      if (j >= 0 && j < tags.length) show[j] = true;
    }
  }
  if (!changed.contains(true) && windowUnchanged) {
    for (var i = 0; i < tags.length && i < context; i++) {
      show[i] = true;
    }
  }
  // 只藏一个 tag 换成「…」不划算：直接显示。
  for (var i = 0; i < tags.length; i++) {
    if (show[i]) continue;
    var j = i;
    while (j < tags.length && !show[j]) {
      j++;
    }
    if (j - i == 1) show[i] = true;
    i = j;
  }
  final out = <AgentDiffSegment?>[];
  for (var i = 0; i < tags.length; i++) {
    if (show[i]) {
      out.addAll(tags[i]);
    } else if (i == 0 || show[i - 1]) {
      out.add(null);
    }
  }
  return out;
}
