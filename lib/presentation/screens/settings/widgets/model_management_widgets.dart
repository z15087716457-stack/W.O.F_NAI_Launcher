import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import 'model_compact_dropdown.dart';
import '../../../../core/utils/localization_extension.dart';

IconData interfaceIcon(LauncherInterface task) => switch (task) {
  LauncherInterface.translate => Icons.south,
  LauncherInterface.promptReverse => Icons.north,
  LauncherInterface.tagTranslate => Icons.label_outline,
  LauncherInterface.wikiTranslate => Icons.menu_book_outlined,
};

Future<LauncherInterface?> showInterfacePresetMenu(
  BuildContext context, {
  Offset? globalPosition,
}) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final anchor = context.findRenderObject()! as RenderBox;
  final position = overlay.globalToLocal(
    globalPosition ?? anchor.localToGlobal(Offset(anchor.size.width - 24, 64)),
  );
  return showMenu<LauncherInterface>(
    context: context,
    shape: modelMenuShape,
    elevation: 3,
    clipBehavior: Clip.antiAlias,
    shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: .14),
    position: RelativeRect.fromSize(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      overlay.size,
    ),
    items: [
      for (final task in LauncherInterface.values)
        PopupMenuItem(
          value: task,
          child: Row(
            children: [
              Icon(interfaceIcon(task), size: 18),
              const SizedBox(width: 12),
              Text(task.titleIn(context.l10n)),
            ],
          ),
        ),
    ],
  );
}

class ManagementTabs extends StatelessWidget {
  const ManagementTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.inProgress = false,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool inProgress;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Stack(
              children: [
                TextButton(
                  onPressed: () => onSelected(i),
                  style: TextButton.styleFrom(
                    foregroundColor: i == selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: i == selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (i == selected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _TabUnderline(inProgress: inProgress),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// The existing tab marker carries activity without adding layout height.
class _TabUnderline extends StatefulWidget {
  const _TabUnderline({required this.inProgress});
  final bool inProgress;
  @override
  State<_TabUnderline> createState() => _TabUnderlineState();
}

class _TabUnderlineState extends State<_TabUnderline>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _animate = false;

  void _syncMotion() {
    final animate =
        widget.inProgress &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate == _animate) return;
    _animate = animate;
    if (animate) {
      _motion.repeat(reverse: true);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _TabUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.inProgress ? context.l10n.modelSettings_testingPreset : null,
    child: AnimatedBuilder(
      animation: _motion,
      builder: (context, _) => AnimatedAlign(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        alignment: Alignment(_animate ? -1 + 2 * _motion.value : 0, 0),
        child: FractionallySizedBox(
          widthFactor: _animate ? .42 : 1,
          child: SizedBox(
            key: const Key('management-tab-underline'),
            height: 2,
            child: ColoredBox(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    ),
  );
}

class ManagementHeading extends StatelessWidget {
  const ManagementHeading(
    this.title, {
    super.key,
    this.description,
    this.actions = const [],
    this.titleSize = 22,
  });
  final String title;
  final String? description;
  final List<Widget> actions;
  final double titleSize;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: titleSize,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
        return constraints.maxWidth < 440
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 12),
                  ...actions,
                ],
              );
      },
    ),
  );
}

class ManagementListItem extends StatelessWidget {
  const ManagementListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
  final String title, subtitle;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: .08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 18,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  child: icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 4), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManagementSplit extends StatelessWidget {
  const ManagementSplit({
    super.key,
    required this.list,
    required this.detail,
    required this.compactPicker,
  });
  final Widget list, detail, compactPicker;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 700
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 184, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: detail),
            ],
          )
        : Column(
            children: [
              Padding(padding: const EdgeInsets.all(12), child: compactPicker),
              const Divider(height: 1),
              Expanded(child: detail),
            ],
          ),
  );
}
