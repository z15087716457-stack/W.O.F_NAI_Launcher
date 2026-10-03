import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'prompt_assistant_models.dart';

extension PromptTaskDefinition on LauncherInterface {
  String get title => titleIn(currentL10n);
  String titleIn(AppLocalizations l10n) => switch (this) {
    LauncherInterface.translate => l10n.modelTask_translateTitle,
    LauncherInterface.promptReverse => l10n.modelTask_promptReverseTitle,
    LauncherInterface.tagTranslate => l10n.modelTask_tagTranslateTitle,
    LauncherInterface.wikiTranslate => l10n.modelTask_wikiTranslateTitle,
  };
  String descriptionIn(AppLocalizations l10n) => switch (this) {
    LauncherInterface.translate => l10n.modelTask_translateDescription,
    LauncherInterface.promptReverse => l10n.modelTask_promptReverseDescription,
    LauncherInterface.tagTranslate => l10n.modelTask_tagTranslateDescription,
    LauncherInterface.wikiTranslate => l10n.modelTask_wikiTranslateDescription,
  };

  // Stable built-in names keep route fingerprints and caches language-neutral.
  String get _builtinName => switch (this) {
    LauncherInterface.translate => '原文 → 阅读语言',
    LauncherInterface.promptReverse => '阅读语言 → 原文',
    LauncherInterface.tagTranslate => '标签名称翻译',
    LauncherInterface.wikiTranslate => '百科正文翻译',
  };
  String get builtinId => 'builtin:$name';
  String get builtinPrompt => switch (this) {
    LauncherInterface.translate =>
      '''Translate image-generation prompts into the requested reading language. Preserve subject relationships, counts, names, weights, grouping and prompt punctuation. Use glossary entries as optional reference material and judge ambiguous words from context. Prefer clear, natural reading text. Preserve canonical names where a translation would obscure their identity.''',
    LauncherInterface.promptReverse =>
      '''Use the edited reading text as the user's desired description. Compare it with the original reading to identify additions, deletions and replacements. Refer to the original generation prompt and apply only requested changes. Preserve unrelated artist tags, names, weights, groups and prompt style. Glossary entries and selected terms are optional reference material. Return an English generation prompt; do not restore deleted phrases or add unrequested content.''',
    LauncherInterface.tagTranslate =>
      '''Translate complete Danbooru tags into concise, natural labels in the requested reading language. Use category, aliases and wiki context to distinguish characters, artists, works and ordinary terms. Preserve an existing supplied label exactly. Return a separate brief definition grounded in the supplied context, including for name-only requests. Keep explanations out of the label and do not invent a different entity.''',
    LauncherInterface.wikiTranslate =>
      '''Translate the full wiki faithfully into the requested reading language. Preserve existing headings, separate explanations by topic and format long enumerations as Markdown lists. Keep canonical tag references intact. Glossary matches are optional evidence: use context to decide meaningful tag hyperlinks and leave uncertain ordinary words unlinked. Include meaningful current-article references in examples and classifications. Return a source-language presentation preserving original wording with matching layout and contextual links. Usually link the first meaningful mention in continuous prose; examples, related-tag lists and new sections may repeat a complete clickable link. Preserve source URLs and do not invent claims, relationships or external links.''',
  };
  TaskPresetConfig get builtinPreset => TaskPresetConfig(
    id: builtinId,
    name: _builtinName,
    task: this,
    prompt: builtinPrompt,
  );
}

extension TaskPresetDisplay on TaskPresetConfig {
  bool get isBuiltin => id.startsWith('builtin:');
  String displayNameIn(AppLocalizations l10n) =>
      isBuiltin ? task.titleIn(l10n) : name;
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
) {
  final effort = config.interfaceFor(task).reasoningEffort;
  return effort != null && model.availableReasoningEfforts.contains(effort)
      ? model.copyWith(reasoningEffort: effort)
      : model;
}

String reasoningEffortLabel(AppLocalizations l10n, String? value) =>
    switch (value) {
      null => l10n.modelReasoning_serviceDefault,
      'none' || 'off' => l10n.modelReasoning_off,
      'on' => l10n.modelReasoning_on,
      'minimal' => l10n.modelReasoning_minimal,
      'low' => l10n.modelReasoning_low,
      'medium' => l10n.modelReasoning_medium,
      'high' => l10n.modelReasoning_high,
      'xhigh' => l10n.modelReasoning_xhigh,
      'max' => l10n.modelReasoning_max,
      _ => value,
    };
