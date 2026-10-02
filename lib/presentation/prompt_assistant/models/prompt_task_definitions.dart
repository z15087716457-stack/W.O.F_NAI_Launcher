import 'prompt_assistant_models.dart';

extension PromptTaskDefinition on LauncherInterface {
  String get title => switch (this) {
    LauncherInterface.translate => '原文 → 阅读语言',
    LauncherInterface.promptReverse => '阅读语言 → 原文',
    LauncherInterface.tagTranslate => '标签名称翻译',
    LauncherInterface.wikiTranslate => '百科正文翻译',
  };
  String get description => switch (this) {
    LauncherInterface.translate => '翻译提示词与积木，保留权重、分组和标签语义。',
    LauncherInterface.promptReverse => '结合原文落实译文中的增删修改，结果填回原文供确认。',
    LauncherInterface.tagTranslate => '为可见标签提供简洁、准确的名称释义。',
    LauncherInterface.wikiTranslate => '翻译百科正文、整理排版，并按语境选择可点击标签。',
  };
  String get builtinId => 'builtin:$name';
  String get builtinPrompt => switch (this) {
    LauncherInterface.translate =>
      '''Translate image-generation prompts into the requested reading language. Preserve subject relationships, counts, names, weights, grouping and prompt punctuation. Use glossary entries as optional reference material and judge ambiguous words from context. Prefer clear, natural reading text. Preserve canonical names where a translation would obscure their identity.''',
    LauncherInterface.promptReverse =>
      '''Use the edited reading text as the user's desired description. Compare it with the original reading to identify additions, deletions and replacements. Refer to the original generation prompt and apply only requested changes. Preserve unrelated artist tags, names, weights, groups and prompt style. Glossary entries and selected terms are optional reference material. Return an English generation prompt; do not restore deleted phrases or add unrequested content.''',
    LauncherInterface.tagTranslate =>
      '''Translate complete Danbooru tags into concise, natural labels in the requested reading language. Use category, aliases and wiki context to distinguish characters, artists, works and ordinary terms. Preserve an existing supplied label exactly. Do not add explanations or invent a different entity.''',
    LauncherInterface.wikiTranslate =>
      '''Translate the full wiki faithfully into the requested reading language. Preserve existing headings, separate explanations by topic and format long enumerations as Markdown lists. Keep canonical tag references intact. Glossary matches are optional evidence: use context to decide meaningful tag hyperlinks and leave uncertain ordinary words unlinked. Include meaningful current-article references in examples and classifications. Return a source-language presentation preserving original wording with matching layout and contextual links. Usually link the first meaningful mention in continuous prose; examples, related-tag lists and new sections may repeat a complete clickable link. Preserve source URLs and do not invent claims, relationships or external links.''',
  };
  TaskPresetConfig get builtinPreset => TaskPresetConfig(
    id: builtinId,
    name: 'Studio 默认 · $title',
    task: this,
    prompt: builtinPrompt,
  );
}

TaskPresetConfig presetFor(
  PromptAssistantConfigState config,
  LauncherInterface task,
) {
  final id = config.interfaceFor(task).presetId;
  if (id == null || id.startsWith('builtin:')) return task.builtinPreset;
  return config.presets
          .where((preset) => preset.id == id && preset.task == task)
          .firstOrNull ??
      task.builtinPreset;
}

ModelConfig effectiveTaskModel(
  PromptAssistantConfigState config,
  LauncherInterface task,
  ModelConfig model,
) => model;
