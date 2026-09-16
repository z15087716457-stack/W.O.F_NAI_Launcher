import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/generation_layout_mode_provider.dart';
import '../../widgets/drop/global_drop_handler.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';
import 'web_style_layout.dart';

/// 图像生成页面
class GenerationScreen extends ConsumerWidget {
  const GenerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlobalDropHandler(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 桌面端布局 (宽度 >= 1000)
          if (constraints.maxWidth >= 1000) {
            final layoutMode = ref.watch(generationLayoutModeNotifierProvider);
            return layoutMode == GenerationLayoutMode.webStyle
                ? const WebStyleGenerationLayout()
                : const DesktopGenerationLayout();
          }

          return const MobileGenerationLayout();
        },
      ),
    );
  }
}
