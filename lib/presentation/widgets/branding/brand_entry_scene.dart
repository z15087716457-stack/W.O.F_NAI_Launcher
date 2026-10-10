import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_version.dart';
import '../../../core/services/titlebar_region_service.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/theme_provider.dart';
import '../../themes/studio_typography.dart';
import '../auth/entry_controls.dart';
import 'entry_field.dart';

/// The complete, original wordmark. The asset only removes empty source margins;
/// both the W.O.F block and the NAI STUDIO signature remain in their original ratio.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 360});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/wof_logo_full.png',
    width: width,
    height: width * 547 / 1111,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'W.O.F NAI Studio',
  );
}

/// 登录与载入共用的整页场景。
///
/// 背景是「去噪」字符场 [EntryField]；Logo、标语与下方的载入进度或登录
/// 卡片作为一个整体放在视区的视觉中心（略高于正中）。换成高矮不同的卡片
/// 时整体平滑滑到新位置，载入页换登录页时也从载入页的位置滑过去，背景
/// 接着走。页脚左侧是客户端说明，右侧是种子 / 去噪步数与版本号。
class BrandEntryScene extends ConsumerStatefulWidget {
  const BrandEntryScene({
    super.key,
    required this.child,
    this.layoutKey,
    this.loading = false,
    this.progress = 0,
    this.busy = false,
  });

  final Widget child;

  /// 当前卡片的标识。变化时按新卡片的高度重新居中；同一张卡片内部变高
  /// （展开账号列表、切换登录方式、出现错误提示）只向下延伸，不挪动正在
  /// 操作的内容。
  final Object? layoutKey;

  /// 载入页：背景随 [progress] 去噪，不穿插解码事件。
  final bool loading;
  final double progress;

  /// 登录中：背景加速去噪。
  final bool busy;

  /// 卡片与进度区的最大宽度。
  static const double panelWidth = 380;

  @override
  ConsumerState<BrandEntryScene> createState() => _BrandEntrySceneState();
}

