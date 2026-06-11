import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/src/listenables/ref.dart';

import 'ref_parent_data.dart';

/// A variant of [Positioned] where the layout is determined by a [RefComputer] callback.
abstract class RefPosition extends RefParentData<StackParentData> {
  /// Positions the child using a [RelativeRect].
  const factory RefPosition(
    RefComputer<RelativeRect> getRect, {
    Key? key,
    required Widget child,
  }) = _RelativeRect;

  /// Positions the child using a [Rect].
  const factory RefPosition.rect(
    RefComputer<Rect> getRect, { //
    Key? key,
    required Widget child,
  }) = _Rect;

  /// Initializes fields for subclasses.
  const RefPosition.constructor({super.key, required super.child});
}

class _RelativeRect extends RefPosition {
  const _RelativeRect(this.getRect, {super.key, required super.child}) : super.constructor();

  final RefComputer<RelativeRect> getRect;

  @override
  bool shouldLayout(Ref ref, StackParentData data) {
    final RelativeRect oldRect = data.rect;
    final RelativeRect newRect = getRect(ref);

    data.rect = newRect;
    return newRect != oldRect;
  }
}

class _Rect extends RefPosition {
  const _Rect(this.getRect, {super.key, required super.child}) : super.constructor();

  final RefComputer<Rect> getRect;

  @override
  bool shouldLayout(Ref ref, StackParentData data) {
    bool needsLayout = false;

    final Rect(:double top, :double left, :double width, :double height) = getRect(ref);

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
