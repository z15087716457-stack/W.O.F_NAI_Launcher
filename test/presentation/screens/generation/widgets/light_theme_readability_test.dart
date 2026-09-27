import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/providers/comfyui/comfyui_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/img2img_panel.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/precise_reference_panel.dart';

import '../../../../helpers/light_theme_contrast.dart';

/// 生成页折叠面板的浅色主题可读性守卫。
///
/// 这些面板都基于 CollapsibleImagePanel：折叠带图时使用随主题变化的玻璃
/// 色调；展开后内容直接贴在 Card 表面。每个用例都把面板展开、并尽量打开
/// 会额外渲染文案的分支，再断言没有近白色文字。
void main() {
  group('生成页面板浅色主题可读性', () {
    testWidgets('Img2ImgPanel（重绘）', (tester) async {
      final container = createStorageFreeContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.enterInpaintMode();
      controller.setPanelExpanded(true);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const Img2ImgPanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'Img2ImgPanel（重绘）');
    });

    testWidgets('Img2ImgPanel（增强）', (tester) async {
      final container = createStorageFreeContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.enterEnhanceMode();
      controller.toggleEnhanceIndividualSettings(true);
      controller.setPanelExpanded(true);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const Img2ImgPanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'Img2ImgPanel（增强）');
    });

    testWidgets('Img2ImgPanel（放大）', (tester) async {
      // 打开 ComfyUI 才会渲染放大模块选择、模型下拉与各项提示文案，
      // 那里集中了原先写死的白色标签。
      final container = createStorageFreeContainer(
        overrides: [
          comfyUISettingsProvider.overrideWith(_EnabledComfyUISettings.new),
          comfyUISeedvr2ModelsProvider.overrideWith(
            _FixedComfyUIUpscaleModels.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.enterUpscaleMode();
      controller.updateSeedvr2Tiled(true);
      controller.setPanelExpanded(true);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const Img2ImgPanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'Img2ImgPanel（放大）');
    });

    testWidgets('Img2ImgPanel（空状态）', (tester) async {
      final container = createStorageFreeContainer();
      addTearDown(container.dispose);

      container
          .read(imageWorkflowControllerProvider.notifier)
          .setPanelExpanded(true);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const Img2ImgPanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'Img2ImgPanel（空状态）');
    });

    testWidgets('PreciseReferencePanel（展开）', (tester) async {
      final container = createStorageFreeContainer();
      addTearDown(container.dispose);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const PreciseReferencePanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'PreciseReferencePanel');
    });

    // UnifiedReferencePanel（Vibe Transfer）未纳入：它在构建时会拉起 Vibe
    // 库的存储与预编码链，widget test 中 pumpAndSettle 无法收敛（实测 >2
    // 分钟仍未完成）。其内容组件 vibe_transfer_content.dart 里的白色已人工
    // 核验，折叠图片的前景色也要随浅色玻璃切换；此用例仍只覆盖展开态。
  });
}

final Uint8List _testImageBytes = Uint8List.fromList(
  img.encodePng(img.Image(width: 8, height: 8)),
);

class _EnabledComfyUISettings extends ComfyUISettings {
  @override
  ComfyUISettingsState build() {
    return const ComfyUISettingsState(enabled: true);
  }
}

class _FixedComfyUIUpscaleModels extends ComfyUISeedvr2Models {
  @override
  List<String> build() {
    return const ['seedvr2_ema_7b_fp16.safetensors', '4x-UltraSharpV2.pth'];
  }

  @override
  Future<void> fetch({bool force = false}) async {}
}
