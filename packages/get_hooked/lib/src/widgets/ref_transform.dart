import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/element_vsync_mixin.dart';

/// A variant of [Transform] that evaluates based on a [RefComputer<Matrix4>].
abstract class RefTransform extends SingleChildRenderObjectWidget {
  /// Creates a [Transform] widget using the provided [RefComputer] callback.
  const factory RefTransform(RefComputer<Matrix4> transform, {Key? key, required Widget child}) =
      _RefTransform;

  /// Initializes fields for subclasses.
  const RefTransform.constructor({super.key, required Widget super.child});

  /// The transformation to apply to the [child] (and its descendants).
  Matrix4 transform(Ref ref);

  static final _noTransform = Matrix4.identity();

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTransform(transform: _noTransform);
  }

  @override
  SingleChildRenderObjectElement createElement() => _TransformElement(this);
}

class _RefTransform extends RefTransform {
  const _RefTransform(this._transform, {super.key, required super.child}) : super.constructor();

  final RefComputer<Matrix4> _transform;

  @override
  Matrix4 transform(Ref ref) => _transform(ref);
}

class _TransformElement extends SingleChildComputeElement<RenderTransform> {
  _TransformElement(super.widget);

  @override
  void recompute() {
    renderObject.transform = (widget as RefTransform).transform(this);
  }
}
