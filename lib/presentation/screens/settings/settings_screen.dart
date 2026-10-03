import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/auth/add_account_dialog.dart';
import '../../providers/settings_navigation_provider.dart';
import 'widgets/settings_search.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_ui_theme.dart';
import 'widgets/settings_typography_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import 'sections/account_settings_section.dart';
import 'sections/appearance_settings_section.dart';
import 'sections/generation_preferences_section.dart';
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
    final sections = [
      _SettingsSection(
        SettingsDestination.appearance,
        StudioIcons.settingsAppearance,
        context.l10n.settings_generalAppearance,
        context.l10n.settings_makeWorkspaceComfortableReadUse,
        const AppearanceSettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.controls,
        StudioIcons.settingsControls,
        context.l10n.settings_controlsShortcuts,
        context.l10n.settings_chooseInteractionCanvasControlsKeyboard,
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
        context.l10n.settings_generationPrompts,
        context.l10n.settings_managePromptInputGenerationReminders,
        GenerationPreferencesSection(
          onManageModels: () => _select(SettingsDestination.models),
        ),
      ),
      _SettingsSection(
        SettingsDestination.storage,
        StudioIcons.settingsStorage,
        context.l10n.settings_galleryFiles,
        context.l10n.settings_manageImageSavingGallerySources,
        const StorageSettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.data,
        StudioIcons.settingsData,
        context.l10n.settings_dictionariesCache,
        context.l10n.settings_manageTagDictionariesIndexesCache,
        const StorageMaintenanceSection(),
      ),
      _SettingsSection(
        SettingsDestination.account,
        StudioIcons.settingsAccount,
        context.l10n.settings_novelaiAccounts,
        context.l10n.settings_viewAccountManageSignIn,
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
        context.l10n.settings_connectionsIntegrations,
        context.l10n.settings_manageExternalToolsBridgesNetwork,
        IntegrationsSettingsSection(
          initialNetwork: widget.initialSectionIndex == 5,
          initialTab: _integrationSearchTab,
        ),
      ),
      _SettingsSection(
        SettingsDestination.privacy,
        StudioIcons.settingsPrivacy,
        context.l10n.settings_privacySharing2,
        context.l10n.settings_controlSharedInformationConfirmationBefore,
        const PrivacySettingsSection(),
      ),
      _SettingsSection(
        SettingsDestination.about,
        StudioIcons.settingsAbout,
        context.l10n.settings_aboutDiagnostics,
        context.l10n.settings_updatesLogsProjectInformation,
        const AboutSettingsSection(),
      ),
    ];
    final section = sections.firstWhere(
      (item) => item.destination == _destination,
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final narrow = MediaQuery.sizeOf(context).width < 730 * scale;
    Widget searchButton() => OutlinedButton.icon(
      key: const Key('settings-open-search'),
      onPressed: () => _search(context, sections),
      icon: const Icon(Icons.search, size: 17),
      label: Text(context.l10n.settings_searchSettings),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
    Widget navItem(_SettingsSection item) {
      final selected = item.destination == _destination;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Semantics(
          selected: selected,
          child: Material(
            color: selected
                ? scheme.onSurface.withValues(alpha: .06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              key: ValueKey('settings-nav-${item.destination.name}'),
              borderRadius: BorderRadius.circular(4),
              onTap: () => _select(item.destination),
              child: Stack(
                children: [
                  if (selected)
                    PositionedDirectional(
                      start: 0,
                      top: 10,
                      bottom: 10,
                      child: Container(
                        key: const Key('settings-nav-selection-line'),
                        width: 2,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? scheme.onSurface
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(26, 20, 16, 6),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: .7),
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
                    height: headerHeight,
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
                  width: 230 * scale,
                  child: Material(
                    key: const Key('settings-sidebar-surface'),
                    color: scheme.surface,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                          child: searchButton(),
                        ),
                        Expanded(
                          child: ListView(
                            key: const Key('settings-navigation-list'),
                            padding: const EdgeInsets.only(bottom: 16),
                            children: [
                              group(
                                context.l10n.settings_preferences,
                                sections.take(2),
                              ),
                              group(
                                context.l10n.settings_creationResources,
                                sections.skip(2).take(3),
                              ),
                              group(
                                context.l10n.settings_servicesConnections,
                                sections.skip(5).take(3),
                              ),
                              group(
                                context.l10n.settings_safetyMaintenance,
                                sections.skip(8),
                              ),
                            ],
                          ),
                        ),
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
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: searchButton(),
                      ),
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
                                  child: Text(item.label),
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
