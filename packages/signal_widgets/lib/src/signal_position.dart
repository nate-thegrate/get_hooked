import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';
import 'signal_parent_data.dart';

/// A variant of [Positioned] where the layout is determined by a [SignalComputer] callback.
abstract class SignalPosition extends SignalParentData<StackParentData> {
  /// Positions the child using a [RelativeRect].
  const factory SignalPosition(
    SignalComputer<RelativeRect> getRect, {
    Key? key,
    required Widget child,
  }) = _RelativeRect;

  /// Positions the child using a [Rect].
  const factory SignalPosition.rect(
    SignalComputer<Rect> getRect, {
    Key? key,
    required Widget child,
  }) = _Rect;

  /// Initializes fields for subclasses.
  const SignalPosition.constructor({super.key, required super.child})
    : super(debugTypicalAncestorWidgetClass: Stack);
}

class _RelativeRect extends SignalPosition {
  const _RelativeRect(this.getRect, {super.key, required super.child}) : super.constructor();

  final SignalComputer<RelativeRect> getRect;

  @override
  bool shouldLayout(BuildContext context, StackParentData data) {
    final RelativeRect oldRect = data.rect;
    final RelativeRect newRect = getRect(context);

    data.rect = newRect;
    return newRect != oldRect;
  }
}

class _Rect extends SignalPosition {
  const _Rect(this.getRect, {super.key, required super.child}) : super.constructor();

  final SignalComputer<Rect> getRect;

  @override
  bool shouldLayout(BuildContext context, StackParentData data) {
    bool needsLayout = false;

    final Rect(:double top, :double left, :double width, :double height) = getRect(context);

    if (top != data.top) {
      data.top = top;
      needsLayout = true;
    }
    if (left != data.left) {
      data.left = left;
      needsLayout = true;
    }
    if (width != data.width) {
      data.width = width;
      needsLayout = true;
    }
    if (height != data.height) {
      data.height = height;
      needsLayout = true;
    }

    return needsLayout;
  }
}
