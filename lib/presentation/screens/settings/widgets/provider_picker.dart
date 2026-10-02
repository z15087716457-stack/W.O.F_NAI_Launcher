import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import 'provider_logo.dart';
import 'settings_dialog.dart';

Future<ProviderPreset?> showProviderPicker(
  BuildContext context,
  ProviderPreset value,
) => showDialog<ProviderPreset>(
  context: context,
  builder: (_) => _ProviderPicker(value: value),
);

class _ProviderPicker extends StatefulWidget {
  const _ProviderPicker({required this.value});
  final ProviderPreset value;
  @override
  State<_ProviderPicker> createState() => _ProviderPickerState();
}

class _ProviderPickerState extends State<_ProviderPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices = ProviderPresetDefaults.selectable
        .where(
          (p) =>
              '${p.label} ${p.group} ${Uri.tryParse(p.defaultBaseUrl)?.host ?? ''}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    return SettingsDialogFrame(
      title: '选择服务商',
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('provider-search'),
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: '搜索厂商、平台或本地服务',
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SizedBox(
              height: 420,
              child: ListView(
                children: [
                  if (choices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('没有匹配的服务商'),
                    ),
                  for (final group in const ['国内厂商', '国际厂商', '聚合平台', '本地与自定义'])
                    if (choices.any((p) => p.group == group)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                        child: Text(
                          group,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final preset in choices.where(
                        (p) => p.group == group,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: preset == widget.value.vendor
                                ? theme.colorScheme.primary.withValues(
                                    alpha: .07,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: ValueKey('choose-provider-${preset.name}'),
                              leading: ProviderLogo(preset, size: 25),
                              title: Text(preset.label),
                              subtitle: Text(
                                preset.defaultBaseUrl.isEmpty
                                    ? '兼容接口 · 地址自行填写'
                                    : Uri.parse(preset.defaultBaseUrl).host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: preset == widget.value.vendor
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(context, preset),
                            ),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
