import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';

class GalleryDeleteDialog extends StatelessWidget {
  const GalleryDeleteDialog({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onConfirm,
    this.fileName,
    this.permanent = false,
  });

  final int count;
  final String? fileName;
  final bool permanent;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static Future<bool> show(
    BuildContext context, {
    required int count,
    String? fileName,
    bool permanent = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(
          alpha: context.ui.dark ? .6 : .45,
        ),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: GalleryDeleteDialog(
            count: count,
            fileName: fileName,
            permanent: permanent,
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return UiPopoverSurface(
      key: const Key('gallery-delete-dialog'),
      width: 420,
      radius: 14,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: permanent
                          ? c.error.withValues(alpha: .12)
                          : c.hover,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: UiGlyph(
                      UiGlyphs.trash,
                      size: 17,
                      color: permanent ? c.error : c.muted,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            permanent
                                ? l.localGallery_deleteForeverTitle(count)
                                : l.localGallery_moveToDeletePoolTitle(count),
                            style: UiText.sans(
                              15,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (fileName case final name?)
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(12.5, color: c.muted),
                          ),
                        Text(
                          permanent
                              ? l.localGallery_deleteForeverDescription
                              : l.localGallery_moveToDeletePoolDescription,
                          style: UiText.sans(
                            12.5,
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
            UiDialogFooter(
              children: [
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      UiBtn(onTap: onCancel, children: [Text(l.common_cancel)]),
                      UiBtn(
                        key: const Key('gallery-delete-confirm'),
                        tone: permanent ? UiBtnTone.danger : UiBtnTone.primary,
                        onTap: onConfirm,
                        children: [
                          Text(
                            permanent
                                ? l.localGallery_deleteForever
                                : l.localGallery_moveToDeletePool,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
