import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import 'provider_logo.dart';

class CompactServiceConnection extends StatelessWidget {
  const CompactServiceConnection({
    super.key,
    required this.preset,
    required this.protocol,
    required this.name,
    required this.url,
    required this.apiKey,
    required this.onChooseProvider,
    required this.onProtocolChanged,
    required this.keyHint,
    this.enabled = true,
  });
  final ProviderPreset preset;
  final ProviderProtocol protocol;
  final TextEditingController name, url, apiKey;
  final VoidCallback onChooseProvider;
  final ValueChanged<ProviderProtocol> onProtocolChanged;
  final bool enabled;
  final String keyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(fontSize: 11);
    Widget field(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 5),
        child,
      ],
    );
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    );
    final provider = field(
      '服务商',
      InkWell(
        key: const Key('service-provider-picker'),
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onChooseProvider : null,
        child: InputDecorator(
          decoration: decoration(''),
          child: Row(
            children: [
              ProviderLogo(preset, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  preset.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const Icon(Icons.unfold_more_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
    final title = field(
      '名称',
      TextField(
        controller: name,
        enabled: enabled,
        style: theme.textTheme.bodySmall,
        decoration: decoration('例如：自用中转'),
      ),
    );
    final format = field(
      '接口协议',
      DropdownButtonFormField<ProviderProtocol>(
        key: ValueKey('service-protocol-${protocol.name}'),
        initialValue: protocol,
        isExpanded: true,
        style: theme.textTheme.bodySmall,
        decoration: decoration(''),
        items: [
          for (final value in ProviderProtocol.values)
            DropdownMenuItem(
              value: value,
              child: Text(
                value.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
        onChanged: enabled
            ? (value) {
                if (value != null) onProtocolChanged(value);
              }
            : null,
      ),
    );
    final address = field(
      '接口地址',
      TextField(
        controller: url,
        enabled: enabled,
        style: theme.textTheme.bodySmall,
        decoration: decoration('https://example.com/v1'),
      ),
    );
    final secret = field(
      'API 密钥',
      TextField(
        controller: apiKey,
        obscureText: true,
        enabled: enabled,
        style: theme.textTheme.bodySmall,
        decoration: decoration(keyHint),
      ),
    );
    Widget pair(
      Widget left,
      Widget right, {
      int leftFlex = 1,
      int rightFlex = 1,
    }) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 12),
        Expanded(flex: rightFlex, child: right),
      ],
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final wide = bounds.maxWidth >= 700 * scale;
        final narrow = bounds.maxWidth < 430 * scale;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: provider),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: title),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: format),
                ],
              )
            else if (narrow) ...[
              provider,
              const SizedBox(height: 10),
              title,
              const SizedBox(height: 10),
              format,
            ] else ...[
              pair(provider, title),
              const SizedBox(height: 10),
              format,
            ],
            const SizedBox(height: 12),
            if (narrow) ...[
              address,
              const SizedBox(height: 10),
              secret,
            ] else
              pair(address, secret, leftFlex: 6, rightFlex: 4),
            const SizedBox(height: 8),
            Text(
              preset.connectionHint,
              style: labelStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
