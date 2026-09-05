import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';

/// Enhanced pagination bar with complete navigation features
/// 增强分页栏，包含完整的导航功能
///
/// Features:
/// - First/Last page navigation
/// - Page number buttons with ellipsis
/// - Items per page selector
/// - Page jump input
/// - Total count and range display
class PaginationBar extends StatefulWidget {
  final int currentPage; // 0-based
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;
  final bool showItemsPerPage;
  final bool showTotalInfo;
  final bool compact;
  final Widget? trailing;

  /// 逻辑列宽（px）：提供时在「每页 N 项」右侧显示列宽调节控件
  final double? columnWidth;

  /// 列宽拖动实时回调（拖动中持续触发，UI 即时生效）
  final ValueChanged<double>? onColumnWidthChanged;

  /// 列宽拖动结束回调（用于持久化）
  final ValueChanged<double>? onColumnWidthChangeEnd;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.totalItems = 0,
    this.itemsPerPage = 50,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const [20, 50, 100, 200],
    this.showItemsPerPage = true,
    this.showTotalInfo = true,
    this.compact = false,
    this.trailing,
    this.columnWidth,
    this.onColumnWidthChanged,
    this.onColumnWidthChangeEnd,
  });

  @override
  State<PaginationBar> createState() => _PaginationBarState();
}

