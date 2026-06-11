import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

/// A variant of [Opacity] that evaluates based on a [RefComputer<double>].
class RefAlign extends SingleChildRenderObjectWidget {
  /// Creates a [Opacity] widget using the provided [RefComputer] callback.
  const RefAlign(this.alignment, {super.key, this.widthFactor, this.heightFactor, super.child});

  /// Computes the [child]'s alignment.
  ///
  /// The x and y values of the [Alignment] control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// See also:
  ///
  ///  * [Alignment], which has more details and some convenience constants for
  ///    common positions.
  ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
  ///    that depends on the [TextDirection].
  final RefComputer<AlignmentGeometry> alignment;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be non-negative.
  final double? widthFactor;

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be non-negative.
  final double? heightFactor;

  @override
  RenderPositionedBox createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBox renderObject) {
    renderObject
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.of(context);
  }

  @override
  SingleChildRenderObjectElement createElement() => _AlignElement(this);
}

class _AlignElement extends SingleChildComputeElement<RenderPositionedBox> {
  _AlignElement(super.widget);

  @override
  void recompute() {
    renderer.alignment = (widget as RefAlign).alignment(this);
  }
}