class _BrandEntrySceneState extends ConsumerState<BrandEntryScene>
    with SingleTickerProviderStateMixin {
  final _heroKey = GlobalKey();
  final _pointer = ValueNotifier<Offset?>(null);
  final _card = _CardHeight();
  late final AnimationController _glide;
  late final Animation<double> _glideCurve;

  @override
  void initState() {
    super.initState();
    // 新场景从上一个场景的位置滑到自己的位置（没有上一个场景时原地不动）
    _glide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _glideCurve = CurvedAnimation(parent: _glide, curve: Curves.easeInOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _glide.value = 1;
  }

  @override
  void didUpdateWidget(BrandEntryScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layoutKey != oldWidget.layoutKey) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _glide.value = 1;
      } else {
        _glide.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _glide.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = EntryPalette.of(context);
    final chromeInBar = TitleBarRegionService.isSupported;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onHover: (event) => _pointer.value = event.localPosition,
        onExit: (_) => _pointer.value = null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            // Logo 按整窗高度取尺寸，载入页和登录页一样大
            final windowHeight = height;
            final logoWidth = math.max(
              180.0,
              math.min(300.0, math.min(width - 96, (windowHeight - 80) * 0.36)),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: EntryField(
                    signal: widget.loading ? widget.progress : 0,
                    ambient: !widget.loading,
                    busy: widget.busy,
                    clearKey: _heroKey,
                    pointer: _pointer,
                  ),
                ),
                Positioned.fill(
                  bottom: 44,
                  child: SingleChildScrollView(
                    key: const Key('brand_entry_scroll'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _HeroPlacement(
                      card: _card,
                      viewportHeight: height - 44,
                      anchorKey: widget.layoutKey,
                      glide: _glideCurve,
                      child: Column(
                        key: _heroKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BrandLogo(width: logoWidth),
                          const SizedBox(height: 18),
                          Text(
                            context.l10n.brand_entryTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 2.6,
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 36),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(
                                BrandEntryScene.panelWidth,
                                width - 32,
                              ),
                            ),
                            child: _CardProbe(card: _card, child: widget.child),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 0,
                  height: 44,
                  child: IgnorePointer(
                    child: _Footer(
                      loading: widget.loading,
                      busy: widget.busy,
                      progress: widget.progress,
                    ),
                  ),
                ),
                // 非 Windows 没有自绘标题栏，明暗切换放回页面右上角
                if (!chromeInBar)
                  Positioned(
                    top: 8,
                    right: 12,
                    child: IconButton(
                      key: const Key('brand_appearance_toggle'),
                      tooltip: palette.dark
                          ? context.l10n.brand_switchToLight
                          : context.l10n.brand_switchToDark,
                      onPressed: () =>
                          ref.read(themeNotifierProvider.notifier).nextTheme(),
                      icon: Icon(
                        palette.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 卡片区的实测高度：[_CardProbe] 布局时写入，[_HeroPlacement] 在同一趟
/// 布局里读取。
class _CardHeight {
  double value = 0;
}

class _CardProbe extends SingleChildRenderObjectWidget {
  const _CardProbe({required this.card, super.child});

  final _CardHeight card;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCardProbe(card);

  @override
  void updateRenderObject(BuildContext context, _RenderCardProbe renderObject) {
    renderObject.card = card;
  }
}

class _RenderCardProbe extends RenderProxyBox {
  _RenderCardProbe(this.card);

  _CardHeight card;

  @override
  void performLayout() {
    super.performLayout();
    card.value = size.height;
  }
}

/// 上一个入口场景最后锚定的卡片高度：载入页换成登录页时，Logo 从载入页
/// 的位置滑到登录卡片对应的位置。
double? _carriedCardHeight;

/// 把 Logo + 标语 + 卡片整体放在视区的视觉中心。
///
/// 居中用「锚定」的卡片高度。[anchorKey] 变化（换卡片）后的 [glide] 期间
/// 跟随卡片的实时高度，并把换卡片那一刻新旧高度之差随 [glide] 收掉：卡片
/// 瞬间换成另一张时整体平滑滑过去，卡片自己连续长大 / 缩小（按钮展开成
/// 表单）时整体实时居中、卡片向上下两边长开。[glide] 结束后锚点固定，
/// 卡片内部再变高只向下延伸。内容高过视区时顶部留 [minTop]，由外层滚动。
class _HeroPlacement extends SingleChildRenderObjectWidget {
  const _HeroPlacement({
    required this.card,
    required this.viewportHeight,
    required this.anchorKey,
    required this.glide,
    required super.child,
  });

  final _CardHeight card;
  final double viewportHeight;
  final Object? anchorKey;
  final Animation<double> glide;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeroPlacement(
    card: card,
    viewportHeight: viewportHeight,
    anchorKey: anchorKey,
    glide: glide,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeroPlacement renderObject,
  ) {
    renderObject
      ..card = card
      ..viewportHeight = viewportHeight
      ..anchorKey = anchorKey
      ..glide = glide;
  }
}

class _RenderHeroPlacement extends RenderShiftedBox {
  _RenderHeroPlacement({
    required _CardHeight card,
    required double viewportHeight,
    required Object? anchorKey,
    required Animation<double> glide,
  }) : _card = card,
       _viewportHeight = viewportHeight,
       _anchorKey = anchorKey,
       _glide = glide,
       _from = _carriedCardHeight,
       super(null);

  /// 整体中心在视区高度的这个比例处，略高于正中才显得居中。
  static const double opticalCenter = 0.45;
  static const double minTop = 20;
  static const double bottomGap = 40;

  _CardHeight _card;
  set card(_CardHeight value) {
    if (identical(value, _card)) return;
    _card = value;
    markNeedsLayout();
  }

  double _viewportHeight;
  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsLayout();
  }

  Object? _anchorKey;
  set anchorKey(Object? value) {
    if (value == _anchorKey) return;
    _anchorKey = value;
    // 从当前位置出发；与新卡片的高度差等这一趟布局量到后再定
    _from = _anchor;
    _gap = null;
    _tracking = true;
    markNeedsLayout();
  }

  Animation<double> _glide;
  set glide(Animation<double> value) {
    if (identical(value, _glide)) return;
    if (attached) _glide.removeListener(_onGlide);
    _glide = value;
    if (attached) _glide.addListener(_onGlide);
    markNeedsLayout();
  }

  /// 换卡片前的锚点。
  double? _from;

  /// 换卡片那一刻旧锚点与新卡片高度之差，随 [glide] 收到 0。
  double? _gap;

  /// 跟随中的卡片高度；[glide] 走完的那一帧最后取一次，之后固定。
  double _to = 0;
  bool _tracking = true;
  double? _anchor;

  void _onGlide() => markNeedsLayout();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _glide.addListener(_onGlide);
  }

  @override
  void detach() {
    _glide.removeListener(_onGlide);
    super.detach();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(width, _viewportHeight));
      return;
    }
    child.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    final live = _card.value;
    final t = _glide.value;
    if (_tracking) {
      _to = live;
      _tracking = t < 1;
    }
    final gap = _gap ??= (_from ?? live) - live;
    final anchor = _anchor = _to + gap * (1 - t);
    _carriedCardHeight = anchor;
    final head = child.size.height - _card.value;
    final top = math.max(
      minTop,
      _viewportHeight * opticalCenter - (head + anchor) / 2,
    );
    (child.parentData! as BoxParentData).offset = Offset(
      (width - child.size.width) / 2,
      top,
    );
    size = constraints.constrain(
      Size(
        width,
        math.max(_viewportHeight, top + child.size.height + bottomGap),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.busy,
    required this.progress,
  });

  final bool loading;
  final bool busy;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final hud = StudioTypography.data.copyWith(
      fontSize: 10.5,
      letterSpacing: 0.84,
      color: palette.faint,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.app_subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: palette.faint),
          ),
        ),
        const SizedBox(width: 12),
        ExcludeSemantics(
          child: ListenableBuilder(
            listenable: Listenable.merge([EntryField.seed, EntryField.level]),
            builder: (context, _) {
              final denoising = loading || busy;
              final level = loading ? progress : EntryField.level.value;
              final step = (level.clamp(0.0, 1.0) * 28).round();
              return Text.rich(
                TextSpan(
                  children: [
                    if (denoising) ...[
                      TextSpan(
                        text: 'DENOISE  ',
                        style: TextStyle(color: palette.muted),
                      ),
                      TextSpan(
                        text: 'STEP ${step.toString().padLeft(2, '0')}/28  ·  ',
                      ),
                    ],
                    TextSpan(text: 'SEED ${EntryField.seed.value}  ·  '),
                    TextSpan(text: 'v${AppVersion.versionName}'),
                  ],
                ),
                style: hud,
              );
            },
          ),
        ),
      ],
    );
  }
}
