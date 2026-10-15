import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_language.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/locale_provider.dart';

/// A shared language picker for login and bootstrap, also used without Windows
/// chrome. Language names remain readable even if the current UI is unfamiliar.
class EntryLanguageButton extends ConsumerWidget {
  const EntryLanguageButton({
    super.key,
    this.width = 40,
    this.height = 36,
    this.iconSize = 15,
  });

  final double width;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = AppLanguage.fromLocale(ref.watch(localeNotifierProvider));
    return SizedBox(
      width: width,
      height: height,
      child: PopupMenuButton<AppLanguage>(
        key: const Key('brand_language_toggle'),
        tooltip: context.l10n.settings_language,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        constraints: const BoxConstraints(minWidth: 180),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          foregroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.9),
        ),
        icon: Icon(Icons.language_outlined, size: iconSize),
        itemBuilder: (context) => [
          for (final language in AppLanguage.values)
            CheckedPopupMenuItem(
              key: Key('brand_language_${language.storageCode}'),
              value: language,
              checked: language == current,
              child: Text(language.nativeName),
            ),
        ],
        onSelected: (language) => ref
            .read(localeNotifierProvider.notifier)
            .setLocale(language.storageCode),
      ),
    );
  }
}
