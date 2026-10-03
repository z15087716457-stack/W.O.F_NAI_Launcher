import 'package:flutter/material.dart';
import 'settings_dialog.dart';
import '../../../../core/utils/localization_extension.dart';

class SettingsNumberDialog extends StatefulWidget {
  const SettingsNumberDialog({
    super.key,
    required this.title,
    required this.label,
    required this.description,
    required this.value,
    this.suffix = '',
    this.minValue = 1,
    this.maxValue,
    this.invalidValueText,
  });
  final String title, label, description, suffix;
  final int value;
  final int minValue;
  final int? maxValue;
  final String? invalidValueText;
  @override
  State<SettingsNumberDialog> createState() => _SettingsNumberDialogState();
}

class _SettingsNumberDialogState extends State<SettingsNumberDialog> {
  late final _controller = TextEditingController(text: '${widget.value}');
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final number = int.tryParse(_controller.text.trim());
    if (number == null ||
        number < widget.minValue ||
        (widget.maxValue != null && number > widget.maxValue!)) {
      setState(
        () => _error =
            widget.invalidValueText ??
            context.l10n.settings_positiveIntegerRequired,
      );
      return;
    }
    Navigator.pop(context, number);
  }

  @override
  Widget build(BuildContext context) => SettingsDialogFrame(
    title: widget.title,
    width: 420,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.common_cancel),
      ),
      FilledButton(
        key: const Key('settings-save-number'),
        onPressed: _save,
        child: Text(context.l10n.common_save),
      ),
    ],
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('settings-positive-number'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: widget.label,
              suffixText: widget.suffix,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
          ),
        ],
      ),
    ),
  );
}
