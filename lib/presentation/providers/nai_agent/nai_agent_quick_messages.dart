import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'nai_agent_workspace_provider.dart';

/// 欢迎页快捷信息：一张卡片 = 图标 + 标题 + 说明 + 发给 Agent 的内容。
/// 内置的几条没被改过时（[builtin] 非 null 且标题/内容为空）按界面语言显示；
/// 用户改过的保存原文，不再翻译。
@immutable
class NaiAgentQuickMessage {
  const NaiAgentQuickMessage({
    required this.id,
    this.icon = 'spark',
    this.title = '',
    this.hint = '',
    this.prompt = '',
    this.send = false,
    this.builtin,
  });
  final String id, icon, title, hint, prompt;

  /// true：点了直接发送；false：填进输入框。
  final bool send;

  /// 内置条目的键（review / analyze / variants / blocks）；用户新建的为 null。
  final String? builtin;

  /// 内置且没改过：文字跟着界面语言走。
  bool get localized => builtin != null && title.isEmpty && prompt.isEmpty;

  NaiAgentQuickMessage copyWith({
    String? icon,
    String? title,
    String? hint,
    String? prompt,
    bool? send,
  }) => NaiAgentQuickMessage(
    id: id,
    icon: icon ?? this.icon,
    title: title ?? this.title,
    hint: hint ?? this.hint,
    prompt: prompt ?? this.prompt,
    send: send ?? this.send,
    builtin: builtin,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'title': title,
    'hint': hint,
    'prompt': prompt,
    'send': send,
    if (builtin != null) 'builtin': builtin,
  };

  static NaiAgentQuickMessage? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    if (id is! String || id.isEmpty) return null;
    String str(String k) => value[k] is String ? value[k] as String : '';
    final builtin = value['builtin'];
    return NaiAgentQuickMessage(
      id: id,
      icon: naiAgentQuickIcons.contains(value['icon'])
          ? value['icon'] as String
          : 'spark',
      title: str('title'),
      hint: str('hint'),
      prompt: str('prompt'),
      send: value['send'] == true,
      builtin: builtin is String && naiAgentQuickBuiltins.contains(builtin)
          ? builtin
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NaiAgentQuickMessage &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// 可选图标（键 → 侧栏 AgentGlyphs）。
const naiAgentQuickIcons = [
  'eye',
  'image',
  'spark',
  'layers',
  'pen',
  'search',
  'book',
  'wand',
  'compare',
  'star',
  'sliders',
  'folder',
];

const naiAgentQuickBuiltins = ['review', 'analyze', 'variants', 'blocks'];

/// 欢迎页最多显示几张。
const naiAgentQuickMax = 6;

const naiAgentQuickDefaults = [
  NaiAgentQuickMessage(id: 'builtin-review', icon: 'eye', builtin: 'review'),
  NaiAgentQuickMessage(
    id: 'builtin-analyze',
    icon: 'image',
    builtin: 'analyze',
  ),
  NaiAgentQuickMessage(
    id: 'builtin-variants',
    icon: 'spark',
    builtin: 'variants',
  ),
  NaiAgentQuickMessage(id: 'builtin-blocks', icon: 'layers', builtin: 'blocks'),
];

/// 全局快捷信息（`agent-data/quick-messages.json`），不分工作区。
class NaiAgentQuickMessages extends ChangeNotifier {
  NaiAgentQuickMessages(this.file);
  final File file;
  List<NaiAgentQuickMessage> items = naiAgentQuickDefaults;
  bool _loaded = false;
  Future<void>? _pending;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    try {
      if (await file.exists()) {
        final value = jsonDecode(await file.readAsString());
        final list = value is Map ? value['items'] : null;
        // 读的过程中用户已经改过（save 先到）：以用户的为准。
        if (list is List && _pending == null) {
          items = List.unmodifiable([
            for (final v in list) ?NaiAgentQuickMessage.fromJson(v),
          ]);
        }
      }
    } catch (_) {
      // 坏文件：沿用默认，下一次保存时覆盖。
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  bool get loaded => _loaded;

  Future<void> save(List<NaiAgentQuickMessage> next) {
    items = List.unmodifiable(next);
    if (!_disposed) notifyListeners();
    final previous = _pending ?? Future<void>.value();
    final write = previous.then((_) async {
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.${const Uuid().v4()}.tmp');
      try {
        await tmp.writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'schema': 1,
            'items': [for (final i in next) i.toJson()],
          }),
          flush: true,
        );
        await tmp.rename(file.path);
      } finally {
        if (await tmp.exists()) await tmp.delete();
      }
    });
    _pending = write.catchError((_) {});
    return write;
  }

  Future<void> upsert(NaiAgentQuickMessage item) {
    final i = items.indexWhere((x) => x.id == item.id);
    return save(i < 0 ? [...items, item] : ([...items]..[i] = item));
  }

  Future<void> remove(String id) => save([
    for (final x in items)
      if (x.id != id) x,
  ]);

  Future<void> move(String id, int to) {
    final list = [...items];
    final i = list.indexWhere((x) => x.id == id);
    if (i < 0) return Future.value();
    final item = list.removeAt(i);
    list.insert(to.clamp(0, list.length), item);
    return save(list);
  }

  Future<void> restoreDefaults() => save(naiAgentQuickDefaults);

  static String newId() => const Uuid().v4();
}

final naiAgentQuickMessagesProvider =
    ChangeNotifierProvider<NaiAgentQuickMessages>((ref) {
      final store = ref.read(naiAgentWorkspaceStoreProvider);
      final messages = NaiAgentQuickMessages(
        File(p.join(store.root.path, 'quick-messages.json')),
      );
      messages.load();
      return messages;
    });
