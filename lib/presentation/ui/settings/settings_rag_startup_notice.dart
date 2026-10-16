import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'settings_kit.dart';

/// The same compact typography, surfaces and controls as the settings pages.
class SettingsRagStartupNotice extends StatelessWidget {
  const SettingsRagStartupNotice({
    super.key,
    required this.onContinue,
    required this.onClose,
  });

  final VoidCallback onContinue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Dialog(
      key: const Key('rag-startup-notice'),
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: UiGlyph(
                              UiGlyphs.layers,
                              size: 20,
                              color: c.accent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Text(
                                l.set_pageRag,
                                style: UiText.sans(11, color: c.muted),
                              ),
                              Semantics(
                                header: true,
                                child: Text(
                                  l.set_rgStartupTitle,
                                  style: UiText.sans(
                                    17,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SettingsIconBtn(
                          key: const Key('rag-startup-notice-close'),
                          glyph: UiGlyphs.close,
                          tooltip: l.common_close,
                          onTap: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l.set_rgStartupBody,
                      style: UiText.sans(12.5, color: c.muted, height: 1.65),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: c.sunk,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: UiGlyph(
                              UiGlyphs.clock,
                              size: 16,
                              color: c.muted,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 5,
                              children: [
                                Text(
                                  l.set_rgStartupWaitTitle,
                                  style: UiText.sans(
                                    12,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                    height: 1.4,
                                  ),
                                ),
                                Text(
                                  l.set_rgStartupWaitBody,
                                  style: UiText.sans(
                                    11.5,
                                    color: c.muted,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final note = Text(
                  l.set_rgStartupFrequency,
                  textAlign: constraints.maxWidth < 360
                      ? TextAlign.center
                      : TextAlign.start,
                  style: UiText.sans(11, color: c.faint, height: 1.4),
                );
                final button = ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 34),
                  child: SettingsBtn(
                    key: const Key('rag-startup-notice-ok'),
                    label: l.common_gotIt,
                    trailingChevron: true,
                    tone: SettingsBtnTone.primary,
                    onTap: onContinue,
                  ),
                );
                return UiDialogFooter(
                  children: constraints.maxWidth < 360
                      ? [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 10,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: button,
                                ),
                                note,
                              ],
                            ),
                          ),
                        ]
                      : [Expanded(child: note), button],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
