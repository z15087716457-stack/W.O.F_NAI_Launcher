import 'package:flutter/material.dart';

import '../../../prompt_assistant/providers/provider_connection_health_provider.dart';
import '../../../../core/utils/localization_extension.dart';

class ProviderConnectionStatusDot extends StatelessWidget {
  const ProviderConnectionStatusDot({
    super.key,
    required this.providerName,
    required this.result,
  });

  final String providerName;
  final ProviderConnectionResult result;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (result.status) {
      ProviderConnectionStatus.healthy =>
        dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      ProviderConnectionStatus.failed =>
        dark ? const Color(0xFFF87171) : const Color(0xFFDC3D38),
      _ => dark ? const Color(0xFFFACC15) : const Color(0xFFD79A00),
    };
    final time = result.checkedAt?.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final message =
        '${result.descriptionIn(context.l10n)}${time == null ? '' : '\n${context.l10n.modelHealth_lastUpdated('${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}')}'}';
    return Tooltip(
      message: message,
      child: Semantics(
        label: '$providerName：$message',
        child: SizedBox(
          width: 26,
          height: 32,
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}
