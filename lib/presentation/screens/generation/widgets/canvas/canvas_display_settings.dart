import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/constants/model_spec.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../widgets/image_editor/widgets/color_picker.dart';
import 'canvas_image_background.dart';

/// Official display.settings: anchored fit toggle + model-gated alpha backdrop.
/// Evidence: cached 5285 display.settings and 5468 module 80341.
class CanvasDisplaySettingsButton extends StatelessWidget {
  const CanvasDisplaySettingsButton({super.key});

  @override
  Widget build(BuildContext context) => MenuAnchor(
    consumeOutsideTap: true,
    alignmentOffset: const Offset(0, 6),
    style: const MenuStyle(
      alignment: AlignmentDirectional.bottomStart,
      padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
    ),
    menuChildren: const [_DisplaySettingsPanel()],
    builder: (context, controller, child) => Tooltip(
      message: context.l10n.generation_canvasDisplaySettings,
      child: InkWell(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: SvgPicture.asset(
            'assets/icons/nai-icon-settings.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ),
  );
}

class _DisplaySettingsPanel extends ConsumerStatefulWidget {
  const _DisplaySettingsPanel();

  @override
  ConsumerState<_DisplaySettingsPanel> createState() =>
      _DisplaySettingsPanelState();
}

class _DisplaySettingsPanelState extends ConsumerState<_DisplaySettingsPanel> {
  bool _showBackground = false;
  bool _showCustom = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fill = ref.watch(canvasZoomToFillNotifierProvider);
    final background = ref.watch(canvasImageBackgroundNotifierProvider);
    final model = ref.watch(
      generationParamsNotifierProvider.select((p) => p.model),
    );
    final transparency = ModelSpecs.of(model).transparency;
    final showPalette = transparency && _showBackground;
    return SizedBox(
      width: showPalette
          ? 236
          : transparency
          ? 96
          : 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.generation_canvasZoomToFill,
                isSelected: fill,
                icon: const StudioIcon(Icons.open_in_full, size: 18),
                selectedIcon: const StudioIcon(Icons.open_in_full, size: 18),
                onPressed: () => ref
                    .read(canvasZoomToFillNotifierProvider.notifier)
                    .toggle(),
              ),
              if (transparency)
                IconButton(
                  tooltip: l10n.generation_canvasBackground,
                  isSelected: _showBackground || background != 'checker',
                  icon: const StudioIcon(Icons.grid_on, size: 18),
                  onPressed: () =>
                      setState(() => _showBackground = !_showBackground),
                ),
            ],
          ),
          if (showPalette)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.generation_canvasBackground,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final value
                          in CanvasImageBackgroundNotifier.presets.take(4))
                        _swatch(context, value, background),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final value
                          in CanvasImageBackgroundNotifier.presets.skip(4))
                        _swatch(context, value, background),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: l10n.generation_canvasBackgroundCustom,
                          icon: const StudioIcon(Icons.colorize, size: 17),
                          onPressed: () =>
                              setState(() => _showCustom = !_showCustom),
                        ),
                      ),
                    ],
                  ),
                  if (_showCustom) ...[
                    const SizedBox(height: 12),
                    HSVColorPicker(
                      color: background.startsWith('#')
                          ? Color(
                              0xFF000000 |
                                  int.parse(background.substring(1), radix: 16),
                            )
                          : const Color(0xFF808080),
                      onColorChanged: (color) => ref
                          .read(canvasImageBackgroundNotifierProvider.notifier)
                          .set(
                            '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                          ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _swatch(BuildContext context, String value, String selected) =>
      Tooltip(
        message: _backgroundLabel(context.l10n, value),
        child: Semantics(
          button: true,
          selected: selected == value,
          child: InkWell(
            key: ValueKey('canvas-background:$value'),
            onTap: () => ref
                .read(canvasImageBackgroundNotifierProvider.notifier)
                .set(value),
            customBorder: const CircleBorder(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: selected == value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: CanvasImageBackdrop(
                  value: value,
                  child: value == 'none'
                      ? const StudioIcon(Icons.block, size: 18)
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
}

String _backgroundLabel(AppLocalizations l10n, String value) => switch (value) {
  'checker' => l10n.generation_canvasBackgroundChecker,
  'checkerLight' => l10n.generation_canvasBackgroundCheckerLight,
  'checkerDark' => l10n.generation_canvasBackgroundCheckerDark,
  'none' => l10n.generation_canvasBackgroundNone,
  'black' => l10n.generation_canvasBackgroundBlack,
  'white' => l10n.generation_canvasBackgroundWhite,
  'gray' => l10n.generation_canvasBackgroundGray,
  'red' => l10n.generation_canvasBackgroundRed,
  'green' => l10n.generation_canvasBackgroundGreen,
  'blue' => l10n.generation_canvasBackgroundBlue,
  _ => l10n.generation_canvasBackgroundCustom,
};
