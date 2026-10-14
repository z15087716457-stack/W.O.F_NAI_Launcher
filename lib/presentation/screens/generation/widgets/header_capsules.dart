import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:nai_launcher/l10n/app_localizations.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/model_display.dart';
import '../../../../core/constants/model_spec.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/image_params.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/anlas/anlas_balance_chip.dart';
import '../../../widgets/anlas/opus_usage_chip.dart';

/// 头部条「Model + Mode」合一胶囊：共享一颗 28px 外框。
/// 左段 Model 灰标签 + 反色内胆（PopupMenuButton 开模型菜单）；
/// 中间细竖线；右段模式区（仅 V4+ 显示，点击切 Anime/Furry，
/// 模式区隐藏时竖线一并收起，胶囊只剩 Model 段）。
///
/// 主生成页左栏与画风探索页头部共用。
class ModelModeCapsule extends ConsumerWidget {
  const ModelModeCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    // 模式切换只对 v4_prompt 结构有意义（V3 及以下无 base_caption）
    final showMode = ModelSpecs.of(model).v4Prompts;
    final furryMode = showMode
        ? ref.watch(
            generationParamsNotifierProvider.select(
              (params) => params.furryMode,
            ),
          )
        : false;

    // 官网式「胶囊套胶囊」外框：浅色底 + 描边；右段模式区直接 InkWell
    // 不套内胆，竖线天然分段。模式段套 Flexible——合并后胶囊是单行
    // 不可拆的 Row，窄侧栏下由次要的模式文字收缩，模型段保持自然宽度。
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GenerationModelMenuButton(theme: theme, model: model),
          if (showMode) ...[
            Container(
              width: 1,
              height: 16,
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
            Flexible(
              child: InkWell(
                onTap: () => ref
                    .read(generationParamsNotifierProvider.notifier)
                    .updateModelMode(!furryMode),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 8),
                  child: SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 官网同款图标：anime=sakura 樱花 / furry=爪印
                        SvgPicture.asset(
                          furryMode
                              ? 'assets/icons/nai-icon-furry.svg'
                              : 'assets/icons/nai-icon-sakura.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // 官网 Mode 胶囊恒为英文（静拍板：纯英文）
                        Flexible(
                          child: Text(
                            furryMode ? 'Furry' : 'Anime',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GenerationModelMenuButton extends ConsumerWidget {
  const GenerationModelMenuButton({
    super.key,
    required this.theme,
    required this.model,
    this.child,
  });

  final ThemeData theme;
  final String model;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shortName = ModelDisplay.shortNameOf(model);
    final fullName = ImageModels.modelDisplayNames[model] ?? model;

    return PopupMenuButton<String>(
      tooltip: fullName,
      offset: const Offset(0, 4),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      itemBuilder: (context) => [
        _modelGroupHeader(theme, l10n.generation_modelGroupNew),
        for (final m in ImageModels.allModels.where(
          (m) => ModelDisplay.groupOf(m) == ModelListGroup.newer,
        ))
          _modelMenuItem(context, l10n, theme, m, model),
        _modelGroupHeader(theme, l10n.generation_modelGroupLegacy),
        for (final m in ImageModels.allModels.where(
          (m) => ModelDisplay.groupOf(m) == ModelListGroup.legacy,
        ))
          _modelMenuItem(context, l10n, theme, m, model),
      ],
      onSelected: (value) {
        ref.read(generationParamsNotifierProvider.notifier).updateModel(value);
      },
      child:
          child ??
          Container(
            // 左段：Model 灰标签 + 反色内胆（图标+短名+▾）作为点击热区视觉锚点；
            // 外框/描边上移给 ModelModeCapsule 共享壳。
            height: 28,
            padding: const EdgeInsets.only(left: 10, right: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Model',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    // 官网式反色内胆：浅色底 + 深色内容（onSurface/surface
                    // 互反，深浅主题自动镜像）
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/novelai-icon.svg',
                        width: 14,
                        height: 14,
                        // 素材是纯黑剪影，srcIn 着色随内胆底色取反
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.surface,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          shortName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.surface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 15,
                        color: theme.colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  PopupMenuEntry<String> _modelGroupHeader(ThemeData theme, String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  PopupMenuEntry<String> _modelMenuItem(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String m,
    String current,
  ) {
    final fullName = ImageModels.modelDisplayNames[m] ?? m;
    final description = ModelDisplay.descriptionOf(l10n, m);
    return PopupMenuItem<String>(
      value: m,
      height: description != null ? 48 : 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: m == current
                ? theme.colorScheme.primary
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 静拍板：官网 NEW 徽标不搬，去掉（显得很怪）
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 头部条额度胶囊（官网式）：Opus 免费额度 + Anlas 余额两格共用一颗
/// 与 Model/Mode 同款的描边外框（28 高 / 圆角 8），中间竖线分隔；
/// Opus 格隐藏（V4 及更早、无额度数据）时竖线一并收起，余额单独居中。
///
/// 主生成页左栏与画风探索页头部共用。
class QuotaChipsCapsule extends ConsumerWidget {
  const QuotaChipsCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 与 OpusUsageChip 自身显隐条件同源：双守卫下竖线不会出现「
    // 半边有内容半边空」的状态
    final hasUsageLimit = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.modelSpec.opusUsageLimit,
      ),
    );
    final hasUsageData = ref.watch(
      subscriptionNotifierProvider.select(
        (state) => state.subscription?.usage != null,
      ),
    );
    final showOpus = hasUsageLimit && hasUsageData;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showOpus) ...[
            const OpusUsageChip(
              compact: true,
              inline: true,
              margin: EdgeInsets.symmetric(horizontal: 2),
            ),
            // 中缝竖线：同描边色、高度留白，避免顶穿外框
            Container(
              width: 1,
              height: 14,
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: AnlasBalanceChip(compact: true, inline: true),
          ),
        ],
      ),
    );
  }
}
