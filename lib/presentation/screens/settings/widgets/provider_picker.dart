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
  static const _order = [
    ProviderPreset.openaiCompatibleChat,
    ProviderPreset.openaiResponses,
    ProviderPreset.anthropic,
    ProviderPreset.gemini,
    ProviderPreset.xai,
    ProviderPreset.mistral,
    ProviderPreset.deepseek,
    ProviderPreset.qwen,
    ProviderPreset.moonshot,
    ProviderPreset.zhipu,
    ProviderPreset.minimax,
    ProviderPreset.doubao,
    ProviderPreset.hunyuan,
    ProviderPreset.qianfan,
    ProviderPreset.siliconflow,
    ProviderPreset.openrouter,
    ProviderPreset.groq,
    ProviderPreset.pollinations,
    ProviderPreset.lmStudioChat,
    ProviderPreset.ollama,
  ];
  String _label(ProviderPreset preset) =>
      preset == ProviderPreset.openaiCompatibleChat ? '自定义端点' : preset.label;
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices =
        ProviderPresetDefaults.selectable
            .where(
              (p) => '${_label(p)} ${p.label} ${p.defaultBaseUrl}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => _order.indexOf(a).compareTo(_order.indexOf(b)));
    return SettingsDialogFrame(
      title: '选择服务商',
      width: 1060,
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
          const SizedBox(height: 10),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final columns = constraints.maxWidth >= 850 * scale
                    ? 4
                    : constraints.maxWidth >= 650 * scale
                    ? 3
                    : constraints.maxWidth >= 430 * scale
                    ? 2
                    : 1;
                final rows =
                    (ProviderPresetDefaults.selectable.length / columns).ceil();
                return SizedBox(
                  height: (rows * (66 * scale + 6) - 2).clamp(0.0, 560.0),
                  child: choices.isEmpty
                      ? const Center(child: Text('没有匹配的服务商'))
                      : GridView.builder(
                          key: const Key('provider-card-grid'),
                          padding: const EdgeInsets.only(bottom: 4),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                mainAxisExtent: 66 * scale,
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
                                    ? theme.colorScheme.onSurface.withValues(
                                        alpha: .085,
                                      )
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: .04,
                                      ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: ValueKey(
                                    'choose-provider-${preset.name}',
                                  ),
                                  onTap: () => Navigator.pop(context, preset),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      children: [
                                        ProviderLogo(preset, size: 24),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _label(preset),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                preset.defaultBaseUrl.isEmpty
                                                    ? '填写兼容接口地址'
                                                    : preset.defaultBaseUrl
                                                          .replaceFirst(
                                                            RegExp(
                                                              r'^https?://',
                                                            ),
                                                            '',
                                                          ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
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
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
