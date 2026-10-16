import 'package:flutter/material.dart';

import '../ui/kit/ui_colors.dart';
import '../widgets/common/image_detail/components/detail_prompt_section.dart';

/// Shares the local gallery's explicit translation and isolated pill document.
Widget buildOnlineTranslation(
  BuildContext context,
  String identity,
  String content,
  Widget Function(Widget action, Widget? translated) section,
) => PromptSection(
  key: ValueKey('online-translation-$identity'),
  title: '',
  icon: Icons.translate,
  content: content,
  sectionBuilder: (context, action, translated) => section(
    action,
    translated == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.ui.raised,
              border: Border.all(color: context.ui.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: translated,
          ),
  ),
);
