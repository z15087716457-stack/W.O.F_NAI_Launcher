import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/auth/add_account_dialog.dart';
import '../../providers/settings_navigation_provider.dart';
import 'widgets/settings_search.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_ui_theme.dart';
import 'widgets/settings_typography_scope.dart';
import 'widgets/settings_preferences_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import 'sections/account_settings_section.dart';
import 'sections/appearance_settings_section.dart';
import 'sections/generation_settings_section.dart';
import 'widgets/data_source_cache_settings.dart';
import 'sections/storage_settings_section.dart';
import 'sections/privacy_settings_section.dart';
import 'sections/shortcut_settings_section.dart';
import 'sections/integrations_settings_section.dart';
import 'sections/about_settings_section.dart';
import 'sections/model_management_section.dart';

enum SettingsDestination {
  appearance,
  controls,
  generation,
  storage,
  data,
  account,
  models,
  integrations,
  privacy,
  about,
}

class _SettingsSection {
  const _SettingsSection(
    this.destination,
    this.icon,
    this.label,
    this.description,
    this.widget,
  );
  final SettingsDestination destination;
  final IconData icon;
  final String label, description;
  final Widget widget;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.initialSectionIndex = 0});

  /// Keep existing deep links stable while redistributing the settings pages.
  final int initialSectionIndex;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SettingsDestination _destination;
  final _scroll = ScrollController();
  final _modelsKey = GlobalKey<ModelManagementSectionState>();
  bool _leavingModels = false;
  int _navigationRevision = 0;
  int? _integrationSearchTab;

  SettingsDestination _legacyDestination(int value) => switch (value) {
    0 => SettingsDestination.account,
    1 => SettingsDestination.appearance,
    2 => SettingsDestination.generation,
    3 => SettingsDestination.storage,
    4 => SettingsDestination.privacy,
    5 || 8 => SettingsDestination.integrations,
    6 => SettingsDestination.controls,
    7 => SettingsDestination.models,
    9 => SettingsDestination.about,
    _ => SettingsDestination.appearance,
  };

  @override
  void initState() {
    super.initState();
    _destination = _legacyDestination(widget.initialSectionIndex);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSectionIndex != widget.initialSectionIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(_legacyDestination(widget.initialSectionIndex));
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _select(SettingsDestination destination) async {
    if (_leavingModels || _destination == destination) return;
    if (_destination == SettingsDestination.models) {
      _leavingModels = true;
      final allowed =
          await (_modelsKey.currentState?.confirmLeave() ?? Future.value(true));
      _leavingModels = false;
      if (!mounted) return;
      if (!allowed) {
        setState(() => _navigationRevision++);
        return;
      }
    }
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _destination = destination);
  }

  Future<void> _search(
    BuildContext context,
    List<_SettingsSection> sections,
  ) async {
    final entry = await showSettingsSearch(
      context,
      settingsSearchEntries(context, {
        for (final item in sections) item.destination.name: item.label,
      }),
    );
    if (!mounted || entry == null) return;
    final target = SettingsDestination.values.byName(entry.page);
    await _select(target);
    if (!mounted || _destination != target) return;
    if (target == SettingsDestination.integrations && entry.subpage != null) {
      setState(
        () => _integrationSearchTab = switch (entry.subpage) {
          'network' => 2,
          'krita' => 1,
          _ => 0,
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (target == SettingsDestination.models && entry.subpage != null) {
        _modelsKey.currentState?.openSearchTab(entry.subpage!);
      }
      BuildContext? found;
      void find(Element element) {
        final widget = element.widget;
        if (widget is SettingsTile &&
            widget.title is Text &&
            (widget.title as Text).data == entry.title) {
          found = element;
        }
        if (found == null) element.visitChildren(find);
      }

      (this.context as Element).visitChildren(find);
      if (found != null) {
        Scrollable.ensureVisible(
          found!,
          alignment: .12,
          duration: const Duration(milliseconds: 220),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsAccountOpenRequestProvider, (previous, next) {
      if (previous != next) _select(SettingsDestination.account);
    });
    return Theme(
      data: settingsUiTheme(Theme.of(context)),
      child: SettingsTypographyScope(child: Builder(builder: _buildSettings)),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final captionHeight = WindowChromeScope.heightOf(context);
    final headerHeight = captionHeight > 44 ? captionHeight : 44.0;
    final language = Localizations.localeOf(context).languageCode;
    String text(String zh, String en, String ja) => language == 'zh'
        ? zh
        : language == 'ja'
        ? ja
        : en;
    final sections = [
      _SettingsSection(
        SettingsDestination.appearance,
        StudioIcons.settingsAppearance,
        text('常规与外观', 'General & appearance', '一般と外観'),
        text(
          '让工作台符合你的阅读与使用习惯。',
          'Make the workspace comfortable to read and use.',
          '使いやすく読みやすいワークスペースに。',
        ),
        const AppearanceSettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.controls,
        StudioIcons.settingsControls,
        text('操作与快捷键', 'Controls & shortcuts', '操作とショートカット'),
        text(
          '设置交互方式、画布操作和键盘快捷键。',
          'Choose interaction, canvas controls and keyboard shortcuts.',
          '操作方法とキーボードショートカットを設定。',
        ),
        const Column(
          children: [
            AppearanceSettingsSection(controlsOnly: true),
            ShortcutSettingsSection(),
          ],
        ),
      ),
      _SettingsSection(
        SettingsDestination.generation,
        StudioIcons.settingsGeneration,
        text('生成与提示词', 'Generation & prompts', '生成とプロンプト'),
        text(
          '管理提示词输入、生成提醒与请求节奏。',
          'Manage prompt input, generation reminders and request pacing.',
          'プロンプト入力と生成の動作を管理。',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GenerationSettingsSection(),
            const DataSourceCacheSettings(controlsOnly: true),
            const PrivacySettingsSection(generationOnly: true),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _select(SettingsDestination.models),
                icon: const Icon(StudioIcons.settingsModels, size: 17),
                label: Text(
                  text(
                    '管理翻译模型与规则',
                    'Manage translation models & rules',
                    '翻訳モデルとルールを管理',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      _SettingsSection(
        SettingsDestination.storage,
        StudioIcons.settingsStorage,
        text('图库与文件', 'Gallery & files', 'ギャラリーとファイル'),
        text(
          '图片保存位置、图库来源与本地缓存。',
          'Image locations, gallery sources and local caches.',
          '画像の保存先、ギャラリーとキャッシュ。',
        ),
        const StorageSettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.data,
        StudioIcons.settingsData,
        text('词库与缓存', 'Dictionaries & cache', '辞書とキャッシュ'),
        text(
          '管理标签词库、索引与缓存维护。',
          'Manage tag dictionaries, indexes and cache maintenance.',
          'タグ辞書、索引とキャッシュを管理。',
        ),
        const StorageMaintenanceSection(),
      ),
      _SettingsSection(
        SettingsDestination.account,
        StudioIcons.settingsAccount,
        text('NovelAI 账号', 'NovelAI accounts', 'NovelAI アカウント'),
        text(
          '查看当前账号，管理登录与默认账号。',
          'View your account and manage sign-in and the default account.',
          'アカウントとログインを管理。',
        ),
        const AccountSettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.models,
        StudioIcons.settingsModels,
        context.l10n.settings_modelsAndInterfaces,
        '',
        ModelManagementSection(key: _modelsKey),
      ),
      _SettingsSection(
        SettingsDestination.integrations,
        StudioIcons.settingsIntegrations,
        text('连接与集成', 'Connections & integrations', '接続と連携'),
        text(
          '管理外部工具、桥接连接与网络设置。',
          'Manage external tools, bridges and network settings.',
          '外部ツール、ブリッジとネットワーク。',
        ),
        IntegrationsSettingsSection(
          initialNetwork: widget.initialSectionIndex == 5,
          initialTab: _integrationSearchTab,
        ),
      ),
      _SettingsSection(
        SettingsDestination.privacy,
        StudioIcons.settingsPrivacy,
        text('隐私与分享', 'Privacy & sharing', 'プライバシーと共有'),
        text(
          '控制分享信息与需要确认的操作。',
          'Control shared information and confirmation before sensitive actions.',
          '共有する情報と確認が必要な操作。',
        ),
        const PrivacySettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.about,
        StudioIcons.settingsAbout,
        text('关于与诊断', 'About & diagnostics', '情報と診断'),
        text(
          '版本更新、日志与项目资料。',
          'Updates, logs and project information.',
          '更新、ログとプロジェクト情報。',
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SettingsPreferencesPanel(), AboutSettingsSection()],
        ),
      ),
    ];
    final section = sections.firstWhere(
      (item) => item.destination == _destination,
    );
    final narrow = MediaQuery.sizeOf(context).width < 650;
    Widget navItem(_SettingsSection item) {
      final selected = item.destination == _destination;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: selected
              ? scheme.primary.withValues(alpha: .08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            key: ValueKey('settings-nav-${item.destination.name}'),
            borderRadius: BorderRadius.circular(7),
            onTap: () => _select(item.destination),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 19,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget group(String title, Iterable<_SettingsSection> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant.withValues(alpha: .65),
            ),
          ),
        ),
        ...items.map(navItem),
      ],
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _search(context, sections),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            _search(context, sections),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(headerHeight),
            child: SizedBox(
              height: headerHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    right: WindowChromeScope.reservedWidthOf(context),
                    child: const WindowDragArea(
                      key: Key('settings-header-drag'),
                    ),
                  ),
                  SizedBox(
                    height: captionHeight,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: IgnorePointer(
                            child: Text(
                              context.l10n.settings_title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          key: const Key('settings-open-search'),
                          onPressed: () => _search(context, sections),
                          icon: const Icon(Icons.search, size: 16),
                          label: Text(text('搜索设置', 'Search settings', '設定を検索')),
                          style: TextButton.styleFrom(
                            minimumSize: Size(0, captionHeight),
                            fixedSize: Size.fromHeight(captionHeight),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            foregroundColor: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(
                          width:
                              WindowChromeScope.reservedWidthOf(context) + 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Row(
            children: [
              if (!narrow)
                SizedBox(
                  width: 190,
                  child: Material(
                    key: const Key('settings-sidebar-surface'),
                    color: scheme.surface,
                    child: ListView(
                      children: [
                        group(
                          text('使用偏好', 'PREFERENCES', '使い方'),
                          sections.take(2),
                        ),
                        group(
                          text('创作与资源', 'CREATION & RESOURCES', '制作とリソース'),
                          sections.skip(2).take(3),
                        ),
                        group(
                          text('服务与连接', 'SERVICES & CONNECTIONS', 'サービスと接続'),
                          sections.skip(5).take(3),
                        ),
                        const SizedBox(height: 24),
                        Divider(height: 1, color: scheme.outlineVariant),
                        const SizedBox(height: 12),
                        ...sections.skip(8).map(navItem),
                      ],
                    ),
                  ),
                ),
              if (!narrow)
                VerticalDivider(
                  width: 1,
                  color: scheme.outlineVariant.withValues(alpha: .5),
                ),
              Expanded(
                child: Column(
                  key: const Key('settings-content-pane'),
                  children: [
                    if (narrow)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: DropdownButtonFormField<SettingsDestination>(
                          key: ValueKey(
                            'settings-category-picker-${_destination.name}-$_navigationRevision',
                          ),
                          initialValue: _destination,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: sections
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.destination,
                                  child: Row(
                                    children: [
                                      Icon(item.icon, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(item.label)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) _select(value);
                          },
                        ),
                      ),
                    Expanded(
                      child: _destination == SettingsDestination.models
                          ? Padding(
                              padding: EdgeInsets.fromLTRB(
                                narrow ? 12 : 24,
                                8,
                                narrow ? 12 : 28,
                                24,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  key: const Key('settings-main-content'),
                                  constraints: const BoxConstraints(
                                    maxWidth: 1400,
                                  ),
                                  child: section.widget,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _scroll,
                              padding: EdgeInsets.fromLTRB(
                                narrow ? 18 : 34,
                                26,
                                narrow ? 18 : 34,
                                36,
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  key: const Key('settings-main-content'),
                                  constraints: const BoxConstraints(
                                    maxWidth: 850,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              section.label,
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          if (_destination ==
                                              SettingsDestination.account)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  AddAccountDialog.show(
                                                    context,
                                                    ref,
                                                  ),
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              label: Text(
                                                context.l10n.auth_addAccount,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        section.description,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              height: 1.5,
                                            ),
                                      ),
                                      const SizedBox(height: 28),
                                      section.widget,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
