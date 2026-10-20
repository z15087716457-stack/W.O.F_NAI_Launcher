/// NAI Agent 侧栏 · 界面契约（方案 B「任务指挥台」，原型 `.devin/mockups/agent-redesign/`）
///
/// 这是新侧栏和后端之间唯一的接口：
/// - [AgentViewData]：此刻侧栏要显示的全部数据。由转接层从 controller / provider 组装，界面只读不改。
/// - [AgentActions]：用户在侧栏上能做的全部操作。由转接层接到 controller / provider / 路由。
/// - [AgentSlots]：需要平台能力的包装（系统拖放、图片拖出），由转接层提供。
///
/// 界面文件（本目录除本文件外的 `agent_*.dart`）不 import 任何 provider、service、数据库或路由。
/// 缺字段时在这里加并通知界面方，不要在界面里取数。
///
/// 口径约定：
/// - 文案：界面自己按 l10n 显示固定文案；本契约里的 `String` 字段是**已经可以直接显示**的内容
///   （聊天名、模型名、控制器给出的错误句子、工具参数原文等），界面不再翻译。
/// - 时间：一律本地时间 [DateTime]；界面自己格式化。
/// - 图片：一律 [ImageProvider]，转接层负责解码来源（base64、工作区文件、历史库）。
/// - 「工具名」一律是**去掉前缀的业务名**（`prompt_update`，不是 `mcp__nai_studio__prompt_update`）；
///   CodeMode 调用由转接层按 `nestedCalls` 展开成多个步骤，界面不显示 `codemode` 本身。
library;

import 'package:flutter/widgets.dart';

// ─────────────────────────────── 顶层 ───────────────────────────────

/// 侧栏顶部的三个标签。
enum AgentTab { chat, shelf, memory }

/// 侧栏此刻要显示的全部数据。
@immutable
class AgentViewData {
  const AgentViewData({
    required this.now,
    required this.workspace,
    required this.chat,
    required this.workspaces,
    required this.chats,
    required this.composer,
    required this.thread,
    required this.shelf,
    required this.usage,
    required this.models,
    required this.thinking,
    required this.permission,
    required this.mentions,
    required this.skills,
    this.memory,
    this.draft,
    this.status = AgentRunStatus.idle,
    this.error,
    this.notices = const [],
    this.initError,
    this.loading = false,
    this.revision = 0,
  });

  /// 当前时间（欢迎语「上午好 / 下午好」、相对时间）。测试里固定。
  final DateTime now;

  final AgentWorkspaceInfo workspace;
  final AgentChatInfo chat;

  /// 全部工作区（聊天列表弹层里「切换工作区」一组），含当前工作区。
  final List<AgentWorkspaceInfo> workspaces;

  /// 当前工作区的聊天，新的在前；含当前聊天。
  final List<AgentChatInfo> chats;

  final AgentComposerData composer;

  /// 对话流：按时间顺序的若干轮。空列表 = 空会话（显示欢迎页）。
  final List<AgentTurn> thread;

  /// 「产物」标签页。
  final AgentShelfData shelf;

  /// 「记忆」标签页；null = 不显示这个标签。
  final AgentMemoryData? memory;

  /// 上下文与用量（标签栏右侧的圆环 + 统计弹层）。
  final AgentUsageData usage;

  /// 模型选择器：可选模型（已按服务商分好，只含能用工具的模型）。
  final List<AgentModelOption> models;

  /// 思考档位；[AgentThinkingData.options] 为空 = 这个模型不可调。
  final AgentThinkingData thinking;

  final AgentPermissionMode permission;

  /// `@` 引用候选（草稿各栏、角色、近期图片、积木）。
  final List<AgentMention> mentions;

  /// `/` 技能候选（已启用、可手动调用的 Skill）。
  final List<AgentSkillOption> skills;

  /// 欢迎页的「当前草稿」卡；null = 不显示（例如不在生图页）。
  final AgentDraftSummary? draft;

  final AgentRunStatus status;

  /// 当前聊天的错误句子（控制器已本地化），或「上次任务已中断」；null = 无。
  final String? error;

  /// 扩展通知 / 状态行（已合并成可显示的行）；空 = 不显示通知条。
  final List<String> notices;

  /// 初始化失败（整栏只显示这条和重试）；null = 正常。
  final String? initError;

