import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../providers/canvas_channel_provider.dart';
import '../../../providers/tips_provider.dart';
import '../../../ui/channel/channel_contract.dart';
import '../../../ui/channel/channel_layer.dart';
import '../../../widgets/branding/brand_entry_scene.dart';
import '../../../widgets/common/tip_welcome.dart';

/// Calm canvas empty state. A tip is chosen once per visit, never on a timer.
class GenerationWelcome extends StatelessWidget {
  const GenerationWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ChannelHostBackdropScope.activeOf(context)) {
      return _buildWelcome(backdropActive: false);
    }
    return const _BackdropAwareGenerationWelcome();
  }
}

class _BackdropAwareGenerationWelcome extends ConsumerWidget {
  const _BackdropAwareGenerationWelcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      canvasChannelNotifierProvider.select((s) => s.mode != ChannelMode.off),
    );
    return _buildWelcome(backdropActive: active);
  }
}

Widget _buildWelcome({required bool backdropActive}) => TipWelcome(
  surface: TipSurface.studio,
  logoAspectRatio: 1111 / 547,
  logoWidthFor: (column) => math.min(300, column * .8),
  logoBuilder: (width) => BrandLogo(width: width),
  backdropActive: backdropActive,
);
