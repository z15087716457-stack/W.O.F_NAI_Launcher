/// 拖拽重排目标下标计算
///
/// 语义与 `List.removeAt(oldIndex)` 后 `insert(newIndex, item)` 的提供方约定一致
/// （同 Flutter `ReorderableListView` 的下标约定：newIndex 是移除前的下标，
/// 若大于 oldIndex 需减一）。
///
/// [oldIndex] 被拖条目原下标；[targetIndex] 悬停目标条目的下标；
/// [insertAfter] 为 true 时插到目标条目之后，否则插到其之前。
/// 返回「移除后」的插入下标。
int computeReorderInsertIndex({
  required int oldIndex,
  required int targetIndex,
  required bool insertAfter,
}) {
  var newIndex = insertAfter ? targetIndex + 1 : targetIndex;
  if (newIndex > oldIndex) newIndex -= 1;
  return newIndex;
}