  /// 还没打开任何聊天（首次启动读取中），整栏显示加载态。
  final bool loading;

  /// 对话内容每变一次 +1（流式文字、步骤状态、待处理卡片）。界面用它判断
  /// 「用户在往上看时来了新内容」，显示「回到最新」。
  final int revision;
}

/// 整个聊天此刻在做什么（标签栏下的细进度条、发送按钮状态、步骤末尾的状态行）。
enum AgentRunStatus {
  idle,

  /// 正在打开聊天 / 启动运行时。
  starting,

  /// 在等服务商请求额度（排队中）。
  waitingSlot,

  /// 模型正在思考或输出、工具正在执行。
  working,

  /// 在等用户：有提问、权限审批或付费确认没处理。
  waitingUser,
}

// ─────────────────────────────── 工作区 / 聊天 ───────────────────────────────

@immutable
class AgentWorkspaceInfo {
  const AgentWorkspaceInfo({
    required this.id,
    required this.name,
    this.chatCount,
  });
  final String id;
  final String name;

  /// 聊天数；null = 未知（不显示数字）。
  final int? chatCount;
}

/// 聊天在列表里的状态点。
enum AgentChatState { idle, running, waitingUser }

@immutable
class AgentChatInfo {
  const AgentChatInfo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.state = AgentChatState.idle,
    this.canExport = false,
  });
  final String id;
  final String title;
  final DateTime createdAt;
  final AgentChatState state;

  /// 已有 Pi 会话文件，可导出 `.jsonl`。
  final bool canExport;
}

// ─────────────────────────────── 对话流 ───────────────────────────────

/// 一轮 = 用户说的一句话 + Agent 对它的全部处理（可能没有，例如刚发出去）。
@immutable
class AgentTurn {
  const AgentTurn({required this.id, required this.user, this.reply});
  final String id;
  final AgentUserMessage user;
  final AgentReply? reply;
}

@immutable
class AgentUserMessage {
  const AgentUserMessage({
    required this.text,
    required this.at,
    this.images = const [],
    this.entryId,
  });

  /// 原文（Markdown）。
  final String text;
  final DateTime at;
  final List<AgentImage> images;

  /// Pi 会话条目 id；非 null 才显示「编辑」（编辑 = 回到这一句重写）。
  final String? entryId;
}

/// Agent 的处理：按发生顺序的若干块。连续的工具调用由转接层合成一个 [AgentStepsBlock]。
@immutable
class AgentReply {
  const AgentReply({
    required this.blocks,
    this.live = false,
    this.canRegenerate = false,
  });
  final List<AgentBlock> blocks;

  /// 还在进行（最后显示「正在思考…」状态行）。
  final bool live;

  /// 最后一轮且没在运行时为 true，显示「重新回答」。
  final bool canRegenerate;
}

sealed class AgentBlock {
  const AgentBlock();
}

/// Markdown 正文。
final class AgentTextBlock extends AgentBlock {
  const AgentTextBlock(this.markdown);
  final String markdown;
}

/// 模型的思考内容（推理过程）。默认折叠，只显示“已思考 · N 字”；
/// [live] = 这一段还在流式输出。
final class AgentThinkingBlock extends AgentBlock {
  const AgentThinkingBlock(this.text, {this.live = false});
  final String text;
  final bool live;
}

/// 一组连续的步骤（工具调用）。
final class AgentStepsBlock extends AgentBlock {
  const AgentStepsBlock(this.steps);
  final List<AgentStep> steps;
}

/// 提示词改动：一次 `prompt_update` 改到的每一栏各一个。
final class AgentDiffBlock extends AgentBlock {
  const AgentDiffBlock(this.diff);
  final AgentPromptDiff diff;
}

/// 角色位置改动：一次 `prompt_update` 改了定位方式或角色位置时出一张，
/// 画成按坐标落点的迷你板（只提示，不带撤销）。
final class AgentPositionBlock extends AgentBlock {
  const AgentPositionBlock({
    required this.id,
    this.customBefore,
    this.customAfter,
    this.marks = const [],
    this.aspect,
  });
  final String id;

  /// 定位方式（true = 自定义坐标，false = AI 选择）；两者都非空且不同才算切换。
  final bool? customBefore, customAfter;

