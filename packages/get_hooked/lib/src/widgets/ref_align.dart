import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';

/// A variant of [Align] that evaluates based on a [RefComputer<AlignmentGeometry>].
class RefAlign extends SingleChildRenderObjectWidget {
  /// Creates a [Align] widget using the provided [RefComputer] callback.
  const RefAlign(this.alignment, {super.key, super.child});

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

  @override
  RenderRefAlign createRenderObject(BuildContext context) => RenderRefAlign();

  @override
  SingleChildRenderObjectElement createElement() => _AlignElement(this);
}

class _AlignElement extends SingleChildComputeElement<RenderRefAlign> {
  _AlignElement(super.widget);

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment = .center;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;

    renderer.alignment = switch (_alignment = value) {
      final Alignment alignment => alignment,
      final AlignmentGeometry alignment => alignment.resolve(Directionality.of(this)),
    };
  }

  @override
  void recompute() {
    alignment = (widget as RefAlign).alignment(this);
  }
}

/// Positions its child using an [Alignment].
///
/// For example, to align a box at the bottom right, pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [Alignment.bottomRight].
///
/// By default, sizes to be as big as possible in both axes. If either axis is
/// unconstrained, then in that direction it will be sized to fit the child's
/// dimensions.
class RenderRefAlign extends RenderShiftedBox {
  /// Creates a render object that positions its child.
  RenderRefAlign() : super(null);

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  @protected
  Alignment get alignment => _alignment;
  Alignment _alignment = .center;
  set alignment(Alignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsPaint();
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final Size childSize = child?.getDryLayout(constraints.loosen()) ?? .zero;
    return constraints.constrain(
      Size(
        constraints.maxWidth == .infinity ? childSize.width : .infinity,
        constraints.maxHeight == .infinity ? childSize.height : .infinity,
      ),
    );
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    child?.layout(constraints.loosen(), parentUsesSize: true);
    final Size childSize = child?.size ?? .zero;
    size = constraints.constrain(
      Size(
        constraints.maxWidth == .infinity ? childSize.width : .infinity,
        constraints.maxHeight == .infinity ? childSize.height : .infinity,
      ),
    );
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    if (kDebugMode) {
      if (child != null && !child!.size.isEmpty) {
        final path = Path();
        final paint = Paint()
          ..style = .stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFFFF00);
        final childParentData = child!.parentData! as BoxParentData;
        if (childParentData.offset.dy > 0.0) {
          // vertical alignment arrows
          final double headSize = math.min(childParentData.offset.dy * 0.2, 10.0);
          path
            ..moveTo(offset.dx + size.width / 2.0, offset.dy)
            ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, 0.0)
            ..moveTo(offset.dx + size.width / 2.0, offset.dy + size.height)
            ..relativeLineTo(0.0, -childParentData.offset.dy + headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(headSize, 0.0);
          context.canvas.drawPath(path, paint);
        }
        if (childParentData.offset.dx > 0.0) {
          // horizontal alignment arrows
          final double headSize = math.min(childParentData.offset.dx * 0.2, 10.0);
          path
            ..moveTo(offset.dx, offset.dy + size.height / 2.0)
            ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(0.0, headSize)
            ..moveTo(offset.dx + size.width, offset.dy + size.height / 2.0)
            ..relativeLineTo(-childParentData.offset.dx + headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(0.0, headSize);
          context.canvas.drawPath(path, paint);
        }
      } else {
        context.canvas.drawRect(offset & size, Paint()..color = const Color(0x90909090));
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child case final child?) {
      assert(!child.debugNeedsLayout);
      assert(child.hasSize);
      assert(hasSize);
      final childParentData = child.parentData! as BoxParentData;
      childParentData.offset = alignment.alongOffset(size - child.size as Offset);
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    final RenderBox? child = this.child;
    if (child == null) return null;

    final BoxConstraints childConstraints = constraints.loosen();
    final double? result = child.getDryBaseline(childConstraints, baseline);
    if (result == null) return null;

    final Size childSize = child.getDryLayout(childConstraints);
    final Size size = constraints.constrain(
      Size(
        constraints.maxWidth == .infinity ? childSize.width : .infinity,
        constraints.maxHeight == .infinity ? childSize.height : .infinity,
      ),
    );

    return result + alignment.alongOffset(size - childSize as Offset).dy;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('alignment', _alignment));
  }
}
