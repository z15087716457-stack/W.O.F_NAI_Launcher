import 'package:flutter/material.dart';
import '../../../../core/utils/localization_extension.dart';
import 'settings_ui_theme.dart';

class SettingsSearchEntry {
  const SettingsSearchEntry(
    this.page,
    this.title,
    this.category, {
    this.keywords = '',
    this.subpage,
  });
  final String page, title, category, keywords;
  final String? subpage;
  bool matches(String query) => '$title $category $keywords'
      .toLowerCase()
      .contains(query.toLowerCase().trim());
}

List<SettingsSearchEntry> settingsSearchEntries(
  BuildContext context,
  Map<String, String> pages,
) {
  final l = context.l10n;
  SettingsSearchEntry item(
    String page,
    String title, [
    String keywords = '',
    String? subpage,
  ]) => SettingsSearchEntry(
    page,
    title,
    pages[page]!,
    keywords: keywords,
    subpage: subpage,
  );
  return [
    for (final page in pages.entries) item(page.key, page.value),
    item('appearance', l.settings_style, 'theme light dark 深浅色 明暗'),
    item('appearance', l.settings_font, 'font 字体'),
    item('appearance', l.settings_fontScale, 'scale 字号'),
    item('appearance', l.settings_language, 'locale 语言'),
    item(
      'appearance',
      context.l10n.settings_notificationsSound,
      'sound notification 音效 声音 自定义',
    ),
    item('controls', l.settings_historyClickBehavior, 'history 历史 点击'),
    item('controls', l.settings_outputViewer, 'canvas viewer 图片 查看器'),
    item('controls', context.l10n.settings_lockCanvasCamera, 'WASD 相机 缩放'),
    item('controls', l.settings_shortcuts, 'shortcut 键盘 快捷键'),
    item(
      'generation',
      l.settings_enablePromptWeightScroll,
      'weight scroll 权重 滚轮',
    ),
    item('generation', context.l10n.settings_tagExpansion, 'tags 标签 扩展 Ctrl'),
    item('generation', l.settings_warnHighAnlasCostTitle, 'Anlas cost 消耗 额度'),
    item('generation', l.settings_generationIntervalTitle, 'interval 间隔 节奏'),
    item('storage', l.settings_imageSavePath, 'path 保存 路径'),
    item('storage', l.settings_autoSave, 'save 自动保存'),
    item('storage', l.settings_vibeLibraryPath, 'Vibe path 素材 路径'),
    item(
      'storage',
      l.settings_galleryThumbnailQuality,
      'thumbnail quality 缩略图 清晰度',
    ),
    item('storage', l.settings_extraRootsTitle, 'gallery folder 图库来源 文件夹'),
    item(
      'data',
      context.l10n.settings_dictionariesCache,
      'dictionary tags cache 中文 汉化 词典 数据源',
    ),
    item(
      'account',
      context.l10n.settings_defaultAccount2,
      'login default 默认 登录',
    ),
    item(
      'account',
      context.l10n.settings_signInAutomatically,
      'auto login 启动 自动 登录',
    ),
    item(
      'account',
      context.l10n.settings_signInCredentials,
      'token credentials 登录 凭据 账号 头像 昵称',
    ),
    item(
      'models',
      context.l10n.settings_translationInterfaces,
      'model translation 接口 术词表 模型',
      'tasks',
    ),
    item(
      'models',
      context.l10n.settings_presetsBuiltInRules,
      'prompt preset 提示词 规则 默认',
      'presets',
    ),
    item('integrations', 'ComfyUI', 'workflow 工作流 连接', 'comfyui'),
    item('integrations', 'Krita', 'bridge 桥接 绘画', 'krita'),
    item(
      'integrations',
      l.settings_network,
      'network proxy endpoint 网络 代理 第三方',
      'network',
    ),
    item('privacy', l.settings_stripMetadataTitle, 'metadata 脱敏 元数据 分享'),
    item(
      'about',
      context.l10n.settings_preferenceBackupRestore,
      'backup import export reset 配置 偏好 导入 导出 恢复 默认',
    ),
  ];
}

Future<SettingsSearchEntry?> showSettingsSearch(
  BuildContext context,
  List<SettingsSearchEntry> entries,
) => showDialog<SettingsSearchEntry>(
  context: context,
  builder: (_) => Theme(
    data: settingsUiTheme(Theme.of(context)),
    child: _SearchDialog(entries),
  ),
);

class _SearchDialog extends StatefulWidget {
  const _SearchDialog(this.entries);
  final List<SettingsSearchEntry> entries;
  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final controller = TextEditingController();
  String query = '';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.entries.where((e) => e.matches(query)).toList();
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        width: 560,
        height:
            MediaQuery.sizeOf(context).height.clamp(260, 620).toDouble() - 60,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                key: const Key('settings-search-input'),
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: context.l10n.settings_searchSettingsFeatures,
                  suffixIcon: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 17),
                  ),
                ),
                onChanged: (value) => setState(() => query = value),
                onSubmitted: (_) {
                  if (results.isNotEmpty) Navigator.pop(context, results.first);
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.settings_noMatchingSettings,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            entry.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward, size: 16),
                          onTap: () => Navigator.pop(context, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