  /// 改动后草稿里的全部角色（顺序 = 角色栏顺序，决定颜色和编号）。
  final List<AgentPositionMark> marks;

  /// 画面宽 / 高；null = 未知（按竖图 2:3 画）。
  final double? aspect;

  bool get modeChanged =>
      customBefore != null &&
      customAfter != null &&
      customBefore != customAfter;

  Iterable<AgentPositionMark> get moved => marks.where((m) => m.moved);
}

/// 一个角色在定位板上的位置；坐标为 0–1（x 向右、y 向下），null = 没有自定义位置。
@immutable
class AgentPositionMark {
  const AgentPositionMark({
    required this.index,
    this.name,
    this.before,
    this.after,
    this.added = false,
  });
  final int index;
  final String? name;
  final Offset? before, after;

  /// 本次新加的角色（没有“原位置”可比）。
  final bool added;

  bool get moved => added ? after != null : before != after;

  /// 九宫方位（0 = 左上 … 4 = 正中 … 8 = 右下），只用于文字说明；
  /// 定位本身是连续坐标（V4 起无极定位）。
  static int region(Offset p) {
    final col = (p.dx * 3).floor().clamp(0, 2);
    final row = (p.dy * 3).floor().clamp(0, 2);
    return row * 3 + col;
  }
}

/// 本轮产物（生成的图、工具出的图）。
final class AgentImagesBlock extends AgentBlock {
  const AgentImagesBlock({
    required this.images,
    this.expected,
    this.anlasSpent,
  });
  final List<AgentImage> images;

  /// 预计张数（生成中显示「3 / 4」和占位格）；null = 已完成或未知。
  final int? expected;

  /// 本轮已花的 Anlas；null = 不显示。
  final int? anlasSpent;
}

enum AgentStepStatus { running, done, failed, waitingUser }

/// 一个工具调用。界面按 [tool] 显示中文动作名（「读取当前草稿」），未知工具显示原名。
@immutable
class AgentStep {
  const AgentStep({
    required this.id,
    required this.tool,
    required this.status,
    this.subject,
    this.duration,
    this.arguments,
    this.result,
    this.images = const [],
  });
  final String id;

  /// 业务工具名，见库注释。外部 MCP 工具给 `server/tool` 原样字符串。
  final String tool;
  final AgentStepStatus status;

  /// 动作对象的一小段说明（「watercolor」「g07.jpg」「80 Anlas」）；null = 不显示。
  final String? subject;
  final Duration? duration;

  /// 参数 / 结果原文（已格式化、已截断、已隐去图片字节），展开步骤时看；null = 没有。
  final String? arguments;
  final String? result;

  /// 结果里的图片。
  final List<AgentImage> images;
}

/// 一栏提示词的改动。
@immutable
class AgentPromptDiff {
  const AgentPromptDiff({
    required this.id,
    required this.field,
    required this.segments,
    this.label,
    this.characterIndex,
    this.state = AgentDiffState.applied,
  });
  final String id;
  final AgentPromptField field;

  /// 角色栏的角色名；没起名时 null，界面按 [characterIndex] 显示「角色 N」。
  final String? label;

  /// 角色栏在角色列表里的位置（从 0 起）；其他栏 null。
  final int? characterIndex;

  /// 改动后的整栏文字，按「不变 / 新增 / 删除」切段。删除段是原来有、现在没有的文字。
  final List<AgentDiffSegment> segments;
  final AgentDiffState state;
}

enum AgentPromptField { prompt, negative, character, characterNegative }

enum AgentDiffState {
  /// 已写入草稿，可撤销。
  applied,

  /// 已撤销。
  undone,

  /// 已写入，但草稿之后又被改过，不能再撤销。
  locked,
}

enum AgentDiffKind { same, added, removed }

@immutable
class AgentDiffSegment {
  const AgentDiffSegment(this.text, [this.kind = AgentDiffKind.same]);
  final String text;
  final AgentDiffKind kind;
}

/// 对话、产物里的一张图。
@immutable
class AgentImage {
  const AgentImage({
    required this.id,
    required this.image,
    this.width,
    this.height,
    this.label,
    this.starred = false,
    this.source = AgentImageSource.generated,
    this.historyId,
  });
  final String id;
  final ImageProvider image;
  final int? width, height;

