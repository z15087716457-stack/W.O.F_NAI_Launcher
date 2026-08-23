import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/utils/gallery_model_labels.dart';

import '../providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';

/// Gallery Filter Panel Widget - Modern UI Design
/// 画廊筛选面板组件 - 现代化UI设计
///
/// Provides advanced filtering options for the local gallery
/// 为本地画廊提供高级筛选选项
class GalleryFilterPanel extends ConsumerStatefulWidget {
  const GalleryFilterPanel({super.key});

  @override
  ConsumerState<GalleryFilterPanel> createState() => _GalleryFilterPanelState();
}

class _GalleryFilterPanelState extends ConsumerState<GalleryFilterPanel>
    with SingleTickerProviderStateMixin {
  final TextEditingController _minStepsController = TextEditingController();
  final TextEditingController _maxStepsController = TextEditingController();
  final TextEditingController _minCfgController = TextEditingController();
  final TextEditingController _maxCfgController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 筛选面板局部状态（应用按钮提交到 provider）
  final Set<String> _selectedModels = {};
  final Set<String> _selectedSamplers = {};
  final Set<String> _selectedResolutions = {};
  String? _orientation;
  String? _nsfwMode;

  // 候选（打开面板时异步拉取；失败降级为空列表）
  late final Future<List<GalleryDistinctValue>> _modelsFuture;
  late final Future<List<GalleryDistinctValue>> _samplersFuture;
  late final Future<List<GalleryDistinctValue>> _resolutionsFuture;

  // tag 自动补全
  Timer? _tagDebounce;
  List<String> _tagSuggestions = [];
  int _tagSuggestionIndex = -1;
  bool _tagSuggesting = false;

  @override
  void initState() {
    super.initState();

    // 动画控制器
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();

    // Initialize with current filter values
    final criteria = ref.read(localGalleryNotifierProvider).filterCriteria;
    _selectedModels.addAll(criteria.filterModels);
    _selectedSamplers.addAll(criteria.filterSamplers);
    _selectedResolutions.addAll(criteria.filterResolutions);
    _orientation = criteria.filterOrientation;
    _nsfwMode = criteria.nsfwMode;
    _minStepsController.text =
        criteria.filterMinSteps?.toString() ?? '';
    _maxStepsController.text =
        criteria.filterMaxSteps?.toString() ?? '';
    _minCfgController.text =
        criteria.filterMinCfg?.toString() ?? '';
    _maxCfgController.text =
        criteria.filterMaxCfg?.toString() ?? '';

    // 异步拉取候选（失败时 FutureBuilder 降级显示提示，不崩）
    final dataSource = GalleryDataSource();
    _modelsFuture = dataSource.getDistinctModels();
    _samplersFuture = dataSource.getDistinctSamplers();
    _resolutionsFuture = dataSource.getDistinctResolutions();
  }

  @override
  void dispose() {
    _animController.dispose();
    _minStepsController.dispose();
    _maxStepsController.dispose();
    _minCfgController.dispose();
    _maxCfgController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    _tagDebounce?.cancel();
    super.dispose();
  }

  /// 将输入框中的标签加入筛选（支持逗号分隔多个），并清空输入框
  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(localGalleryNotifierProvider.notifier);
    final tags = text
        .split(RegExp(r'[,，]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.isNotEmpty) {
      notifier.addSelectedTags(tags);
    }
    _tagController.clear();
    _tagSuggestions = [];
    _tagSuggestionIndex = -1;
    _tagSuggesting = false;
    setState(() {});
  }

  /// 标签输入变化：防抖查询自动补全候选
  void _onTagChanged(String value) {
    setState(() {});

    _tagDebounce?.cancel();
    final text = value.trim();
    if (text.isEmpty) {
      _tagSuggestions = [];
      _tagSuggestionIndex = -1;
      _tagSuggesting = false;
      return;
    }
    _tagSuggesting = true;

    _tagDebounce = Timer(const Duration(milliseconds: 200), () async {
      final suggestions = await GalleryDataSource().autocompleteTags(text);
      if (!mounted) return;
      setState(() {
        _tagSuggestions = suggestions;
        _tagSuggestionIndex = -1;
      });
    });
  }

  /// 回车：有高亮建议时加入建议，否则走普通添加
  void _handleTagSubmitted(String _) {
    if (_tagSuggestions.isNotEmpty &&
        _tagSuggestionIndex >= 0 &&
        _tagSuggestionIndex < _tagSuggestions.length) {
      _addSuggestion(_tagSuggestions[_tagSuggestionIndex]);
      return;
    }
    _addTag();
  }

  /// 加入单个自动补全建议（并清空输入）
  void _addSuggestion(String tag) {
    ref.read(localGalleryNotifierProvider.notifier).addSelectedTags([tag]);
    _tagController.clear();
    _tagSuggestions = [];
    _tagSuggestionIndex = -1;
    _tagSuggesting = false;
    setState(() {});
  }

  /// 键盘上下键选择建议 / Escape 关闭下拉
  KeyEventResult _handleTagKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_tagSuggestions.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _tagSuggestionIndex = (_tagSuggestionIndex + 1) % _tagSuggestions.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _tagSuggestionIndex = _tagSuggestionIndex <= 0
            ? _tagSuggestions.length - 1
            : _tagSuggestionIndex - 1;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _tagSuggestions = [];
        _tagSuggestionIndex = -1;
        _tagSuggesting = false;
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Apply all filters
  void _applyFilters() {
    final notifier = ref.read(localGalleryNotifierProvider.notifier);

    // Parse values
    final minSteps = _minStepsController.text.trim().isEmpty
        ? null
        : int.tryParse(_minStepsController.text.trim());
    final maxSteps = _maxStepsController.text.trim().isEmpty
        ? null
        : int.tryParse(_maxStepsController.text.trim());
    final minCfg = _minCfgController.text.trim().isEmpty
        ? null
        : double.tryParse(_minCfgController.text.trim());
    final maxCfg = _maxCfgController.text.trim().isEmpty
        ? null
        : double.tryParse(_maxCfgController.text.trim());

    // Apply filters
    notifier.setFilterModels(_selectedModels.toList()..sort());
    notifier.setFilterSamplers(_selectedSamplers.toList()..sort());
    notifier.setFilterResolutions(_selectedResolutions.toList()..sort());
    notifier.setFilterOrientation(_orientation);
    notifier.setNsfwMode(_nsfwMode);
    notifier.setFilterSteps(minSteps, maxSteps);
    notifier.setFilterCfg(minCfg, maxCfg);

    // Close the panel with animation
    _animController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  /// Reset all advanced filters
  void _resetFilters() {
    final notifier = ref.read(localGalleryNotifierProvider.notifier);

    notifier.setFilterModels(const []);
    notifier.setFilterSamplers(const []);
    notifier.setFilterResolutions(const []);
    notifier.setFilterOrientation(null);
    notifier.setNsfwMode(null);
    notifier.setFilterSteps(null, null);
    notifier.setFilterCfg(null, null);
    // 标签过滤同样属于会话过滤：重置时一并清空
    notifier.setSelectedTags(const []);

    // Clear local state with animation
    setState(() {
      _selectedModels.clear();
      _selectedSamplers.clear();
      _selectedResolutions.clear();
      _orientation = null;
      _nsfwMode = null;
      _minStepsController.clear();
      _maxStepsController.clear();
      _minCfgController.clear();
      _maxCfgController.clear();
      _tagController.clear();
      _tagSuggestions = [];
      _tagSuggestionIndex = -1;
      _tagSuggesting = false;
    });
  }

  /// Check if any filter is active
  bool get _hasActiveFilters {
    return _selectedModels.isNotEmpty ||
        _selectedSamplers.isNotEmpty ||
        _selectedResolutions.isNotEmpty ||
        _orientation != null ||
        _nsfwMode != null ||
        _minStepsController.text.isNotEmpty ||
        _maxStepsController.text.isNotEmpty ||
        _minCfgController.text.isNotEmpty ||
        _maxCfgController.text.isNotEmpty ||
        // 已选标签 chip 挂在 provider 状态上，同样计入「有活动过滤」
        ref
            .read(localGalleryNotifierProvider)
            .filterCriteria
            .selectedTags
            .isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 460,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              _buildHeader(theme, l10n, isDark, colorScheme),

              // Filters content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag filter card
                      _buildFilterCard(
                        theme: theme,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        icon: Icons.tag,
                        iconColor: Colors.pink,
                        title: l10n.localGallery_filterByTags,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Focus(
                              onKeyEvent: _handleTagKeyEvent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _tagController,
                                      focusNode: _tagFocusNode,
                                      hintText: l10n.localGallery_tagInputHint,
                                      theme: theme,
                                      isDark: isDark,
                                      colorScheme: colorScheme,
                                      onChanged: _onTagChanged,
                                      onSubmitted: _handleTagSubmitted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: _addTag,
                                    icon: const Icon(Icons.add, size: 18),
                                    tooltip: l10n.localGallery_addTag,
                                  ),
                                ],
                              ),
                            ),
                            if (_tagSuggesting)
                              _buildTagSuggestions(theme, l10n, colorScheme),
                            const SizedBox(height: 10),
                            _buildSelectedTagChips(theme),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model filter card
                      _buildFilterCard(
                        theme: theme,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        icon: Icons.auto_awesome,
                        iconColor: Colors.purple,
                        title: l10n.localGallery_filterByModel,
                        child: _buildCandidateChips(
                          future: _modelsFuture,
                          selected: _selectedModels,
                          theme: theme,
                          colorScheme: colorScheme,
                          emptyText: l10n.localGallery_noModelCandidates,
                          labelBuilder: (value) =>
                              '${galleryModelFriendlyName(value.value)} · ${value.count}',
                          onToggle: (value) {
                            setState(() {
                              if (!_selectedModels.remove(value.value)) {
                                _selectedModels.add(value.value);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sampler filter card
                      _buildFilterCard(
                        theme: theme,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        icon: Icons.timeline,
                        iconColor: Colors.blue,
                        title: l10n.localGallery_filterBySampler,
                        child: _buildCandidateChips(
                          future: _samplersFuture,
                          selected: _selectedSamplers,
                          theme: theme,
                          colorScheme: colorScheme,
                          emptyText: l10n.localGallery_noSamplerCandidates,
                          labelBuilder: (value) =>
                              '${value.value} · ${value.count}',
                          onToggle: (value) {
                            setState(() {
                              if (!_selectedSamplers.remove(value.value)) {
                                _selectedSamplers.add(value.value);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NSFW filter card
                      _buildFilterCard(
                        theme: theme,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        icon: Icons.visibility_off_outlined,
                        iconColor: Colors.deepOrange,
                        title: l10n.localGallery_filterNsfw,
                        compact: true,
                        child: _buildNsfwSelector(theme, l10n, colorScheme),
                      ),
                      const SizedBox(height: 16),

                      // Steps and CFG in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Steps filter
                          Expanded(
                            child: _buildFilterCard(
                              theme: theme,
                              isDark: isDark,
                              colorScheme: colorScheme,
                              icon: Icons.layers,
                              iconColor: Colors.orange,
                              title: l10n.localGallery_filterBySteps,
                              compact: true,
                              child: _buildRangeInput(
                                minController: _minStepsController,
                                maxController: _maxStepsController,
                                theme: theme,
                                isDark: isDark,
                                colorScheme: colorScheme,
                                isInteger: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // CFG filter
                          Expanded(
                            child: _buildFilterCard(
                              theme: theme,
                              isDark: isDark,
                              colorScheme: colorScheme,
                              icon: Icons.tune,
                              iconColor: Colors.teal,
                              title: l10n.localGallery_filterByCfg,
                              compact: true,
                              child: _buildRangeInput(
                                minController: _minCfgController,
                                maxController: _maxCfgController,
                                theme: theme,
                                isDark: isDark,
                                colorScheme: colorScheme,
                                isInteger: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Resolution filter card
                      _buildFilterCard(
                        theme: theme,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        icon: Icons.aspect_ratio,
                        iconColor: Colors.green,
                        title: l10n.localGallery_filterByResolution,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.localGallery_filterOrientation,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildOrientationSelector(theme, l10n, colorScheme),
                            const SizedBox(height: 12),
                            _buildCandidateChips(
                              future: _resolutionsFuture,
                              selected: _selectedResolutions,
                              theme: theme,
                              colorScheme: colorScheme,
                              emptyText:
                                  l10n.localGallery_noResolutionCandidates,
                              labelBuilder: (value) =>
                                  '${value.value} · ${value.count}',
                              onToggle: (value) {
                                setState(() {
                                  if (!_selectedResolutions.remove(value.value)) {
                                    _selectedResolutions.add(value.value);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              _buildActionButtons(theme, l10n, isDark, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// tag 自动补全下拉
  Widget _buildTagSuggestions(
    ThemeData theme,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _tagSuggestions.length; i++)
            InkWell(
              onTap: () => _addSuggestion(_tagSuggestions[i]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: i == _tagSuggestionIndex
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Text(
                  _tagSuggestions[i],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (_tagSuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.localGallery_noTagSuggestions,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 候选 chips 流（FutureBuilder；失败/为空时显示提示文案）
  Widget _buildCandidateChips({
    required Future<List<GalleryDistinctValue>> future,
    required Set<String> selected,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String emptyText,
    required String Function(GalleryDistinctValue) labelBuilder,
    required void Function(GalleryDistinctValue) onToggle,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<GalleryDistinctValue>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildHintText(theme, l10n.localGallery_candidatesLoadFailed);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildHintText(theme, emptyText);
        }

        final candidates = snapshot.data!;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final candidate in candidates)
                  FilterChip(
                    label: Text(
                      labelBuilder(candidate),
                      style: theme.textTheme.bodySmall,
                    ),
                    selected: selected.contains(candidate.value),
                    onSelected: (_) => onToggle(candidate),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected.contains(candidate.value)
                          ? colorScheme.primary.withValues(alpha: 0.6)
                          : colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHintText(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  /// 画面方向三态选择
  Widget _buildOrientationSelector(
    ThemeData theme,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'any',
          label: Text(l10n.localGallery_orientationAny),
        ),
        ButtonSegment(
          value: 'landscape',
          icon: const Icon(Icons.landscape_outlined, size: 16),
          label: Text(l10n.localGallery_orientationLandscape),
        ),
        ButtonSegment(
          value: 'portrait',
          icon: const Icon(Icons.portrait_outlined, size: 16),
          label: Text(l10n.localGallery_orientationPortrait),
        ),
        ButtonSegment(
          value: 'square',
          icon: const Icon(Icons.square_outlined, size: 16),
          label: Text(l10n.localGallery_orientationSquare),
        ),
      ],
      selected: {_orientation ?? 'any'},
      onSelectionChanged: (selection) {
        setState(() {
          final value = selection.first;
          _orientation = value == 'any' ? null : value;
        });
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.bodySmall),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      ),
    );
  }

  /// 内容分级三态选择
  Widget _buildNsfwSelector(
    ThemeData theme,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'any',
          label: Text(l10n.localGallery_nsfwAny),
        ),
        ButtonSegment(
          value: 'sfw',
          label: Text(l10n.localGallery_nsfwSfw),
        ),
        ButtonSegment(
          value: 'nsfw',
          label: Text(l10n.localGallery_nsfwOnly),
        ),
      ],
      selected: {_nsfwMode ?? 'any'},
      onSelectionChanged: (selection) {
        setState(() {
          final value = selection.first;
          _nsfwMode = value == 'any' ? null : value;
        });
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.bodySmall),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  /// Build header with gradient background
  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.15),
                  colorScheme.secondary.withValues(alpha: 0.1),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localGallery_advancedFilters,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.localGallery_filterSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              _animController.reverse().then((_) {
                Navigator.of(context).pop();
              });
            },
            tooltip: l10n.common_close,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a modern filter card
  Widget _buildFilterCard({
    required ThemeData theme,
    required bool isDark,
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          child,
        ],
      ),
    );
  }

  /// 当前已选标签 chips（删除即时生效）
  Widget _buildSelectedTagChips(ThemeData theme) {
    final tags =
        ref.watch(localGalleryNotifierProvider).filterCriteria.selectedTags;
    if (tags.isEmpty) {
      return Text(
        context.l10n.localGallery_tagIntersection,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          InputChip(
            avatar: const Icon(Icons.tag, size: 14),
            label: Text(tag),
            onDeleted: () {
              ref
                  .read(localGalleryNotifierProvider.notifier)
                  .removeSelectedTag(tag);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }

  /// Build a modern text field
  Widget _buildModernTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    required ThemeData theme,
    required bool isDark,
    required ColorScheme colorScheme,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
      ),
      child: ThemedInput(
        controller: controller,
        focusNode: focusNode,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          isDense: true,
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.clear();
                      if (identical(controller, _tagController)) {
                        _tagSuggestions = [];
                        _tagSuggestionIndex = -1;
                        _tagSuggesting = false;
                      }
                    });
                  },
                )
              : null,
        ),
        onChanged: onChanged ?? (_) => setState(() {}),
        onSubmitted: onSubmitted,
      ),
    );
  }

  /// Build range input (min ~ max)
  Widget _buildRangeInput({
    required TextEditingController minController,
    required TextEditingController maxController,
    required ThemeData theme,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isInteger,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactTextField(
            controller: minController,
            hintText: context.l10n.common_minimum,
            theme: theme,
            isDark: isDark,
            colorScheme: colorScheme,
            isNumber: true,
            isInteger: isInteger,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.remove,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: _buildCompactTextField(
            controller: maxController,
            hintText: context.l10n.common_maximum,
            theme: theme,
            isDark: isDark,
            colorScheme: colorScheme,
            isNumber: true,
            isInteger: isInteger,
          ),
        ),
      ],
    );
  }

  /// Build compact text field for number inputs
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hintText,
    required ThemeData theme,
    required bool isDark,
    required ColorScheme colorScheme,
    bool isNumber = false,
    bool isInteger = true,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
      ),
      child: ThemedInput(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: isNumber
            ? TextInputType.numberWithOptions(decimal: !isInteger)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [
                FilteringTextInputFormatter.allow(
                  isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
                ),
              ]
            : null,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(
    ThemeData theme,
    AppLocalizations l10n,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Active filter indicator
          if (_hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 14, color: colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.localGallery_activeFiltersSet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Reset button
          TextButton.icon(
            onPressed: _hasActiveFilters ? _resetFilters : null,
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: _hasActiveFilters
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            label: Text(
              l10n.localGallery_resetAdvancedFilters,
              style: TextStyle(
                color: _hasActiveFilters
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Apply button
          FilledButton.icon(
            onPressed: _applyFilters,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(l10n.localGallery_applyFilters),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show filter panel as a dialog
/// 以对话框形式显示筛选面板
void showGalleryFilterPanel(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const Center(
      child: Material(color: Colors.transparent, child: GalleryFilterPanel()),
    ),
  );
}
