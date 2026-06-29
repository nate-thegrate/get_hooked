import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';

/// A variant of [Transform] that evaluates based on a [RefComputer<Matrix4>].
class RefTransform extends SingleChildRenderObjectWidget {
  /// Creates a [Transform] widget using the provided [RefComputer] callback.
  ///
  /// [transformHitTests] defaults to `true`.
  const RefTransform(
    this.transform, {
    super.key,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  });

  /// The transformation to apply to the [child] (and its descendants).
  final RefComputer<Matrix4> transform;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? alignment;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// {@macro flutter.widgets.Transform.optional.FilterQuality}
  final FilterQuality? filterQuality;

  static final _noTransform = Matrix4.identity();

  @override
  RenderTransform createRenderObject(BuildContext context) {
    return RenderTransform(
      transform: _noTransform,
      origin: origin,
      alignment: alignment,
      transformHitTests: transformHitTests,
      filterQuality: filterQuality,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..origin = origin
      ..alignment = alignment
      ..transformHitTests = transformHitTests
      ..filterQuality = filterQuality;
  }

  @override
  SingleChildRenderObjectElement createElement() => _TransformElement(this);
}

class _TransformElement extends SingleChildComputeElement<RenderTransform> {
  _TransformElement(super.widget);

  @override
  void recompute() {
    renderer.transform = (widget as RefTransform).transform(this);
  }
}
