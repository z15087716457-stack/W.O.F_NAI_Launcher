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
    final choices =
        ProviderPresetDefaults.selectable
            .where(
              (p) => '${p.label} ${Uri.tryParse(p.defaultBaseUrl)?.host ?? ''}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );
    return SettingsDialogFrame(
      title: '选择服务商',
      width: 860,
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
              height: 480,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final columns = constraints.maxWidth >= 700 * scale
                      ? 3
                      : constraints.maxWidth >= 450 * scale
                      ? 2
                      : 1;
                  if (choices.isEmpty) {
                    return const Center(child: Text('没有匹配的服务商'));
                  }
                  return GridView.builder(
                    key: const Key('provider-card-grid'),
                    padding: const EdgeInsets.only(bottom: 4),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 82 * scale,
                    ),
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final preset = choices[index],
                          selected = preset == widget.value.vendor;
                      return Semantics(
                        selected: selected,
                        button: true,
                        child: Material(
                          color: selected
                              ? theme.colorScheme.primary.withValues(alpha: .07)
                              : theme.colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: selected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: .4,
                                    )
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey('choose-provider-${preset.name}'),
                            onTap: () => Navigator.pop(context, preset),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  ProviderLogo(preset, size: 25),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          preset.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          preset.defaultBaseUrl.isEmpty
                                              ? '兼容接口 · 自行填写地址'
                                              : Uri.parse(
                                                  preset.defaultBaseUrl,
                                                ).host,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 7),
                                    Icon(
                                      Icons.check,
                                      size: 17,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
