import 'package:flutter/material.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import 'provider_logo.dart';
import 'settings_dialog.dart';
import '../../../../core/utils/localization_extension.dart';

Future<ProviderPreset?> showProviderPicker(
  BuildContext context, [
  ProviderPreset? value,
]) => showDialog<ProviderPreset>(
  context: context,
  builder: (_) => _ProviderPicker(value: value),
);

class _ProviderPicker extends StatefulWidget {
  const _ProviderPicker({required this.value});
  final ProviderPreset? value;
  @override
  State<_ProviderPicker> createState() => _ProviderPickerState();
}

class _ProviderPickerState extends State<_ProviderPicker> {
  String _label(ProviderPreset preset) =>
      preset == ProviderPreset.openaiCompatibleChat
      ? context.l10n.modelProvider_customEndpoint
      : preset.labelIn(context.l10n);
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final choices = ProviderPresetDefaults.selectable
        .where(
          (p) => '${_label(p)} ${p.searchText}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return SettingsDialogFrame(
      title: context.l10n.modelProvider_pickerTitle,
      width: 1060,
      height: MediaQuery.sizeOf(context).height * .85,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          TextField(
            key: const Key('provider-search'),
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: context.l10n.modelProvider_pickerSearch,
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
                final api = choices.where((p) => !p.isLocal).toList();
                final local = choices.where((p) => p.isLocal).toList();
                return choices.isEmpty
                    ? Center(
                        child: Text(context.l10n.modelProvider_pickerEmpty),
                      )
                    : CustomScrollView(
                        key: const Key('provider-catalog-scroll'),
                        slivers: [
                          ..._section(
                            context,
                            context.l10n.modelProvider_groupApiKey,
                            api,
                            columns,
                            scale,
                            const Key('provider-card-grid'),
                          ),
                          ..._section(
                            context,
                            context.l10n.modelProvider_groupLocal,
                            local,
                            columns,
                            scale,
                            const Key('provider-local-grid'),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 4)),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<ProviderPreset> choices,
    int columns,
    double scale,
    Key key,
  ) {
    if (choices.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      SliverGrid(
        key: key,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          mainAxisExtent: 50 * scale,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _card(context, choices[index]),
          childCount: choices.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
    ];
  }

  Widget _card(BuildContext context, ProviderPreset preset) {
    final theme = Theme.of(context);
    final selected = preset == widget.value?.vendor;
    final address = preset.defaultBaseUrl.isEmpty
        ? context.l10n.modelProvider_enterCompatibleAddress
        : preset.defaultBaseUrl.replaceFirst(RegExp(r'^https?://'), '');
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: '${_label(preset)}\n$address',
        child: Material(
          color: theme.colorScheme.onSurface.withValues(
            alpha: selected ? .085 : .04,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('choose-provider-${preset.name}'),
            onTap: () => Navigator.pop(context, preset),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  ProviderLogo(preset, size: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(preset),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
