import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../core/nai_agent/mcp_config.dart';
import '../../../core/utils/app_language.dart';
import '../../../core/utils/localization_extension.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

const naiAgentDefaultPromptVersion = '2026-10-18.1';
const _defaultSystemPromptZh = '''
你是 NAI Agent，W.O.F NAI Studio 内的创作与工作区助手。用用户的语言，直接完成已授权的任务，说明结果与不确定性。
涉及当前草稿、参数或图片时先用 studio_context 读取；修改沿工具的版本检查与回读。
Studio 业务操作通过 codemode 调用 mcp__nai_studio，用法见 nai-studio skill；写或改提示词先读 nai-prompt skill。
实际生成与付费操作必须有用户在界面上的确认；缺关键输入用 ask_user。不把计划、失败或未知费用说成完成。
''';
const _defaultSystemPromptEn = '''
You are NAI Agent, the creative and workspace assistant inside W.O.F NAI Studio. Reply in the user's language, complete authorized tasks directly, and state results and uncertainties.
When the current draft, parameters or images matter, read them first with studio_context; make changes through the tools' version checks and read back.
Studio operations go through codemode calling mcp__nai_studio; see the nai-studio skill for usage. Read the nai-prompt skill before writing or revising prompts.
Actual generation and paid operations require the user's confirmation in the UI; use ask_user when key input is missing. Never report plans, failures or unknown costs as done.
''';

/// Built-in base prompt: Chinese for the Chinese interfaces, English otherwise.
/// Saved custom prompts are never translated.
String naiAgentDefaultSystemPromptFor(AppLanguage language) =>
    language.isChinese ? _defaultSystemPromptZh : _defaultSystemPromptEn;
String get naiAgentDefaultSystemPrompt =>
    naiAgentDefaultSystemPromptFor(currentAppLanguage);

/// Skill names follow the Agent Skills spec; the folder name is the identity.
final naiAgentSkillName = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
const naiAgentBuiltinSkillNames = {'nai-studio', 'nai-prompt'};

class AgentExtensionConfig {
  const AgentExtensionConfig({required this.path, this.enabled = true});
  final String path;
  final bool enabled;
  Map<String, dynamic> toJson() => {'path': path, 'enabled': enabled};
}

class AgentSettings {
  const AgentSettings({
    this.providerId = '',
    this.modelId = '',
    this.customSystemPrompt,
    this.globalInstructions = '',
    this.systemPromptPrefix = '',
    this.selectedWorkspaceId,
    this.panelExpanded = false,
    this.panelWidth = 520,
    this.panelLayoutVersion = 1,
    this.enterToSend = true,
    this.maxRequestsPerRun = 32,
    this.permissionMode = 'auto',
    this.reasoningEfforts = const {},
    this.extensions = const [],
    this.mcpServers = const [],
    this.studioMcpEnabled = true,
    this.studioMcpExposure = 'codemode',
    this.disabledSkills = const [],
    this.skillModes = const {},
  });
  final String providerId, modelId;
  final String? customSystemPrompt, selectedWorkspaceId;
  final String globalInstructions, systemPromptPrefix;
  final bool panelExpanded, enterToSend;
  final double panelWidth;
  final int panelLayoutVersion;
  final int maxRequestsPerRun;
  final String permissionMode;
  final Map<String, String> reasoningEfforts;
  final List<AgentExtensionConfig> extensions;
  final List<AgentMcpServer> mcpServers;
  final bool studioMcpEnabled;
  final String studioMcpExposure;

  /// `<global|workspace>/<name>` keys the user switched off; built-ins stay on.
  final List<String> disabledSkills;

