import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../themes/studio_typography.dart';
import '../../generation/widgets/generation_param_sections.dart';
import 'explore_controls.dart';
import 'explore_text.dart';
import 'explore_style.dart';

class ExploreDrawCount extends StatefulWidget {
  const ExploreDrawCount({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;
  @override
  State<ExploreDrawCount> createState() => _ExploreDrawCountState();
}

class _ExploreDrawCountState extends State<ExploreDrawCount> {
  late final _text = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_blur);
  }

  void _blur() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final count = (int.tryParse(_text.text) ?? widget.value).clamp(
      1,
      ImageCountSection.maxRequests,
    );
    _text.text = '$count';
    if (count != widget.value) widget.onChanged(count);
  }

  @override
  void didUpdateWidget(ExploreDrawCount old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _text.text != '${widget.value}') {
      _text.text = '${widget.value}';
    }
  }

  void _step(int delta) {
    final count = ((int.tryParse(_text.text) ?? widget.value) + delta).clamp(
      1,
      ImageCountSection.maxRequests,
    );
    _text.text = '$count';
    widget.onChanged(count);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          ExploreText(
            l.styleExplore_drawCountLabel,
            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExploreIconButton(
                  'chevL',
                  key: const Key('explore-draw-count-down'),
                  width: 22,
                  height: 32,
                  size: 12,
                  onPressed: widget.value > 1 ? () => _step(-1) : null,
                ),
                SizedBox(
                  width: 34,
                  child: TextField(
                    key: const Key('explore-draw-count'),
                    controller: _text,
                    focusNode: _focus,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: StudioTypography.data.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (text) {
                      final n = int.tryParse(text);
                      if (n != null &&
                          n >= 1 &&
                          n <= ImageCountSection.maxRequests) {
                        widget.onChanged(n);
                      }
                    },
                    onSubmitted: (_) => _commit(),
                  ),
                ),
                ExploreIconButton(
                  'chevR',
                  key: const Key('explore-draw-count-up'),
                  width: 22,
                  height: 32,
                  size: 12,
                  onPressed: widget.value < ImageCountSection.maxRequests
                      ? () => _step(1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ExploreText(
              l.styleExplore_drawCountSuffix,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: ExploreStyle.faint(t)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focus.removeListener(_blur);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }
}
