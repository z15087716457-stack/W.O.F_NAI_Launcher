import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ui_scale_provider.dart';
import '../../ui/kit/ui_scale.dart';

class AppUiScale extends ConsumerWidget {
  const AppUiScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UiScale(scale: ref.watch(uiScaleProvider), child: child);
}