  /// 角标（「1」「2」）；null = 不显示。
  final String? label;
  final bool starred;
  final AgentImageSource source;

  /// 历史库里的图片 id；非 null 才能「在历史中显示」、拖到画布。
  final String? historyId;
}

enum AgentImageSource { generated, attachment, tool }

// ─────────────────────────────── 待处理卡片 ───────────────────────────────
//
// 这些卡片出现在对话流最后，按 [AgentComposerData.pending] 的顺序（先来先显示）。

sealed class AgentPending {
  const AgentPending(this.id);
  final String id;
}

/// `ask_user` 提问，以及扩展 UI 的 select / confirm / input / editor。
final class AgentAsk extends AgentPending {
  const AgentAsk(super.id, {required this.questions, this.title});

  /// 扩展对话框的标题；`ask_user` 为 null。
  final String? title;
  final List<AgentQuestion> questions;
}

@immutable
class AgentQuestion {
  const AgentQuestion({
    required this.id,
    required this.text,
    this.options = const [],
    this.allowCustom = true,
    this.allowEmpty = false,
    this.multiline = false,
    this.prefill = '',
    this.placeholder,
  });
  final String id, text;
  final List<String> options;
  final bool allowCustom, allowEmpty, multiline;
  final String prefill;
  final String? placeholder;

  /// 和控制器同一条规则：界面用它决定「回答」能不能点。
  bool accepts(String answer) =>
      (allowEmpty || answer.trim().isNotEmpty) &&
      (allowCustom || options.contains(answer));
}

/// 工具权限审批（「询问」模式下的修改、命令等）。
final class AgentApproval extends AgentPending {
  const AgentApproval(
    super.id, {
    required this.tool,
    required this.preview,
    required this.options,
  });

  /// 工具名（去前缀，同 [AgentStep.tool]）。
  final String tool;

  /// 已隐去敏感信息的参数原文。
  final String preview;

  /// 选项原文（「允许一次 / 本会话允许相同调用 / 拒绝」），按顺序显示；最后一个是拒绝类。
  final List<String> options;
}

/// 花 Anlas 之前的确认（生成、变体 / 增强、云端图像工具）。价格由 Studio 计算，模型改不了。
final class AgentGate extends AgentPending {
  const AgentGate(
    super.id, {
    required this.kind,
    required this.expiresAt,
    required this.ready,
    this.title,
    this.model,
    this.width,
    this.height,
    this.requests,
    this.batch,
    this.unitAnlas,
    this.encodingAnlas,
    this.totalAnlas,
    this.balanceAnlas,
    this.account,
    this.prompt,
    this.extra,
    this.source,
    this.changed = false,
  });
  final AgentGateKind kind;

  /// 云端图像工具的工具名（「去背景」「上色」…，已本地化）；生成类为 null，界面按 [kind] 显示。
  final String? title;
  final DateTime expiresAt;

  /// Studio 复核通过（`check()` 没抛错），确认按钮可点。
  final bool ready;
  final String? model;
  final int? width, height;

  /// 请求次数 × 每次张数。
  final int? requests, batch;
  final int? unitAnlas, encodingAnlas, totalAnlas, balanceAnlas;
  final String? account;
  final String? prompt;

  /// 额外一行（本地超分、情绪等），已本地化；null = 不显示。
  final String? extra;

  /// 图生图 / 重绘 / 图像工具的原图。
  final ImageProvider? source;

  /// 报价后配置变了，需要重新准备（确认按钮不可点）。
  final bool changed;
}

enum AgentGateKind {
  text2img,
  img2img,
  inpaint,
  variations,
  enhance,
  imageTool,
}

// ─────────────────────────────── 输入区 ───────────────────────────────

@immutable
class AgentComposerData {
  const AgentComposerData({
    required this.text,
    this.attachments = const [],
    this.queue = const [],
    this.pending = const [],
    this.canSend = false,
    this.blocked,
    this.importing = 0,
    this.canAttachCanvas = false,
    this.enterSends = true,
  });

  /// 输入框草稿（切聊天会换）。界面只在 id 或文字被外部改写时同步，不打断正在输入。
  final String text;
  final List<AgentAttachment> attachments;

  /// 运行中发出去、还在排队的消息。
  final List<AgentQueued> queue;

