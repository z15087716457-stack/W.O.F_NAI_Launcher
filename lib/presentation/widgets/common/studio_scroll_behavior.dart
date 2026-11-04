import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudioScrollBehavior extends MaterialScrollBehavior {
  const StudioScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      getPlatform(context) == TargetPlatform.macOS
      ? const _MacScrollPhysics(parent: RangeMaintainingScrollPhysics())
      : super.getScrollPhysics(context);
}

/// Keep Flutter's macOS velocity tracking, spring and fast desktop deceleration.
/// Apply edge resistance from the first pixel past the boundary, including
/// when macOS combines several trackpad updates into one event.
class _MacScrollPhysics extends BouncingScrollPhysics {
  const _MacScrollPhysics({super.parent})
    : super(decelerationRate: ScrollDecelerationRate.fast);

  @override
  _MacScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _MacScrollPhysics(parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final direction = offset.sign;
    final edge = direction > 0
        ? position.minScrollExtent
        : position.maxScrollExtent;
    final toEdge = (position.pixels - edge) * direction;
    final distance = offset.abs();
    if (distance <= toEdge) {
      return super.applyPhysicsToUserOffset(position, offset);
    }

    final inBounds = math.max(0.0, toEdge);
    final past = math.max(0.0, -toEdge);
    final remaining = position.viewportDimension - past;
    if (remaining <= 0) return direction * inBounds;

    // Integrate Flutter's quadratic frictionFactor over the whole pull. This
    // is the same resistance curve whether macOS delivers one big delta or
    // many small ones. Approaching one viewport of stretch takes unbounded input.
    final pull =
        (distance - inBounds) *
        frictionFactor(past / position.viewportDimension);
    final stretch = remaining * (pull / (remaining + pull));
    return direction * (inBounds + stretch);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Controller-less vertical lists implicitly get AlwaysScrollableScrollPhysics.
    // A gesture on a list that fits should leave its content in place.
    if (position.minScrollExtent == position.maxScrollExtent) {
      return const ClampingScrollPhysics().applyBoundaryConditions(
        position,
        value,
      );
    }
    return super.applyBoundaryConditions(position, value);
  }
}

/// A vertical wheel can advance a horizontal strip. Keep true horizontal input
/// and two-finger gestures on the Scrollable's normal axis/direction pipeline.
/// At a boundary the nearest ancestor that can move gets the tick.
void scrollStripWithWheel(
  ScrollController controller,
  PointerSignalEvent event,
) {
  if (event is! PointerScrollEvent ||
      event.kind == PointerDeviceKind.trackpad ||
      (event.kind == PointerDeviceKind.mouse &&
          HardwareKeyboard.instance.isShiftPressed) ||
      event.scrollDelta.dx != 0 ||
      event.scrollDelta.dy == 0 ||
      !controller.hasClients) {
    return;
  }
  final position = controller.position;
  final delta = event.scrollDelta.dy;
  if (!position.hasContentDimensions ||
      (delta > 0 ? position.extentAfter : position.extentBefore) <= 0) {
    return;
  }
  GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
    position.pointerScroll(delta);
    (resolved as PointerScrollEvent).respond(allowPlatformDefault: false);
  });
}
