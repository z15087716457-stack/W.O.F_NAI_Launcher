import 'dart:typed_data';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/krita/krita_outbound_image.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../widgets/common/app_toast.dart';

class KritaSendHelper {
  const KritaSendHelper._();

  static void sendImageBytes(
    BuildContext context,
    WidgetRef ref,
    Uint8List imageBytes, {
    required String name,
  }) {
    final outboundImage = _prepareImage(context, imageBytes, name);
    if (outboundImage == null) {
      return;
    }

    final sent = ref
        .read(kritaBridgeNotifierProvider.notifier)
        .sendImageToKrita(outboundImage.bytes, name: outboundImage.name);
    if (!sent) {
      AppToast.warning(context, context.l10n.toast_kritaNotConnected);
      return;
    }

    AppToast.success(context, context.l10n.toast_sentToKrita);
  }

  static KritaOutboundImage? _prepareImage(
    BuildContext context,
    Uint8List imageBytes,
    String name,
  ) {
    try {
      return KritaOutboundImage.prepare(imageBytes, name: name);
    } on FormatException {
      AppToast.warning(context, context.l10n.toast_kritaUnsupportedImageFormat);
      return null;
    }
  }
}