  /// 等用户处理的卡片（显示在对话流最后）。
  final List<AgentPending> pending;

  /// 能发送：有可用模型、没在导入图片、没在启动、有内容。
  final bool canSend;

  /// 不能发送的原因；null = 没有特别原因（例如只是空输入）。
  final AgentSendBlock? blocked;

  /// 正在导入的图片数（> 0 时显示「正在添加图片」）。
  final int importing;

  /// 画布上当前有选中的图，可以「附上当前图片」。
  final bool canAttachCanvas;

  /// Enter 发送（否则 Ctrl+Enter 发送）。
  final bool enterSends;
}

enum AgentSendBlock { noModel, starting, importing }

@immutable
class AgentAttachment {
  const AgentAttachment({
    required this.id,
    required this.name,
    this.image,
    this.width,
    this.height,
    this.metadata,
  });
  final String id, name;

  /// null = 读取失败（显示破图占位）。
  final ImageProvider? image;
  final int? width, height;

  /// 图片自带的生成信息摘要；null = 没有，不显示「信息」角标。
  /// 完整元数据留给 Agent 的 image_read(metadata_only)。
  final AgentImageInfo? metadata;
}

/// 悬停卡片上的生成信息：每项都可空，只显示有的。卡片可滚动，提示词给全文。
@immutable
class AgentImageInfo {
  const AgentImageInfo({
    this.model,
    this.steps,
    this.scale,
    this.sampler,
    this.seed,
    this.prompt,
    this.negative,
    this.cfgRescale,
    this.noiseSchedule,
    this.smea,
    this.characterPrompts = const [],
    int? characters,
  }) : _characters = characters;
  final String? model, sampler, prompt, negative, noiseSchedule;
  final int? steps, seed;
  final double? scale, cfgRescale;

  /// SMEA 开关描述（如「SMEA」「SMEA DYN」）；没开或不适用时 null。
  final String? smea;

  /// 各角色的提示词与负面，按顺序。
  final List<AgentImageCharacter> characterPrompts;
  final int? _characters;

  /// 角色提示词条数。
  int get characters => _characters ?? characterPrompts.length;
}

@immutable
class AgentImageCharacter {
  const AgentImageCharacter({required this.prompt, this.negative});
  final String prompt;
  final String? negative;
}

enum AgentQueueKind { queued, steer, recovered }

@immutable
class AgentQueued {
  const AgentQueued({required this.id, required this.text, required this.kind});
  final String id, text;
  final AgentQueueKind kind;
}

// ─────────────────────────────── 产物 / 记忆 ───────────────────────────────

@immutable
class AgentShelfData {
  const AgentShelfData({this.groups = const [], this.files = const []});

  /// 按轮分组的图片，新的在前。
  final List<AgentShelfGroup> groups;
  final List<AgentFile> files;

  int get imageCount => groups.fold(0, (n, g) => n + g.images.length);
  int get count => imageCount + files.length;
}

@immutable
class AgentShelfGroup {
  const AgentShelfGroup({
    required this.id,
    required this.title,
    required this.at,
    required this.images,
  });

  /// 这一组来自哪一轮（用户那句话的开头，已截断）。
  final String title;
  final String id;
  final DateTime at;
  final List<AgentImage> images;
}

@immutable
class AgentFile {
  const AgentFile({
    required this.id,
    required this.name,
    this.bytes,
    this.note,
  });
  final String id, name;
  final int? bytes;

  /// 「备份」「Agent 写入」这类短注；null = 不显示。
  final String? note;
}

@immutable
class AgentMemoryData {
  const AgentMemoryData({
    this.globalInstructions = '',
    this.workspaceRules = '',
    this.activeSkills = const [],
  });

  /// 全局指令（所有工作区）。
  final String globalInstructions;

  /// 本工作区规则（`instructions.md`）。
  final String workspaceRules;

  /// 本工作区生效的 Skill 名。
  final List<String> activeSkills;
}

// ─────────────────────────────── 模型 / 用量 / 引用 ───────────────────────────────

@immutable
class AgentModelOption {
  const AgentModelOption({
    required this.providerId,
    required this.modelId,
    required this.label,
    required this.provider,
    this.selected = false,
  });
  final String providerId, modelId, label, provider;
  final bool selected;
}

