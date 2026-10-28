import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';

/// 实例是否是不依赖块库的临时块（Agent 或拆解直接建出来的，没有原块）。
bool isStandaloneTemp(PillInstance instance) =>
    instance.temporary && instance.blockId.isEmpty;

/// 不依赖块库的临时块的显示用块：标题、颜色、图标取 `temp` 自带的值，
/// 缺标题时用 [fallbackTitle]（中性的“临时块”文案，不是“块已删除”）。
PromptBlock standaloneTempBlock(PillInstance instance, String fallbackTitle) {
  final temp = instance.temp!;
  final title = temp.title?.trim() ?? '';
  return PromptBlock.create(
    id: '',
    title: title.isEmpty ? fallbackTitle : title,
    content: temp.content,
    negativeContent: temp.negativeContent ?? '',
    color: temp.color ?? '#FF607D8B',
    iconName: temp.iconName,
  );
}
