import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 本地放大组件的装饰性品牌标记；名称与语义由旁边的标题提供。
class UpscaleBrandLogo extends StatelessWidget {
  const UpscaleBrandLogo.seedvr({super.key, this.size = 22}) : _nvidia = false;
  const UpscaleBrandLogo.nvidia({super.key, this.size = 22}) : _nvidia = true;

  final double size;
  final bool _nvidia;

  @override
  Widget build(BuildContext context) {
    if (_nvidia) {
      return SvgPicture.asset(
        'assets/icons/providers/nvidia.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: const ColorFilter.mode(Color(0xff76b900), BlendMode.srcIn),
      );
    }
    // 保留原 1280 × 342 图像，只显示左侧 320 × 320 徽记。
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox.square(
              dimension: 320,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 1280,
                  maxWidth: 1280,
                  minHeight: 342,
                  maxHeight: 342,
                  child: Image.asset(
                    'assets/icons/seedvr_logo.png',
                    width: 1280,
                    height: 342,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
