import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_card.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'statistics_contract.dart';
import 'statistics_layout.dart';

/// 首次统计中：和正式页面同样的卡片骨架。
class StatsLoadingBody extends StatelessWidget {
  const StatsLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(double chart, {double title = 90}) => UiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiSkeleton(width: title, height: 14),
          const SizedBox(height: 18),
          UiSkeleton(height: chart, opacity: .7),
        ],
      ),
    );
    return StatsPageFrame(
      builder: (layout) => [
        UiCard(
          padding: EdgeInsets.zero,
          child: StatsKpiFrame(
            cells: [
              for (var i = 0; i < 5; i++)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiSkeleton(width: 60, height: 12),
                    SizedBox(height: 10),
                    UiSkeleton(width: 120, height: 26),
                    SizedBox(height: 9),
                    UiSkeleton(width: 150, height: 11),
                  ],
                ),
            ],
          ),
        ),
        block(130),
        block(230),
        StatsCardGrid(
          columns: layout.columns,
          children: [for (var i = 0; i < 3; i++) block(200, title: 80)],
        ),
      ],
    );
  }
}

/// 图库为空：引导去生图或加文件夹。
class StatsEmptyBody extends StatelessWidget {
  const StatsEmptyBody({super.key, required this.actions});
  final StatsActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredMessage(
      icon: Icon(StudioIcons.statistics, size: 30, color: context.ui.muted),
      title: l10n.stats_emptyTitle,
      body: l10n.stats_emptyBody,
      buttons: [
        UiChipButton(
          key: const Key('stats-empty-generate'),
          primary: true,
          onPressed: actions.onGoGenerate,
          children: [Text(l10n.stats_emptyGenerate)],
        ),
        UiChipButton(
          key: const Key('stats-empty-add-folder'),
          onPressed: actions.onAddGalleryFolder,
          children: [Text(l10n.stats_emptyAddFolder)],
        ),
      ],
    );
  }
}

/// 没有任何结果且出错：显示原因和重试。
class StatsErrorBody extends StatelessWidget {
  const StatsErrorBody({
    super.key,
    required this.message,
    required this.actions,
  });
  final String message;
  final StatsActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredMessage(
      icon: UiGlyph(UiGlyphs.alert, size: 28, color: context.ui.error),
      title: l10n.stats_errorTitle,
      body: message,
      selectableBody: true,
      buttons: [
        UiChipButton(
          key: const Key('stats-error-retry'),
          primary: true,
          onPressed: actions.onRefresh,
          children: [Text(l10n.stats_errorRetry)],
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttons,
    this.selectableBody = false,
  });

  final Widget icon;
  final String title;
  final String body;
  final List<Widget> buttons;
  final bool selectableBody;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final bodyStyle = UiText.sans(13, color: c.muted);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.control,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: icon,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: UiText.sans(16, weight: FontWeight.w600, color: c.ink),
              ),
              const SizedBox(height: 10),
              if (selectableBody)
                SelectableText(
                  body,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
                )
              else
                Text(body, textAlign: TextAlign.center, style: bodyStyle),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: buttons,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