@immutable
class AgentThinkingData {
  const AgentThinkingData({
    this.options = const [],
    this.selected,
    this.followsModel = true,
  });

  /// (id, 已本地化的名字)，例如 ('high', '高')。
  final List<(String, String)> options;

  /// 当前档位 id；null = 跟随模型设置。
  final String? selected;

  /// 用的是模型设置里的默认档（选择器里「使用模型设置」打勾）。
  final bool followsModel;
}

enum AgentPermissionMode { auto, ask, readonly }

@immutable
class AgentUsageData {
  const AgentUsageData({
    this.tokens,
    this.window,
    this.input,
    this.output,
    this.cacheRead,
    this.cacheWrite,
    this.total,
    this.userMessages,
    this.assistantMessages,
    this.toolCalls,
  });

  /// 当前上下文 tokens 与模型窗口；任一为 null = 未知（圆环显示虚线）。
  final int? tokens, window;

  /// 本聊天累计用量。
  final int? input, output, cacheRead, cacheWrite, total;
  final int? userMessages, assistantMessages, toolCalls;

  double? get fraction => tokens == null || window == null || window! <= 0
      ? null
      : (tokens! / window!).clamp(0.0, 1.0);
}

enum AgentMentionKind { prompt, negative, character, image, block }

@immutable
class AgentMention {
  const AgentMention({
    required this.id,
    required this.kind,
    required this.label,
    this.detail,
    this.image,
  });
  final String id;
  final AgentMentionKind kind;

  /// 插进输入框的名字（「基础提示词」「角色 1」「400精选画师池」）。
  final String label;

  /// 右侧小字（「24 个标签」「832×1216」）。
  final String? detail;
  final ImageProvider? image;
}

@immutable
class AgentSkillOption {
  const AgentSkillOption({required this.name, required this.description});
  final String name, description;
}

/// 欢迎页「当前草稿」卡。
@immutable
class AgentDraftSummary {
  const AgentDraftSummary({
    required this.model,
    required this.prompt,
    this.width,
    this.height,
    this.image,
    this.characters = 0,
    this.blocks = 0,
    this.references = 0,
  });
  final String model;

  /// 正面提示词（界面截一行）。
  final String prompt;
  final int? width, height;

  /// 最近一张图；null = 显示占位。
  final ImageProvider? image;
  final int characters, blocks, references;
}

// ─────────────────────────────── 操作 ───────────────────────────────

/// 返回 false 的回调 = 没做成（界面显示通用失败提示，不改本地状态）。
@immutable
class AgentActions {
  const AgentActions({
    required this.onClose,
    required this.onNewChat,
    required this.onSelectChat,
    required this.onRenameChat,
    required this.onSelectWorkspace,
    required this.onCreateWorkspace,
    required this.onRenameWorkspace,
    required this.onOpenWorkspaceFolder,
    required this.onCompact,
    required this.onExport,
    required this.onOpenSettings,
    required this.onComposerChanged,
    required this.onSend,
    required this.onStop,
    required this.onPickImages,
    required this.onAttachCanvas,
    required this.onAttachImage,
    required this.onPaste,
    required this.onRemoveAttachment,
    required this.onEditQueued,
    required this.onSteerQueued,
    required this.onWithdrawQueued,
    required this.onRestoreQueued,
    required this.onEditMessage,
    required this.onRegenerate,
    required this.onAnswer,
    required this.onCancelAsk,
    required this.onApprove,
    required this.onCancelApproval,
    required this.onDecideGate,
    required this.onUndoDiff,
    required this.onRevealImage,
    required this.onOpenFile,
    required this.onOpenLink,
    required this.onSelectModel,
    required this.onOpenModelSettings,
    required this.onThinking,
    required this.onPermission,
    required this.onRefreshUsage,
    required this.onDismissNotices,
    required this.onRetryInit,
    required this.onEditMemory,
  });

  /// 收起侧栏。
  final VoidCallback onClose;
  final Future<bool> Function() onNewChat;
  final Future<bool> Function(String chatId) onSelectChat;
  final Future<bool> Function(String chatId, String title) onRenameChat;
  final Future<bool> Function(String workspaceId) onSelectWorkspace;
  final Future<bool> Function(String name) onCreateWorkspace;
  final Future<bool> Function(String workspaceId, String name)
  onRenameWorkspace;
  final VoidCallback onOpenWorkspaceFolder;