class _PaginationBarState extends State<PaginationBar> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = (widget.currentPage + 1).toString();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _submitPage() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _cancelEditing();
      return;
    }

    final parsed = int.tryParse(input);
    if (parsed == null) {
      _cancelEditing();
      return;
    }

    int targetPage = parsed - 1;
    if (targetPage < 0) targetPage = 0;
    if (targetPage >= widget.totalPages) targetPage = widget.totalPages - 1;

    setState(() {
      _isEditing = false;
    });

    if (targetPage != widget.currentPage) {
      widget.onPageChanged(targetPage);
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: widget.compact
          ? _buildCompactLayout(theme, colorScheme)
          : _buildFullLayout(theme, colorScheme),
    );
  }

  Widget _buildFullLayout(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Total info
        if (widget.showTotalInfo && widget.totalItems > 0)
          _buildTotalInfo(theme, colorScheme),

        const Spacer(),

        // Page navigation
        _buildPageNavigation(theme, colorScheme),

        const Spacer(),

        // Items per page selector
        if (widget.showItemsPerPage && widget.onItemsPerPageChanged != null)
          _buildItemsPerPageSelector(theme, colorScheme),

        // Column width control (本地画廊专用：提供回调时才显示)
        if (widget.onColumnWidthChanged != null && widget.columnWidth != null)
          _buildColumnWidthControl(theme, colorScheme),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildPageNavigation(theme, colorScheme),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  Widget _buildTotalInfo(ThemeData theme, ColorScheme colorScheme) {
    final startItem = widget.currentPage * widget.itemsPerPage + 1;
    final endItem = ((widget.currentPage + 1) * widget.itemsPerPage).clamp(
      0,
      widget.totalItems,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          '$startItem-$endItem',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' / ${widget.totalItems}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigation(ThemeData theme, ColorScheme colorScheme) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First page
        _buildNavButton(
          icon: Icons.first_page,
          tooltip: l10n.pagination_firstPage,
          onPressed: widget.currentPage > 0
              ? () => widget.onPageChanged(0)
              : null,
        ),

        // Previous page
        _buildNavButton(
          icon: Icons.chevron_left,
          tooltip: l10n.pagination_previousPage,
          onPressed: widget.currentPage > 0
              ? () => widget.onPageChanged(widget.currentPage - 1)
              : null,
        ),

        const SizedBox(width: 4),

        // Page numbers
        ..._buildPageNumbers(theme, colorScheme),

        const SizedBox(width: 4),

        // Next page
        _buildNavButton(
          icon: Icons.chevron_right,
          tooltip: l10n.pagination_nextPage,
          onPressed: widget.currentPage < widget.totalPages - 1
              ? () => widget.onPageChanged(widget.currentPage + 1)
              : null,
        ),

        // Last page
        _buildNavButton(
          icon: Icons.last_page,
          tooltip: l10n.pagination_lastPage,
          onPressed: widget.currentPage < widget.totalPages - 1
              ? () => widget.onPageChanged(widget.totalPages - 1)
              : null,
        ),

        const SizedBox(width: 8),

        // Jump to page
        _buildJumpToPage(theme, colorScheme),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  List<Widget> _buildPageNumbers(ThemeData theme, ColorScheme colorScheme) {
    final List<Widget> buttons = [];
    final int current = widget.currentPage;
    final int total = widget.totalPages;

    if (total <= 7) {
      // Show all pages
      for (int i = 0; i < total; i++) {
        buttons.add(_buildPageButton(i, theme, colorScheme));
      }
    } else {
      // Show with ellipsis
      // Always show first page
      buttons.add(_buildPageButton(0, theme, colorScheme));

      if (current > 3) {
        buttons.add(_buildEllipsis(theme));
      }

      // Show pages around current
      int start = (current - 1).clamp(1, total - 4);
      int end = (current + 1).clamp(3, total - 2);

      if (current <= 3) {
        end = 4;
      }
      if (current >= total - 4) {
        start = total - 5;
      }

      for (int i = start; i <= end; i++) {
        buttons.add(_buildPageButton(i, theme, colorScheme));
      }

      if (current < total - 4) {
        buttons.add(_buildEllipsis(theme));
      }

      // Always show last page
      buttons.add(_buildPageButton(total - 1, theme, colorScheme));
    }

    return buttons;
  }

  Widget _buildPageButton(int page, ThemeData theme, ColorScheme colorScheme) {
    final isSelected = page == widget.currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: isSelected ? null : () => widget.onPageChanged(page),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '${page + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildJumpToPage(ThemeData theme, ColorScheme colorScheme) {
    if (_isEditing) {
      return SizedBox(
        width: 60,
        height: 32,
        child: ThemedInput(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          onSubmitted: (_) => _submitPage(),
        ),
      );
    }

    return Tooltip(
      message: context.l10n.pagination_jumpToPage,
      child: InkWell(
        onTap: widget.totalPages > 1 ? _startEditing : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.pagination_jump,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPerPageSelector(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.pagination_itemsPerPage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: widget.itemsPerPage,
              isDense: true,
              items: widget.itemsPerPageOptions.map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count', style: theme.textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && widget.onItemsPerPageChanged != null) {
                  widget.onItemsPerPageChanged!(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          context.l10n.pagination_itemUnit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 列宽调节控件：图标按钮点开小弹层，Slider 实时生效、松手持久化
  Widget _buildColumnWidthControl(ThemeData theme, ColorScheme colorScheme) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: MenuAnchor(
        builder: (context, controller, child) => Tooltip(
          message: l10n.localGallery_columnWidth,
          child: IconButton(
            icon: Icon(
              Icons.view_column_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: l10n.localGallery_columnWidth,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(6),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        ),
        style: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        menuChildren: [
          _ColumnWidthMenuPanel(
            width: widget.columnWidth ?? 260,
            onChanged: widget.onColumnWidthChanged,
            onChangeEnd: widget.onColumnWidthChangeEnd,
          ),
        ],
      ),
    );
  }
}

/// 列宽设置弹层：Slider（140~480，步进 20）+ 实时「约 N 列」
class _ColumnWidthMenuPanel extends StatelessWidget {
  final double width;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _ColumnWidthMenuPanel({
    required this.width,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // 「约 N 列」按屏幕宽度估算（列宽越窄列数越多）
    final approxColumns = (MediaQuery.of(context).size.width / width)
        .round()
        .clamp(1, 99);

    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.localGallery_columnWidth,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.localGallery_aboutColumns(approxColumns),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: width,
            min: 140,
            max: 480,
            divisions: 17,
            label: '${width.round()}',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
