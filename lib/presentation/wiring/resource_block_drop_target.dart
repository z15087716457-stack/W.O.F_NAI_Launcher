import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../core/utils/resource_window_drag.dart';
import '../widgets/common/app_toast.dart';
import 'blocks_actions.dart';

/// Native id-only block drop into a specific current editor lane. No styling;
/// existing insertion owns backup, latest-object and draft-version checks.
class ResourceBlockDropTarget extends ConsumerWidget {
  const ResourceBlockDropTarget({
    super.key,
    required this.scope,
    required this.child,
  });
  final String scope;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DropRegion(
    formats: [ResourceWindowDrag.block],
    hitTestBehavior: HitTestBehavior.translucent,
    onDropOver: (event) =>
        ResourceWindowDrag.operation(event.session, ResourceDragKind.block),
    onPerformDrop: (event) async {
      ResourceWindowDrag.receive(
        event,
        kind: ResourceDragKind.block,
        onReference: (reference) => unawaited(
          BlocksActions(
            ref,
            context,
            () => context.mounted,
          ).insert([reference.id], targetScope: scope),
        ),
        onError: (error) {
          if (context.mounted) AppToast.error(context, '$error');
        },
      );
    },
    child: child,
  );
}