  /// 压缩当前聊天上下文（运行中不可用，界面已禁用）。
  final Future<bool> Function() onCompact;

  /// 导出当前聊天（转接层负责选保存位置）；用户取消也返回 true。
  final Future<bool> Function() onExport;

  /// 打开「设置 · NAI Agent」。
  final VoidCallback onOpenSettings;

  /// 输入框文字变了（保存草稿；不发送）。
  final void Function(String text) onComposerChanged;

  /// 发送；运行中 [steer] = 作为引导插入，否则排队。
  final Future<bool> Function({required bool steer}) onSend;
  final Future<bool> Function() onStop;

  /// 选文件添加图片（转接层开文件选择器）。
  final Future<bool> Function() onPickImages;

  /// 附上画布当前选中的图。
  final Future<bool> Function() onAttachCanvas;

  /// 把对话 / 产物 / `@` 引用里的一张图附到输入区（[AgentImage.id] 或 [AgentMention.id]）。
  final Future<bool> Function(String imageId) onAttachImage;

  /// Ctrl+V / 右键粘贴：转接层先读剪贴板图片并附上；返回要插进输入框的文字
  /// （没有文字或已当图片处理返回 null）。
  final Future<String?> Function() onPaste;
  final Future<bool> Function(String attachmentId) onRemoveAttachment;

  final Future<bool> Function(String queueId, String text) onEditQueued;
  final Future<bool> Function(String queueId) onSteerQueued;
  final Future<bool> Function(String queueId) onWithdrawQueued;

  /// 把恢复的排队消息放回输入框（输入框非空时转接层返回 false）。
  final Future<bool> Function(String queueId) onRestoreQueued;

  /// 回到这句话重写（文字放回输入框）。
  final Future<bool> Function(String entryId) onEditMessage;

  /// 重新回答最后一轮。
  final Future<bool> Function() onRegenerate;

  /// 回答提问：问题 id → 答案。
  final void Function(String askId, Map<String, String> answers) onAnswer;
  final void Function(String askId) onCancelAsk;

  /// 审批：选了 [AgentApproval.options] 里的哪一项。
  final void Function(String approvalId, String option) onApprove;
  final void Function(String approvalId) onCancelApproval;

  /// 付费确认：true = 确认执行。
  final void Function(String gateId, {required bool confirm}) onDecideGate;

  /// 撤销一栏提示词改动（草稿已变时转接层返回 false）。
  final Future<bool> Function(String diffId) onUndoDiff;

  /// 在历史栏里选中这张图（[AgentImage.historyId] 非 null 时可用）。
  final void Function(String imageId) onRevealImage;
  final void Function(String fileId) onOpenFile;

  /// Markdown 链接：http(s) 或工作区内文件。
  final void Function(String url) onOpenLink;

  final Future<bool> Function(String providerId, String modelId) onSelectModel;
  final VoidCallback onOpenModelSettings;

  /// 思考档位；null = 跟随模型设置。
  final Future<bool> Function(String? effort) onThinking;
  final Future<bool> Function(AgentPermissionMode mode) onPermission;

  /// 打开用量弹层前刷新一次。
  final Future<void> Function() onRefreshUsage;
  final VoidCallback onDismissNotices;
  final VoidCallback onRetryInit;

  /// 「记忆」页的编辑：打开设置里对应的位置。
  final void Function(AgentMemoryTarget target) onEditMemory;
}

enum AgentMemoryTarget { global, workspace, skills }

/// 需要平台能力的包装，由转接层提供；null = 不包。
@immutable
class AgentSlots {
  const AgentSlots({this.dropTarget, this.imageDrag});

  /// 包住整个侧栏的系统拖放区（外部文件、历史缩略图拖进来 = 附图）。
  /// [onHover] 由转接层在拖入 / 离开时调用，界面据此显示「松开以附加」。
  final Widget Function(
    BuildContext context,
    void Function(bool hovering) onHover,
    Widget child,
  )?
  dropTarget;

  /// 产物图拖出（拖到画布 / 资源管理器）。
  final Widget Function(BuildContext context, AgentImage image, Widget child)?
  imageDrag;
}
