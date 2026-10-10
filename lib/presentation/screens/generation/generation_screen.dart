import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/drop/global_drop_handler.dart';
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
            return const WebStyleGenerationLayout();
          }

          return const MobileGenerationLayout();
        },
      ),
    );
  }
}