  /// `<source>/<name>` -> `auto` | `manual`; missing keys follow SKILL.md.
  final Map<String, String> skillModes;
  String get modelSelectionKey => jsonEncode([providerId, modelId]);
  String? get reasoningEffort => reasoningEfforts[modelSelectionKey];
  List<String> get enabledExtensionPaths => [
    for (final extension in extensions)
      if (extension.enabled) extension.path,
  ];
  String get extensionSignature => jsonEncode({
    'extensions': enabledExtensionPaths,
    'disabledSkills': disabledSkills,
    'skillModes': skillModes,
    'studioMcpEnabled': studioMcpEnabled,
    'studioMcpExposure': studioMcpExposure,
    'mcpServers': mcpServers.map((server) => server.toJson()).toList(),
  });
  String get systemPrompt => customSystemPrompt ?? naiAgentDefaultSystemPrompt;
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'promptVersion': naiAgentDefaultPromptVersion,
    'providerId': providerId,
    'modelId': modelId,
    'customSystemPrompt': customSystemPrompt,
    'globalInstructions': globalInstructions,
    'systemPromptPrefix': systemPromptPrefix,
    'selectedWorkspaceId': selectedWorkspaceId,
    'panelExpanded': panelExpanded,
    'panelWidth': panelWidth,
    'panelLayoutVersion': panelLayoutVersion,
    'enterToSend': enterToSend,
    'maxRequestsPerRun': maxRequestsPerRun,
    'permissionMode': permissionMode,
    'reasoningEfforts': reasoningEfforts,
    'extensions': extensions.map((extension) => extension.toJson()).toList(),
    'mcpServers': mcpServers.map((server) => server.toJson()).toList(),
    'studioMcpEnabled': studioMcpEnabled,
    'studioMcpExposure': studioMcpExposure,
    'disabledSkills': disabledSkills,
    'skillModes': skillModes,
  };
  factory AgentSettings.fromJson(Map<String, dynamic> value) => AgentSettings(
    providerId: value['providerId'] as String? ?? '',
    modelId: value['modelId'] as String? ?? '',
    customSystemPrompt: value['customSystemPrompt'] as String?,
    globalInstructions: value['globalInstructions'] as String? ?? '',
    systemPromptPrefix: value['systemPromptPrefix'] as String? ?? '',
    permissionMode:
        const {'auto', 'ask', 'readonly'}.contains(value['permissionMode'])
        ? value['permissionMode'] as String
        : value['permissionMode'] == null
        ? 'auto'
        : 'ask',
    reasoningEfforts: Map.unmodifiable({
      for (final entry in (value['reasoningEfforts'] as Map? ?? {}).entries)
        if (entry.key is String &&
            const {
              'none',
              'minimal',
              'low',
              'medium',
              'high',
              'xhigh',
              'max',
            }.contains(entry.value))
          entry.key as String: entry.value as String,
    }),
    studioMcpEnabled: value['studioMcpEnabled'] != false,
    studioMcpExposure: naiAgentMcpExposures.contains(value['studioMcpExposure'])
        ? value['studioMcpExposure'] as String
        : 'codemode',
    mcpServers: List.unmodifiable([
      for (final server in value['mcpServers'] as List? ?? [])
        AgentMcpServer.fromJson(Map<String, dynamic>.from(server as Map)),
    ]),
    selectedWorkspaceId: value['selectedWorkspaceId'] as String?,
    panelExpanded: value['panelExpanded'] == true,
    panelWidth: _panelWidth(value),
    enterToSend: value['enterToSend'] != false,
    maxRequestsPerRun: ((value['maxRequestsPerRun'] as num?)?.toInt() ?? 32)
        .clamp(1, 200),
    extensions: List.unmodifiable([
      for (final row in value['extensions'] as List? ?? [])
        if (row is Map &&
            row['path'] is String &&
            p.isAbsolute(row['path'] as String))
          AgentExtensionConfig(
            path: row['path'] as String,
            enabled: row['enabled'] != false,
          ),
    ]),
    disabledSkills: List.unmodifiable({
      for (final key in value['disabledSkills'] as List? ?? [])
        if (key is String && isSkillKey(key)) key,
    }),
    skillModes: Map.unmodifiable({
      for (final entry in (value['skillModes'] as Map? ?? {}).entries)
        if (entry.key is String &&
            isSkillKey(entry.key as String) &&
            const {'auto', 'manual'}.contains(entry.value))
          entry.key as String: entry.value as String,
    }),
  );

  static bool isSkillKey(String key) {
    final parts = key.split('/');
    return parts.length == 2 &&
        const {'builtin', 'global', 'workspace'}.contains(parts[0]) &&
        parts[1].isNotEmpty &&
        parts[1].length <= 128 &&
        parts[1] != '.' &&
        parts[1] != '..' &&
        !parts[1].contains(RegExp(r'[\\/:*?"<>|]'));
  }

  static double _panelWidth(Map<String, dynamic> value) {
    final stored = (value['panelWidth'] as num?)?.toDouble();
    var width = stored != null && stored.isFinite ? stored : 520.0;
    // One-time migration to the wider layout; subsequent user sizes survive.
    if ((value['panelLayoutVersion'] as num? ?? 0) < 1 && width < 520) {
      width = 520;
    }
    return width.clamp(320.0, 1280.0);
  }
}

class AgentWorkspace {
  const AgentWorkspace({
    required this.id,
    required this.name,
    required this.directory,
    required this.createdAt,
    this.customSystemPrompt,
    this.lastSessionId,
  });
  final String id, name;
  final Directory directory;
  final DateTime createdAt;
  final String? customSystemPrompt, lastSessionId;
  Directory get sessions => Directory(p.join(directory.path, 'sessions'));
  Directory get agentDirectory => Directory(p.join(directory.path, '.agent'));
  Directory get skills => Directory(p.join(directory.path, 'skills'));
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'customSystemPrompt': customSystemPrompt,
    'lastSessionId': lastSessionId,
  };
}

class AgentAttachment {
  const AgentAttachment({
    required this.id,
    required this.name,
    required this.relativePath,
    required this.mimeType,
    required this.bytes,
    required this.sha256Hex,
    this.width,
    this.height,
    this.metadata,
  });
  final String id, name, relativePath, mimeType, sha256Hex;
  final int bytes;
  final int? width, height;
  final Map<String, dynamic>? metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': relativePath,
    'mimeType': mimeType,
    'bytes': bytes,
    'sha256': sha256Hex,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (metadata != null) 'metadata': metadata,
  };
  factory AgentAttachment.fromJson(Map<String, dynamic> value) =>
      AgentAttachment(
        id: value['id'] as String,
        name: value['name'] as String,
        relativePath: value['path'] as String,
        mimeType: value['mimeType'] as String,
        bytes: value['bytes'] as int,
        sha256Hex: value['sha256'] as String,
        width: value['width'] as int?,
        height: value['height'] as int?,
        metadata: value['metadata'] is Map
            ? Map<String, dynamic>.from(value['metadata'] as Map)
            : null,
      );
}

class AgentChat {
  const AgentChat({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.createdAt,
    this.sessionFile,
  });
  final String id, workspaceId, title;
  final DateTime createdAt;

  /// A reference to official Pi history, never copied conversation messages.
  final String? sessionFile;
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'id': id,
    'workspaceId': workspaceId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'sessionFile': sessionFile,
  };
}

/// UI-only state. Pi JSONL remains the sole conversation history.
class AgentComposerState {
  const AgentComposerState({
    this.text = '',
    this.attachments = const [],
    this.pending = const [],
    this.interrupted = false,
    this.wasRunning = false,
  });
  final String text;
  final List<AgentAttachment> attachments;
  final List<Map<String, dynamic>> pending;
  final bool interrupted, wasRunning;
  Map<String, dynamic> toJson() => {
    'schema': 1,
    'text': text,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'pending': pending,
    'wasRunning': wasRunning,
    'interrupted': interrupted,
  };
  factory AgentComposerState.fromJson(
    Map<String, dynamic> value, {
    bool recovered = false,
  }) => AgentComposerState(
    text: value['text'] as String? ?? '',
    attachments: [
      for (final a in value['attachments'] as List? ?? [])
        AgentAttachment.fromJson(Map<String, dynamic>.from(a as Map)),
    ],
    pending: [
      for (final message in value['pending'] as List? ?? [])
        Map<String, dynamic>.from(message as Map),
    ],
    interrupted:
        value['interrupted'] == true ||
        (recovered && value['wasRunning'] == true),
    wasRunning: recovered ? false : value['wasRunning'] == true,
  );
}

class AgentSkillExists implements Exception {
  const AgentSkillExists(this.name);
  final String name;
  @override
  String toString() => 'Skill already exists: $name';
}

/// No credentials, secondary chat format, automatic replay or generation state.
class AgentWorkspaceStore {
  AgentWorkspaceStore(this.root, {Directory? builtinSkillsDirectory})
    : builtinSkillsDirectory =
          builtinSkillsDirectory ??
          Directory(p.join(root.parent.path, 'tools', 'nai-agent', 'skills'));
  final Directory root;

  /// Read-only skills shipped with the runtime; replaced on each update.
  final Directory builtinSkillsDirectory;

  /// User skills shared by every workspace; kept with agent-data across updates.
  Directory get globalSkillsDirectory => Directory(p.join(root.path, 'skills'));
  Future<void> _tail = Future.value();
  static final _ids = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,100}$');

  Future<T> _write<T>(Future<T> Function() action) {
    final task = _tail.then((_) => action());
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  static void _id(String id) {
    if (!_ids.hasMatch(id)) {
      throw const FormatException('Invalid Agent identity');
    }
  }

  Directory workspaceDirectory(String id) {
    _id(id);
    return Directory(p.join(root.path, 'workspaces', id));
  }

  File _metadata(String id) =>
      File(p.join(workspaceDirectory(id).path, 'workspace.json'));

  Future<void> _atomic(File file, Map<String, dynamic> value) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.${const Uuid().v4()}.tmp');
    try {
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(value),
        flush: true,
      );
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<Map<String, dynamic>> _read(File file) async {
    if (!await file.exists()) return {};
    final value = jsonDecode(await file.readAsString());
    if (value is! Map) throw const FormatException('Invalid Agent state');
    return Map<String, dynamic>.from(value);
  }

  Future<AgentSettings> readSettings() async => AgentSettings.fromJson(
    await _read(File(p.join(root.path, 'settings.json'))),
  );
  Future<void> saveSettings(AgentSettings settings) => _write(() async {
    await _saveSettings(settings);
  });
  Future<AgentSettings> patchSettings(Map<String, dynamic> changes) =>
      patchSettingsChecked(changes);

  Future<AgentSettings> patchSettingsChecked(
    Map<String, dynamic> changes, {
    Map<String, dynamic>? expected,
  }) => _write(() async {
    final current = await readSettings();
    if (expected != null) {
      final values = current.toJson();
      for (final entry in expected.entries) {
        if (!const DeepCollectionEquality().equals(
          values[entry.key],
          entry.value,
        )) {
          throw StateError('Agent settings changed while editing');
        }
      }
    }
    final settings = AgentSettings.fromJson({
      ...current.toJson(),
      ...changes,
      'reasoningEfforts': {
        ...current.reasoningEfforts,
        ...?changes['reasoningEfforts'] as Map?,
      },
    });
    await _saveSettings(settings);
    return settings;
  });

  /// Mutate only one explicit user-selected extension against the latest settings.
  Future<AgentSettings> configureExtension(
    String path, {
    bool? enabled,
    bool remove = false,
  }) => _write(() async {
    if (!p.isAbsolute(path)) {
      throw const FormatException('Extension path must be absolute');
    }
    final current = await readSettings();
    final key = p.normalize(path);
    bool matches(AgentExtensionConfig value) => Platform.isWindows
        ? p.normalize(value.path).toLowerCase() == key.toLowerCase()
        : p.normalize(value.path) == key;
    final existing = current.extensions.where(matches).firstOrNull;
    if (existing == null && !remove) {
      final type = await FileSystemEntity.type(path);
      if (type != FileSystemEntityType.directory &&
          (type != FileSystemEntityType.file ||
              !{
                '.ts',
                '.js',
                '.mjs',
                '.cjs',
              }.contains(p.extension(path).toLowerCase()))) {
        throw const FormatException('Select a Pi extension file or directory');
      }
      if (current.extensions.length >= 64) {
        throw const FormatException('Too many extensions');
      }
    }
    final extensions = [
      for (final value in current.extensions)
        if (!matches(value))
          value
        else if (!remove)
          AgentExtensionConfig(
            path: value.path,
            enabled: enabled ?? value.enabled,
          ),
      if (existing == null && !remove)
        AgentExtensionConfig(path: key, enabled: enabled ?? true),
    ];
    final result = AgentSettings.fromJson({
      ...current.toJson(),
      'extensions': extensions.map((value) => value.toJson()).toList(),
    });
    await _saveSettings(result);
    return result;
  });
  Future<void> _saveSettings(AgentSettings settings) async {
    final file = File(p.join(root.path, 'settings.json'));
    final old = await _read(file);
    if (old.isNotEmpty &&
        (old['customSystemPrompt'] != settings.customSystemPrompt ||
            (old['globalInstructions'] ?? '') != settings.globalInstructions ||
            (old['systemPromptPrefix'] ?? '') != settings.systemPromptPrefix)) {
      await _atomic(
        File(p.join(root.path, 'prompt-history', '${const Uuid().v4()}.json')),
        {
          'savedAt': DateTime.now().toIso8601String(),
          'promptVersion': old['promptVersion'],
          'customSystemPrompt': old['customSystemPrompt'],
          'globalInstructions': old['globalInstructions'] ?? '',
          'systemPromptPrefix': old['systemPromptPrefix'] ?? '',
        },
      );
    }
    await _atomic(file, settings.toJson());
  }

  Future<AgentWorkspace> createWorkspace(String name) => _write(() async {
    if (name.trim().isEmpty) {
      throw const FormatException('Workspace name is empty');
    }
    final id = const Uuid().v4();
    // One stable ID governs the path; display names are never paths.
    final actual = AgentWorkspace(
      id: id,
      name: name.trim(),
      directory: workspaceDirectory(id),
      createdAt: DateTime.now(),
    );
    for (final child in [
      'notes',
      'outputs',
      'attachments',
      'sessions',
      'snapshots',
      'skills',
      '.agent',
      'ui',
    ]) {
      await Directory(
        p.join(actual.directory.path, child),
      ).create(recursive: true);
    }
    await File(
      p.join(actual.directory.path, 'instructions.md'),
    ).writeAsString('', flush: true);
    await _atomic(_metadata(actual.id), actual.toJson());
    return actual;
  });
  Future<AgentWorkspace> getWorkspace(String id) async {
    final value = await _read(_metadata(id));
    if (value['id'] != id) {
      throw const FormatException('Workspace is missing or identity differs');
    }
    final directory = workspaceDirectory(id);
    final resolved = await directory.resolveSymbolicLinks();
    final parent = await Directory(
      p.join(root.path, 'workspaces'),
    ).resolveSymbolicLinks();
    if (!p.isWithin(parent, resolved)) {
      throw const FormatException('Workspace directory leaves Agent data');
    }
    return AgentWorkspace(
      id: id,
      name: value['name'] as String,
      directory: directory,
      createdAt: DateTime.parse(value['createdAt'] as String),
      customSystemPrompt: value['customSystemPrompt'] as String?,
      lastSessionId: value['lastSessionId'] as String?,
    );
  }

  Future<List<AgentWorkspace>> listWorkspaces() async {
    final parent = Directory(p.join(root.path, 'workspaces'));
    if (!await parent.exists()) return [];
    final result = <AgentWorkspace>[];
    await for (final item in parent.list(followLinks: false)) {
      if (item is Directory && _ids.hasMatch(p.basename(item.path))) {
        result.add(await getWorkspace(p.basename(item.path)));
      }
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Future<AgentWorkspace> updateWorkspace(
    String id, {
    String? name,
    String? customSystemPrompt,
    bool resetPrompt = false,
    String? lastSessionId,
    bool checkPrompt = false,
    String? expectedPrompt,
    bool requireSelected = false,
  }) => _write(() async {
    final old = await getWorkspace(id);
    if (checkPrompt && old.customSystemPrompt != expectedPrompt) {
      throw StateError('Workspace prompt changed while editing');
    }
    if (requireSelected && (await readSettings()).selectedWorkspaceId != id) {
      throw StateError('Selected workspace changed while editing');
    }
    if (name != null && name.trim().isEmpty) {
      throw const FormatException('Workspace name is empty');
    }
    if (lastSessionId != null) _id(lastSessionId);
    final value = AgentWorkspace(
      id: id,
      name: name?.trim() ?? old.name,
      directory: old.directory,
      createdAt: old.createdAt,
      customSystemPrompt: resetPrompt
          ? null
          : customSystemPrompt ?? old.customSystemPrompt,
      lastSessionId: lastSessionId ?? old.lastSessionId,
    );
    if (value.customSystemPrompt != old.customSystemPrompt) {
      await _atomic(
        File(
          p.join(
            old.directory.path,
            '.agent',
            'prompt-history',
            '${const Uuid().v4()}.json',
          ),
        ),
        {
          'savedAt': DateTime.now().toIso8601String(),
          'customSystemPrompt': old.customSystemPrompt,
        },
      );
    }
    await _atomic(_metadata(id), value.toJson());
    return value;
  });
  Future<String> effectiveSystemPrompt(String workspaceId) async {
    final workspace = await getWorkspace(workspaceId);
    final settings = await readSettings();
    final instructions = await File(
      p.join(workspace.directory.path, 'instructions.md'),
    ).readAsString();
    final zh = currentAppLanguage.isChinese;
    return [
      if (settings.systemPromptPrefix.trim().isNotEmpty)
        settings.systemPromptPrefix,
      workspace.customSystemPrompt ?? settings.systemPrompt,
      if (settings.globalInstructions.trim().isNotEmpty)
        '${zh ? '用户的全局指令：' : 'User global instructions:'}\n'
            '${settings.globalInstructions}',
      if (instructions.trim().isNotEmpty)
        '${zh ? '用户的工作区规则：' : 'User workspace rules:'}\n$instructions',
      zh
          ? '工作区笔记在 notes/，产物在 outputs/。'
          : 'Workspace notes live in notes/; outputs go to outputs/.',
    ].join('\n\n');
  }

  /// Host-side skill sources and switches. Pi formats the catalog itself.
  Map<String, dynamic> skillConfig(
    AgentWorkspace workspace,
    AgentSettings settings,
  ) {
    return {
      'builtinDirectory': builtinSkillsDirectory.absolute.path,
      'globalDirectory': globalSkillsDirectory.absolute.path,
      'workspaceDirectory': workspace.skills.absolute.path,
      'disabled': settings.disabledSkills,
      'modes': settings.skillModes,
    };
  }

  Directory skillSourceDirectory(String source, {String? workspaceId}) =>
      switch (source) {
        'builtin' => builtinSkillsDirectory,
        'global' => globalSkillsDirectory,
        'workspace' => Directory(
          p.join(workspaceDirectory(workspaceId!).path, 'skills'),
        ),
        _ => throw FormatException('Invalid skill source: $source'),
      };

  /// Switch one user skill or change its invocation mode against the latest settings.
  Future<AgentSettings> configureSkill(
    String key, {
    bool? enabled,
    String? mode,
  }) => _write(() async {
    if (!AgentSettings.isSkillKey(key)) {
      throw const FormatException('Invalid skill key');
    }
    if (mode != null && !const {'auto', 'manual'}.contains(mode)) {
      throw const FormatException('Invalid skill mode');
    }
    final current = await readSettings();
    final result = AgentSettings.fromJson({
      ...current.toJson(),
      if (enabled != null)
        'disabledSkills': [
          for (final value in current.disabledSkills)
            if (value != key) value,
          if (!enabled) key,
        ],
      if (mode != null) 'skillModes': {...current.skillModes, key: mode},
    });
    await _saveSettings(result);
    return result;
  });

  /// Copy a user-selected skill folder (with SKILL.md) into a skill source.
  /// Never overwrites; the original folder is neither linked nor watched.
  Future<String> importSkill(
    String folder, {
    required String source,
    String? workspaceId,
  }) => _write(() async {
    final from = Directory(folder);
    if (!p.isAbsolute(folder) || !await from.exists()) {
      throw const FormatException('Select a skill folder');
    }
    if (!await File(p.join(from.path, 'SKILL.md')).exists()) {
      throw const FormatException('The folder has no SKILL.md');
    }
    final name = p.basename(p.normalize(from.path));
    final target = await _newSkillTarget(source, name, workspaceId);
    await _copyTree(from, target);
    return name;
  });

  /// Create an empty user skill with valid front matter.
  Future<String> createSkill(
    String name, {
    required String source,
    String? workspaceId,
  }) => _write(() async {
    final target = await _newSkillTarget(source, name, workspaceId);
    final temporary = Directory('${target.path}.${const Uuid().v4()}.tmp');
    try {
      await temporary.create(recursive: true);
      await File(p.join(temporary.path, 'SKILL.md')).writeAsString(
        '---\nname: $name\n'
        'description: Describe when the Agent should use this skill.\n'
        '---\n\n# $name\n',
        flush: true,
      );
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    }
    return name;
  });

  /// Copy a built-in skill to the global folder; the copy then replaces it.
  Future<String> copyBuiltinSkill(String name) => _write(() async {
    if (!naiAgentBuiltinSkillNames.contains(name)) {
      throw const FormatException('Unknown built-in skill');
    }
    final from = Directory(p.join(builtinSkillsDirectory.path, name));
    if (!await from.exists()) {
      throw const FormatException('Built-in skill missing');
    }
    final target = await _newSkillTarget('global', name, null);
    await _copyTree(from, target);
    return name;
  });

  /// Move a user skill folder into `skill-trash/`; nothing is deleted outright.
  Future<AgentSettings> removeSkill(
    String key, {
    String? workspaceId,
  }) => _write(() async {
    if (!AgentSettings.isSkillKey(key) || key.startsWith('builtin/')) {
      throw const FormatException('Only user skills can be removed');
    }
    final parts = key.split('/');
    final folder = Directory(
      p.join(
        skillSourceDirectory(parts[0], workspaceId: workspaceId).path,
        parts[1],
      ),
    );
    if (await folder.exists()) {
      final trash = Directory(
        p.join(
          root.path,
          'skill-trash',
          '${DateTime.now().millisecondsSinceEpoch}-${parts[0]}-${parts[1]}',
        ),
      );
      await trash.parent.create(recursive: true);
      await folder.rename(trash.path);
    }
    final current = await readSettings();
    final result = AgentSettings.fromJson({
      ...current.toJson(),
      'disabledSkills': [
        for (final value in current.disabledSkills)
          if (value != key) value,
      ],
      'skillModes': {...current.skillModes}..remove(key),
    });
    await _saveSettings(result);
    return result;
  });

  Future<Directory> _newSkillTarget(
    String source,
    String name,
    String? workspaceId,
  ) async {
    if (source != 'global' && source != 'workspace') {
      throw FormatException('Invalid skill source: $source');
    }
    if (!naiAgentSkillName.hasMatch(name) || name.length > 64) {
      throw const FormatException('Invalid skill name');
    }
    final parent = skillSourceDirectory(source, workspaceId: workspaceId);
    final target = Directory(p.join(parent.path, name));
    if (await FileSystemEntity.type(target.path) !=
        FileSystemEntityType.notFound) {
      throw AgentSkillExists(name);
    }
    await parent.create(recursive: true);
    return target;
  }

  static Future<void> _copyTree(Directory from, Directory to) async {
    final temporary = Directory('${to.path}.${const Uuid().v4()}.tmp');
    try {
      await temporary.create(recursive: true);
      await for (final entity in from.list(
        recursive: true,
        followLinks: false,
      )) {
        final relative = p.relative(entity.path, from: from.path);
        if (p
            .split(relative)
            .any((part) => part == '.git' || part == 'node_modules')) {
          continue;
        }
        final target = p.join(temporary.path, relative);
        if (entity is Directory) {
          await Directory(target).create(recursive: true);
        } else if (entity is File) {
          await File(target).parent.create(recursive: true);
          await entity.copy(target);
        }
      }
      await temporary.rename(to.path);
    } finally {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    }
  }

  Future<AgentChat> createChat(String workspaceId, String title) =>
      _write(() async {
        await getWorkspace(workspaceId);
        final chat = AgentChat(
          id: const Uuid().v4(),
          workspaceId: workspaceId,
          title: title.trim(),
          createdAt: DateTime.now(),
        );
        await _atomic(
          File(
            p.join(
              workspaceDirectory(workspaceId).path,
              'ui',
              'chats',
              '${chat.id}.json',
            ),
          ),
          chat.toJson(),
        );
        return chat;
      });
  Future<List<AgentChat>> listChats(String workspaceId) async {
    await getWorkspace(workspaceId);
    final dir = Directory(
      p.join(workspaceDirectory(workspaceId).path, 'ui', 'chats'),
    );
    if (!await dir.exists()) return [];
    final result = <AgentChat>[];
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File || p.extension(file.path) != '.json') continue;
      final value = await _read(file);
      final id = value['id'] as String;
      _id(id);
      if (value['workspaceId'] != workspaceId ||
          p.basename(file.path) != '$id.json') {
        throw const FormatException('Chat identity differs');
      }
      result.add(
        AgentChat(
          id: id,
          workspaceId: workspaceId,
          title: value['title'] as String,
          createdAt: DateTime.parse(value['createdAt'] as String),
          sessionFile: value['sessionFile'] as String?,
        ),
      );
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<AgentChat> updateChat(
    String workspaceId,
    String chatId, {
    String? title,
    String? sessionFile,
  }) => _write(() async {
    _id(chatId);
    final chat = (await listChats(
      workspaceId,
    )).where((c) => c.id == chatId).firstOrNull;
    if (chat == null) throw const FormatException('Chat missing');
    if (sessionFile != null &&
        (p.isAbsolute(sessionFile) ||
            p.dirname(p.normalize(sessionFile)) != 'sessions' ||
            p.extension(sessionFile) != '.jsonl')) {
      throw const FormatException(
        'Pi session reference leaves workspace sessions',
      );
    }
    final value = AgentChat(
      id: chatId,
      workspaceId: workspaceId,
      title: title ?? chat.title,
      createdAt: chat.createdAt,
      sessionFile: sessionFile ?? chat.sessionFile,
    );
    await _atomic(
      File(
        p.join(
          workspaceDirectory(workspaceId).path,
          'ui',
          'chats',
          '$chatId.json',
        ),
      ),
      value.toJson(),
    );
    return value;
  });

  File _composer(String workspaceId, String sessionId) {
    _id(sessionId);
    return File(
      p.join(workspaceDirectory(workspaceId).path, 'ui', '$sessionId.json'),
    );
  }

  Future<AgentComposerState> readComposer(
    String workspaceId,
    String sessionId,
  ) async {
    await getWorkspace(workspaceId);
    return AgentComposerState.fromJson(
      await _read(_composer(workspaceId, sessionId)),
      recovered: true,
    );
  }

  Future<void> saveComposer(
    String workspaceId,
    String sessionId,
    AgentComposerState state,
  ) => _write(() async {
    await getWorkspace(workspaceId);
    await _atomic(_composer(workspaceId, sessionId), state.toJson());
  });
  Future<AgentAttachment> addAttachment(
    String workspaceId,
    String sessionId, {
    required String name,
    required Uint8List bytes,
    required String mimeType,
    int? width,
    int? height,
    Map<String, dynamic>? metadata,
  }) => _write(() async {
    _id(sessionId);
    if (bytes.isEmpty ||
        bytes.length > 64 * 1024 * 1024 ||
        !{
          'image/png',
          'image/jpeg',
          'image/webp',
          'image/gif',
          'image/bmp',
        }.contains(mimeType)) {
      throw const FormatException('Unsupported or oversized image attachment');
    }
    final workspace = await getWorkspace(workspaceId);
    final id = const Uuid().v4();
    final suffix = switch (mimeType) {
      'image/jpeg' => '.jpg',
      'image/webp' => '.webp',
      'image/gif' => '.gif',
      'image/bmp' => '.bmp',
      _ => '.png',
    };
    final relative = p.join('attachments', sessionId, id + suffix);
    final file = File(p.join(workspace.directory.path, relative));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return AgentAttachment(
      id: id,
      name: p.basename(name),
      relativePath: relative,
      mimeType: mimeType,
      bytes: bytes.length,
      sha256Hex: sha256.convert(bytes).toString(),
      width: width,
      height: height,
      metadata: metadata,
    );
  });
  Future<Uint8List> readAttachment(
    String workspaceId,
    AgentAttachment attachment,
  ) async {
    final workspace = await getWorkspace(workspaceId);
    if (p.isAbsolute(attachment.relativePath)) {
      throw const FormatException('Invalid attachment path');
    }
    final resolved = await File(
      p.join(workspace.directory.path, attachment.relativePath),
    ).resolveSymbolicLinks();
    final expectedRoot = await Directory(
      p.join(workspace.directory.path, 'attachments'),
    ).resolveSymbolicLinks();
    if (!p.isWithin(expectedRoot, resolved)) {
      throw const FormatException('Attachment leaves workspace');
    }
    final bytes = await File(resolved).readAsBytes();
    if (bytes.length != attachment.bytes ||
        sha256.convert(bytes).toString() != attachment.sha256Hex) {
      throw const FormatException(
        'Attachment changed; attach the current image again',
      );
    }
    return bytes;
  }

  Future<File> saveSnapshot(
    String workspaceId,
    String name,
    Map<String, dynamic> draft,
  ) => _write(() async {
    final workspace = await getWorkspace(workspaceId);
    final file = File(
      p.join(
        workspace.directory.path,
        'snapshots',
        '${const Uuid().v4()}.json',
      ),
    );
    await _atomic(file, {
      'schema': 1,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
      'draft': draft,
    });
    return file;
  });
  Future<List<File>> snapshots(String workspaceId) async {
    final workspace = await getWorkspace(workspaceId);
    return (await Directory(
          p.join(workspace.directory.path, 'snapshots'),
        ).list(followLinks: false).toList())
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.json')
        .toList();
  }

  Future<Map<String, dynamic>> readSnapshot(
    String workspaceId,
    String id,
  ) async {
    _id(id);
    final workspace = await getWorkspace(workspaceId);
    final file = File(
      p.join(workspace.directory.path, 'snapshots', '$id.json'),
    );
    final canonical = await file.resolveSymbolicLinks();
    final parent = await Directory(
      p.join(workspace.directory.path, 'snapshots'),
    ).resolveSymbolicLinks();
    if (!p.isWithin(parent, canonical)) {
      throw const FormatException('Snapshot leaves workspace');
    }
    final value = await _read(File(canonical));
    if (value['schema'] != 1 || value['draft'] is! Map) {
      throw const FormatException('Invalid snapshot');
    }
    return value;
  }
}
